#!/bin/bash
# ============================================
# AI Runner - エラーリカバリ機構付きAI実行
# ============================================
# 使用方法:
#   ./scripts/ai-runner.sh claude "プロンプト"
#   ./scripts/ai-runner.sh codex "タスク"
#   ./scripts/ai-runner.sh gemini "質問"
#
# オプション:
#   --timeout 300      タイムアウト秒数（デフォルト: 300）
#   --retry 3          リトライ回数（デフォルト: 3）
#   --fallback         失敗時に別AIにフォールバック
#   --quiet            静かに実行
# ============================================

set -e

# Load sensitive file filter
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/lib/sensitive-filter.sh" ]; then
    # shellcheck source=lib/sensitive-filter.sh
    source "$SCRIPT_DIR/lib/sensitive-filter.sh"
fi

# カラー定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
# shellcheck disable=SC2034
GRAY='\033[0;90m'
NC='\033[0m'
# shellcheck disable=SC2034
BOLD='\033[1m'

# デフォルト設定
TIMEOUT=300
MAX_RETRY=3
FALLBACK=false
QUIET=false
RETRY_DELAY=5

# ============================================
# 関数定義
# ============================================

log_info() {
    if [ "$QUIET" = false ]; then
        echo -e "${BLUE}[INFO]${NC} $1"
    fi
}

log_success() {
    if [ "$QUIET" = false ]; then
        echo -e "${GREEN}[SUCCESS]${NC} $1"
    fi
}

log_warn() {
    if [ "$QUIET" = false ]; then
        echo -e "${YELLOW}[WARN]${NC} $1"
    fi
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# スピナー表示
show_spinner() {
    local pid=$1
    local message=$2
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0

    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) % 10 ))
        printf "\r${CYAN}${spin:$i:1}${NC} $message"
        sleep 0.1
    done
    printf "\r"
}

# AIコマンドの存在確認
check_ai_available() {
    local ai=$1

    case $ai in
        claude)
            command -v claude >/dev/null 2>&1
            ;;
        codex)
            command -v codex >/dev/null 2>&1
            ;;
        gemini)
            command -v gemini >/dev/null 2>&1
            ;;
        *)
            return 1
            ;;
    esac
}

# AI実行
run_ai() {
    local ai=$1
    local prompt=$2
    local output_file
    output_file=$(mktemp)

    # Warn when sending to external AI services
    if [ "$ai" = "codex" ] || [ "$ai" = "gemini" ]; then
        if type warn_external_ai_send &>/dev/null; then
            warn_external_ai_send "$ai"
        fi
    fi

    case $ai in
        claude)
            timeout $TIMEOUT claude --print "$prompt" > "$output_file" 2>&1
            ;;
        codex)
            timeout $TIMEOUT codex exec --full-auto "$prompt" > "$output_file" 2>&1
            ;;
        gemini)
            timeout $TIMEOUT gemini "$prompt" > "$output_file" 2>&1
            ;;
    esac

    local exit_code=$?
    cat "$output_file"
    rm -f "$output_file"
    return $exit_code
}

# フォールバック先を決定
get_fallback_ai() {
    local failed_ai=$1

    case $failed_ai in
        claude)
            # Claude失敗 → Codexで実装、またはGeminiで解析
            if check_ai_available codex; then
                echo "codex"
            elif check_ai_available gemini; then
                echo "gemini"
            fi
            ;;
        codex)
            # Codex失敗 → Claudeで実装
            if check_ai_available claude; then
                echo "claude"
            fi
            ;;
        gemini)
            # Gemini失敗 → Claudeで解析（要約モード）
            if check_ai_available claude; then
                echo "claude"
            fi
            ;;
    esac
}

# エラーの種類を判定
classify_error() {
    local error_output=$1

    if echo "$error_output" | grep -qi "timeout"; then
        echo "timeout"
    elif echo "$error_output" | grep -qi "rate.limit\|too.many.requests\|429"; then
        echo "rate_limit"
    elif echo "$error_output" | grep -qi "auth\|unauthorized\|401\|403"; then
        echo "auth"
    elif echo "$error_output" | grep -qi "network\|connection\|ECONNREFUSED"; then
        echo "network"
    elif echo "$error_output" | grep -qi "not.found\|command.not.found"; then
        echo "not_installed"
    else
        echo "unknown"
    fi
}

# レート制限時の待機
handle_rate_limit() {
    local wait_time=${1:-60}
    log_warn "レート制限に達しました。${wait_time}秒待機します..."

    for i in $(seq $wait_time -1 1); do
        printf "\r${YELLOW}待機中: ${i}秒${NC}  "
        sleep 1
    done
    printf "\r                    \r"
}

# メイン実行関数
execute_with_recovery() {
    local ai=$1
    local prompt=$2
    local attempt=1
    local last_error=""

    # AI利用可能性チェック
    if ! check_ai_available "$ai"; then
        log_error "$ai がインストールされていません"

        if [ "$FALLBACK" = true ]; then
            local fallback_ai
            fallback_ai=$(get_fallback_ai "$ai")
            if [ -n "$fallback_ai" ]; then
                log_warn "フォールバック: $fallback_ai を使用します"
                ai=$fallback_ai
            else
                return 1
            fi
        else
            echo ""
            echo "インストール方法:"
            case $ai in
                claude)
                    echo "  npm install -g @anthropic-ai/claude-code"
                    ;;
                codex)
                    echo "  npm install -g @openai/codex"
                    ;;
                gemini)
                    echo "  npm install -g @google/gemini-cli"
                    ;;
            esac
            return 1
        fi
    fi

    # リトライループ
    while [ $attempt -le $MAX_RETRY ]; do
        log_info "実行中: $ai (試行 $attempt/$MAX_RETRY)"

        # 実行
        local output_file
        output_file=$(mktemp)
        local start_time
        start_time=$(date +%s)

        if [ "$QUIET" = false ]; then
            run_ai "$ai" "$prompt" &
            local pid=$!
            show_spinner $pid "$ai を実行中..."
            wait $pid
            local exit_code=$?
        else
            run_ai "$ai" "$prompt"
            local exit_code=$?
        fi

        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))

        # 成功
        if [ $exit_code -eq 0 ]; then
            log_success "完了 (${duration}秒)"
            return 0
        fi

        # エラー分類
        last_error=$(classify_error "$(cat "$output_file" 2>/dev/null)")
        rm -f "$output_file"

        case $last_error in
            timeout)
                log_warn "タイムアウト (${TIMEOUT}秒)"
                ;;
            rate_limit)
                handle_rate_limit 60
                ;;
            auth)
                log_error "認証エラー: 再ログインが必要です"
                echo "  $ai を実行してログインしてください"
                return 1
                ;;
            network)
                log_warn "ネットワークエラー"
                sleep $RETRY_DELAY
                ;;
            not_installed)
                log_error "$ai がインストールされていません"
                return 1
                ;;
            *)
                log_warn "エラーが発生しました"
                sleep $RETRY_DELAY
                ;;
        esac

        attempt=$((attempt + 1))

        if [ $attempt -le $MAX_RETRY ]; then
            log_info "${RETRY_DELAY}秒後にリトライします..."
            sleep $RETRY_DELAY
        fi
    done

    # 全リトライ失敗
    log_error "$MAX_RETRY 回試行しましたが失敗しました"

    # フォールバック
    if [ "$FALLBACK" = true ]; then
        local fallback_ai
        fallback_ai=$(get_fallback_ai "$ai")
        if [ -n "$fallback_ai" ]; then
            log_warn "フォールバック: $fallback_ai で再試行します"
            execute_with_recovery "$fallback_ai" "$prompt"
            return $?
        fi
    fi

    return 1
}

# ヘルプ表示
show_help() {
    echo "AI Runner - エラーリカバリ機構付きAI実行"
    echo ""
    echo "使用方法:"
    echo "  ./scripts/ai-runner.sh <ai> <prompt> [options]"
    echo ""
    echo "AI:"
    echo "  claude    Claude Code"
    echo "  codex     OpenAI Codex"
    echo "  gemini    Google Gemini"
    echo ""
    echo "オプション:"
    echo "  --timeout <秒>     タイムアウト秒数（デフォルト: 300）"
    echo "  --retry <回数>     リトライ回数（デフォルト: 3）"
    echo "  --fallback         失敗時に別AIにフォールバック"
    echo "  --quiet            静かに実行"
    echo "  --help             このヘルプを表示"
    echo ""
    echo "例:"
    echo "  ./scripts/ai-runner.sh claude \"この関数を説明して\""
    echo "  ./scripts/ai-runner.sh codex \"テストを作成\" --timeout 600"
    echo "  ./scripts/ai-runner.sh gemini \"コードを解析\" --fallback"
    echo ""
    echo "フォールバック順序:"
    echo "  Claude失敗 → Codex → Gemini"
    echo "  Codex失敗  → Claude"
    echo "  Gemini失敗 → Claude"
}

# ============================================
# メイン処理
# ============================================

# 引数がない場合
if [ $# -lt 1 ]; then
    show_help
    exit 1
fi

# 引数パース
AI=""
PROMPT=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        --retry)
            MAX_RETRY="$2"
            shift 2
            ;;
        --fallback)
            FALLBACK=true
            shift
            ;;
        --quiet|-q)
            QUIET=true
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        claude|codex|gemini)
            AI="$1"
            shift
            ;;
        *)
            if [ -z "$AI" ]; then
                log_error "不明なAI: $1"
                exit 1
            else
                PROMPT="$1"
                shift
            fi
            ;;
    esac
done

# バリデーション
if [ -z "$AI" ]; then
    log_error "AIを指定してください (claude/codex/gemini)"
    exit 1
fi

if [ -z "$PROMPT" ]; then
    log_error "プロンプトを指定してください"
    exit 1
fi

# 実行
execute_with_recovery "$AI" "$PROMPT"
