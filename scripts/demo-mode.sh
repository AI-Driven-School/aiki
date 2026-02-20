#!/usr/bin/env bash
# demo-mode.sh - 30-second viral demo of aiki pipeline
# Scripted TUI demo showing 4 AIs collaborating on a feature.
# All 4 AIs (Claude/Codex/Gemini/Grok) featured with completed app preview.
# Usage: bash scripts/demo-mode.sh ["feature name"]
#   or record: asciinema rec -c "bash scripts/demo-mode.sh" demo.cast

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Load TUI library
# shellcheck source=lib/tui.sh
source "${SCRIPT_DIR}/lib/tui.sh"

# ── Configuration ──────────────────────────────────────────────────

FEATURE="${1:-ECサイトのカート機能}"

# Timing
TYPE_DELAY=0.035
LINE_PAUSE=0.25
PHASE_PAUSE=0.35

# ── Helper ─────────────────────────────────────────────────────────

out() {
    local text="$1"
    local delay="${2:-$LINE_PAUSE}"
    printf '%b\n' "$text"
    sleep "$delay"
}

blank() {
    printf '\n'
    sleep 0.1
}

# ── DEMO START ─────────────────────────────────────────────────────

clear
_tui_hide_cursor
sleep 0.5

# [0-2s] Typing: npx aiki "feature"
printf '%b%b❯%b ' "${TUI_GREEN}" "${TUI_BOLD}" "${TUI_RESET}"
tui_typing "npx aiki \"${FEATURE}\"" "$TYPE_DELAY"
printf '\n'
sleep 0.6

# Banner
tui_banner "$FEATURE"
sleep "$PHASE_PAUSE"

# ── Phase 1: Research (Gemini/Blue) ───────────────────────────────
tui_phase_header 1 "Research" "Gemini" 8
tui_spinner "Analyzing tech stack & best practices..."
sleep 1.8
tui_spinner_stop
tui_file_appear ".claude/docs/research/cart-analysis.md"
out "      ${TUI_GREEN}✓${TUI_RESET} Compared 3 cart libraries, recommended zustand" 0.2
out "      ${TUI_GREEN}✓${TUI_RESET} Payment API: Stripe recommended ${TUI_GRAY}(1M token analysis)${TUI_RESET}" 0.15
blank
sleep "$PHASE_PAUSE"

# ── Phase 2: Trend Check (Grok/Red) ──────────────────────────────
tui_phase_header 2 "Trend Check" "Grok" 8
tui_spinner "Searching X for latest cart UX trends..."
sleep 1.5
tui_spinner_stop
tui_file_appear ".claude/docs/research/grok-cart-trends.md"
out "      ${TUI_GREEN}✓${TUI_RESET} Trending: one-tap checkout ${TUI_GRAY}(+340% engagement)${TUI_RESET}" 0.2
out "      ${TUI_GREEN}✓${TUI_RESET} Warning: Stripe SDK v4 breaking change detected" 0.15
blank
sleep "$PHASE_PAUSE"

# ── Phase 3: Requirements (Claude/Gold) ───────────────────────────
tui_phase_header 3 "Requirements" "Claude" 8
tui_spinner "Generating requirements from research..."
sleep 1.5
tui_spinner_stop
tui_file_appear "docs/requirements/cart.md"
out "      ${TUI_GREEN}✓${TUI_RESET} 6 user stories, 14 acceptance criteria" 0.2
blank
sleep "$PHASE_PAUSE"

# ── Phase 4: Design (Claude/Gold) ─────────────────────────────────
tui_phase_header 4 "Design" "Claude" 8
tui_spinner "Designing API & UI specs..."
sleep 1.5
tui_spinner_stop
tui_file_appear "docs/specs/cart-ui.md"
tui_file_appear "docs/api/cart.yaml"
out "      ${TUI_GREEN}✓${TUI_RESET} 6 endpoints, cart state machine, one-tap checkout" 0.2
blank
sleep "$PHASE_PAUSE"

# ── Phase 5: Implementation (Codex/Green ★$0) ─────────────────────
tui_phase_header 5 "Implementation" "Codex" 8
tui_spinner "Delegating to Codex (full-auto)..."
sleep 2.5
tui_spinner_stop
tui_file_appear "src/app/cart/page.tsx"
tui_file_appear "src/lib/api/cart.ts"
tui_file_appear "src/components/CartItem.tsx"
tui_file_appear "src/components/CartSummary.tsx"
tui_file_appear "src/components/OneTapCheckout.tsx"
tui_file_appear "src/hooks/useCart.ts"
out "      ${TUI_GREEN}✓${TUI_RESET} 6 files generated ${TUI_GRAY}(428 lines)${TUI_RESET}" 0.2
blank
sleep "$PHASE_PAUSE"

# ── Phase 6: Testing (Codex/Green ★$0) ────────────────────────────
tui_phase_header 6 "Testing" "Codex" 8
tui_spinner "Generating and running tests..."
sleep 1.8
tui_spinner_stop
tui_file_appear "tests/cart.spec.ts"
tui_file_appear "tests/cart-api.spec.ts"
tui_file_appear "tests/one-tap.spec.ts"
out "      ${TUI_GREEN}✓${TUI_RESET} 18 tests passed ${TUI_GRAY}(coverage: 96%)${TUI_RESET}" 0.2
blank
sleep "$PHASE_PAUSE"

# ── Phase 7: Review (Claude/Gold) ─────────────────────────────────
tui_phase_header 7 "Review" "Claude" 8
tui_spinner "Reviewing implementation..."
sleep 1.2
tui_spinner_stop
out "      ${TUI_GREEN}✓${TUI_RESET} Acceptance: ${TUI_GREEN}14/14 passed${TUI_RESET}" 0.12
out "      ${TUI_GREEN}✓${TUI_RESET} Security:   ${TUI_GREEN}passed${TUI_RESET} ${TUI_GRAY}(Stripe SDK v4 applied)${TUI_RESET}" 0.12
out "      ${TUI_GREEN}✓${TUI_RESET} Performance:${TUI_GREEN} passed${TUI_RESET}" 0.12
blank
sleep "$PHASE_PAUSE"

# ── Phase 8: Deploy ───────────────────────────────────────────────
tui_phase_header 8 "Deploy" "Claude" 8
tui_spinner "Deploying to Vercel..."
sleep 1.2
tui_spinner_stop
out "      ${TUI_GREEN}✓${TUI_RESET} ${AI_GEMINI}https://my-app.vercel.app${TUI_RESET}" 0.2
blank
sleep 0.3

# ── Completed App Preview ─────────────────────────────────────────
tui_separator "$AI_CLAUDE"
out "  ${TUI_WHITE}${TUI_BOLD}Completed App Preview${TUI_RESET}" 0.3
blank

printf '%b' "${TUI_GRAY}"
out "  ┌─────────────────────────────────────────────┐" 0.08
out "  │  ${TUI_WHITE}${TUI_BOLD}🛒 Shopping Cart${TUI_RESET}${TUI_GRAY}              my-app.vercel │" 0.08
out "  │─────────────────────────────────────────────│" 0.08
out "  │                                             │" 0.06
out "  │  ${TUI_WHITE}MacBook Pro 14\"${TUI_RESET}${TUI_GRAY}                           │" 0.06
out "  │  ${TUI_GRAY}Qty: 1          ${TUI_WHITE}¥298,800${TUI_RESET}${TUI_GRAY}                │" 0.06
out "  │                                             │" 0.06
out "  │  ${TUI_WHITE}AirPods Pro${TUI_RESET}${TUI_GRAY}                               │" 0.06
out "  │  ${TUI_GRAY}Qty: 2           ${TUI_WHITE}¥79,600${TUI_RESET}${TUI_GRAY}                │" 0.06
out "  │                                             │" 0.06
out "  │  ─────────────────────────────────────────  │" 0.06
out "  │  ${TUI_WHITE}${TUI_BOLD}Total:                      ¥378,400${TUI_RESET}${TUI_GRAY}    │" 0.08
out "  │                                             │" 0.06
out "  │  ${TUI_BOLD}${TUI_GREEN}[  ⚡ One-Tap Checkout  ]${TUI_RESET}${TUI_GRAY}                │" 0.08
out "  │                                             │" 0.06
out "  └─────────────────────────────────────────────┘" 0.08
printf '%b' "${TUI_RESET}"
blank
sleep 0.8

# ── Summary ───────────────────────────────────────────────────────
tui_separator
out "${TUI_GREEN}${TUI_BOLD}  Pipeline complete!${TUI_RESET}" 0.3
blank

# Phase result table
tui_summary_table \
    "Research:PASS:1.8s" \
    "Trend Check:PASS:1.5s" \
    "Requirements:PASS:1.5s" \
    "Design:PASS:1.5s" \
    "Implementation:PASS:2.5s" \
    "Testing:PASS:1.8s" \
    "Review:PASS:1.2s" \
    "Deploy:PASS:1.2s"

blank

# AI contribution summary
out "  ${TUI_WHITE}${TUI_BOLD}AI Contributions:${TUI_RESET}" 0.15
out "    ${AI_GEMINI}Gemini${TUI_RESET}  Research & tech comparison     ${TUI_GRAY}(free)${TUI_RESET}" 0.1
out "    ${AI_GROK}Grok${TUI_RESET}    X trend research & alerts     ${TUI_GRAY}(\$0.03)${TUI_RESET}" 0.1
out "    ${AI_CLAUDE}Claude${TUI_RESET}  Requirements, design, review  ${TUI_GRAY}(\$0.18)${TUI_RESET}" 0.1
out "    ${AI_CODEX}Codex${TUI_RESET}   Implementation & testing      ${TUI_GRAY}${TUI_BOLD}(\$0)${TUI_RESET}" 0.1
blank

# Score gauge
tui_score_gauge 96
blank

# Cost comparison bars
tui_cost_bars
blank

# Total
out "  ${TUI_WHITE}${TUI_BOLD}Total:${TUI_RESET} ${TUI_BOLD}13.0s${TUI_RESET}  ${TUI_GREEN}${TUI_BOLD}\$0.21${TUI_RESET}  ${TUI_GRAY}(4 AIs collaborated autonomously)${TUI_RESET}" 0.4
blank

tui_separator
blank

out "  ${TUI_GRAY}github.com/AI-Driven-School/aiki${TUI_RESET}" 0.2
out "  ${AI_CLAUDE}★ Star on GitHub to support 4-AI collaboration${TUI_RESET}" 0.3
blank

_tui_show_cursor
sleep 2.0
