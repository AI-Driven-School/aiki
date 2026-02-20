#!/usr/bin/env bash
# simulate-demo.sh - Realistic terminal demo for screen recording
# Records a convincing simulation of the 4-AI collaborative workflow.
# Now uses the shared TUI library for consistent visuals.
# Usage: bash landing/simulate-demo.sh
#   or record with: asciinema rec -c "bash landing/simulate-demo.sh" demo.cast

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Load TUI library
# shellcheck source=../scripts/lib/tui.sh
source "${SCRIPT_DIR}/scripts/lib/tui.sh"

# ===== Timing =====
TYPE_DELAY=0.04
LINE_PAUSE=0.3
PHASE_PAUSE=1.0
COMMAND_PAUSE=0.8

# ===== Helper Functions =====

# Print prompt and type a command
type_command() {
  local cmd="$1"
  printf "${TUI_GREEN}${TUI_BOLD}❯${TUI_RESET} "
  tui_typing "$cmd" "$TYPE_DELAY"
  printf '\n'
  sleep "$COMMAND_PAUSE"
}

# Print a line with optional delay
out() {
  local text="$1"
  local delay="${2:-$LINE_PAUSE}"
  printf '%b\n' "$text"
  sleep "$delay"
}

# Print a blank line
blank() {
  printf '\n'
  sleep 0.15
}

# ===== DEMO START =====

clear
sleep 1.0

# ---------- Setup: npx init ----------
type_command "npx aiki init my-app"

out "  ${TUI_GRAY}Creating project structure...${TUI_RESET}" 0.2
tui_spinner "Scaffolding files"
sleep 2
tui_spinner_stop
out "  ${TUI_GREEN}✓${TUI_RESET} Created ${TUI_WHITE}${TUI_BOLD}my-app/${TUI_RESET} with 13 skills configured"
out "  ${TUI_GREEN}✓${TUI_RESET} Claude, Codex, Gemini, Grok contexts ready"
blank
out "  ${TUI_DIM}cd my-app${TUI_RESET}" 0.3

sleep "$PHASE_PAUSE"

# ---------- Main: /project ----------
type_command "/project user authentication"

blank
out "${TUI_WHITE}${TUI_BOLD}  Starting project pipeline: user authentication${TUI_RESET}" 0.6
blank

# --- Phase 1: Requirements ---
tui_phase_header 1 "Requirements" "Claude"
tui_spinner "Analyzing requirements"
sleep 2
tui_spinner_stop
tui_file_appear "docs/requirements/auth.md"
out "      ${TUI_GREEN}✓${TUI_RESET} 5 user stories, 12 acceptance criteria" 0.3
blank
sleep 0.5

# --- Phase 2: API Design ---
tui_phase_header 2 "API Design" "Claude"
tui_spinner "Designing API endpoints"
sleep 2
tui_spinner_stop
tui_file_appear "docs/api/auth.yaml"
out "      ${TUI_GREEN}✓${TUI_RESET} 4 endpoints, JWT + refresh tokens" 0.3
blank
sleep 0.5

# --- Phase 3: Implementation ---
tui_phase_header 3 "Implementation" "Codex"
tui_spinner "Delegating to Codex (full-auto)"
sleep 3
tui_spinner_stop
tui_file_appear "src/app/login/page.tsx"
tui_file_appear "src/lib/api/auth.ts"
tui_file_appear "src/components/LoginForm.tsx"
out "      ${TUI_GREEN}✓${TUI_RESET} 3 files generated ${TUI_GRAY}(247 lines)${TUI_RESET}" 0.3
blank
sleep 0.5

# --- Phase 4: Testing ---
tui_phase_header 4 "Testing" "Codex"
tui_spinner "Generating and running tests"
sleep 2
tui_spinner_stop
tui_file_appear "tests/auth.spec.ts"
out "      ${TUI_GREEN}✓${TUI_RESET} 8 tests passed ${TUI_GRAY}(coverage: 94%)${TUI_RESET}" 0.3
blank
sleep 0.5

# --- Phase 5: Review ---
tui_phase_header 5 "Review" "Claude"
tui_spinner "Reviewing implementation"
sleep 2
tui_spinner_stop
out "      ${TUI_GREEN}✓${TUI_RESET} Acceptance criteria: ${TUI_GREEN}passed${TUI_RESET}" 0.2
out "      ${TUI_GREEN}✓${TUI_RESET} Security check:      ${TUI_GREEN}passed${TUI_RESET}" 0.2
out "      ${TUI_GREEN}✓${TUI_RESET} Test coverage:       ${TUI_GREEN}94%${TUI_RESET}" 0.2
blank
sleep 0.5

# --- Phase 6: Deploy ---
tui_phase_header 6 "Deploy" "Grok"
tui_spinner "Deploying to Vercel"
sleep 2
tui_spinner_stop
out "      ${TUI_GREEN}✓${TUI_RESET} ${AI_GEMINI}https://my-app.vercel.app${TUI_RESET}" 0.3
blank

sleep 0.6

# ---------- Summary ----------
tui_separator
out "${TUI_GREEN}${TUI_BOLD}  Pipeline complete!${TUI_RESET}" 0.3
blank
out "  ${TUI_WHITE}${TUI_BOLD}Time:${TUI_RESET}  ${TUI_BOLD}3m 12s${TUI_RESET}" 0.3

tui_summary_table \
    "Requirements:PASS:12s" \
    "Design:PASS:18s" \
    "Implementation:PASS:85s" \
    "Testing:PASS:42s" \
    "Review:PASS:15s" \
    "Deploy:PASS:20s"

blank

# Quality score gauge
tui_score_gauge 94

blank
out "  ${TUI_WHITE}${TUI_BOLD}Files:${TUI_RESET} ${TUI_BOLD}7 created${TUI_RESET}" 0.3
blank

tui_separator

sleep 1.0

# ---------- Cost comparison ----------
tui_cost_bars
blank

sleep 1.5

# ---------- End ----------
out "  ${TUI_GRAY}github.com/AI-Driven-School/aiki${TUI_RESET}" 0.3
out "  ${AI_CLAUDE}★ Star on GitHub${TUI_RESET}" 0.3
blank

sleep 3.0
