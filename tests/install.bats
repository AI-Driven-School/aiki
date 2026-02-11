#!/usr/bin/env bats

load helpers

@test "install.sh: valid bash syntax" {
    run bash -n "$PROJECT_ROOT/install.sh"
    [ "$status" -eq 0 ]
}

@test "install-fullstack.sh: valid bash syntax" {
    run bash -n "$PROJECT_ROOT/install-fullstack.sh"
    [ "$status" -eq 0 ]
}

@test "delegate.sh: valid bash syntax" {
    run bash -n "$PROJECT_ROOT/scripts/delegate.sh"
    [ "$status" -eq 0 ]
}

@test "auto-delegate.sh: valid bash syntax" {
    run bash -n "$PROJECT_ROOT/scripts/auto-delegate.sh"
    [ "$status" -eq 0 ]
}

@test "ai-runner.sh: valid bash syntax" {
    run bash -n "$PROJECT_ROOT/scripts/ai-runner.sh"
    [ "$status" -eq 0 ]
}

@test "project-workflow.sh: valid bash syntax" {
    run bash -n "$PROJECT_ROOT/scripts/project-workflow.sh"
    [ "$status" -eq 0 ]
}

@test "usage-report.sh: valid bash syntax" {
    run bash -n "$PROJECT_ROOT/scripts/usage-report.sh"
    [ "$status" -eq 0 ]
}

@test "sensitive-filter.sh: valid bash syntax" {
    run bash -n "$PROJECT_ROOT/scripts/lib/sensitive-filter.sh"
    [ "$status" -eq 0 ]
}
