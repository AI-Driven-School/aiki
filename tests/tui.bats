#!/usr/bin/env bats

load helpers

setup() {
    export PATH="$BATS_TEST_DIRNAME/mocks:$PATH"
    export TEST_WORKSPACE
    TEST_WORKSPACE="$(mktemp -d)"
}

teardown() {
    if [ -n "${TEST_WORKSPACE:-}" ] && [ -d "$TEST_WORKSPACE" ]; then
        rm -rf "$TEST_WORKSPACE"
    fi
}

# ══════════════════════════════════════════════════════════════════════
# Syntax validation
# ══════════════════════════════════════════════════════════════════════

@test "tui.sh: valid bash syntax" {
    run bash -n "$PROJECT_ROOT/scripts/lib/tui.sh"
    [ "$status" -eq 0 ]
}

# ══════════════════════════════════════════════════════════════════════
# Load guard: sourcing twice should not error
# ══════════════════════════════════════════════════════════════════════

@test "tui.sh: can be sourced twice without error" {
    run bash -c "source '$PROJECT_ROOT/scripts/lib/tui.sh' && source '$PROJECT_ROOT/scripts/lib/tui.sh' && echo OK"
    [ "$status" -eq 0 ]
    [[ "$output" == *"OK"* ]]
}

# ══════════════════════════════════════════════════════════════════════
# TUI_AVAILABLE detection
# ══════════════════════════════════════════════════════════════════════

@test "tui.sh: TUI_AVAILABLE=false when not a terminal" {
    # Pipe to cat to make stdout not a terminal
    result=$(bash -c "source '$PROJECT_ROOT/scripts/lib/tui.sh' && echo \$TUI_AVAILABLE" | cat)
    [ "$result" = "false" ]
}

@test "tui.sh: TUI_AVAILABLE=false when NO_TUI=true" {
    run bash -c "export NO_TUI=true; source '$PROJECT_ROOT/scripts/lib/tui.sh'; echo \$TUI_AVAILABLE"
    [ "$status" -eq 0 ]
    [[ "$output" == *"false"* ]]
}

# ══════════════════════════════════════════════════════════════════════
# AI color mapping
# ══════════════════════════════════════════════════════════════════════

@test "tui.sh: _tui_ai_color returns different colors for each AI" {
    run bash -c "
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        c=\$(_tui_ai_color Claude)
        x=\$(_tui_ai_color Codex)
        g=\$(_tui_ai_color Gemini)
        k=\$(_tui_ai_color Grok)
        # All should be non-empty and distinct
        [ -n \"\$c\" ] && [ -n \"\$x\" ] && [ -n \"\$g\" ] && [ -n \"\$k\" ]
        [ \"\$c\" != \"\$x\" ] && [ \"\$x\" != \"\$g\" ] && [ \"\$g\" != \"\$k\" ]
        echo PASS
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"PASS"* ]]
}

@test "tui.sh: _tui_ai_color handles unknown AI" {
    run bash -c "source '$PROJECT_ROOT/scripts/lib/tui.sh'; _tui_ai_color Unknown"
    [ "$status" -eq 0 ]
    # Should return something (white fallback)
    [ -n "$output" ]
}

# ══════════════════════════════════════════════════════════════════════
# tui_banner
# ══════════════════════════════════════════════════════════════════════

@test "tui_banner: outputs project name when TUI available" {
    run bash -c "
        export TUI_AVAILABLE=true
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        TUI_AVAILABLE=true
        tui_banner 'Test Feature'
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"aiki Pipeline"* ]]
    [[ "$output" == *"Test Feature"* ]]
    [[ "$output" == *"Claude + Codex + Gemini + Grok"* ]]
}

@test "tui_banner: fallback when TUI not available" {
    run bash -c "
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        TUI_AVAILABLE=false
        tui_banner 'Test Feature'
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"Pipeline"* ]]
    [[ "$output" == *"Test Feature"* ]]
}

@test "tui_banner: handles Japanese characters" {
    run bash -c "
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        TUI_AVAILABLE=false
        tui_banner 'ECサイトのカート機能'
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"ECサイトのカート機能"* ]]
}

# ══════════════════════════════════════════════════════════════════════
# tui_phase_header
# ══════════════════════════════════════════════════════════════════════

@test "tui_phase_header: shows phase number and AI name" {
    run bash -c "
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        TUI_AVAILABLE=false
        tui_phase_header 3 'Implementation' 'Codex'
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"3/6"* ]]
    [[ "$output" == *"Implementation"* ]]
    [[ "$output" == *"Codex"* ]]
}

@test "tui_phase_header: accepts custom total" {
    run bash -c "
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        TUI_AVAILABLE=false
        tui_phase_header 2 'Design' 'Claude' 5
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"2/5"* ]]
    [[ "$output" == *"Claude"* ]]
}

@test "tui_phase_header: Codex badge with TUI enabled" {
    run bash -c "
        export TUI_AVAILABLE=true
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        TUI_AVAILABLE=true
        tui_phase_header 3 'Implementation' 'Codex' | cat
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *'$0'* ]]
}

@test "tui_phase_header: no badge for Claude" {
    run bash -c "
        export TUI_AVAILABLE=true
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        TUI_AVAILABLE=true
        tui_phase_header 1 'Requirements' 'Claude' | cat
    "
    [ "$status" -eq 0 ]
    [[ "$output" != *'$0'* ]]
}

# ══════════════════════════════════════════════════════════════════════
# tui_spinner / tui_spinner_stop
# ══════════════════════════════════════════════════════════════════════

@test "tui_spinner: fallback outputs message when TUI disabled" {
    run bash -c "
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        TUI_AVAILABLE=false
        tui_spinner 'Processing...'
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"Processing..."* ]]
}

@test "tui_spinner_stop: outputs result message" {
    run bash -c "
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        TUI_AVAILABLE=false
        _TUI_SPINNER_PID=''
        tui_spinner_stop 'Done successfully'
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"Done successfully"* ]]
}

@test "tui_spinner: start and stop cycle completes cleanly" {
    run bash -c "
        export TUI_AVAILABLE=true
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        TUI_AVAILABLE=true
        tui_spinner 'Working...'
        sleep 0.3
        tui_spinner_stop 'Completed'
        echo EXIT_OK
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"EXIT_OK"* ]]
}

@test "tui_spinner_stop: safe to call with no active spinner" {
    run bash -c "
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        _TUI_SPINNER_PID=''
        tui_spinner_stop 'No spinner active'
        echo SAFE
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"SAFE"* ]]
}

@test "tui_spinner_stop: safe to call with empty result" {
    run bash -c "
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        _TUI_SPINNER_PID=''
        tui_spinner_stop
        echo SAFE_EMPTY
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"SAFE_EMPTY"* ]]
}

# ══════════════════════════════════════════════════════════════════════
# tui_file_appear
# ══════════════════════════════════════════════════════════════════════

@test "tui_file_appear: shows file path" {
    run bash -c "
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        TUI_AVAILABLE=false
        tui_file_appear 'src/app/login/page.tsx'
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"src/app/login/page.tsx"* ]]
}

@test "tui_file_appear: shows custom status" {
    run bash -c "
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        TUI_AVAILABLE=false
        tui_file_appear 'test.ts' 'created'
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"test.ts"* ]]
    [[ "$output" == *"created"* ]]
}

# ══════════════════════════════════════════════════════════════════════
# tui_typing
# ══════════════════════════════════════════════════════════════════════

@test "tui_typing: outputs full text" {
    run bash -c "
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        TUI_AVAILABLE=false
        tui_typing 'hello world'
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"hello world"* ]]
}

@test "tui_typing: handles Japanese text" {
    run bash -c "
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        TUI_AVAILABLE=false
        tui_typing 'カート機能'
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"カート機能"* ]]
}

# ══════════════════════════════════════════════════════════════════════
# tui_score_gauge
# ══════════════════════════════════════════════════════════════════════

@test "tui_score_gauge: fallback shows score" {
    run bash -c "
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        TUI_AVAILABLE=false
        tui_score_gauge 96
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"96"* ]]
    [[ "$output" == *"100"* ]]
}

@test "tui_score_gauge: TUI mode shows bar characters" {
    run bash -c "
        export TUI_AVAILABLE=true
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        TUI_AVAILABLE=true
        tui_score_gauge 80 | cat
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"80"* ]]
    # Should contain filled block chars
    [[ "$output" == *"█"* ]]
}

@test "tui_score_gauge: score 0 shows all empty" {
    run bash -c "
        export TUI_AVAILABLE=true
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        TUI_AVAILABLE=true
        tui_score_gauge 0 | cat
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"0/100"* ]]
    [[ "$output" == *"░"* ]]
}

@test "tui_score_gauge: score 100 shows all filled" {
    run bash -c "
        export TUI_AVAILABLE=true
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        TUI_AVAILABLE=true
        tui_score_gauge 100 | cat
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"100/100"* ]]
    [[ "$output" == *"█"* ]]
    # Should NOT contain empty blocks
    [[ "$output" != *"░"* ]]
}

@test "tui_score_gauge: custom max" {
    run bash -c "
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        TUI_AVAILABLE=false
        tui_score_gauge 45 50
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"45/50"* ]]
}

# ══════════════════════════════════════════════════════════════════════
# tui_cost_bars
# ══════════════════════════════════════════════════════════════════════

@test "tui_cost_bars: fallback shows all three costs" {
    run bash -c "
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        TUI_AVAILABLE=false
        tui_cost_bars
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"Devin"* ]]
    [[ "$output" == *"500"* ]]
    [[ "$output" == *"Single AI"* ]]
    [[ "$output" == *"0.85"* ]]
    [[ "$output" == *"aiki"* ]]
    [[ "$output" == *"0.21"* ]]
}

@test "tui_cost_bars: TUI mode shows bar characters" {
    run bash -c "
        export TUI_AVAILABLE=true
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        TUI_AVAILABLE=true
        tui_cost_bars | cat
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"▓"* ]]
    [[ "$output" == *"Devin"* ]]
    [[ "$output" == *"aiki"* ]]
    [[ "$output" == *"75% saved"* ]]
}

# ══════════════════════════════════════════════════════════════════════
# tui_separator
# ══════════════════════════════════════════════════════════════════════

@test "tui_separator: fallback outputs dashes" {
    run bash -c "
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        TUI_AVAILABLE=false
        tui_separator
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"────"* ]]
}

@test "tui_separator: TUI mode outputs bold line" {
    run bash -c "
        export TUI_AVAILABLE=true
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        TUI_AVAILABLE=true
        tui_separator | cat
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"━━━"* ]]
}

# ══════════════════════════════════════════════════════════════════════
# tui_summary_table
# ══════════════════════════════════════════════════════════════════════

@test "tui_summary_table: fallback shows entries" {
    run bash -c "
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        TUI_AVAILABLE=false
        tui_summary_table 'Requirements:PASS:2s' 'Design:FAIL:5s'
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"Requirements:PASS:2s"* ]]
    [[ "$output" == *"Design:FAIL:5s"* ]]
}

@test "tui_summary_table: TUI mode shows aligned table" {
    run bash -c "
        export TUI_AVAILABLE=true
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        TUI_AVAILABLE=true
        tui_summary_table 'Requirements:PASS:2s' 'Design:FAIL:5s' 'Test:SKIP:0s' | cat
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"Phase"* ]]
    [[ "$output" == *"Result"* ]]
    [[ "$output" == *"Duration"* ]]
    [[ "$output" == *"Requirements"* ]]
    [[ "$output" == *"PASS"* ]]
    [[ "$output" == *"FAIL"* ]]
    [[ "$output" == *"SKIP"* ]]
}

# ══════════════════════════════════════════════════════════════════════
# tui_success / tui_error / tui_info
# ══════════════════════════════════════════════════════════════════════

@test "tui_success: shows checkmark and message" {
    run bash -c "
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        tui_success 'Operation completed' | cat
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"✓"* ]]
    [[ "$output" == *"Operation completed"* ]]
}

@test "tui_error: shows cross and message" {
    run bash -c "
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        tui_error 'Something failed' | cat
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"✗"* ]]
    [[ "$output" == *"Something failed"* ]]
}

@test "tui_info: shows arrow and message" {
    run bash -c "
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        tui_info 'Processing step' | cat
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"→"* ]]
    [[ "$output" == *"Processing step"* ]]
}

# ══════════════════════════════════════════════════════════════════════
# Edge cases and robustness
# ══════════════════════════════════════════════════════════════════════

@test "tui.sh: all functions exist after sourcing" {
    run bash -c "
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        type tui_banner >/dev/null 2>&1 && \
        type tui_phase_header >/dev/null 2>&1 && \
        type tui_spinner >/dev/null 2>&1 && \
        type tui_spinner_stop >/dev/null 2>&1 && \
        type tui_file_appear >/dev/null 2>&1 && \
        type tui_typing >/dev/null 2>&1 && \
        type tui_score_gauge >/dev/null 2>&1 && \
        type tui_cost_bars >/dev/null 2>&1 && \
        type tui_separator >/dev/null 2>&1 && \
        type tui_summary_table >/dev/null 2>&1 && \
        type tui_success >/dev/null 2>&1 && \
        type tui_error >/dev/null 2>&1 && \
        type tui_info >/dev/null 2>&1 && \
        echo ALL_FUNCTIONS_EXIST
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"ALL_FUNCTIONS_EXIST"* ]]
}

@test "tui.sh: variables exported correctly" {
    run bash -c "
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        [ -n \"\$AI_CLAUDE\" ] && \
        [ -n \"\$AI_CODEX\" ] && \
        [ -n \"\$AI_GEMINI\" ] && \
        [ -n \"\$AI_GROK\" ] && \
        [ -n \"\$TUI_BOLD\" ] && \
        [ -n \"\$TUI_RESET\" ] && \
        echo ALL_VARS_SET
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"ALL_VARS_SET"* ]]
}

@test "tui.sh: empty string arguments don't crash" {
    run bash -c "
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        TUI_AVAILABLE=false
        tui_banner ''
        tui_phase_header '' '' ''
        tui_file_appear ''
        tui_typing ''
        tui_score_gauge 0
        tui_separator
        echo NO_CRASH
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"NO_CRASH"* ]]
}

@test "tui.sh: special characters in arguments don't break output" {
    run bash -c "
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        TUI_AVAILABLE=false
        tui_banner 'Feature with \"quotes\" & <special> chars'
        tui_file_appear 'src/path/with spaces/file.ts'
        echo SPECIAL_OK
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"SPECIAL_OK"* ]]
}
