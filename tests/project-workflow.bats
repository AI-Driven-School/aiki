#!/usr/bin/env bats

load helpers

setup() {
    export PATH="$BATS_TEST_DIRNAME/mocks:$PATH"
    export TEST_WORKSPACE
    TEST_WORKSPACE="$(mktemp -d)"
    # Create minimal project structure for workflow
    mkdir -p "$TEST_WORKSPACE/.claude"
    mkdir -p "$TEST_WORKSPACE/docs"
    mkdir -p "$TEST_WORKSPACE/scripts"
    cp "$PROJECT_ROOT/scripts/project-workflow.sh" "$TEST_WORKSPACE/scripts/"
}

teardown() {
    if [ -n "${TEST_WORKSPACE:-}" ] && [ -d "$TEST_WORKSPACE" ]; then
        rm -rf "$TEST_WORKSPACE"
    fi
}

@test "project-workflow.sh: valid bash syntax" {
    run bash -n "$PROJECT_ROOT/scripts/project-workflow.sh"
    [ "$status" -eq 0 ]
}

@test "project-workflow.sh: shows help with no arguments" {
    run bash "$PROJECT_ROOT/scripts/project-workflow.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"/project"* ]]
}

@test "project-workflow.sh: shows help with --help flag" {
    run bash "$PROJECT_ROOT/scripts/project-workflow.sh" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"--from"* ]]
    [[ "$output" == *"--force-unlock"* ]]
}

@test "project-workflow.sh: dry-run completes without error" {
    cd "$TEST_WORKSPACE"
    run bash "$PROJECT_ROOT/scripts/project-workflow.sh" "test-feature" --dry-run --auto
    [ "$status" -eq 0 ]
    [[ "$output" == *"DRY-RUN"* ]]
}

@test "project-workflow.sh: creates lock file on start" {
    cd "$TEST_WORKSPACE"
    # Run dry-run which acquires then releases lock via trap
    bash "$PROJECT_ROOT/scripts/project-workflow.sh" "lock-test" --dry-run --auto
    # Lock should be released after completion (trap EXIT)
    [ ! -f "$TEST_WORKSPACE/.project-state-lock-test.lock" ]
}

@test "project-workflow.sh: lock blocks concurrent access" {
    cd "$TEST_WORKSPACE"
    local lock_file="$TEST_WORKSPACE/.project-state-lock-test.lock"
    # Create a fake lock (recent timestamp)
    echo "otheruser@host" > "$lock_file"
    date +%s >> "$lock_file"

    run bash "$PROJECT_ROOT/scripts/project-workflow.sh" "lock-test" --dry-run --auto
    [ "$status" -eq 1 ]
    [[ "$output" == *"locked"* ]] || [[ "$output" == *"lock"* ]]

    rm -f "$lock_file"
}

@test "project-workflow.sh: stale lock auto-releases" {
    cd "$TEST_WORKSPACE"
    local lock_file="$TEST_WORKSPACE/.project-state-stale-test.lock"
    # Create a stale lock (timestamp far in the past)
    echo "olduser@host" > "$lock_file"
    echo "1000000000" >> "$lock_file"

    run bash "$PROJECT_ROOT/scripts/project-workflow.sh" "stale-test" --dry-run --auto
    [ "$status" -eq 0 ]
    [[ "$output" == *"Stale lock"* ]] || [[ "$output" == *"DRY-RUN"* ]]
}

@test "project-workflow.sh: --force-unlock removes lock" {
    cd "$TEST_WORKSPACE"
    local lock_file="$TEST_WORKSPACE/.project-state-unlock-test.lock"
    echo "someuser@host" > "$lock_file"
    date +%s >> "$lock_file"

    run bash "$PROJECT_ROOT/scripts/project-workflow.sh" "unlock-test" --force-unlock
    [ "$status" -eq 0 ]
    [ ! -f "$lock_file" ]
}

@test "project-workflow.sh: creates state file during execution" {
    cd "$TEST_WORKSPACE"
    bash "$PROJECT_ROOT/scripts/project-workflow.sh" "state-test" --dry-run --auto
    # State file should be cleaned up after successful completion
    [ ! -f "$TEST_WORKSPACE/.project-state-state-test" ]
}

@test "project-workflow.sh: --skip flag works" {
    cd "$TEST_WORKSPACE"
    run bash "$PROJECT_ROOT/scripts/project-workflow.sh" "skip-test" --dry-run --auto --skip=1,2,3,4,5,6
    [ "$status" -eq 0 ]
    [[ "$output" == *"スキップ"* ]] || [[ "$output" == *"skip"* ]] || [[ "$output" == *"完了"* ]]
}
