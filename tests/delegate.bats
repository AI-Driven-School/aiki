#!/usr/bin/env bats

load helpers

setup() {
    export PATH="$BATS_TEST_DIRNAME/mocks:$PATH"
}

@test "delegate.sh: shows help with no arguments" {
    run bash "$PROJECT_ROOT/scripts/delegate.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"4AI Collaboration"* ]] || [[ "$output" == *"Delegation Script"* ]]
}

@test "delegate.sh: shows help with --help flag" {
    run bash "$PROJECT_ROOT/scripts/delegate.sh" help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]] || [[ "$output" == *"Commands:"* ]]
}

@test "delegate.sh: rejects unknown AI name" {
    run bash "$PROJECT_ROOT/scripts/delegate.sh" unknown-ai implement test
    [ "$status" -eq 1 ]
    [[ "$output" == *"Unknown AI"* ]]
}

@test "delegate.sh: rejects unknown codex command" {
    run bash "$PROJECT_ROOT/scripts/delegate.sh" codex unknown-cmd test
    [ "$status" -eq 1 ]
    [[ "$output" == *"Unknown command"* ]]
}

@test "delegate.sh: rejects unknown gemini command" {
    run bash "$PROJECT_ROOT/scripts/delegate.sh" gemini unknown-cmd test
    [ "$status" -eq 1 ]
    [[ "$output" == *"Unknown command"* ]]
}
