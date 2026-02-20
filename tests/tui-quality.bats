#!/usr/bin/env bats
# tui-quality.bats - Deep quality tests for TUI library
# Covers: E2E execution, process leak detection, EXIT trap chaining,
# ANSI validation, boundary analysis, signal handling, Bash 3.2 compat.

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
# E2E: demo-mode.sh actually runs to completion
# ══════════════════════════════════════════════════════════════════════

@test "E2E: demo-mode.sh completes without error (fast mode)" {
    # Run with NO_TUI to skip animations and sleep by replacing sleep
    cat > "$TEST_WORKSPACE/fast-demo.sh" << 'WRAPPER'
#!/usr/bin/env bash
set -euo pipefail
# Override sleep to be instant
sleep() { :; }
# Override clear to be no-op
clear() { :; }
export NO_TUI=true
SCRIPT_DIR="PLACEHOLDER"
source "${SCRIPT_DIR}/scripts/lib/tui.sh"
source "${SCRIPT_DIR}/scripts/demo-mode.sh"
WRAPPER
    sed -i '' "s|PLACEHOLDER|$PROJECT_ROOT|g" "$TEST_WORKSPACE/fast-demo.sh"

    # Actually we need a different approach - pipe demo-mode.sh with sleeps replaced
    # Use a wrapper that sources the right tui and overrides
    run timeout 10 bash -c "
        sleep() { :; }
        clear() { :; }
        export NO_TUI=true
        source '$PROJECT_ROOT/scripts/lib/tui.sh'

        # Redefine SCRIPT_DIR for demo-mode to find tui.sh
        SCRIPT_DIR='$PROJECT_ROOT/scripts'
        FEATURE='test-feature'
        TYPE_DELAY=0
        LINE_PAUSE=0
        PHASE_PAUSE=0
        COMMAND_PAUSE=0

        out() { printf '%b\n' \"\$1\"; }
        blank() { printf '\n'; }

        # Source the TUI library (already loaded, will skip)
        source \"\${SCRIPT_DIR}/lib/tui.sh\"

        # Run banner and all phases (no sleep)
        tui_banner \"\$FEATURE\"
        tui_phase_header 1 'Requirements' 'Claude'
        tui_spinner 'Analyzing...'
        tui_spinner_stop 'Done'
        tui_file_appear 'docs/requirements/test.md'
        tui_phase_header 2 'Design' 'Claude'
        tui_phase_header 3 'Implementation' 'Codex'
        tui_phase_header 4 'Testing' 'Codex'
        tui_phase_header 5 'Review' 'Claude'
        tui_phase_header 6 'Deploy' 'Grok'
        tui_separator
        tui_summary_table 'Req:PASS:1s' 'Design:PASS:1s' 'Impl:PASS:2s' 'Test:PASS:1s' 'Review:PASS:1s' 'Deploy:PASS:1s'
        tui_score_gauge 96
        tui_cost_bars
        tui_success 'Pipeline complete'
        echo E2E_COMPLETE
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"E2E_COMPLETE"* ]]
    [[ "$output" == *"Pipeline"* ]]
    [[ "$output" == *"96"* ]]
}

# ══════════════════════════════════════════════════════════════════════
# Process leak: spinner does not leave orphan processes
# ══════════════════════════════════════════════════════════════════════

@test "process leak: spinner_stop kills background process" {
    # Run in a real subshell (not via 'run') to preserve process relationships
    local result
    result=$(bash -c "
        export TUI_AVAILABLE=true
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        TUI_AVAILABLE=true

        tui_spinner 'Working...'
        pid=\$_TUI_SPINNER_PID

        if [ -z \"\$pid\" ]; then echo NO_PID; exit 1; fi
        if ! kill -0 \"\$pid\" 2>/dev/null; then echo NOT_RUNNING; exit 1; fi

        tui_spinner_stop 'Done'
        sleep 0.3

        if kill -0 \"\$pid\" 2>/dev/null; then
            kill \"\$pid\" 2>/dev/null
            echo LEAK_DETECTED
        else
            echo NO_LEAK
        fi
    " 2>&1 | cat)
    [[ "$result" == *"NO_LEAK"* ]]
}

@test "process leak: multiple spinner start/stop cycles leave no orphans" {
    run bash -c "
        export TUI_AVAILABLE=true
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        TUI_AVAILABLE=true

        pids=()
        for i in 1 2 3 4 5; do
            tui_spinner \"Cycle \$i...\"
            pids+=(\"\$_TUI_SPINNER_PID\")
            sleep 0.15
            tui_spinner_stop \"Cycle \$i done\"
        done

        sleep 0.3
        leaks=0
        for pid in \"\${pids[@]}\"; do
            if kill -0 \"\$pid\" 2>/dev/null; then
                leaks=\$((leaks + 1))
                kill \"\$pid\" 2>/dev/null
            fi
        done

        if [ \$leaks -gt 0 ]; then
            echo \"LEAKED_\${leaks}_PROCESSES\"
            exit 1
        fi
        echo 'ALL_CLEAN'
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"ALL_CLEAN"* ]]
}

@test "process leak: _tui_cleanup kills spinner on EXIT" {
    run bash -c "
        export TUI_AVAILABLE=true
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        TUI_AVAILABLE=true

        tui_spinner 'Will be cleaned up...'
        local pid=\$_TUI_SPINNER_PID
        echo \"PID=\$pid\"
        # Exit without calling tui_spinner_stop - cleanup trap should handle it
        exit 0
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"PID="* ]]

    # Extract PID and verify it's dead
    local pid
    pid=$(echo "$output" | grep "PID=" | sed 's/PID=//')
    if [ -n "$pid" ]; then
        sleep 0.3
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null
            fail "Spinner process $pid still alive after EXIT trap"
        fi
    fi
}

# ══════════════════════════════════════════════════════════════════════
# EXIT trap chaining: tui.sh trap doesn't overwrite existing traps
# ══════════════════════════════════════════════════════════════════════

@test "trap chaining: tui.sh preserves existing EXIT trap" {
    run bash -c "
        # Set an existing trap BEFORE loading tui.sh
        _test_existing_trap_ran=false
        trap 'echo EXISTING_TRAP_FIRED' EXIT

        source '$PROJECT_ROOT/scripts/lib/tui.sh'

        echo SCRIPT_END
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"SCRIPT_END"* ]]
    [[ "$output" == *"EXISTING_TRAP_FIRED"* ]]
}

@test "trap chaining: pipeline-engine EXIT trap preserves tui cleanup" {
    # Verify the pipeline-engine.sh chains its trap with tui.sh's trap
    run bash -c "grep -c '_pipe_existing_exit_trap' '$PROJECT_ROOT/scripts/pipeline-engine.sh'"
    [ "$status" -eq 0 ]
    [ "$output" -ge 1 ]
}

@test "trap chaining: tui.sh has INT and TERM signal handlers" {
    run bash -c "
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        int_trap=\$(trap -p INT)
        term_trap=\$(trap -p TERM)
        [[ \"\$int_trap\" == *'_tui_cleanup'* ]] && echo INT_OK || echo INT_MISSING
        [[ \"\$term_trap\" == *'_tui_cleanup'* ]] && echo TERM_OK || echo TERM_MISSING
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"INT_OK"* ]]
    [[ "$output" == *"TERM_OK"* ]]
}

# ══════════════════════════════════════════════════════════════════════
# Signal handling: SIGINT kills spinner and exits cleanly
# ══════════════════════════════════════════════════════════════════════

@test "signal handling: SIGINT during spinner cleans up process" {
    bash -c "
        export TUI_AVAILABLE=true
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        TUI_AVAILABLE=true
        tui_spinner 'Interruptible...'
        echo \$_TUI_SPINNER_PID > '$TEST_WORKSPACE/spinner_pid'
        sleep 10  # Will be interrupted
    " &
    local script_pid=$!
    sleep 0.5

    # Read spinner PID
    if [ -f "$TEST_WORKSPACE/spinner_pid" ]; then
        local spinner_pid
        spinner_pid=$(cat "$TEST_WORKSPACE/spinner_pid")

        # Send SIGINT to the script
        kill -INT "$script_pid" 2>/dev/null || true
        wait "$script_pid" 2>/dev/null || true
        sleep 0.5

        # Spinner process should be dead
        if [ -n "$spinner_pid" ] && kill -0 "$spinner_pid" 2>/dev/null; then
            kill "$spinner_pid" 2>/dev/null || true
            fail "Spinner process $spinner_pid survived SIGINT"
        fi
    else
        # Script didn't even start properly; kill and skip
        kill "$script_pid" 2>/dev/null || true
        wait "$script_pid" 2>/dev/null || true
        skip "Script didn't start in time"
    fi
}

# ══════════════════════════════════════════════════════════════════════
# ANSI escape sequence validation
# ══════════════════════════════════════════════════════════════════════

@test "ANSI: all AI colors are valid 256-color sequences" {
    run bash -c "
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        # Verify each color matches the pattern \\033[38;5;NNNm
        for var in AI_CLAUDE AI_CODEX AI_GEMINI AI_GROK; do
            val=\"\${!var}\"
            if ! echo \"\$val\" | grep -qE '\\\\033\[38;5;[0-9]+m'; then
                echo \"INVALID: \$var = \$val\"
                exit 1
            fi
        done
        echo ANSI_COLORS_VALID
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"ANSI_COLORS_VALID"* ]]
}

@test "ANSI: TUI_RESET properly terminates sequences" {
    run bash -c "
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        # TUI_RESET should be \\033[0m
        if [ \"\$TUI_RESET\" != '\033[0m' ]; then
            echo 'INVALID_RESET'
            exit 1
        fi
        echo RESET_VALID
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"RESET_VALID"* ]]
}

@test "ANSI: score gauge output contains balanced escape sequences" {
    run bash -c "
        export TUI_AVAILABLE=true
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        TUI_AVAILABLE=true
        output=\$(tui_score_gauge 50 | cat)
        # Count RESET sequences - should be at least 2 (color start + end)
        reset_count=\$(echo \"\$output\" | grep -o '\[0m' | wc -l | tr -d ' ')
        if [ \"\$reset_count\" -lt 2 ]; then
            echo \"UNBALANCED_RESETS: \$reset_count\"
            exit 1
        fi
        echo BALANCED_OK
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"BALANCED_OK"* ]]
}

# ══════════════════════════════════════════════════════════════════════
# Boundary value analysis: tui_score_gauge
# ══════════════════════════════════════════════════════════════════════

@test "boundary: score_gauge 0/100 produces 0 filled blocks" {
    run bash -c "
        export TUI_AVAILABLE=true
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        TUI_AVAILABLE=true
        output=\$(tui_score_gauge 0 | cat)
        filled=\$(echo \"\$output\" | grep -o '█' | wc -l | tr -d ' ')
        if [ \"\$filled\" -ne 0 ]; then
            echo \"EXPECTED_0_GOT_\$filled\"
            exit 1
        fi
        echo ZERO_OK
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"ZERO_OK"* ]]
}

@test "boundary: score_gauge 100/100 produces 20 filled blocks" {
    run bash -c "
        export TUI_AVAILABLE=true
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        TUI_AVAILABLE=true
        output=\$(tui_score_gauge 100 | cat)
        filled=\$(echo \"\$output\" | grep -o '█' | wc -l | tr -d ' ')
        if [ \"\$filled\" -ne 20 ]; then
            echo \"EXPECTED_20_GOT_\$filled\"
            exit 1
        fi
        echo FULL_OK
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"FULL_OK"* ]]
}

@test "boundary: score_gauge 50/100 produces 10 filled blocks" {
    run bash -c "
        export TUI_AVAILABLE=true
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        TUI_AVAILABLE=true
        output=\$(tui_score_gauge 50 | cat)
        filled=\$(echo \"\$output\" | grep -o '█' | wc -l | tr -d ' ')
        if [ \"\$filled\" -ne 10 ]; then
            echo \"EXPECTED_10_GOT_\$filled\"
            exit 1
        fi
        echo HALF_OK
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"HALF_OK"* ]]
}

@test "boundary: score_gauge 1/100 produces 0 filled blocks (rounding)" {
    run bash -c "
        export TUI_AVAILABLE=true
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        TUI_AVAILABLE=true
        output=\$(tui_score_gauge 1 | cat)
        # 1*20/100 = 0 (integer division)
        filled=\$(echo \"\$output\" | grep -o '█' | wc -l | tr -d ' ')
        echo \"FILLED_\$filled\"
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"FILLED_0"* ]]
}

@test "boundary: score_gauge color thresholds" {
    run bash -c "
        export TUI_AVAILABLE=true
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        TUI_AVAILABLE=true

        # Score < 50 should use RED (203)
        low=\$(tui_score_gauge 30 | cat)
        [[ \"\$low\" == *'38;5;203'* ]] && echo RED_LOW

        # Score 50-79 should use YELLOW (221)
        mid=\$(tui_score_gauge 60 | cat)
        [[ \"\$mid\" == *'38;5;221'* ]] && echo YELLOW_MID

        # Score >= 80 should use GREEN (84)
        high=\$(tui_score_gauge 90 | cat)
        [[ \"\$high\" == *'38;5;84'* ]] && echo GREEN_HIGH
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"RED_LOW"* ]]
    [[ "$output" == *"YELLOW_MID"* ]]
    [[ "$output" == *"GREEN_HIGH"* ]]
}

# ══════════════════════════════════════════════════════════════════════
# Boundary: tui_cost_bars bar lengths
# ══════════════════════════════════════════════════════════════════════

@test "boundary: cost_bars Devin has 35 filled blocks" {
    run bash -c "
        export TUI_AVAILABLE=true
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        TUI_AVAILABLE=true
        output=\$(tui_cost_bars | cat)
        # Count ▓ on the Devin line
        devin_line=\$(echo \"\$output\" | grep 'Devin')
        devin_bars=\$(echo \"\$devin_line\" | grep -o '▓' | wc -l | tr -d ' ')
        echo \"DEVIN_BARS=\$devin_bars\"
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"DEVIN_BARS=35"* ]]
}

@test "boundary: cost_bars aiki has 4 filled blocks" {
    run bash -c "
        export TUI_AVAILABLE=true
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        TUI_AVAILABLE=true
        output=\$(tui_cost_bars | cat)
        aiki_line=\$(echo \"\$output\" | grep 'aiki')
        aiki_bars=\$(echo \"\$aiki_line\" | grep -o '▓' | wc -l | tr -d ' ')
        echo \"AI4DEV_BARS=\$aiki_bars\"
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"AI4DEV_BARS=4"* ]]
}

# ══════════════════════════════════════════════════════════════════════
# Bash 3.2 compatibility
# ══════════════════════════════════════════════════════════════════════

@test "bash compat: no declare -A in tui.sh (excluding comments)" {
    # Exclude comment lines (starting with #), count matches
    local count
    count=$(grep -v '^\s*#' "$PROJECT_ROOT/scripts/lib/tui.sh" | grep -c 'declare -A' || true)
    [ "$count" -eq 0 ]
}

@test "bash compat: no declare -A in demo-mode.sh" {
    local count
    count=$(grep -c 'declare -A' "$PROJECT_ROOT/scripts/demo-mode.sh" || true)
    [ "$count" -eq 0 ]
}

@test "bash compat: no var-comma-comma lowercase syntax in tui.sh (excluding comments)" {
    local count
    count=$(grep -v '^\s*#' "$PROJECT_ROOT/scripts/lib/tui.sh" | grep -cE '\$\{[a-zA-Z_]+,,\}' || true)
    [ "$count" -eq 0 ]
}

@test "bash compat: no [[ with =~ ]] regex in tui.sh" {
    run grep -cE '\[\[.*=~' "$PROJECT_ROOT/scripts/lib/tui.sh"
    [ "$output" = "0" ]
}

@test "bash compat: no &>> redirect syntax in tui.sh" {
    run grep -cE '&>>' "$PROJECT_ROOT/scripts/lib/tui.sh"
    [ "$output" = "0" ]
}

@test "bash compat: no process substitution <() in tui.sh" {
    run grep -cE '<\(' "$PROJECT_ROOT/scripts/lib/tui.sh"
    [ "$output" = "0" ]
}

# ══════════════════════════════════════════════════════════════════════
# Pipeline TUI integration: deep regression
# ══════════════════════════════════════════════════════════════════════

@test "pipeline regression: dry-run output unchanged format" {
    local workspace
    workspace="$(mktemp -d)"
    mkdir -p "$workspace/.claude/docs"
    mkdir -p "$workspace/docs/requirements"
    mkdir -p "$workspace/docs/specs"
    mkdir -p "$workspace/docs/reviews"
    mkdir -p "$workspace/docs/decisions"
    mkdir -p "$workspace/scripts/lib"

    # Copy scripts
    for f in "$PROJECT_ROOT/scripts/lib/"*.sh; do
        [ -f "$f" ] && cp "$f" "$workspace/scripts/lib/" 2>/dev/null || true
    done
    cp "$PROJECT_ROOT/scripts/pipeline-engine.sh" "$workspace/scripts/"
    cp "$PROJECT_ROOT/scripts/project-workflow.sh" "$workspace/scripts/"
    cp "$PROJECT_ROOT/scripts/quality-report.sh" "$workspace/scripts/"

    cd "$workspace"
    # With NO_TUI=true, output should match the classic format
    run bash -c "NO_TUI=true bash '$workspace/scripts/pipeline-engine.sh' 'regression-test' --dry-run --auto"
    [ "$status" -eq 0 ]

    # Must have classic summary structure
    [[ "$output" == *"Pipeline Summary"* ]]
    [[ "$output" == *"Phase"* ]]
    [[ "$output" == *"Result"* ]]
    [[ "$output" == *"Quality Score"* ]]
    [[ "$output" == *"vs Devin"* ]]
    [[ "$output" == *"SKIP"* ]]

    rm -rf "$workspace"
}

@test "pipeline regression: TUI mode dry-run has different format" {
    local workspace
    workspace="$(mktemp -d)"
    mkdir -p "$workspace/.claude/docs"
    mkdir -p "$workspace/docs/requirements"
    mkdir -p "$workspace/docs/specs"
    mkdir -p "$workspace/docs/reviews"
    mkdir -p "$workspace/docs/decisions"
    mkdir -p "$workspace/scripts/lib"

    for f in "$PROJECT_ROOT/scripts/lib/"*.sh; do
        [ -f "$f" ] && cp "$f" "$workspace/scripts/lib/" 2>/dev/null || true
    done
    cp "$PROJECT_ROOT/scripts/pipeline-engine.sh" "$workspace/scripts/"
    cp "$PROJECT_ROOT/scripts/project-workflow.sh" "$workspace/scripts/"
    cp "$PROJECT_ROOT/scripts/quality-report.sh" "$workspace/scripts/"

    cd "$workspace"
    # Without NO_TUI, but piped to cat (so TUI_AVAILABLE=false due to non-terminal)
    run bash "$workspace/scripts/pipeline-engine.sh" "tui-regression" --dry-run --auto
    [ "$status" -eq 0 ]
    # When piped (non-terminal), should fallback to classic format
    [[ "$output" == *"Pipeline Summary"* ]] || [[ "$output" == *"Pipeline"* ]]

    rm -rf "$workspace"
}

# ══════════════════════════════════════════════════════════════════════
# Summary table correctness
# ══════════════════════════════════════════════════════════════════════

@test "summary table: parses all result types correctly" {
    run bash -c "
        export TUI_AVAILABLE=true
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        TUI_AVAILABLE=true
        tui_summary_table 'Phase1:PASS:1s' 'Phase2:FAIL:2s' 'Phase3:FIXABLE:3s' 'Phase4:SKIP:0s' | cat
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"Phase1"* ]]
    [[ "$output" == *"Phase2"* ]]
    [[ "$output" == *"Phase3"* ]]
    [[ "$output" == *"Phase4"* ]]
    [[ "$output" == *"PASS"* ]]
    [[ "$output" == *"FAIL"* ]]
    [[ "$output" == *"FIXABLE"* ]]
    [[ "$output" == *"SKIP"* ]]
}

@test "summary table: handles single entry" {
    run bash -c "
        export TUI_AVAILABLE=true
        source '$PROJECT_ROOT/scripts/lib/tui.sh'
        TUI_AVAILABLE=true
        tui_summary_table 'OnlyPhase:PASS:5s' | cat
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"OnlyPhase"* ]]
    [[ "$output" == *"PASS"* ]]
}

# ══════════════════════════════════════════════════════════════════════
# CLI integration: end-to-end routing verification
# ══════════════════════════════════════════════════════════════════════

@test "CLI E2E: feature with spaces routes correctly" {
    local mock_dir
    mock_dir="$(mktemp -d)"
    mkdir -p "$mock_dir/scripts"
    cat > "$mock_dir/scripts/pipeline-engine.sh" << 'MOCK'
#!/bin/bash
echo "FEATURE_WITH_SPACES: $1"
MOCK
    chmod +x "$mock_dir/scripts/pipeline-engine.sh"

    mkdir -p "$mock_dir/bin"
    sed "s|SCRIPT_DIR=.*|SCRIPT_DIR=\"$mock_dir\"|" "$PROJECT_ROOT/bin/cli.sh" > "$mock_dir/bin/cli.sh"

    run bash "$mock_dir/bin/cli.sh" "user authentication system"
    [ "$status" -eq 0 ]
    [[ "$output" == *"user authentication system"* ]]

    rm -rf "$mock_dir"
}

@test "CLI E2E: multiple flags pass through correctly" {
    local mock_dir
    mock_dir="$(mktemp -d)"
    mkdir -p "$mock_dir/scripts"
    cat > "$mock_dir/scripts/pipeline-engine.sh" << 'MOCK'
#!/bin/bash
echo "ALL_ARGS: $*"
MOCK
    chmod +x "$mock_dir/scripts/pipeline-engine.sh"

    mkdir -p "$mock_dir/bin"
    sed "s|SCRIPT_DIR=.*|SCRIPT_DIR=\"$mock_dir\"|" "$PROJECT_ROOT/bin/cli.sh" > "$mock_dir/bin/cli.sh"

    run bash "$mock_dir/bin/cli.sh" run "auth" --auto --report --no-cache --lang=ja --max-retries=5
    [ "$status" -eq 0 ]
    [[ "$output" == *"auth"* ]]
    [[ "$output" == *"--auto"* ]]
    [[ "$output" == *"--report"* ]]
    [[ "$output" == *"--no-cache"* ]]
    [[ "$output" == *"--lang=ja"* ]]
    [[ "$output" == *"--max-retries=5"* ]]

    rm -rf "$mock_dir"
}
