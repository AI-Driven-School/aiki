#!/bin/bash
# ============================================
# AI Usage Report - Token Usage & Cost Tracking
# ============================================
# Usage:
#   ./scripts/usage-report.sh          # Today's usage
#   ./scripts/usage-report.sh --week   # Past 7 days
#   ./scripts/usage-report.sh --month  # Past 30 days
#   ./scripts/usage-report.sh --reset  # Reset data
# ============================================

set -euo pipefail

# Color definitions
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
GRAY='\033[0;90m'
NC='\033[0m'
BOLD='\033[1m'

# Settings
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
USAGE_DIR="$PROJECT_DIR/.usage"
USAGE_FILE="$USAGE_DIR/usage.log"
# shellcheck disable=SC2034
SUMMARY_FILE="$USAGE_DIR/summary.json"

# Pricing (per 1K tokens)
CLAUDE_INPUT_COST=0.003    # $3/1M input
CLAUDE_OUTPUT_COST=0.015   # $15/1M output
# shellcheck disable=SC2034
CODEX_COST=0               # Included in ChatGPT Pro
# shellcheck disable=SC2034
GEMINI_COST=0              # Free tier

# Initialize directory
mkdir -p "$USAGE_DIR"
touch "$USAGE_FILE"

# ============================================
# Functions
# ============================================

show_header() {
    echo -e "${CYAN}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  AI Usage Report - claude-codex-collab"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${NC}"
}

# Record usage
log_usage() {
    local ai="$1"
    local input_tokens="$2"
    local output_tokens="$3"
    local task="$4"
    local timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    echo "$timestamp|$ai|$input_tokens|$output_tokens|$task" >> "$USAGE_FILE"
}

# Get today's usage
get_today_usage() {
    local today
    today=$(date +"%Y-%m-%d")
    grep "^$today" "$USAGE_FILE" 2>/dev/null || echo ""
}

# Get usage for period
get_period_usage() {
    local days="$1"
    local start_date
    start_date=$(date -v-${days}d +"%Y-%m-%d" 2>/dev/null || date -d "-${days} days" +"%Y-%m-%d")

    while IFS= read -r line; do
        local log_date
        log_date=$(echo "$line" | cut -d'|' -f1 | cut -d' ' -f1)
        if [[ "$log_date" > "$start_date" ]] || [[ "$log_date" == "$start_date" ]]; then
            echo "$line"
        fi
    done < "$USAGE_FILE"
}

# Aggregate usage
calculate_usage() {
    local data="$1"

    local claude_input=0
    local claude_output=0
    local codex_input=0
    local codex_output=0
    local gemini_input=0
    local gemini_output=0

    while IFS='|' read -r timestamp ai input output task; do
        case "$ai" in
            "claude")
                claude_input=$((claude_input + input))
                claude_output=$((claude_output + output))
                ;;
            "codex")
                codex_input=$((codex_input + input))
                codex_output=$((codex_output + output))
                ;;
            "gemini")
                gemini_input=$((gemini_input + input))
                gemini_output=$((gemini_output + output))
                ;;
        esac
    done <<< "$data"

    echo "$claude_input|$claude_output|$codex_input|$codex_output|$gemini_input|$gemini_output"
}

# Calculate cost
calculate_cost() {
    local claude_input="$1"
    local claude_output="$2"

    # Claude cost ($3/1M input, $15/1M output)
    local input_cost
    input_cost=$(echo "scale=4; $claude_input * $CLAUDE_INPUT_COST / 1000" | bc)
    local output_cost
    output_cost=$(echo "scale=4; $claude_output * $CLAUDE_OUTPUT_COST / 1000" | bc)
    local total
    total=$(echo "scale=2; $input_cost + $output_cost" | bc)

    echo "$total"
}

# Draw progress bar
draw_bar() {
    local value="$1"
    local max="$2"
    local width=20
    local color="$3"

    if [ "$max" -eq 0 ]; then
        max=1
    fi

    local filled=$((value * width / max))
    if [ "$filled" -gt "$width" ]; then
        filled=$width
    fi

    local empty=$((width - filled))

    printf "${color}"
    printf '█%.0s' $(seq 1 $filled 2>/dev/null) || true
    printf "${GRAY}"
    printf '░%.0s' $(seq 1 $empty 2>/dev/null) || true
    printf "${NC}"
}

# Display main report
show_report() {
    # shellcheck disable=SC2034
    local period="$1"
    local period_label="$2"
    local data="$3"

    if [ -z "$data" ]; then
        echo -e "${YELLOW}No data available${NC}"
        echo ""
        echo "To record usage:"
        echo -e "  ${BLUE}./scripts/usage-report.sh --log claude 1000 500 \"design task\"${NC}"
        echo ""
        return
    fi

    local usage
    usage=$(calculate_usage "$data")
    IFS='|' read -r claude_in claude_out codex_in codex_out gemini_in gemini_out <<< "$usage"

    local claude_total=$((claude_in + claude_out))
    local codex_total=$((codex_in + codex_out))
    local gemini_total=$((gemini_in + gemini_out))
    local all_total=$((claude_total + codex_total + gemini_total))

    local claude_cost
    claude_cost=$(calculate_cost "$claude_in" "$claude_out")

    echo -e "${BOLD}$period_label${NC}"
    echo ""

    # Claude
    printf "  ${BLUE}Claude${NC}   "
    draw_bar "$claude_total" "$all_total" "$BLUE"
    printf "  %'d tokens" "$claude_total"
    echo -e "  ${YELLOW}\$${claude_cost}${NC}"

    # Codex
    printf "  ${GREEN}Codex${NC}    "
    draw_bar "$codex_total" "$all_total" "$GREEN"
    printf "  %'d tokens" "$codex_total"
    echo -e "  ${GREEN}\$0.00${NC} ${GRAY}(included in Pro)${NC}"

    # Gemini
    printf "  ${CYAN}Gemini${NC}   "
    draw_bar "$gemini_total" "$all_total" "$CYAN"
    printf "  %'d tokens" "$gemini_total"
    echo -e "  ${GREEN}\$0.00${NC} ${GRAY}(free)${NC}"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Total and cost savings
    local claude_only_cost
    claude_only_cost=$(echo "scale=2; ($claude_in + $codex_in + $gemini_in) * $CLAUDE_INPUT_COST / 1000 + ($claude_out + $codex_out + $gemini_out) * $CLAUDE_OUTPUT_COST / 1000" | bc)
    local savings
    savings=$(echo "scale=0; (1 - $claude_cost / $claude_only_cost) * 100" | bc 2>/dev/null || echo "0")

    printf "  ${BOLD}Total:${NC} %'d tokens\n" "$all_total"
    echo ""
    echo -e "  ${BOLD}Cost:${NC} ${YELLOW}\$${claude_cost}${NC}"
    echo -e "  ${GRAY}(Claude-only would be \$${claude_only_cost})${NC}"

    if [ "$savings" != "0" ] && [ -n "$savings" ]; then
        echo ""
        echo -e "  ${GREEN}${savings}% cost reduction achieved!${NC}"
    fi

    echo ""
}

# Cost reduction simulation
show_simulation() {
    echo -e "${BOLD}Cost Reduction Simulation${NC}"
    echo ""
    echo "  Enter monthly lines of code (e.g., 5000)"
    read -p "  > " lines

    if ! [[ "$lines" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Please enter a number${NC}"
        return
    fi

    # Estimate: 1 line ~ 20 tokens, implementation 50%, design 30%, testing 20%
    local total_tokens=$((lines * 20))
    local design_tokens=$((total_tokens * 30 / 100))
    # shellcheck disable=SC2034
    local impl_tokens=$((total_tokens * 50 / 100))
    # shellcheck disable=SC2034
    local test_tokens=$((total_tokens * 20 / 100))

    local claude_only
    claude_only=$(echo "scale=2; $total_tokens * ($CLAUDE_INPUT_COST + $CLAUDE_OUTPUT_COST) / 2 / 1000" | bc)
    local with_collab
    with_collab=$(echo "scale=2; $design_tokens * ($CLAUDE_INPUT_COST + $CLAUDE_OUTPUT_COST) / 2 / 1000" | bc)
    local savings
    savings=$(echo "scale=2; $claude_only - $with_collab" | bc)
    local percent
    percent=$(echo "scale=0; (1 - $with_collab / $claude_only) * 100" | bc)

    echo ""
    echo "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "  ${GRAY}Claude only:${NC}       \$${claude_only}/mo"
    echo ""
    echo -e "  ${BOLD}claude-codex-collab:${NC}"
    echo -e "    Claude (design): \$${with_collab}"
    echo -e "    Codex (impl):    ${GREEN}\$0.00${NC}"
    echo -e "    Gemini (analysis):${GREEN}\$0.00${NC}"
    echo -e "    ────────────────────"
    echo -e "    ${BOLD}Total:${NC}           ${YELLOW}\$${with_collab}/mo${NC}"
    echo ""
    echo -e "  ${GREEN}Savings: \$${savings}/mo (${percent}% reduction)${NC}"
    echo ""
}

# Reset data
reset_data() {
    echo -e "${YELLOW}Reset usage data? [y/N]${NC}"
    read -p "> " confirm

    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        rm -f "$USAGE_FILE"
        touch "$USAGE_FILE"
        echo -e "${GREEN}Reset complete${NC}"
    else
        echo "Cancelled"
    fi
}

# Log usage manually
manual_log() {
    local ai="$2"
    local input="$3"
    local output="$4"
    local task="${5:-manual entry}"

    if [ -z "$ai" ] || [ -z "$input" ] || [ -z "$output" ]; then
        echo "Usage: ./scripts/usage-report.sh --log <ai> <input_tokens> <output_tokens> [task]"
        echo "Example: ./scripts/usage-report.sh --log claude 1000 500 \"design task\""
        exit 1
    fi

    log_usage "$ai" "$input" "$output" "$task"
    echo -e "${GREEN}Recorded: $ai - input:$input, output:$output${NC}"
}

# Show help
show_help() {
    echo "AI Usage Report - claude-codex-collab"
    echo ""
    echo "Usage:"
    echo "  ./scripts/usage-report.sh              Show today's usage"
    echo "  ./scripts/usage-report.sh --week       Past 7 days"
    echo "  ./scripts/usage-report.sh --month      Past 30 days"
    echo "  ./scripts/usage-report.sh --simulate   Cost reduction simulation"
    echo "  ./scripts/usage-report.sh --log <ai> <in> <out> [task]  Record usage"
    echo "  ./scripts/usage-report.sh --reset      Reset data"
    echo "  ./scripts/usage-report.sh --help       Show this help"
    echo ""
    echo "Examples:"
    echo "  ./scripts/usage-report.sh --log claude 1500 800 \"API design\""
    echo "  ./scripts/usage-report.sh --log codex 5000 3000 \"implementation\""
    echo "  ./scripts/usage-report.sh --log gemini 10000 2000 \"code analysis\""
}

# ============================================
# Main
# ============================================

case "${1:-}" in
    "--week")
        show_header
        data=$(get_period_usage 7)
        show_report 7 "Usage (past 7 days)" "$data"
        ;;
    "--month")
        show_header
        data=$(get_period_usage 30)
        show_report 30 "Usage (past 30 days)" "$data"
        ;;
    "--simulate")
        show_header
        show_simulation
        ;;
    "--log")
        manual_log "$@"
        ;;
    "--reset")
        reset_data
        ;;
    "--help"|"-h")
        show_help
        ;;
    *)
        show_header
        data=$(get_today_usage)
        show_report 1 "Today's usage ($(date +%Y-%m-%d))" "$data"
        ;;
esac
