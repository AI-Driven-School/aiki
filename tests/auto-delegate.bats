#!/usr/bin/env bats

load helpers

setup() {
    export PATH="$BATS_TEST_DIRNAME/mocks:$PATH"
}

@test "auto-delegate.sh: shows help with no arguments" {
    run bash "$PROJECT_ROOT/scripts/auto-delegate.sh" help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage"* ]] || [[ "$output" == *"Commands"* ]]
}

@test "auto-delegate.sh: shows help with --help flag" {
    run bash "$PROJECT_ROOT/scripts/auto-delegate.sh" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Commands"* ]]
}

@test "auto-delegate.sh: rejects unknown command" {
    run bash "$PROJECT_ROOT/scripts/auto-delegate.sh" unknown-command
    [ "$status" -eq 1 ]
    [[ "$output" == *"Unknown command"* ]]
}

@test "auto-delegate.sh: blocks sensitive file in test command" {
    run bash "$PROJECT_ROOT/scripts/auto-delegate.sh" test ".env"
    [ "$status" -eq 1 ]
    [[ "$output" == *"sensitive"* ]] || [[ "$output" == *"Refusing"* ]]
}

@test "auto-delegate.sh: blocks sensitive file in refactor command" {
    run bash "$PROJECT_ROOT/scripts/auto-delegate.sh" refactor "credentials.json"
    [ "$status" -eq 1 ]
    [[ "$output" == *"sensitive"* ]] || [[ "$output" == *"Refusing"* ]]
}
