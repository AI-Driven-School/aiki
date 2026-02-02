#!/bin/bash
# 3AI協調システム - プロジェクトワークフロー
# 6フェーズの設計→実装→デプロイフローを自動実行

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# 現在の作業ディレクトリを使用（実際のプロジェクト）
PROJECT_DIR="${PWD}"
TEMPLATE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# 色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# 状態管理
STATE_FILE=""
FEATURE=""
CURRENT_PHASE=1
TOTAL_PHASES=6

# ログ出力
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

# ヘルプ表示
show_help() {
    cat << EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 /project ワークフロー
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

使用方法:
  $0 <機能名> [オプション]

例:
  $0 "ユーザー認証"
  $0 "商品検索" --from=3
  $0 "ダッシュボード" --skip=1,2

オプション:
  --from=N      N番目のフェーズから開始
  --skip=N,M    指定フェーズをスキップ
  --auto        全承認を自動でY
  --dry-run     実行せずにプレビュー

フェーズ:
  [1] 要件定義   (Claude)  → docs/requirements/{feature}.md
  [2] 設計       (Claude)  → docs/specs/{feature}.md
  [3] 実装       (Codex)   → src/**/*
  [4] テスト     (Codex)   → tests/**/*
  [5] レビュー   (Claude)  → docs/reviews/{feature}.md
  [6] デプロイ   (Claude)  → 最終確認

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
}

# 状態保存
save_state() {
    echo "$CURRENT_PHASE" > "$STATE_FILE"
}

# 状態復元
load_state() {
    if [ -f "$STATE_FILE" ]; then
        CURRENT_PHASE=$(cat "$STATE_FILE")
    fi
}

# ユーザー確認
ask_approval() {
    local message="$1"
    if [ "$AUTO_APPROVE" = "true" ]; then
        echo "Y (自動承認)"
        return 0
    fi

    echo -e "\n${YELLOW}${message}${NC}"
    read -p "承認しますか？ [Y/n/reject 理由] > " answer

    case "$answer" in
        [Yy]|"")
            return 0
            ;;
        [Nn])
            return 1
            ;;
        reject*)
            local reason="${answer#reject }"
            log_warn "却下: ${reason}"
            return 2
            ;;
        *)
            return 1
            ;;
    esac
}

# Phase 1: 要件定義
phase_requirements() {
    log_phase 1 "要件定義を生成中..." "Claude"

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

    if ask_approval "要件定義を承認しますか？"; then
        log_success "要件定義を承認しました"
        return 0
    else
        return 1
    fi
}

# Phase 2: 設計
phase_design() {
    log_phase 2 "設計を生成中..." "Claude"

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

    if ask_approval "設計を承認しますか？"; then
        log_success "設計を承認しました"
        return 0
    else
        return 1
    fi
}

# Phase 3: 実装
phase_implement() {
    log_phase 3 "実装中..." "Codex - full-auto"
    log_warn "★ Codexに委譲します（ChatGPT Pro必須）"

    # Codexがある場合は実行
    if command -v codex &> /dev/null; then
        bash "$SCRIPT_DIR/delegate.sh" codex implement "$FEATURE_SLUG" --full-auto
        log_success "実装が完了しました"
    else
        log_warn "Codexが未インストールのためスキップ"
        log_info "手動で実装してください: src/app/${FEATURE_SLUG}/"
    fi

    return 0
}

# Phase 4: テスト
phase_test() {
    log_phase 4 "テスト生成中..." "Codex"

    if command -v codex &> /dev/null; then
        bash "$SCRIPT_DIR/delegate.sh" codex test "$FEATURE_SLUG" --full-auto
        log_success "テストが生成されました"
    else
        log_warn "Codexが未インストールのためスキップ"
        log_info "手動でテストを作成してください: tests/${FEATURE_SLUG}.spec.ts"
    fi

    return 0
}

# Phase 5: レビュー
phase_review() {
    log_phase 5 "レビュー中..." "Claude"

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
    log_success "レビューテンプレートを作成しました"
    log_info "Claude Codeで詳細レビューを実行してください"

    return 0
}

# Phase 6: デプロイ
phase_deploy() {
    log_phase 6 "デプロイ準備完了" "Claude"

    echo ""
    echo "───────────────────────────────────────"
    echo "レビュー結果:"
    echo "  ⏳ 受入条件: 確認待ち"
    echo "  ⏳ テスト: 未実行"
    echo "───────────────────────────────────────"

    if ask_approval "本番にデプロイしますか？"; then
        log_info "デプロイを実行中..."

        # Vercelがある場合
        if command -v vercel &> /dev/null; then
            vercel --prod
            log_success "デプロイ完了！"
        else
            log_warn "Vercelが未インストールです"
            log_info "手動でデプロイしてください: vercel --prod"
        fi
    else
        log_warn "デプロイをスキップしました"
    fi

    return 0
}

# メイン処理
main() {
    # まず--helpを先にチェック
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
    # 日本語を含む場合はそのまま使用、英数字のみの場合は小文字化
    if echo "$FEATURE" | grep -q '[^a-zA-Z0-9 -]'; then
        # 日本語等を含む場合はスペースをハイフンに置換
        FEATURE_SLUG=$(echo "$FEATURE" | sed 's/ /-/g')
    else
        # 英数字のみの場合は小文字化
        FEATURE_SLUG=$(echo "$FEATURE" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')
    fi
    STATE_FILE="${PROJECT_DIR}/.project-state-${FEATURE_SLUG}"

    shift

    # オプション解析
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
        esac
        shift
    done

    CURRENT_PHASE=$start_phase

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "🚀 ${BOLD}プロジェクト開始: ${FEATURE}${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # 各フェーズを実行
    local phases=(phase_requirements phase_design phase_implement phase_test phase_review phase_deploy)

    for i in "${!phases[@]}"; do
        local phase_num=$((i + 1))

        # 開始フェーズより前はスキップ
        if [ $phase_num -lt $start_phase ]; then
            continue
        fi

        # スキップ指定されたフェーズはスキップ
        if [[ ",$skip_phases," == *",$phase_num,"* ]]; then
            log_warn "Phase ${phase_num} をスキップ"
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
            log_error "Phase ${phase_num} で中断されました"
            log_info "再開: $0 \"${FEATURE}\" --from=${phase_num}"
            exit 1
        fi
    done

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${GREEN}✅ プロジェクト完了！${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "生成されたファイル:"
    echo "  📄 docs/requirements/${FEATURE_SLUG}.md"
    echo "  📄 docs/specs/${FEATURE_SLUG}.md"
    echo "  📄 docs/api/${FEATURE_SLUG}.yaml"
    echo "  📄 docs/reviews/${FEATURE_SLUG}.md"
    echo ""

    # 状態ファイル削除
    rm -f "$STATE_FILE"
}

main "$@"
