#!/bin/bash
# 3-AI Collaboration System - Main Delegation Script
# Delegates tasks from Claude Code to Codex / Gemini

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# Use current working directory (actual project)
PROJECT_DIR="${PWD}"

# Load sensitive file filter
if [ -f "$SCRIPT_DIR/lib/sensitive-filter.sh" ]; then
    # shellcheck source=lib/sensitive-filter.sh
    source "$SCRIPT_DIR/lib/sensitive-filter.sh"
fi

# Load version checker
if [ -f "$SCRIPT_DIR/lib/version-check.sh" ]; then
    # shellcheck source=lib/version-check.sh
    source "$SCRIPT_DIR/lib/version-check.sh"
fi
# shellcheck disable=SC2034
TEMPLATE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
# shellcheck disable=SC2034
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Log output
log_info() { echo -e "${CYAN}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[⚠]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }

# Help
show_help() {
    cat << EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  3AI Collaboration - Delegation Script
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Usage:
  $0 <ai> <command> [options]

AI:
  codex     OpenAI Codex (requires ChatGPT Pro)
  gemini    Google Gemini CLI (free)

Commands:

  [Codex]
  implement <feature>   Generate implementation from design docs
  test <feature>        Generate test code
  refactor <path>       Refactor code
  review [branch]       Run code review

  [Gemini]
  analyze [path]        Large-scale code analysis
  research <topic>      Technical research

  [Common]
  exec "<prompt>"       Execute a custom prompt

Options:
  --full-auto           Run without approval (Codex)
  --yolo                Run without approval (Gemini)
  --background          Run in background
  --output <file>       Specify output file
  --force               Bypass sensitive file filter (not recommended)

Examples:
  $0 codex implement auth
  $0 codex test auth --full-auto
  $0 gemini analyze src/
  $0 gemini research "JWT vs Session auth"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
}

# Initialize task directory
init_task_dir() {
    TASK_DIR="${PROJECT_DIR}/.delegate-tasks"
    mkdir -p "$TASK_DIR"
    TASK_ID=$(date +%Y%m%d-%H%M%S)
    OUTPUT_FILE="${TASK_DIR}/output-${TASK_ID}.txt"
    # shellcheck disable=SC2034
    LOG_FILE="${TASK_DIR}/log-${TASK_ID}.txt"

    log_info "Project directory: ${PROJECT_DIR}"
}

# Run Codex
run_codex() {
    local command="$1"
    local args="$2"
    local full_auto="${FULL_AUTO:-false}"
    local background="${BACKGROUND:-false}"

    # Check Codex CLI is installed
    if ! command -v codex &> /dev/null; then
        log_error "Codex CLI is not installed"
        log_info "Install: npm install -g @openai/codex"
        exit 1
    fi

    # Version compatibility check
    if type check_ai_compatibility &>/dev/null; then
        local compat
        compat=$(check_ai_compatibility "codex" "${SCRIPT_DIR}/../.ai-versions.json" 2>/dev/null || echo "unknown")
        if [ "$compat" = "below_min" ]; then
            log_warn "Codex CLI version may be outdated. Update recommended."
        fi
    fi

    local codex_flags=""
    if [ "$full_auto" = "true" ]; then
        codex_flags="--full-auto"
    fi

    warn_external_ai_send "Codex"

    case "$command" in
        implement)
            local feature="$args"
            log_info "Codex: generating implementation... (${feature})"

            # Search for design docs
            local req_file=""
            local spec_file=""
            local api_file=""

            # Find requirements
            for f in "docs/requirements/${feature}.md" "docs/requirements/${feature%-ai}.md"; do
                if [ -f "$f" ]; then req_file="$f"; break; fi
            done

            # Find UI specs
            for f in "docs/specs/${feature}.md" "docs/specs/${feature%-ai}.md"; do
                if [ -f "$f" ]; then spec_file="$f"; break; fi
            done

            # Find API specs
            for f in "docs/api/${feature}.yaml" "docs/api/${feature%-ai}.yaml" "docs/api/${feature}.yml"; do
                if [ -f "$f" ]; then api_file="$f"; break; fi
            done

            log_info "Requirements: ${req_file:-none}"
            log_info "UI specs: ${spec_file:-none}"
            log_info "API specs: ${api_file:-none}"

            local prompt
            prompt="
以下の設計書を読み込み、実装してください。

【要件定義】
$(safe_cat "$req_file" 2>/dev/null || echo "ファイルなし")

【画面設計】
$(safe_cat "$spec_file" 2>/dev/null || echo "ファイルなし")

【API設計】
$(safe_cat "$api_file" 2>/dev/null || echo "ファイルなし")

【実装要件】
- 既存のコードスタイルに従う
- TypeScript strict mode
- エラーハンドリングを適切に行う
"
            if [ "$background" = "true" ]; then
                codex exec $codex_flags -C "$PROJECT_DIR" "$prompt" > "$OUTPUT_FILE" 2>&1 &
                echo $! > "${TASK_DIR}/pid-${TASK_ID}.txt"
                log_success "Running in background (PID: $!)"
                log_info "Check output: tail -f $OUTPUT_FILE"
            else
                codex exec $codex_flags -C "$PROJECT_DIR" "$prompt" 2>&1 | tee "$OUTPUT_FILE"
            fi
            ;;

        test)
            local feature="$args"
            log_info "Codex: generating tests... (${feature})"

            local prompt
            prompt="
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
            log_info "Codex: refactoring... (${path})"

            codex exec $codex_flags -C "$PROJECT_DIR" \
                "${path}のコードを整理・リファクタリングしてください。機能は変更せず、可読性とメンテナンス性を向上させてください。" \
                2>&1 | tee "$OUTPUT_FILE"
            ;;

        review)
            local branch="${args:-}"
            log_info "Codex: reviewing code..."

            if [ -n "$branch" ]; then
                codex review --base "$branch" 2>&1 | tee "$OUTPUT_FILE"
            else
                codex review --uncommitted 2>&1 | tee "$OUTPUT_FILE"
            fi
            ;;

        exec)
            log_info "Codex: running custom task..."
            if [ "$background" = "true" ]; then
                codex exec $codex_flags -C "$PROJECT_DIR" "$args" > "$OUTPUT_FILE" 2>&1 &
                echo $! > "${TASK_DIR}/pid-${TASK_ID}.txt"
                log_success "Running in background (PID: $!)"
            else
                codex exec $codex_flags -C "$PROJECT_DIR" "$args" 2>&1 | tee "$OUTPUT_FILE"
            fi
            ;;

        *)
            log_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# Run Gemini
run_gemini() {
    local command="$1"
    local args="$2"
    local yolo="${YOLO:-false}"
    local background="${BACKGROUND:-false}"

    # Check Gemini CLI is installed
    if ! command -v gemini &> /dev/null; then
        log_error "Gemini CLI is not installed"
        log_info "Install: npm install -g @google/gemini-cli"
        exit 1
    fi

    # Version compatibility check
    if type check_ai_compatibility &>/dev/null; then
        local compat
        compat=$(check_ai_compatibility "gemini" "${SCRIPT_DIR}/../.ai-versions.json" 2>/dev/null || echo "unknown")
        if [ "$compat" = "below_min" ]; then
            log_warn "Gemini CLI version may be outdated. Update recommended."
        fi
    fi

    local gemini_flags=""
    if [ "$yolo" = "true" ]; then
        gemini_flags="--yolo"
    fi

    case "$command" in
        analyze)
            local path="${args:-.}"
            log_info "Gemini: analyzing codebase... (${path})"

            # Collect codebase (excluding sensitive files)
            local code_content
            local file_list
            file_list=$(find "$path" -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.py" -o -name "*.js" -o -name "*.jsx" \) 2>/dev/null)
            local safe_files
            safe_files=$(filter_sensitive_files "$file_list" 2>/dev/null)
            code_content=""
            while IFS= read -r f; do
                [ -z "$f" ] && continue
                code_content="${code_content}$(cat "$f" 2>/dev/null)"
            done <<< "$safe_files"
            code_content=$(echo "$code_content" | head -c 500000)
            local file_count
            file_count=$(echo "$safe_files" | grep -c . 2>/dev/null || echo "0")
            warn_external_ai_send "Gemini" "$file_count"

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
                log_success "Running in background (PID: $!)"
            else
                echo "$prompt" | gemini $gemini_flags 2>&1 | tee "$OUTPUT_FILE"
            fi
            ;;

        research)
            local topic="$args"
            log_info "Gemini: researching... (${topic})"

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
                log_success "Running in background (PID: $!)"
            else
                gemini $gemini_flags -p "$prompt" 2>&1 | tee "$OUTPUT_FILE"
            fi
            ;;

        exec)
            log_info "Gemini: running custom task..."
            if [ "$background" = "true" ]; then
                gemini $gemini_flags -p "$args" > "$OUTPUT_FILE" 2>&1 &
                echo $! > "${TASK_DIR}/pid-${TASK_ID}.txt"
                log_success "Running in background (PID: $!)"
            else
                gemini $gemini_flags -p "$args" 2>&1 | tee "$OUTPUT_FILE"
            fi
            ;;

        *)
            log_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# Main
main() {
    # Parse arguments
    if [ $# -lt 1 ]; then
        show_help
        exit 0
    fi

    local ai="$1"
    local command="${2:-}"
    local args=""

    # Process arguments from 3rd position onwards
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
            --force)
                FORCE_SEND=true
                export FORCE_SEND
                ;;
            --output)
                shift
                OUTPUT_FILE="$1"
                ;;
            -*)
                # Ignore unknown options
                ;;
            *)
                # Positional argument (feature name, etc.)
                if [ -z "$args" ]; then
                    args="$1"
                fi
                ;;
        esac
        shift
    done

    # Initialize task directory
    init_task_dir

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "3AI Collaboration System"
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
            log_error "Unknown AI: $ai"
            log_info "Available: codex, gemini"
            show_help
            exit 1
            ;;
    esac

    echo ""
    log_success "Done - output: $OUTPUT_FILE"
    echo ""
}

main "$@"
