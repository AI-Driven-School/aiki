#!/usr/bin/env bash
# tui.sh - TUI visual library for aiki
# Provides spinners, gauges, badges, banners, and AI-colored phase headers.
# Bash 3.2+ compatible (no declare -A, no ${var,,}).
# No external tool dependencies (no gum, dialog, etc).

# ── Guard: only load once ──────────────────────────────────────────
if [ "${_TUI_LOADED:-}" = "true" ]; then return 0 2>/dev/null || true; fi
_TUI_LOADED=true

# ── Feature detection ──────────────────────────────────────────────
TUI_AVAILABLE=true

# Disable TUI if not a terminal or explicitly disabled
if [ ! -t 1 ] || [ "${NO_TUI:-}" = "true" ]; then
    TUI_AVAILABLE=false
fi

# ── AI Color Scheme (256-color) ────────────────────────────────────
AI_CLAUDE='\033[38;5;179m'    # Gold
AI_CODEX='\033[38;5;84m'      # Bright green
AI_GEMINI='\033[38;5;111m'    # Blue
AI_GROK='\033[38;5;203m'      # Red/coral

TUI_BOLD='\033[1m'
TUI_DIM='\033[2m'
TUI_RESET='\033[0m'
TUI_WHITE='\033[38;5;255m'
TUI_GRAY='\033[38;5;243m'
TUI_GREEN='\033[38;5;84m'
TUI_RED='\033[38;5;203m'
TUI_YELLOW='\033[38;5;221m'

# ── Cursor management ─────────────────────────────────────────────
_tui_cursor_hidden=false

_tui_hide_cursor() {
    if [ "$TUI_AVAILABLE" = "true" ] && [ "$_tui_cursor_hidden" = "false" ]; then
        tput civis 2>/dev/null || true
        _tui_cursor_hidden=true
    fi
}

_tui_show_cursor() {
    if [ "$_tui_cursor_hidden" = "true" ]; then
        tput cnorm 2>/dev/null || true
        _tui_cursor_hidden=false
    fi
}

# Cleanup: kill spinner + restore cursor
_tui_cleanup() {
    if [ -n "${_TUI_SPINNER_PID:-}" ]; then
        kill "$_TUI_SPINNER_PID" 2>/dev/null || true
        wait "$_TUI_SPINNER_PID" 2>/dev/null || true
        _TUI_SPINNER_PID=""
    fi
    _tui_show_cursor
}

# Chain with existing EXIT trap (don't overwrite)
_tui_existing_exit_trap=$(trap -p EXIT | sed "s/^trap -- '//;s/' EXIT$//")
if [ -n "$_tui_existing_exit_trap" ]; then
    trap "_tui_cleanup; $_tui_existing_exit_trap" EXIT
else
    trap '_tui_cleanup' EXIT
fi

# Also handle SIGINT/SIGTERM to prevent orphan spinner processes
trap '_tui_cleanup; exit 130' INT
trap '_tui_cleanup; exit 143' TERM

# ── Color for AI name ─────────────────────────────────────────────
_tui_ai_color() {
    local ai="$1"
    case "$ai" in
        Claude|claude) printf '%b' "$AI_CLAUDE" ;;
        Codex|codex)   printf '%b' "$AI_CODEX" ;;
        Gemini|gemini) printf '%b' "$AI_GEMINI" ;;
        Grok|grok)     printf '%b' "$AI_GROK" ;;
        *)             printf '%b' "$TUI_WHITE" ;;
    esac
}

# ── tui_banner ─────────────────────────────────────────────────────
# ASCII-framed project start banner
# Usage: tui_banner "ECサイトのカート機能"
tui_banner() {
    local title="$1"
    if [ "$TUI_AVAILABLE" != "true" ]; then
        echo "=== Pipeline: ${title} ==="
        return
    fi
    echo ""
    printf '%b' "${TUI_BOLD}${AI_CLAUDE}"
    echo "  ┌──────────────────────────────────────────────────┐"
    printf "  │  %-48s│\n" "aiki Pipeline"
    printf "  │  %-48s│\n" "${title}"
    echo "  │                                                  │"
    printf "  │  %-48s│\n" "Claude + Codex + Gemini + Grok"
    echo "  └──────────────────────────────────────────────────┘"
    printf '%b' "${TUI_RESET}"
    echo ""
}

# ── tui_phase_header ───────────────────────────────────────────────
# Displays: [N/6] Phase Name (AI) + $0 badge for Codex
# Usage: tui_phase_header 3 "Implementation" "Codex"
tui_phase_header() {
    local num="$1"
    local name="$2"
    local ai="$3"
    local total="${4:-6}"

    if [ "$TUI_AVAILABLE" != "true" ]; then
        echo "[${num}/${total}] ${name} (${ai})"
        return
    fi

    local color
    color=$(_tui_ai_color "$ai")

    local badge=""
    case "$ai" in
        Codex|codex) badge=" ${TUI_BOLD}${AI_CODEX}★ \$0${TUI_RESET}" ;;
    esac

    printf '%b' "${TUI_GRAY}[${num}/${total}]${TUI_RESET} "
    printf '%b' "${TUI_WHITE}${TUI_BOLD}%-18s${TUI_RESET} " "$name"
    printf '%b' "${color}(${ai})${TUI_RESET}"
    printf '%b' "${badge}"
    echo ""
}

# ── tui_spinner / tui_spinner_stop ─────────────────────────────────
# Braille spinner running in background
# Usage:
#   tui_spinner "Analyzing requirements..."
#   sleep 2
#   tui_spinner_stop
_TUI_SPINNER_PID=""

tui_spinner() {
    local msg="$1"

    if [ "$TUI_AVAILABLE" != "true" ]; then
        echo "  ... ${msg}"
        return
    fi

    _tui_hide_cursor

    (
        local chars='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
        local i=0
        local len=${#chars}
        while true; do
            local c="${chars:$i:1}"
            printf "\r  %b%s %b%b" "${TUI_GRAY}" "$c" "$msg" "${TUI_RESET}"
            sleep 0.08
            i=$(( (i + 1) % len ))
        done
    ) &
    _TUI_SPINNER_PID=$!
    disown $_TUI_SPINNER_PID 2>/dev/null || true
}

tui_spinner_stop() {
    local result="${1:-}"

    if [ -n "$_TUI_SPINNER_PID" ]; then
        kill "$_TUI_SPINNER_PID" 2>/dev/null || true
        wait "$_TUI_SPINNER_PID" 2>/dev/null || true
        _TUI_SPINNER_PID=""
    fi

    # Clear spinner line
    printf "\r\033[K"
    _tui_show_cursor

    if [ -n "$result" ]; then
        printf '  %b✓%b %s\n' "${TUI_GREEN}" "${TUI_RESET}" "$result"
    fi
}

# ── tui_file_appear ────────────────────────────────────────────────
# Cascade display of file paths
# Usage: tui_file_appear "src/app/login/page.tsx"
tui_file_appear() {
    local filepath="$1"
    local status="${2:-✓}"

    if [ "$TUI_AVAILABLE" != "true" ]; then
        echo "  -> ${filepath} ${status}"
        return
    fi

    printf '      %b→%b %b%s%b %b%s%b\n' \
        "${TUI_GRAY}" "${TUI_RESET}" \
        "${AI_GEMINI}" "$filepath" "${TUI_RESET}" \
        "${TUI_GREEN}" "$status" "${TUI_RESET}"
    sleep 0.25
}

# ── tui_typing ─────────────────────────────────────────────────────
# Typing animation
# Usage: tui_typing "npx aiki 'ECサイトのカート機能'"
tui_typing() {
    local text="$1"
    local delay="${2:-0.04}"

    if [ "$TUI_AVAILABLE" != "true" ]; then
        echo "$text"
        return
    fi

    _tui_hide_cursor
    local i=0
    while [ $i -lt ${#text} ]; do
        printf '%s' "${text:$i:1}"
        sleep "$delay"
        i=$((i + 1))
    done
    _tui_show_cursor
}

# ── tui_score_gauge ────────────────────────────────────────────────
# Quality score bar: Quality Score: 96/100 █████████████░░░
# Usage: tui_score_gauge 96
tui_score_gauge() {
    local score="$1"
    local max="${2:-100}"
    local bar_width=20

    if [ "$TUI_AVAILABLE" != "true" ]; then
        echo "  Quality Score: ${score}/${max}"
        return
    fi

    local filled=$((score * bar_width / max))
    local empty=$((bar_width - filled))

    # Color based on score
    local color="$TUI_GREEN"
    if [ "$score" -lt 50 ]; then
        color="$TUI_RED"
    elif [ "$score" -lt 80 ]; then
        color="$TUI_YELLOW"
    fi

    printf '  %b%bQuality Score:%b ' "${TUI_WHITE}" "${TUI_BOLD}" "${TUI_RESET}"
    printf '%b%b%s/%s%b ' "$color" "${TUI_BOLD}" "$score" "$max" "${TUI_RESET}"

    # Draw bar
    printf '%b' "$color"
    local j=0
    while [ $j -lt $filled ]; do
        printf '█'
        j=$((j + 1))
    done
    printf '%b' "${TUI_GRAY}"
    j=0
    while [ $j -lt $empty ]; do
        printf '░'
        j=$((j + 1))
    done
    printf '%b\n' "${TUI_RESET}"
}

# ── tui_cost_bars ──────────────────────────────────────────────────
# 3-tier cost comparison bars: Devin / SingleAI / aiki
# Usage: tui_cost_bars
tui_cost_bars() {
    if [ "$TUI_AVAILABLE" != "true" ]; then
        echo "  Cost: Devin \$500/mo | Single AI \$0.85 | aiki \$0.21"
        return
    fi

    echo ""
    printf '  %b%bCost Comparison%b\n' "${TUI_WHITE}" "${TUI_BOLD}" "${TUI_RESET}"
    echo ""

    # Devin: $500/mo - long red bar
    printf '  %bDevin     \$500/mo%b  ' "${TUI_RED}" "${TUI_RESET}"
    printf '%b' "${TUI_RED}"
    local k=0
    while [ $k -lt 35 ]; do printf '▓'; k=$((k + 1)); done
    printf '%b\n' "${TUI_RESET}"

    # Single AI: $0.85 - medium yellow bar
    printf '  %bSingle AI   \$0.85%b  ' "${TUI_YELLOW}" "${TUI_RESET}"
    printf '%b' "${TUI_YELLOW}"
    k=0
    while [ $k -lt 14 ]; do printf '▓'; k=$((k + 1)); done
    printf '%b' "${TUI_GRAY}"
    while [ $k -lt 35 ]; do printf '░'; k=$((k + 1)); done
    printf '%b\n' "${TUI_RESET}"

    # aiki: $0.21 - short green bar
    printf '  %baiki      \$0.21%b  ' "${TUI_GREEN}" "${TUI_RESET}"
    printf '%b' "${TUI_GREEN}"
    k=0
    while [ $k -lt 4 ]; do printf '▓'; k=$((k + 1)); done
    printf '%b' "${TUI_GRAY}"
    while [ $k -lt 35 ]; do printf '░'; k=$((k + 1)); done
    printf '  %b%b75%% saved%b\n' "${TUI_GREEN}" "${TUI_BOLD}" "${TUI_RESET}"
}

# ── tui_separator ──────────────────────────────────────────────────
# Theme separator line
# Usage: tui_separator
tui_separator() {
    local color="${1:-$TUI_GREEN}"

    if [ "$TUI_AVAILABLE" != "true" ]; then
        echo "────────────────────────────────────────────────"
        return
    fi

    printf '%b━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%b\n' "$color" "${TUI_RESET}"
}

# ── tui_summary_table ──────────────────────────────────────────────
# Aligned summary table of phase results
# Usage: tui_summary_table "Phase:Result:Duration" ...
# Each arg format: "name:result:duration"
tui_summary_table() {
    if [ "$TUI_AVAILABLE" != "true" ]; then
        for entry in "$@"; do
            echo "  $entry"
        done
        return
    fi

    printf '\n'
    printf '  %b%b%-18s %-10s %-10s%b\n' "${TUI_WHITE}" "${TUI_BOLD}" "Phase" "Result" "Duration" "${TUI_RESET}"
    printf '  %-18s %-10s %-10s\n' "──────────────────" "──────────" "──────────"

    for entry in "$@"; do
        local name result duration color
        # Parse colon-separated entry
        name=$(echo "$entry" | cut -d: -f1)
        result=$(echo "$entry" | cut -d: -f2)
        duration=$(echo "$entry" | cut -d: -f3)

        color="${TUI_GREEN}"
        case "$result" in
            FAIL*|fail*) color="${TUI_RED}" ;;
            WARN*|warn*|FIXABLE*) color="${TUI_YELLOW}" ;;
            SKIP*|skip*) color="${TUI_GRAY}" ;;
        esac

        printf '  %-18s %b%-10s%b %-10s\n' "$name" "$color" "$result" "${TUI_RESET}" "$duration"
    done
}

# ── tui_success / tui_error ────────────────────────────────────────
tui_success() {
    printf '  %b✓%b %s\n' "${TUI_GREEN}" "${TUI_RESET}" "$1"
}

tui_error() {
    printf '  %b✗%b %s\n' "${TUI_RED}" "${TUI_RESET}" "$1"
}

tui_info() {
    printf '  %b→%b %s\n' "${TUI_GRAY}" "${TUI_RESET}" "$1"
}
