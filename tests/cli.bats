#!/usr/bin/env bats

load helpers

setup() {
    export PATH="$BATS_TEST_DIRNAME/mocks:$PATH"
}

# ══════════════════════════════════════════════════════════════════════
# Syntax validation
# ══════════════════════════════════════════════════════════════════════

@test "cli.sh: valid bash syntax" {
    run bash -n "$PROJECT_ROOT/bin/cli.sh"
    [ "$status" -eq 0 ]
}

# ══════════════════════════════════════════════════════════════════════
# Help output
# ══════════════════════════════════════════════════════════════════════

@test "cli.sh: shows help with no arguments" {
    run bash "$PROJECT_ROOT/bin/cli.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"aiki"* ]]
    [[ "$output" == *"Commands"* ]]
}

@test "cli.sh: shows help with --help" {
    run bash "$PROJECT_ROOT/bin/cli.sh" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage"* ]]
}

@test "cli.sh: shows help with -h" {
    run bash "$PROJECT_ROOT/bin/cli.sh" -h
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage"* ]]
}

@test "cli.sh: help includes run command" {
    run bash "$PROJECT_ROOT/bin/cli.sh" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"run"* ]]
    [[ "$output" == *"--demo"* ]]
}

@test "cli.sh: help includes feature name usage" {
    run bash "$PROJECT_ROOT/bin/cli.sh" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *'"<feature>"'* ]] || [[ "$output" == *'<feature>'* ]]
}

@test "cli.sh: help includes all options for run" {
    run bash "$PROJECT_ROOT/bin/cli.sh" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"--demo"* ]]
    [[ "$output" == *"--dry-run"* ]]
    [[ "$output" == *"--auto"* ]]
}

# ══════════════════════════════════════════════════════════════════════
# Version
# ══════════════════════════════════════════════════════════════════════

@test "cli.sh: shows version with --version" {
    run bash "$PROJECT_ROOT/bin/cli.sh" --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"aiki v"* ]]
}

@test "cli.sh: shows version with -v" {
    run bash "$PROJECT_ROOT/bin/cli.sh" -v
    [ "$status" -eq 0 ]
    [[ "$output" == *"aiki v"* ]]
}

# ══════════════════════════════════════════════════════════════════════
# init command (existing)
# ══════════════════════════════════════════════════════════════════════

@test "cli.sh: init requires directory argument" {
    run bash "$PROJECT_ROOT/bin/cli.sh" init
    [ "$status" -eq 1 ]
    [[ "$output" == *"Usage"* ]]
}

# ══════════════════════════════════════════════════════════════════════
# run command
# ══════════════════════════════════════════════════════════════════════

@test "cli.sh: run requires feature argument" {
    run bash "$PROJECT_ROOT/bin/cli.sh" run
    [ "$status" -eq 1 ]
    [[ "$output" == *"Usage"* ]] || [[ "$output" == *"feature"* ]]
}

@test "cli.sh: run rejects unknown options" {
    run bash "$PROJECT_ROOT/bin/cli.sh" run "test-feature" --unknown-flag
    [ "$status" -eq 1 ]
    [[ "$output" == *"Unknown option"* ]]
}

# ══════════════════════════════════════════════════════════════════════
# Feature-name routing (unknown commands as feature names)
# ══════════════════════════════════════════════════════════════════════

@test "cli.sh: unknown option shows error" {
    run bash "$PROJECT_ROOT/bin/cli.sh" --nonexistent
    [ "$status" -eq 1 ]
    [[ "$output" == *"Unknown option"* ]]
}

# ══════════════════════════════════════════════════════════════════════
# --demo flag routing
# ══════════════════════════════════════════════════════════════════════

@test "cli.sh: --demo flag triggers demo-mode.sh" {
    # Create a mock demo-mode.sh that confirms it was called
    local mock_dir
    mock_dir="$(mktemp -d)"
    mkdir -p "$mock_dir/scripts"
    cat > "$mock_dir/scripts/demo-mode.sh" << 'MOCK'
#!/bin/bash
echo "DEMO_MODE_CALLED: $1"
exit 0
MOCK
    chmod +x "$mock_dir/scripts/demo-mode.sh"

    # Create a minimal cli.sh copy pointing to mock
    mkdir -p "$mock_dir/bin"
    sed "s|SCRIPT_DIR=.*|SCRIPT_DIR=\"$mock_dir\"|" "$PROJECT_ROOT/bin/cli.sh" > "$mock_dir/bin/cli.sh"

    run bash "$mock_dir/bin/cli.sh" "test-feature" --demo
    [ "$status" -eq 0 ]
    [[ "$output" == *"DEMO_MODE_CALLED"* ]]
    [[ "$output" == *"test-feature"* ]]

    rm -rf "$mock_dir"
}

@test "cli.sh: run subcommand with --demo also works" {
    local mock_dir
    mock_dir="$(mktemp -d)"
    mkdir -p "$mock_dir/scripts"
    cat > "$mock_dir/scripts/demo-mode.sh" << 'MOCK'
#!/bin/bash
echo "DEMO_RUN: $1"
exit 0
MOCK
    chmod +x "$mock_dir/scripts/demo-mode.sh"

    mkdir -p "$mock_dir/bin"
    sed "s|SCRIPT_DIR=.*|SCRIPT_DIR=\"$mock_dir\"|" "$PROJECT_ROOT/bin/cli.sh" > "$mock_dir/bin/cli.sh"

    run bash "$mock_dir/bin/cli.sh" run "auth" --demo
    [ "$status" -eq 0 ]
    [[ "$output" == *"DEMO_RUN"* ]]
    [[ "$output" == *"auth"* ]]

    rm -rf "$mock_dir"
}

# ══════════════════════════════════════════════════════════════════════
# Pipeline routing (without --demo)
# ══════════════════════════════════════════════════════════════════════

@test "cli.sh: feature name routes to pipeline-engine.sh" {
    local mock_dir
    mock_dir="$(mktemp -d)"
    mkdir -p "$mock_dir/scripts"
    cat > "$mock_dir/scripts/pipeline-engine.sh" << 'MOCK'
#!/bin/bash
echo "PIPELINE_CALLED: $*"
exit 0
MOCK
    chmod +x "$mock_dir/scripts/pipeline-engine.sh"

    mkdir -p "$mock_dir/bin"
    sed "s|SCRIPT_DIR=.*|SCRIPT_DIR=\"$mock_dir\"|" "$PROJECT_ROOT/bin/cli.sh" > "$mock_dir/bin/cli.sh"

    run bash "$mock_dir/bin/cli.sh" "my-feature" --dry-run --auto
    [ "$status" -eq 0 ]
    [[ "$output" == *"PIPELINE_CALLED"* ]]
    [[ "$output" == *"my-feature"* ]]
    [[ "$output" == *"--dry-run"* ]]
    [[ "$output" == *"--auto"* ]]

    rm -rf "$mock_dir"
}

@test "cli.sh: run subcommand passes flags to pipeline" {
    local mock_dir
    mock_dir="$(mktemp -d)"
    mkdir -p "$mock_dir/scripts"
    cat > "$mock_dir/scripts/pipeline-engine.sh" << 'MOCK'
#!/bin/bash
echo "PIPELINE_FLAGS: $*"
exit 0
MOCK
    chmod +x "$mock_dir/scripts/pipeline-engine.sh"

    mkdir -p "$mock_dir/bin"
    sed "s|SCRIPT_DIR=.*|SCRIPT_DIR=\"$mock_dir\"|" "$PROJECT_ROOT/bin/cli.sh" > "$mock_dir/bin/cli.sh"

    run bash "$mock_dir/bin/cli.sh" run "auth" --auto --report --lang=en
    [ "$status" -eq 0 ]
    [[ "$output" == *"PIPELINE_FLAGS"* ]]
    [[ "$output" == *"auth"* ]]
    [[ "$output" == *"--auto"* ]]
    [[ "$output" == *"--report"* ]]
    [[ "$output" == *"--lang=en"* ]]

    rm -rf "$mock_dir"
}

# ══════════════════════════════════════════════════════════════════════
# Japanese feature names
# ══════════════════════════════════════════════════════════════════════

@test "cli.sh: handles Japanese feature names" {
    local mock_dir
    mock_dir="$(mktemp -d)"
    mkdir -p "$mock_dir/scripts"
    cat > "$mock_dir/scripts/pipeline-engine.sh" << 'MOCK'
#!/bin/bash
echo "JP_FEATURE: $1"
exit 0
MOCK
    chmod +x "$mock_dir/scripts/pipeline-engine.sh"

    mkdir -p "$mock_dir/bin"
    sed "s|SCRIPT_DIR=.*|SCRIPT_DIR=\"$mock_dir\"|" "$PROJECT_ROOT/bin/cli.sh" > "$mock_dir/bin/cli.sh"

    run bash "$mock_dir/bin/cli.sh" "ECサイトのカート機能"
    [ "$status" -eq 0 ]
    [[ "$output" == *"ECサイトのカート機能"* ]]

    rm -rf "$mock_dir"
}
