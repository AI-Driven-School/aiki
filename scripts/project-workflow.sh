#!/bin/bash
# 4-AI Collaboration System - Project Workflow
# Automated 6-phase design -> implementation -> deploy flow

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# Use current working directory (actual project)
PROJECT_DIR="${PWD}"
# shellcheck disable=SC2034
TEMPLATE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Load knowledge loop if available
if [ -f "${SCRIPT_DIR}/lib/knowledge-loop.sh" ]; then
    # shellcheck source=lib/knowledge-loop.sh
    source "${SCRIPT_DIR}/lib/knowledge-loop.sh"
fi

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
AUTO_APPROVE=false
DRY_RUN=false

# Language flag (default: ja for backward compatibility)
LANG_FLAG="ja"

# Timing & cost tracking
PHASE_DURATIONS=("" "" "" "" "" "" "")  # index 1-6
PHASE_STARTS=("" "" "" "" "" "" "")
WORKFLOW_START=""
TOTAL_CLAUDE_CHARS=0

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

# ===== Timing helpers =====

start_timer() {
    local phase_num=$1
    PHASE_STARTS[$phase_num]=$(date +%s)
}

end_timer() {
    local phase_num=$1
    local start=${PHASE_STARTS[$phase_num]}
    if [ -n "$start" ]; then
        local end
        end=$(date +%s)
        PHASE_DURATIONS[$phase_num]=$((end - start))
    fi
}

format_duration() {
    local seconds=$1
    if [ "$seconds" -ge 60 ]; then
        local mins=$((seconds / 60))
        local secs=$((seconds % 60))
        echo "${mins}m ${secs}s"
    else
        echo "${seconds}s"
    fi
}

# ===== Claude CLI integration =====

invoke_claude() {
    local prompt="$1"
    local output_file="$2"
    local fallback_func="$3"

    if command -v claude &>/dev/null; then
        log_info "Calling Claude CLI..."
        local result
        if result=$(timeout 120 claude -p "$prompt" 2>/dev/null); then
            echo "$result" > "$output_file"
            local char_count=${#result}
            TOTAL_CLAUDE_CHARS=$((TOTAL_CLAUDE_CHARS + char_count))
            log_success "AI-generated content (${char_count} chars)"
            return 0
        else
            log_warn "Claude CLI failed, using fallback template"
            $fallback_func "$output_file"
            return 0
        fi
    else
        log_info "Claude CLI not found, using template"
        $fallback_func "$output_file"
        return 0
    fi
}

# Compute weakness profile from metrics.jsonl for a feature
compute_weakness_profile() {
    local feature="$1"
    local metrics_file="${PROJECT_DIR}/.claude/docs/metrics.jsonl"

    if [ ! -f "$metrics_file" ]; then
        return
    fi

    # Count FAIL and FIXABLE per phase across all runs for this feature
    local profile=""
    local feature_lines
    feature_lines=$(grep "\"feature\":\"${feature}\"" "$metrics_file" 2>/dev/null)

    if [ -z "$feature_lines" ]; then
        return
    fi

    for phase_name in requirements design implement test review; do
        local fail_count=0
        local fixable_count=0

        # Count FAIL occurrences for this phase
        fail_count=$(echo "$feature_lines" | grep -c "\"name\":\"${phase_name}\",\"result\":\"FAIL\"" 2>/dev/null || echo "0")
        fixable_count=$(echo "$feature_lines" | grep -c "\"name\":\"${phase_name}\",\"result\":\"FIXABLE\"" 2>/dev/null || echo "0")

        if [ "$fail_count" -gt 0 ] || [ "$fixable_count" -gt 0 ]; then
            profile="${profile}Phase '${phase_name}' has failed ${fail_count} times and needed fixes ${fixable_count} times. Pay extra attention to ${phase_name} quality.
"
        fi
    done

    if [ -n "$profile" ]; then
        echo "$profile"
    fi
}

# Compute global weakness profile across ALL features
compute_global_weakness_profile() {
    local metrics_file="${PROJECT_DIR}/.claude/docs/metrics.jsonl"

    if [ ! -f "$metrics_file" ]; then
        return
    fi

    local profile=""
    for phase_name in requirements design implement test review; do
        local fail_count=0
        local fixable_count=0

        fail_count=$(grep -c "\"name\":\"${phase_name}\",\"result\":\"FAIL\"" "$metrics_file" 2>/dev/null || echo "0")
        fixable_count=$(grep -c "\"name\":\"${phase_name}\",\"result\":\"FIXABLE\"" "$metrics_file" 2>/dev/null || echo "0")

        if [ "$fail_count" -gt 0 ] || [ "$fixable_count" -gt 0 ]; then
            profile="${profile}[Global] Phase '${phase_name}' has failed ${fail_count} times and needed fixes ${fixable_count} times across ALL features.
"
        fi
    done

    if [ -n "$profile" ]; then
        echo "$profile"
    fi
}

build_prompt() {
    local phase="$1"
    local feature="$2"
    local lang="$3"

    # Use cached knowledge context if available, otherwise compute
    local knowledge_ctx="${CACHED_KNOWLEDGE_CTX:-}"
    if [ -z "$knowledge_ctx" ] && type get_knowledge_context &>/dev/null 2>&1; then
        knowledge_ctx=$(get_knowledge_context "$PROJECT_DIR" 2>/dev/null || true)
    fi
    if [ -n "$knowledge_ctx" ]; then
        echo "# Context from past reviews and decisions"
        echo "$knowledge_ctx"
        echo ""
        echo "---"
        echo ""
    fi

    # Metrics-driven weakness profile (feature-specific + global)
    local weakness_profile
    weakness_profile=$(compute_weakness_profile "$feature" 2>/dev/null || true)
    local global_profile
    global_profile=$(compute_global_weakness_profile 2>/dev/null || true)
    if [ -n "$weakness_profile" ] || [ -n "$global_profile" ]; then
        echo "# Quality Intelligence"
        [ -n "$weakness_profile" ] && echo "$weakness_profile"
        [ -n "$global_profile" ] && echo "$global_profile"
        echo ""
        echo "---"
        echo ""
    fi

    case "$phase" in
        implement)
            local req_content="" spec_content="" api_content=""
            local req_file="${PROJECT_DIR}/docs/requirements/${FEATURE_SLUG}.md"
            local spec_file="${PROJECT_DIR}/docs/specs/${FEATURE_SLUG}.md"
            local api_file="${PROJECT_DIR}/docs/api/${FEATURE_SLUG}.yaml"
            [ -f "$req_file" ] && req_content=$(cat "$req_file")
            [ -f "$spec_file" ] && spec_content=$(cat "$spec_file")
            [ -f "$api_file" ] && api_content=$(cat "$api_file")
            if [ "$lang" = "en" ]; then
                cat <<PROMPT
You are a senior full-stack developer. Implement the following feature: ${feature}

Requirements:
---
${req_content}
---

Design Spec:
---
${spec_content}
---

API Spec:
---
${api_content}
---

Implement this feature following existing code patterns. Create all necessary files under src/.
Use TypeScript, follow best practices, handle errors properly.
Output working, production-ready code. Do not use placeholders.
PROMPT
            else
                cat <<PROMPT
あなたはシニアフルスタックエンジニアです。以下の機能を実装してください: ${feature}

要件定義書:
---
${req_content}
---

設計書:
---
${spec_content}
---

API仕様:
---
${api_content}
---

既存のコードパターンに従って実装してください。src/配下に必要なファイルを全て作成してください。
TypeScriptを使用し、ベストプラクティスに従い、エラーハンドリングを適切に行ってください。
動作する本番品質のコードを出力してください。プレースホルダーは使わないでください。
PROMPT
            fi
            ;;
        test_gen)
            local spec_content="" src_summary=""
            local spec_file="${PROJECT_DIR}/docs/specs/${FEATURE_SLUG}.md"
            [ -f "$spec_file" ] && spec_content=$(cat "$spec_file")
            if [ -d "${PROJECT_DIR}/src" ]; then
                src_summary=$(find "${PROJECT_DIR}/src" -type f -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' 2>/dev/null | head -20 | while read -r f; do echo "--- $f ---"; head -50 "$f" 2>/dev/null; done)
            fi
            if [ "$lang" = "en" ]; then
                cat <<PROMPT
You are a senior test engineer. Generate comprehensive tests for: ${feature}

Design Spec:
---
${spec_content}
---

Source files:
---
${src_summary}
---

Generate tests that cover all acceptance criteria. Use the project's test framework.
Include unit tests and integration tests. Ensure high coverage.
PROMPT
            else
                cat <<PROMPT
あなたはシニアテストエンジニアです。以下の機能の包括的なテストを生成してください: ${feature}

設計書:
---
${spec_content}
---

ソースファイル:
---
${src_summary}
---

受入条件を全てカバーするテストを生成してください。プロジェクトのテストフレームワークを使用してください。
ユニットテストと結合テストを含め、高いカバレッジを確保してください。
PROMPT
            fi
            ;;
        requirements)
            if [ "$lang" = "en" ]; then
                cat <<PROMPT
You are a senior software architect. Generate a requirements document for: ${feature}

Include:
- User stories (AS A / I WANT / SO THAT format) - at least 3
- Acceptance criteria (5+) with specific, testable conditions
- Non-functional requirements (performance, security, accessibility)
- Technical constraints and assumptions
- Screen/page list with routes

Output in Markdown. Be specific and detailed, no placeholders.
PROMPT
            else
                cat <<PROMPT
あなたはシニアソフトウェアアーキテクトです。以下の機能の要件定義書を作成してください: ${feature}

含める内容:
- ユーザーストーリー (AS A / I WANT / SO THAT 形式) - 最低3つ
- 受入条件 (5つ以上) - 具体的でテスト可能な条件
- 非機能要件 (パフォーマンス、セキュリティ、アクセシビリティ)
- 技術的制約と前提条件
- 画面一覧とルーティング

Markdown形式で出力してください。具体的かつ詳細に、プレースホルダーは使わないでください。
PROMPT
            fi
            ;;
        design_spec)
            local req_content=""
            local req_file="${PROJECT_DIR}/docs/requirements/${FEATURE_SLUG}.md"
            if [ -f "$req_file" ]; then
                req_content=$(cat "$req_file")
            fi
            if [ "$lang" = "en" ]; then
                cat <<PROMPT
You are a senior UI/UX designer. Generate a screen design specification for: ${feature}

Requirements document:
---
${req_content}
---

Include:
- Component hierarchy with types (Page, Component, Layout)
- State transitions with triggers
- Interactions and user flows
- Responsive breakpoints
- Error states and loading states

Output in Markdown. Be specific and detailed.
PROMPT
            else
                cat <<PROMPT
あなたはシニアUI/UXデザイナーです。以下の機能の画面設計書を作成してください: ${feature}

要件定義書:
---
${req_content}
---

含める内容:
- コンポーネント構成 (種類: Page, Component, Layout)
- 状態遷移とトリガー
- インタラクションとユーザーフロー
- レスポンシブ対応のブレークポイント
- エラー状態とローディング状態

Markdown形式で出力してください。具体的かつ詳細に。
PROMPT
            fi
            ;;
        design_api)
            local req_content=""
            local req_file="${PROJECT_DIR}/docs/requirements/${FEATURE_SLUG}.md"
            if [ -f "$req_file" ]; then
                req_content=$(cat "$req_file")
            fi
            if [ "$lang" = "en" ]; then
                cat <<PROMPT
You are a senior API architect. Generate an OpenAPI 3.0 specification for: ${feature}

Requirements document:
---
${req_content}
---

Include all CRUD endpoints, request/response schemas, error responses, and authentication.
Output ONLY valid YAML, no markdown fencing, no explanation text.
PROMPT
            else
                cat <<PROMPT
あなたはシニアAPIアーキテクトです。以下の機能のOpenAPI 3.0仕様書を作成してください: ${feature}

要件定義書:
---
${req_content}
---

CRUD全エンドポイント、リクエスト/レスポンススキーマ、エラーレスポンス、認証を含めてください。
有効なYAMLのみ出力してください。マークダウンのフェンスや説明テキストは不要です。
PROMPT
            fi
            ;;
        review)
            local req_content=""
            local spec_content=""
            local req_file="${PROJECT_DIR}/docs/requirements/${FEATURE_SLUG}.md"
            local spec_file="${PROJECT_DIR}/docs/specs/${FEATURE_SLUG}.md"
            if [ -f "$req_file" ]; then
                req_content=$(cat "$req_file")
            fi
            if [ -f "$spec_file" ]; then
                spec_content=$(cat "$spec_file")
            fi
            # Gather recent source files if src/ exists
            local src_summary=""
            if [ -d "${PROJECT_DIR}/src" ]; then
                src_summary=$(find "${PROJECT_DIR}/src" -type f -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' 2>/dev/null | head -20 | while read -r f; do echo "--- $f ---"; head -50 "$f" 2>/dev/null; done)
            fi
            if [ "$lang" = "en" ]; then
                cat <<PROMPT
You are a senior code reviewer. Review the implementation of: ${feature}

Requirements:
---
${req_content}
---

Design spec:
---
${spec_content}
---

Source files:
---
${src_summary}
---

Provide a review covering:
- Acceptance criteria check (pass/fail for each)
- Security check (XSS, CSRF, auth)
- Performance considerations
- Test coverage assessment
- Improvement suggestions
- Final verdict (APPROVED / NEEDS CHANGES)

Output in Markdown.
PROMPT
            else
                cat <<PROMPT
あなたはシニアコードレビュアーです。以下の機能の実装をレビューしてください: ${feature}

要件定義書:
---
${req_content}
---

設計書:
---
${spec_content}
---

ソースファイル:
---
${src_summary}
---

以下をカバーするレビューを作成してください:
- 受入条件チェック (各条件のpass/fail)
- セキュリティチェック (XSS, CSRF, 認証)
- パフォーマンスの考慮事項
- テストカバレッジ評価
- 改善提案
- 最終判定 (APPROVED / NEEDS CHANGES)

Markdown形式で出力してください。
PROMPT
            fi
            ;;
    esac
}

estimate_cost() {
    # Rough estimate: Claude API ~$3/1M input + $15/1M output chars
    # Simplified: ~$0.01 per 1000 output chars
    if command -v bc &>/dev/null; then
        echo "$(echo "scale=2; $TOTAL_CLAUDE_CHARS * 0.01 / 1000" | bc)"
    else
        echo "N/A"
    fi
}

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
  --lang=LANG     Output language (ja|en, default: ja)

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

# Phase 1: Requirements - fallback template
_fallback_requirements() {
    local output_file="$1"
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
}

# Phase 1: Requirements
phase_requirements() {
    log_phase 1 "Generating requirements..." "Claude"

    local output_dir="${PROJECT_DIR}/docs/requirements"
    local output_file="${output_dir}/${FEATURE_SLUG}.md"
    mkdir -p "$output_dir"

    local prompt
    prompt=$(build_prompt "requirements" "$FEATURE" "$LANG_FLAG")
    invoke_claude "$prompt" "$output_file" "_fallback_requirements"

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

# Phase 2: Design - fallback templates
_fallback_design_spec() {
    local output_file="$1"
    cat << EOF > "$output_file"
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
}

_fallback_design_api() {
    local output_file="$1"
    cat << EOF > "$output_file"
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
}

# Phase 2: Design (parallel execution of UI spec + API spec)
phase_design() {
    log_phase 2 "Generating design..." "Claude (parallel)"

    local spec_dir="${PROJECT_DIR}/docs/specs"
    local api_dir="${PROJECT_DIR}/docs/api"
    mkdir -p "$spec_dir" "$api_dir"

    local spec_file="${spec_dir}/${FEATURE_SLUG}.md"
    local api_file="${api_dir}/${FEATURE_SLUG}.yaml"

    # Build prompts (sequential - cheap)
    local spec_prompt
    spec_prompt=$(build_prompt "design_spec" "$FEATURE" "$LANG_FLAG")
    local api_prompt
    api_prompt=$(build_prompt "design_api" "$FEATURE" "$LANG_FLAG")

    # Run both Claude calls in parallel
    invoke_claude "$spec_prompt" "$spec_file" "_fallback_design_spec" &
    local spec_pid=$!
    invoke_claude "$api_prompt" "$api_file" "_fallback_design_api" &
    local api_pid=$!

    # Wait for both to complete
    local spec_ok=0 api_ok=0
    wait "$spec_pid" || spec_ok=$?
    wait "$api_pid" || api_ok=$?

    # Recover TOTAL_CLAUDE_CHARS from file sizes (subshells can't update parent vars)
    if [ -f "$spec_file" ]; then
        TOTAL_CLAUDE_CHARS=$((TOTAL_CLAUDE_CHARS + $(wc -c < "$spec_file" | tr -d ' ')))
    fi
    if [ -f "$api_file" ]; then
        TOTAL_CLAUDE_CHARS=$((TOTAL_CLAUDE_CHARS + $(wc -c < "$api_file" | tr -d ' ')))
    fi

    log_info "→ ${spec_file}"
    log_info "→ ${api_file}"

    if [ "$spec_ok" -ne 0 ] || [ "$api_ok" -ne 0 ]; then
        log_warn "One or both design tasks had issues (spec: ${spec_ok}, api: ${api_ok})"
    fi

    if ask_approval "Approve design?"; then
        log_success "Design approved"
        return 0
    else
        return 1
    fi
}

# Phase 3: Implementation (Codex or Claude CLI fallback)
phase_implement() {
    if command -v codex &> /dev/null; then
        log_phase 3 "Implementing..." "Codex - full-auto"
        bash "$SCRIPT_DIR/delegate.sh" codex implement "$FEATURE_SLUG" --full-auto
        log_success "Implementation complete"
    elif command -v claude &> /dev/null; then
        log_phase 3 "Implementing..." "Claude CLI (Codex fallback)"
        log_info "Codex not installed, using Claude CLI as fallback implementer"

        local impl_prompt
        impl_prompt=$(build_prompt "implement" "$FEATURE" "$LANG_FLAG")
        # Claude CLI in print mode generates code to stdout; we capture and log
        local impl_output
        if impl_output=$(timeout 180 claude -p "$impl_prompt" 2>/dev/null); then
            local char_count=${#impl_output}
            TOTAL_CLAUDE_CHARS=$((TOTAL_CLAUDE_CHARS + char_count))
            log_success "Claude generated implementation (${char_count} chars)"
        else
            log_warn "Claude CLI implementation timed out or failed"
        fi
    else
        log_phase 3 "Implementing..." "Manual"
        log_warn "Neither Codex nor Claude CLI available"
        log_info "Please implement manually: src/app/${FEATURE_SLUG}/"
    fi

    return 0
}

# Phase 4: Testing (Codex or Claude CLI fallback)
phase_test() {
    if command -v codex &> /dev/null; then
        log_phase 4 "Generating tests..." "Codex"
        bash "$SCRIPT_DIR/delegate.sh" codex test "$FEATURE_SLUG" --full-auto
        log_success "Tests generated"
    elif command -v claude &> /dev/null; then
        log_phase 4 "Generating tests..." "Claude CLI (Codex fallback)"
        log_info "Codex not installed, using Claude CLI as fallback test generator"

        local test_prompt
        test_prompt=$(build_prompt "test_gen" "$FEATURE" "$LANG_FLAG")
        local test_output
        if test_output=$(timeout 180 claude -p "$test_prompt" 2>/dev/null); then
            local char_count=${#test_output}
            TOTAL_CLAUDE_CHARS=$((TOTAL_CLAUDE_CHARS + char_count))
            log_success "Claude generated tests (${char_count} chars)"
        else
            log_warn "Claude CLI test generation timed out or failed"
        fi
    else
        log_phase 4 "Generating tests..." "Manual"
        log_warn "Neither Codex nor Claude CLI available"
        log_info "Please create tests manually: tests/${FEATURE_SLUG}.spec.ts"
    fi

    return 0
}

# Phase 5: Review - fallback template
_fallback_review() {
    local output_file="$1"
    cat << EOF > "$output_file"
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
}

# Phase 5: Review
phase_review() {
    log_phase 5 "Reviewing..." "Claude"

    local review_dir="${PROJECT_DIR}/docs/reviews"
    mkdir -p "$review_dir"
    local review_file="${review_dir}/${FEATURE_SLUG}.md"

    local prompt
    prompt=$(build_prompt "review" "$FEATURE" "$LANG_FLAG")
    invoke_claude "$prompt" "$review_file" "_fallback_review"

    log_info "→ ${review_file}"
    log_success "Review complete"

    return 0
}

# Phase 6: Deploy (with safety gate)
phase_deploy() {
    log_phase 6 "Deploy ready" "Claude"

    echo ""
    echo "───────────────────────────────────────"

    # Deploy safety gate: 3 checks before allowing deploy
    local deploy_blocked=false
    local block_reasons=""

    # Check 1: Review must be APPROVED
    local review_file="${PROJECT_DIR}/docs/reviews/${FEATURE_SLUG}.md"
    if [ -f "$review_file" ]; then
        if grep -qi 'APPROVED' "$review_file" 2>/dev/null; then
            echo "  Review: APPROVED"
        else
            echo "  Review: NOT APPROVED"
            deploy_blocked=true
            block_reasons="${block_reasons}Review not approved. "
        fi
    else
        echo "  Review: file not found"
        deploy_blocked=true
        block_reasons="${block_reasons}Review file missing. "
    fi

    # Check 2: No FAIL phases in latest pipeline metrics
    local metrics_file="${PROJECT_DIR}/.claude/docs/metrics.jsonl"
    if [ -f "$metrics_file" ]; then
        local latest_run
        latest_run=$(grep "\"feature\":\"${FEATURE}\"" "$metrics_file" 2>/dev/null | tail -1)
        if [ -n "$latest_run" ] && echo "$latest_run" | grep -q '"result":"FAIL"'; then
            echo "  Pipeline: has FAIL phases"
            deploy_blocked=true
            block_reasons="${block_reasons}Pipeline has failed phases. "
        else
            echo "  Pipeline: clean"
        fi
    else
        echo "  Pipeline: no metrics (first run)"
    fi

    # Check 3: No secrets in uncommitted changes
    local diff_content
    diff_content=$(cd "$PROJECT_DIR" && git diff HEAD 2>/dev/null; cd "$PROJECT_DIR" && git diff --cached 2>/dev/null)
    if [ -n "$diff_content" ]; then
        local secret_hits
        secret_hits=$(echo "$diff_content" | grep -nE '(AKIA[0-9A-Z]{16}|ghp_[a-zA-Z0-9]{36}|sk-[a-zA-Z0-9]{32,}|BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY|xox[baprs]-[a-zA-Z0-9-]+|sk_live_[a-zA-Z0-9]+|rk_live_[a-zA-Z0-9]+)' 2>/dev/null | head -5)
        if [ -n "$secret_hits" ]; then
            echo "  Secrets: DETECTED in uncommitted changes"
            deploy_blocked=true
            block_reasons="${block_reasons}Secrets detected in uncommitted changes. "
        else
            echo "  Secrets: clean"
        fi
    else
        echo "  Secrets: clean (no uncommitted changes)"
    fi

    echo "───────────────────────────────────────"

    if [ "$deploy_blocked" = "true" ]; then
        log_error "Deploy BLOCKED: ${block_reasons}"
        log_info "Fix the issues above before deploying."
        return 1
    fi

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
            --lang=*)
                LANG_FLAG="${1#--lang=}"
                ;;
        esac
        shift
    done

    # Acquire lock for team coordination
    acquire_lock
    trap release_lock EXIT

    CURRENT_PHASE=$start_phase

    WORKFLOW_START=$(date +%s)

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${BOLD}Project started: ${FEATURE}${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Execute each phase
    local phases=(phase_requirements phase_design phase_implement phase_test phase_review phase_deploy)
    local phase_names=("Requirements" "Design" "Implementation" "Testing" "Review" "Deploy")

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

        start_timer "$phase_num"
        ${phases[$i]}

        if [ $? -ne 0 ]; then
            end_timer "$phase_num"
            log_error "Interrupted at phase ${phase_num}"
            log_info "Resume: $0 \"${FEATURE}\" --from=${phase_num}"
            exit 1
        fi
        end_timer "$phase_num"
    done

    local workflow_end
    workflow_end=$(date +%s)
    local total_seconds=$((workflow_end - WORKFLOW_START))
    local cost
    cost=$(estimate_cost)

    # Count generated files
    local file_count=0
    [ -f "${PROJECT_DIR}/docs/requirements/${FEATURE_SLUG}.md" ] && file_count=$((file_count + 1))
    [ -f "${PROJECT_DIR}/docs/specs/${FEATURE_SLUG}.md" ] && file_count=$((file_count + 1))
    [ -f "${PROJECT_DIR}/docs/api/${FEATURE_SLUG}.yaml" ] && file_count=$((file_count + 1))
    [ -f "${PROJECT_DIR}/docs/reviews/${FEATURE_SLUG}.md" ] && file_count=$((file_count + 1))

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${GREEN}✅ Project complete!${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "  ${BOLD}Time:${NC}  $(format_duration $total_seconds)"
    for i in "${!phase_names[@]}"; do
        local pn=$((i + 1))
        local dur="${PHASE_DURATIONS[$pn]}"
        if [ -n "$dur" ]; then
            printf "    Phase %d %-18s %s\n" "$pn" "${phase_names[$i]}" "$(format_duration "$dur")"
        fi
    done
    echo ""
    if [ "$cost" = "N/A" ]; then
        echo -e "  ${BOLD}Cost:${NC}  N/A"
    else
        echo -e "  ${BOLD}Cost:${NC}  \$${cost} (Claude: \$${cost}, Codex: \$0)"
    fi
    echo -e "  ${BOLD}Files:${NC} ${file_count} created"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Persist metrics (JSONL) for workflow runs outside the pipeline
    local metrics_file="${PROJECT_DIR}/.claude/docs/metrics.jsonl"
    mkdir -p "$(dirname "$metrics_file")"
    local ts
    ts=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
    local sha
    sha=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    printf '{"feature":"%s","timestamp":"%s","git_sha":"%s","total_duration":%s,"quality_score":null,"source":"project-workflow"}\n' \
        "$FEATURE" "$ts" "$sha" "$total_seconds" >> "$metrics_file"

    # Remove state file
    rm -f "$STATE_FILE"
}

main "$@"
