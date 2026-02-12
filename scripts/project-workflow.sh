#!/bin/bash
# 3-AI Collaboration System - Project Workflow
# Automated 6-phase design -> implementation -> deploy flow

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# Use current working directory (actual project)
PROJECT_DIR="${PWD}"
# shellcheck disable=SC2034
TEMPLATE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
# shellcheck disable=SC2034
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# State management
STATE_FILE=""
LOCK_FILE=""
FEATURE=""
CURRENT_PHASE=1
TOTAL_PHASES=6

# Log output
log_phase() {
    local phase=$1
    local desc=$2
    local ai=$3
    echo -e "\n${BOLD}[${phase}/${TOTAL_PHASES}]${NC} ${CYAN}${desc}${NC} ${PURPLE}(${ai})${NC}"
}

log_info() { echo -e "${CYAN}    →${NC} $1"; }
log_success() { echo -e "${GREEN}    ✓${NC} $1"; }
log_warn() { echo -e "${YELLOW}    ⚠${NC} $1"; }
log_error() { echo -e "${RED}    ✗${NC} $1"; }

# Show help
show_help() {
    cat << EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /project Workflow
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Usage:
  $0 <feature> [options]

Examples:
  $0 "user-auth"
  $0 "search" --from=3
  $0 "dashboard" --skip=1,2

Options:
  --from=N        Start from phase N
  --skip=N,M      Skip specified phases
  --auto          Auto-approve all phases
  --dry-run       Preview without executing
  --force-unlock  Force-release a stale lock

Phases:
  [1] Requirements (Claude)  -> docs/requirements/{feature}.md
  [2] Design       (Claude)  -> docs/specs/{feature}.md
  [3] Implement    (Codex)   -> src/**/*
  [4] Test         (Codex)   -> tests/**/*
  [5] Review       (Claude)  -> docs/reviews/{feature}.md
  [6] Deploy       (Claude)  -> Final check

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
}

# ===== Team locking =====

# Read team config if available
TEAM_CONFIG_FILE="${PROJECT_DIR}/.claude/team-config.yaml"
LOCK_TIMEOUT_MINUTES=60

if [ -f "$TEAM_CONFIG_FILE" ]; then
    _timeout=$(grep 'lock_timeout_minutes:' "$TEAM_CONFIG_FILE" 2>/dev/null | sed 's/.*: *//')
    if [ -n "$_timeout" ]; then
        LOCK_TIMEOUT_MINUTES="$_timeout"
    fi
fi

acquire_lock() {
    LOCK_FILE="${PROJECT_DIR}/.project-state-${FEATURE_SLUG}.lock"
    LOCK_FD=9

    # Try atomic lock with flock if available (Linux), fall back to mkdir (portable)
    if command -v flock &>/dev/null; then
        _acquire_lock_flock
    else
        _acquire_lock_mkdir
    fi
}

_acquire_lock_flock() {
    # Open lock file descriptor for flock
    eval "exec ${LOCK_FD}>\"${LOCK_FILE}\""

    if ! flock -n "$LOCK_FD" 2>/dev/null; then
        # Lock held by another process — read owner info
        local lock_owner
        lock_owner=$(head -1 "$LOCK_FILE" 2>/dev/null || echo "unknown")
        log_error "Feature '${FEATURE}' is locked by: ${lock_owner}"
        log_info "Use --force-unlock to override"
        exit 1
    fi

    # Write owner info (we hold the flock)
    echo "$(whoami)@$(hostname)" > "$LOCK_FILE"
    date +%s >> "$LOCK_FILE"
}

_acquire_lock_mkdir() {
    # mkdir is atomic on all filesystems including NFS
    local lock_dir="${LOCK_FILE}.d"

    if mkdir "$lock_dir" 2>/dev/null; then
        # We got the lock — write info
        echo "$(whoami)@$(hostname)" > "$LOCK_FILE"
        date +%s >> "$LOCK_FILE"
        return 0
    fi

    # Lock exists — check staleness
    if [ -f "$LOCK_FILE" ]; then
        local lock_owner lock_time current_time age_minutes
        lock_owner=$(head -1 "$LOCK_FILE" 2>/dev/null || echo "unknown")
        lock_time=$(sed -n '2p' "$LOCK_FILE" 2>/dev/null || echo "0")
        current_time=$(date +%s)
        age_minutes=$(( (current_time - lock_time) / 60 ))

        if [ "$age_minutes" -ge "$LOCK_TIMEOUT_MINUTES" ]; then
            log_warn "Stale lock detected (${age_minutes}min old, owner: ${lock_owner}). Auto-releasing."
            rm -rf "$lock_dir"
            rm -f "$LOCK_FILE"
            # Retry once
            if mkdir "$lock_dir" 2>/dev/null; then
                echo "$(whoami)@$(hostname)" > "$LOCK_FILE"
                date +%s >> "$LOCK_FILE"
                return 0
            fi
        fi

        log_error "Feature '${FEATURE}' is locked by: ${lock_owner} (${age_minutes}min ago)"
        log_info "Use --force-unlock to override"
        exit 1
    fi

    log_error "Lock acquisition failed for '${FEATURE}'"
    exit 1
}

release_lock() {
    if [ -n "${LOCK_FILE:-}" ]; then
        rm -f "$LOCK_FILE"
        rm -rf "${LOCK_FILE}.d" 2>/dev/null || true
        # Release flock fd if held
        eval "exec ${LOCK_FD:-9}>&-" 2>/dev/null || true
    fi
}

force_unlock() {
    local slug="$1"
    local lock="${PROJECT_DIR}/.project-state-${slug}.lock"
    if [ -f "$lock" ] || [ -d "${lock}.d" ]; then
        log_warn "Force-removing lock: $lock"
        rm -f "$lock"
        rm -rf "${lock}.d" 2>/dev/null || true
        log_success "Lock released"
    else
        log_info "No lock found for: $slug"
    fi
}

# Save state
save_state() {
    echo "$CURRENT_PHASE" > "$STATE_FILE"
}

# Load state
load_state() {
    if [ -f "$STATE_FILE" ]; then
        CURRENT_PHASE=$(cat "$STATE_FILE")
    fi
}

# User confirmation
ask_approval() {
    local message="$1"
    if [ "$AUTO_APPROVE" = "true" ]; then
        echo "Y (auto-approved)"
        return 0
    fi

    echo -e "\n${YELLOW}${message}${NC}"
    read -p "Approve? [Y/n/reject reason] > " answer

    case "$answer" in
        [Yy]|"")
            return 0
            ;;
        [Nn])
            return 1
            ;;
        reject*)
            local reason="${answer#reject }"
            log_warn "Rejected: ${reason}"
            return 2
            ;;
        *)
            return 1
            ;;
    esac
}

# Phase 1: Requirements
phase_requirements() {
    log_phase 1 "Generating requirements..." "Claude"

    local output_dir="${PROJECT_DIR}/docs/requirements"
    local output_file="${output_dir}/${FEATURE_SLUG}.md"
    mkdir -p "$output_dir"

    # Claudeに要件定義を生成させる（このスクリプト自体がClaudeから呼ばれる想定）
    cat << EOF > "$output_file"
# 要件定義: ${FEATURE}

**作成日**: $(date '+%Y-%m-%d')
**ステータス**: Draft

---

## ユーザーストーリー

AS A ユーザー
I WANT TO ${FEATURE}
SO THAT 目的を達成できる

---

## 受入条件

### 機能要件
- [ ] 条件1: （詳細を記述）
- [ ] 条件2: （詳細を記述）
- [ ] 条件3: （詳細を記述）

### 非機能要件
- **パフォーマンス**: ページロード3秒以内
- **セキュリティ**: OWASP Top 10対策
- **アクセシビリティ**: WCAG 2.1 AA準拠

---

## 制約事項

- **フレームワーク**: Next.js 14 App Router
- **言語**: TypeScript
- **スタイリング**: Tailwind CSS
- **データベース**: (指定があれば)

---

## 画面一覧

| 画面名 | パス | 概要 |
|--------|------|------|
| ${FEATURE}画面 | /${FEATURE_SLUG} | メイン画面 |

---

## 備考

（補足事項があれば記載）
EOF

    log_info "→ ${output_file}"

    # 内容を表示
    echo ""
    echo "───────────────────────────────────────"
    head -40 "$output_file"
    echo "..."
    echo "───────────────────────────────────────"

    if ask_approval "Approve requirements?"; then
        log_success "Requirements approved"
        return 0
    else
        return 1
    fi
}

# Phase 2: Design
phase_design() {
    log_phase 2 "Generating design..." "Claude"

    local spec_dir="${PROJECT_DIR}/docs/specs"
    local api_dir="${PROJECT_DIR}/docs/api"
    mkdir -p "$spec_dir" "$api_dir"

    local spec_file="${spec_dir}/${FEATURE_SLUG}.md"
    local api_file="${api_dir}/${FEATURE_SLUG}.yaml"

    # 画面設計
    cat << EOF > "$spec_file"
# 画面設計: ${FEATURE}

**作成日**: $(date '+%Y-%m-%d')
**関連要件**: docs/requirements/${FEATURE_SLUG}.md

---

## 概要

${FEATURE}の画面設計書です。

---

## コンポーネント構成

| コンポーネント | 種類 | 説明 |
|--------------|------|------|
| ${FEATURE}Page | Page | メインページ |
| ${FEATURE}Form | Component | 入力フォーム |
| ${FEATURE}List | Component | 一覧表示 |

---

## 状態遷移

| 状態 | トリガー | 遷移先 |
|------|---------|--------|
| 初期表示 | ページロード | データ取得中 |
| データ取得中 | API応答 | 表示完了 |
| エラー | API失敗 | エラー表示 |

---

## インタラクション

- **送信ボタン**: フォームをバリデーション後、API呼び出し
- **キャンセル**: 入力内容をクリア
- **削除**: 確認ダイアログ後、削除実行
EOF

    log_info "→ ${spec_file}"

    # API設計
    cat << EOF > "$api_file"
openapi: 3.0.0
info:
  title: ${FEATURE} API
  version: 1.0.0
  description: ${FEATURE}機能のAPI仕様

paths:
  /api/${FEATURE_SLUG}:
    get:
      summary: ${FEATURE}一覧取得
      responses:
        '200':
          description: 成功
          content:
            application/json:
              schema:
                type: array
                items:
                  \$ref: '#/components/schemas/${FEATURE}Item'

    post:
      summary: ${FEATURE}作成
      requestBody:
        required: true
        content:
          application/json:
            schema:
              \$ref: '#/components/schemas/${FEATURE}Input'
      responses:
        '201':
          description: 作成成功
        '400':
          description: バリデーションエラー

  /api/${FEATURE_SLUG}/{id}:
    get:
      summary: ${FEATURE}詳細取得
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
      responses:
        '200':
          description: 成功
        '404':
          description: 見つからない

components:
  schemas:
    ${FEATURE}Item:
      type: object
      properties:
        id:
          type: string
        name:
          type: string
        createdAt:
          type: string
          format: date-time

    ${FEATURE}Input:
      type: object
      required:
        - name
      properties:
        name:
          type: string
EOF

    log_info "→ ${api_file}"

    if ask_approval "Approve design?"; then
        log_success "Design approved"
        return 0
    else
        return 1
    fi
}

# Phase 3: Implementation
phase_implement() {
    log_phase 3 "Implementing..." "Codex - full-auto"
    log_warn "Delegating to Codex (requires ChatGPT Pro)"

    if command -v codex &> /dev/null; then
        bash "$SCRIPT_DIR/delegate.sh" codex implement "$FEATURE_SLUG" --full-auto
        log_success "Implementation complete"
    else
        log_warn "Codex not installed, skipping"
        log_info "Please implement manually: src/app/${FEATURE_SLUG}/"
    fi

    return 0
}

# Phase 4: Testing
phase_test() {
    log_phase 4 "Generating tests..." "Codex"

    if command -v codex &> /dev/null; then
        bash "$SCRIPT_DIR/delegate.sh" codex test "$FEATURE_SLUG" --full-auto
        log_success "Tests generated"
    else
        log_warn "Codex not installed, skipping"
        log_info "Please create tests manually: tests/${FEATURE_SLUG}.spec.ts"
    fi

    return 0
}

# Phase 5: Review
phase_review() {
    log_phase 5 "Reviewing..." "Claude"

    local review_dir="${PROJECT_DIR}/docs/reviews"
    mkdir -p "$review_dir"
    local review_file="${review_dir}/${FEATURE_SLUG}.md"

    cat << EOF > "$review_file"
# コードレビュー: ${FEATURE}

**レビュー日**: $(date '+%Y-%m-%d')
**レビュアー**: Claude Code

---

## サマリー

| 項目 | 結果 |
|------|------|
| 受入条件 | - / - クリア |
| テストカバレッジ | - % |
| 改善提案 | - 件 |
| ブロッカー | 0 件 |

## 判定: ⏳ レビュー中

---

## 受入条件チェック

### 機能要件
- [ ] 条件1: 確認中
- [ ] 条件2: 確認中

### UI/UX要件
- [ ] レスポンシブデザイン
- [ ] キーボードナビゲーション

---

## セキュリティチェック

| チェック項目 | 結果 | 該当箇所 |
|-------------|:----:|---------:|
| XSS対策 | ⏳ | - |
| CSRF対策 | ⏳ | - |
| 認証/認可 | ⏳ | - |

---

## 改善提案

（レビュー後に記載）

---

## 結論

（レビュー完了後に判定）
EOF

    log_info "→ ${review_file}"
    log_success "Review template created"
    log_info "Run detailed review with Claude Code"

    return 0
}

# Phase 6: Deploy
phase_deploy() {
    log_phase 6 "Deploy ready" "Claude"

    echo ""
    echo "───────────────────────────────────────"
    echo "Review results:"
    echo "  Acceptance criteria: pending"
    echo "  Tests: not executed"
    echo "───────────────────────────────────────"

    if ask_approval "Deploy to production?"; then
        log_info "Deploying..."

        if command -v vercel &> /dev/null; then
            vercel --prod
            log_success "Deploy complete!"
        else
            log_warn "Vercel not installed"
            log_info "Please deploy manually: vercel --prod"
        fi
    else
        log_warn "Deploy skipped"
    fi

    return 0
}

# Main
main() {
    # Check --help first
    for arg in "$@"; do
        case "$arg" in
            --help|-h|help)
                show_help
                exit 0
                ;;
        esac
    done

    if [ $# -lt 1 ]; then
        show_help
        exit 0
    fi

    FEATURE="$1"
    # If contains non-ASCII (e.g. Japanese), use as-is; otherwise lowercase
    if echo "$FEATURE" | grep -q '[^a-zA-Z0-9 -]'; then
        # Non-ASCII: replace spaces with hyphens
        FEATURE_SLUG=$(echo "$FEATURE" | sed 's/ /-/g')
    else
        # ASCII only: lowercase and replace spaces with hyphens
        FEATURE_SLUG=$(echo "$FEATURE" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')
    fi
    STATE_FILE="${PROJECT_DIR}/.project-state-${FEATURE_SLUG}"

    shift

    # Parse options
    local start_phase=1
    local skip_phases=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --from=*)
                start_phase="${1#--from=}"
                ;;
            --skip=*)
                skip_phases="${1#--skip=}"
                ;;
            --auto)
                AUTO_APPROVE=true
                ;;
            --dry-run)
                DRY_RUN=true
                ;;
            --force-unlock)
                force_unlock "$FEATURE_SLUG"
                exit 0
                ;;
        esac
        shift
    done

    # Acquire lock for team coordination
    acquire_lock
    trap release_lock EXIT

    CURRENT_PHASE=$start_phase

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${BOLD}Project started: ${FEATURE}${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Execute each phase
    local phases=(phase_requirements phase_design phase_implement phase_test phase_review phase_deploy)

    for i in "${!phases[@]}"; do
        local phase_num=$((i + 1))

        # Skip phases before start phase
        if [ $phase_num -lt $start_phase ]; then
            continue
        fi

        # Skip specified phases
        if [[ ",$skip_phases," == *",$phase_num,"* ]]; then
            log_warn "Skipping phase ${phase_num}"
            continue
        fi

        CURRENT_PHASE=$phase_num
        save_state

        if [ "$DRY_RUN" = "true" ]; then
            log_info "[DRY-RUN] ${phases[$i]} をスキップ"
            continue
        fi

        ${phases[$i]}

        if [ $? -ne 0 ]; then
            log_error "Interrupted at phase ${phase_num}"
            log_info "Resume: $0 \"${FEATURE}\" --from=${phase_num}"
            exit 1
        fi
    done

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${GREEN}Project complete!${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Generated files:"
    echo "  📄 docs/requirements/${FEATURE_SLUG}.md"
    echo "  📄 docs/specs/${FEATURE_SLUG}.md"
    echo "  📄 docs/api/${FEATURE_SLUG}.yaml"
    echo "  📄 docs/reviews/${FEATURE_SLUG}.md"
    echo ""

    # Remove state file
    rm -f "$STATE_FILE"
}

main "$@"
