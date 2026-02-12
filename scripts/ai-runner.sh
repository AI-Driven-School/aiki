#!/bin/bash
# ============================================
# AI Runner - AI Execution with Error Recovery
# ============================================
# Usage:
#   ./scripts/ai-runner.sh claude "prompt"
#   ./scripts/ai-runner.sh codex "task"
#   ./scripts/ai-runner.sh gemini "question"
#
# Options:
#   --timeout 300      Timeout in seconds (default: 300)
#   --retry 3          Retry count (default: 3)
#   --fallback         Fall back to another AI on failure
#   --quiet            Quiet mode
# ============================================

set -euo pipefail

# Load sensitive file filter
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/lib/sensitive-filter.sh" ]; then
    # shellcheck source=lib/sensitive-filter.sh
    source "$SCRIPT_DIR/lib/sensitive-filter.sh"
fi

# Color definitions
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

# Default settings
TIMEOUT=300
MAX_RETRY=3
FALLBACK=false
QUIET=false
RETRY_DELAY=5

# ============================================
# Functions
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

# Show spinner
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

# Check AI command availability
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

# Execute AI
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

# Determine fallback AI
get_fallback_ai() {
    local failed_ai=$1

    case $failed_ai in
        claude)
            # Claude failed -> try Codex, then Gemini
            if check_ai_available codex; then
                echo "codex"
            elif check_ai_available gemini; then
                echo "gemini"
            fi
            ;;
        codex)
            # Codex failed -> try Claude
            if check_ai_available claude; then
                echo "claude"
            fi
            ;;
        gemini)
            # Gemini failed -> try Claude
            if check_ai_available claude; then
                echo "claude"
            fi
            ;;
    esac
}

# Classify error type
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

# Handle rate limiting
handle_rate_limit() {
    local wait_time=${1:-60}
    log_warn "Rate limited. Waiting ${wait_time}s..."

    for i in $(seq $wait_time -1 1); do
        printf "\r${YELLOW}Waiting: ${i}s${NC}  "
        sleep 1
    done
    printf "\r                    \r"
}

# Main execution function
execute_with_recovery() {
    local ai=$1
    local prompt=$2
    local attempt=1
    local last_error=""

    # Check AI availability
    if ! check_ai_available "$ai"; then
        log_error "$ai is not installed"

        if [ "$FALLBACK" = true ]; then
            local fallback_ai
            fallback_ai=$(get_fallback_ai "$ai")
            if [ -n "$fallback_ai" ]; then
                log_warn "Fallback: using $fallback_ai"
                ai=$fallback_ai
            else
                return 1
            fi
        else
            echo ""
            echo "Install with:"
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

    # Retry loop
    while [ $attempt -le $MAX_RETRY ]; do
        log_info "Running: $ai (attempt $attempt/$MAX_RETRY)"

        # Execute
        local output_file
        output_file=$(mktemp)
        local start_time
        start_time=$(date +%s)

        if [ "$QUIET" = false ]; then
            run_ai "$ai" "$prompt" &
            local pid=$!
            show_spinner $pid "Running $ai..."
            wait $pid
            local exit_code=$?
        else
            run_ai "$ai" "$prompt"
            local exit_code=$?
        fi

        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))

        # Success
        if [ $exit_code -eq 0 ]; then
            log_success "Done (${duration}s)"
            return 0
        fi

        # Classify error
        last_error=$(classify_error "$(cat "$output_file" 2>/dev/null)")
        rm -f "$output_file"

        case $last_error in
            timeout)
                log_warn "Timeout (${TIMEOUT}s)"
                ;;
            rate_limit)
                handle_rate_limit 60
                ;;
            auth)
                log_error "Auth error: re-login required"
                echo "  Run $ai to re-authenticate"
                return 1
                ;;
            network)
                log_warn "Network error"
                sleep $RETRY_DELAY
                ;;
            not_installed)
                log_error "$ai is not installed"
                return 1
                ;;
            *)
                log_warn "An error occurred"
                sleep $RETRY_DELAY
                ;;
        esac

        attempt=$((attempt + 1))

        if [ $attempt -le $MAX_RETRY ]; then
            log_info "Retrying in ${RETRY_DELAY}s..."
            sleep $RETRY_DELAY
        fi
    done

    # All retries failed
    log_error "Failed after $MAX_RETRY attempts"

    # Fallback
    if [ "$FALLBACK" = true ]; then
        local fallback_ai
        fallback_ai=$(get_fallback_ai "$ai")
        if [ -n "$fallback_ai" ]; then
            log_warn "Fallback: retrying with $fallback_ai"
            execute_with_recovery "$fallback_ai" "$prompt"
            return $?
        fi
    fi

    return 1
}

# Show help
show_help() {
    echo "AI Runner - AI execution with error recovery"
    echo ""
    echo "Usage:"
    echo "  ./scripts/ai-runner.sh <ai> <prompt> [options]"
    echo ""
    echo "AI:"
    echo "  claude    Claude Code"
    echo "  codex     OpenAI Codex"
    echo "  gemini    Google Gemini"
    echo ""
    echo "Options:"
    echo "  --timeout <secs>   Timeout in seconds (default: 300)"
    echo "  --retry <count>    Retry count (default: 3)"
    echo "  --fallback         Fall back to another AI on failure"
    echo "  --quiet            Quiet mode"
    echo "  --help             Show this help"
    echo ""
    echo "Examples:"
    echo "  ./scripts/ai-runner.sh claude \"Explain this function\""
    echo "  ./scripts/ai-runner.sh codex \"Create tests\" --timeout 600"
    echo "  ./scripts/ai-runner.sh gemini \"Analyze code\" --fallback"
    echo ""
    echo "Fallback order:"
    echo "  Claude fail -> Codex -> Gemini"
    echo "  Codex fail  -> Claude"
    echo "  Gemini fail -> Claude"
}

# ============================================
# Main
# ============================================

# No arguments
if [ $# -lt 1 ]; then
    show_help
    exit 1
fi

# Parse arguments
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
                log_error "Unknown AI: $1"
                exit 1
            else
                PROMPT="$1"
                shift
            fi
            ;;
    esac
done

# Validation
if [ -z "$AI" ]; then
    log_error "Please specify an AI (claude/codex/gemini)"
    exit 1
fi

if [ -z "$PROMPT" ]; then
    log_error "Please specify a prompt"
    exit 1
fi

# Run
execute_with_recovery "$AI" "$PROMPT"
