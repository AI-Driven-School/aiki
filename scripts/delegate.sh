#!/bin/bash
# 3AI協調システム - メイン委譲スクリプト
# Claude Code から Codex / Gemini にタスクを委譲

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
NC='\033[0m' # No Color

# ログ出力
log_info() { echo -e "${CYAN}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[⚠]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }

# ヘルプ表示
show_help() {
    cat << EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🤖 3AI協調システム - 委譲スクリプト
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

使用方法:
  $0 <ai> <command> [options]

AI:
  codex     OpenAI Codex (ChatGPT Pro必須)
  gemini    Google Gemini CLI (無料)

コマンド:

  [Codex専用]
  implement <feature>   設計書から実装を生成
  test <feature>        テストコードを生成
  refactor <path>       コードをリファクタリング
  review [branch]       コードレビューを実行

  [Gemini専用]
  analyze [path]        大規模コード解析
  research <topic>      技術リサーチ

  [共通]
  exec "<prompt>"       カスタムプロンプトを実行

オプション:
  --full-auto           承認なしで自動実行 (Codex)
  --yolo                承認なしで自動実行 (Gemini)
  --background          バックグラウンドで実行
  --output <file>       出力ファイルを指定

例:
  $0 codex implement auth
  $0 codex test auth --full-auto
  $0 gemini analyze src/
  $0 gemini research "JWT vs Session認証"
  $0 codex exec "READMEを更新して" --full-auto

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
}

# タスクディレクトリ初期化
init_task_dir() {
    TASK_DIR="${PROJECT_DIR}/.delegate-tasks"
    mkdir -p "$TASK_DIR"
    TASK_ID=$(date +%Y%m%d-%H%M%S)
    OUTPUT_FILE="${TASK_DIR}/output-${TASK_ID}.txt"
    LOG_FILE="${TASK_DIR}/log-${TASK_ID}.txt"

    log_info "プロジェクトディレクトリ: ${PROJECT_DIR}"
}

# Codex実行
run_codex() {
    local command="$1"
    local args="$2"
    local full_auto="${FULL_AUTO:-false}"
    local background="${BACKGROUND:-false}"

    # Codexがインストールされているか確認
    if ! command -v codex &> /dev/null; then
        log_error "Codex CLIがインストールされていません"
        log_info "インストール: npm install -g @openai/codex"
        exit 1
    fi

    local codex_flags=""
    if [ "$full_auto" = "true" ]; then
        codex_flags="--full-auto"
    fi

    case "$command" in
        implement)
            local feature="$args"
            log_info "🔧 Codexで実装を生成中... (${feature})"

            # 設計書を検索（複数のパターンを試行）
            local req_file=""
            local spec_file=""
            local api_file=""

            # 要件定義を検索
            for f in "docs/requirements/${feature}.md" "docs/requirements/${feature%-ai}.md"; do
                if [ -f "$f" ]; then req_file="$f"; break; fi
            done

            # 画面設計を検索
            for f in "docs/specs/${feature}.md" "docs/specs/${feature%-ai}.md"; do
                if [ -f "$f" ]; then spec_file="$f"; break; fi
            done

            # API設計を検索
            for f in "docs/api/${feature}.yaml" "docs/api/${feature%-ai}.yaml" "docs/api/${feature}.yml"; do
                if [ -f "$f" ]; then api_file="$f"; break; fi
            done

            log_info "要件定義: ${req_file:-なし}"
            log_info "画面設計: ${spec_file:-なし}"
            log_info "API設計: ${api_file:-なし}"

            local prompt="
以下の設計書を読み込み、実装してください。

【要件定義】
$(cat "$req_file" 2>/dev/null || echo "ファイルなし")

【画面設計】
$(cat "$spec_file" 2>/dev/null || echo "ファイルなし")

【API設計】
$(cat "$api_file" 2>/dev/null || echo "ファイルなし")

【実装要件】
- 既存のコードスタイルに従う
- TypeScript strict mode
- エラーハンドリングを適切に行う
"
            if [ "$background" = "true" ]; then
                codex exec $codex_flags -C "$PROJECT_DIR" "$prompt" > "$OUTPUT_FILE" 2>&1 &
                echo $! > "${TASK_DIR}/pid-${TASK_ID}.txt"
                log_success "バックグラウンドで実行中 (PID: $!)"
                log_info "出力確認: tail -f $OUTPUT_FILE"
            else
                codex exec $codex_flags -C "$PROJECT_DIR" "$prompt" 2>&1 | tee "$OUTPUT_FILE"
            fi
            ;;

        test)
            local feature="$args"
            log_info "🧪 Codexでテストを生成中... (${feature})"

            local prompt="
以下の受入条件を全てカバーするE2Eテストを生成してください。

【受入条件】
$(cat "docs/requirements/${feature}.md" 2>/dev/null | grep -A 100 '## 受入条件' || echo "ファイルなし")

【テスト要件】
- Playwright使用
- 各受入条件に対応するテストケース
- Happy path + Edge case
- 適切なセレクタ（data-testid推奨）
- 日本語でテスト名を記述
"
            codex exec $codex_flags -C "$PROJECT_DIR" "$prompt" 2>&1 | tee "$OUTPUT_FILE"
            ;;

        refactor)
            local path="${args:-src/}"
            log_info "🔧 Codexでリファクタリング中... (${path})"

            codex exec $codex_flags -C "$PROJECT_DIR" \
                "${path}のコードを整理・リファクタリングしてください。機能は変更せず、可読性とメンテナンス性を向上させてください。" \
                2>&1 | tee "$OUTPUT_FILE"
            ;;

        review)
            local branch="${args:-}"
            log_info "🔍 Codexでコードレビュー中..."

            if [ -n "$branch" ]; then
                codex review --base "$branch" 2>&1 | tee "$OUTPUT_FILE"
            else
                codex review --uncommitted 2>&1 | tee "$OUTPUT_FILE"
            fi
            ;;

        exec)
            log_info "⚡ Codexでカスタムタスク実行中..."
            if [ "$background" = "true" ]; then
                codex exec $codex_flags -C "$PROJECT_DIR" "$args" > "$OUTPUT_FILE" 2>&1 &
                echo $! > "${TASK_DIR}/pid-${TASK_ID}.txt"
                log_success "バックグラウンドで実行中 (PID: $!)"
            else
                codex exec $codex_flags -C "$PROJECT_DIR" "$args" 2>&1 | tee "$OUTPUT_FILE"
            fi
            ;;

        *)
            log_error "不明なコマンド: $command"
            show_help
            exit 1
            ;;
    esac
}

# Gemini実行
run_gemini() {
    local command="$1"
    local args="$2"
    local yolo="${YOLO:-false}"
    local background="${BACKGROUND:-false}"

    # Geminiがインストールされているか確認
    if ! command -v gemini &> /dev/null; then
        log_error "Gemini CLIがインストールされていません"
        log_info "インストール: npm install -g @anthropic/gemini-cli"
        exit 1
    fi

    local gemini_flags=""
    if [ "$yolo" = "true" ]; then
        gemini_flags="--yolo"
    fi

    case "$command" in
        analyze)
            local path="${args:-.}"
            log_info "🔍 Geminiで大規模解析中... (${path})"

            # コードベースを収集
            local code_content=$(find "$path" -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.py" -o -name "*.js" -o -name "*.jsx" \) -exec cat {} \; 2>/dev/null | head -c 500000)

            local prompt="
以下のコードベースを解析し、レポートを作成してください。

【解析観点】
1. アーキテクチャ概要
   - 全体構造
   - 主要コンポーネント
   - データフロー

2. 技術スタック
   - 使用フレームワーク/ライブラリ
   - 設計パターン

3. コード品質
   - 良い点
   - 改善点

4. セキュリティ懸念
   - 潜在的な脆弱性
   - 推奨対策

5. パフォーマンス
   - ボトルネック候補
   - 最適化提案

6. 改善ロードマップ
   - 優先度高の改善点（3つ）
   - 中長期的な改善点

【出力形式】
Markdown形式で、図や表を活用して分かりやすく。日本語で出力。

【コードベース】
$code_content
"
            if [ "$background" = "true" ]; then
                echo "$prompt" | gemini $gemini_flags > "$OUTPUT_FILE" 2>&1 &
                echo $! > "${TASK_DIR}/pid-${TASK_ID}.txt"
                log_success "バックグラウンドで実行中 (PID: $!)"
            else
                echo "$prompt" | gemini $gemini_flags 2>&1 | tee "$OUTPUT_FILE"
            fi
            ;;

        research)
            local topic="$args"
            log_info "🔬 Geminiでリサーチ中... (${topic})"

            local prompt="
以下の技術トピックについて詳細にリサーチし、レポートを作成してください。

【トピック】
${topic}

【リサーチ観点】
1. 概要・背景
2. 主要な選択肢/アプローチ
3. 比較表（該当する場合）
4. ベストプラクティス
5. 実装例（コード）
6. 参考リソース

【出力要件】
- Markdown形式
- コード例は実用的なもの
- 最新の情報を反映
- 日本語で出力
"
            if [ "$background" = "true" ]; then
                gemini $gemini_flags -p "$prompt" > "$OUTPUT_FILE" 2>&1 &
                echo $! > "${TASK_DIR}/pid-${TASK_ID}.txt"
                log_success "バックグラウンドで実行中 (PID: $!)"
            else
                gemini $gemini_flags -p "$prompt" 2>&1 | tee "$OUTPUT_FILE"
            fi
            ;;

        exec)
            log_info "⚡ Geminiでカスタムタスク実行中..."
            if [ "$background" = "true" ]; then
                gemini $gemini_flags -p "$args" > "$OUTPUT_FILE" 2>&1 &
                echo $! > "${TASK_DIR}/pid-${TASK_ID}.txt"
                log_success "バックグラウンドで実行中 (PID: $!)"
            else
                gemini $gemini_flags -p "$args" 2>&1 | tee "$OUTPUT_FILE"
            fi
            ;;

        *)
            log_error "不明なコマンド: $command"
            show_help
            exit 1
            ;;
    esac
}

# メイン処理
main() {
    # 引数パース
    if [ $# -lt 1 ]; then
        show_help
        exit 0
    fi

    local ai="$1"
    local command="${2:-}"
    local args=""

    # 3番目以降の引数を処理
    shift 2 2>/dev/null || true

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --full-auto)
                FULL_AUTO=true
                ;;
            --yolo)
                YOLO=true
                ;;
            --background)
                BACKGROUND=true
                ;;
            --output)
                shift
                OUTPUT_FILE="$1"
                ;;
            -*)
                # 未知のオプションは無視
                ;;
            *)
                # 位置引数（feature名など）
                if [ -z "$args" ]; then
                    args="$1"
                fi
                ;;
        esac
        shift
    done

    # タスクディレクトリ初期化
    init_task_dir

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🤖 3AI協調システム"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    case "$ai" in
        codex)
            run_codex "$command" "$args"
            ;;
        gemini)
            run_gemini "$command" "$args"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "不明なAI: $ai"
            log_info "使用可能: codex, gemini"
            show_help
            exit 1
            ;;
    esac

    echo ""
    log_success "完了 - 出力: $OUTPUT_FILE"
    echo ""
}

main "$@"
