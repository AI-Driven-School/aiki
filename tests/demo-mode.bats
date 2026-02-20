#!/usr/bin/env bats

load helpers

# ══════════════════════════════════════════════════════════════════════
# Syntax validation
# ══════════════════════════════════════════════════════════════════════

@test "demo-mode.sh: valid bash syntax" {
    run bash -n "$PROJECT_ROOT/scripts/demo-mode.sh"
    [ "$status" -eq 0 ]
}

@test "simulate-demo.sh: valid bash syntax" {
    run bash -n "$PROJECT_ROOT/landing/simulate-demo.sh"
    [ "$status" -eq 0 ]
}

# ══════════════════════════════════════════════════════════════════════
# TUI library integration
# ══════════════════════════════════════════════════════════════════════

@test "demo-mode.sh: sources tui.sh successfully" {
    run bash -c "
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        type tui_banner >/dev/null 2>&1 && echo TUI_LOADED
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"TUI_LOADED"* ]]
}

@test "simulate-demo.sh: sources tui.sh via relative path" {
    # Verify the SCRIPT_DIR computation finds tui.sh
    run bash -c "
        SCRIPT_DIR='$PROJECT_ROOT/landing'
        # shellcheck source=../scripts/lib/tui.sh
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        type tui_phase_header >/dev/null 2>&1 && echo TUI_AVAILABLE
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"TUI_AVAILABLE"* ]]
}

# ══════════════════════════════════════════════════════════════════════
# Demo mode content validation
# ══════════════════════════════════════════════════════════════════════

@test "demo-mode.sh: contains all 6 phases" {
    local content
    content=$(cat "$PROJECT_ROOT/scripts/demo-mode.sh")
    [[ "$content" == *"Phase 1"* ]] || [[ "$content" == *"tui_phase_header 1"* ]]
    [[ "$content" == *"tui_phase_header 2"* ]]
    [[ "$content" == *"tui_phase_header 3"* ]]
    [[ "$content" == *"tui_phase_header 4"* ]]
    [[ "$content" == *"tui_phase_header 5"* ]]
    [[ "$content" == *"tui_phase_header 6"* ]]
}

@test "demo-mode.sh: includes all 4 AIs" {
    local content
    content=$(cat "$PROJECT_ROOT/scripts/demo-mode.sh")
    [[ "$content" == *"Claude"* ]]
    [[ "$content" == *"Codex"* ]]
    [[ "$content" == *"Grok"* ]]
}

@test "demo-mode.sh: includes score gauge" {
    local content
    content=$(cat "$PROJECT_ROOT/scripts/demo-mode.sh")
    [[ "$content" == *"tui_score_gauge"* ]]
}

@test "demo-mode.sh: includes cost bars" {
    local content
    content=$(cat "$PROJECT_ROOT/scripts/demo-mode.sh")
    [[ "$content" == *"tui_cost_bars"* ]]
}

@test "demo-mode.sh: includes file cascade" {
    local content
    content=$(cat "$PROJECT_ROOT/scripts/demo-mode.sh")
    [[ "$content" == *"tui_file_appear"* ]]
}

@test "demo-mode.sh: includes summary table" {
    local content
    content=$(cat "$PROJECT_ROOT/scripts/demo-mode.sh")
    [[ "$content" == *"tui_summary_table"* ]]
}

@test "demo-mode.sh: includes GitHub CTA" {
    local content
    content=$(cat "$PROJECT_ROOT/scripts/demo-mode.sh")
    [[ "$content" == *"github.com"* ]] || [[ "$content" == *"GitHub"* ]]
}

@test "demo-mode.sh: accepts custom feature name" {
    # Verify the script uses $1 as feature name
    local content
    content=$(cat "$PROJECT_ROOT/scripts/demo-mode.sh")
    [[ "$content" == *'FEATURE="${1:-'* ]]
}

# ══════════════════════════════════════════════════════════════════════
# simulate-demo.sh content validation (TUI unified)
# ══════════════════════════════════════════════════════════════════════

@test "simulate-demo.sh: uses TUI library functions" {
    local content
    content=$(cat "$PROJECT_ROOT/landing/simulate-demo.sh")
    [[ "$content" == *"tui_phase_header"* ]]
    [[ "$content" == *"tui_spinner"* ]]
    [[ "$content" == *"tui_spinner_stop"* ]]
    [[ "$content" == *"tui_file_appear"* ]]
}

@test "simulate-demo.sh: uses tui_cost_bars instead of inline bars" {
    local content
    content=$(cat "$PROJECT_ROOT/landing/simulate-demo.sh")
    [[ "$content" == *"tui_cost_bars"* ]]
}

@test "simulate-demo.sh: uses tui_score_gauge" {
    local content
    content=$(cat "$PROJECT_ROOT/landing/simulate-demo.sh")
    [[ "$content" == *"tui_score_gauge"* ]]
}

@test "simulate-demo.sh: includes Grok (4-AI)" {
    local content
    content=$(cat "$PROJECT_ROOT/landing/simulate-demo.sh")
    [[ "$content" == *"Grok"* ]]
}

@test "simulate-demo.sh: uses tui_summary_table" {
    local content
    content=$(cat "$PROJECT_ROOT/landing/simulate-demo.sh")
    [[ "$content" == *"tui_summary_table"* ]]
}

# ══════════════════════════════════════════════════════════════════════
# package.json scripts
# ══════════════════════════════════════════════════════════════════════

@test "package.json: has demo script" {
    run bash -c "python3 -c \"
import json
pkg = json.load(open('$PROJECT_ROOT/package.json'))
assert 'demo' in pkg.get('scripts', {}), 'demo script missing'
print('DEMO_SCRIPT_EXISTS')
\""
    [ "$status" -eq 0 ]
    [[ "$output" == *"DEMO_SCRIPT_EXISTS"* ]]
}

@test "package.json: demo script references demo-mode.sh" {
    run bash -c "python3 -c \"
import json
pkg = json.load(open('$PROJECT_ROOT/package.json'))
demo = pkg['scripts']['demo']
assert 'demo-mode.sh' in demo, f'demo script does not reference demo-mode.sh: {demo}'
print('DEMO_REFS_OK')
\""
    [ "$status" -eq 0 ]
    [[ "$output" == *"DEMO_REFS_OK"* ]]
}

@test "package.json: has record script" {
    run bash -c "python3 -c \"
import json
pkg = json.load(open('$PROJECT_ROOT/package.json'))
assert 'record' in pkg.get('scripts', {}), 'record script missing'
print('RECORD_SCRIPT_EXISTS')
\""
    [ "$status" -eq 0 ]
    [[ "$output" == *"RECORD_SCRIPT_EXISTS"* ]]
}

@test "package.json: valid JSON" {
    run python3 -m json.tool "$PROJECT_ROOT/package.json"
    [ "$status" -eq 0 ]
}
