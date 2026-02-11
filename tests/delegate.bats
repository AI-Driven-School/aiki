#!/usr/bin/env bats

load helpers

setup() {
    export PATH="$BATS_TEST_DIRNAME/mocks:$PATH"
}

@test "delegate.sh: shows help with no arguments" {
    run bash "$PROJECT_ROOT/scripts/delegate.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"3AI協調システム"* ]] || [[ "$output" == *"委譲スクリプト"* ]]
}

@test "delegate.sh: shows help with --help flag" {
    run bash "$PROJECT_ROOT/scripts/delegate.sh" help
    [ "$status" -eq 0 ]
    [[ "$output" == *"使用方法"* ]] || [[ "$output" == *"コマンド"* ]]
}

@test "delegate.sh: rejects unknown AI name" {
    run bash "$PROJECT_ROOT/scripts/delegate.sh" unknown-ai implement test
    [ "$status" -eq 1 ]
    [[ "$output" == *"不明なAI"* ]]
}

@test "delegate.sh: rejects unknown codex command" {
    run bash "$PROJECT_ROOT/scripts/delegate.sh" codex unknown-cmd test
    [ "$status" -eq 1 ]
    [[ "$output" == *"不明なコマンド"* ]]
}

@test "delegate.sh: rejects unknown gemini command" {
    run bash "$PROJECT_ROOT/scripts/delegate.sh" gemini unknown-cmd test
    [ "$status" -eq 1 ]
    [[ "$output" == *"不明なコマンド"* ]]
}
