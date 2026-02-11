# tests/helpers.bash - Common test setup for bats tests

# Project root
export PROJECT_ROOT
PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

# Add mock binaries to PATH
export PATH="$BATS_TEST_DIRNAME/mocks:$PATH"

# Load bats-support and bats-assert if available
if [ -f "$BATS_TEST_DIRNAME/../node_modules/bats-support/load.bash" ]; then
    load "../node_modules/bats-support/load.bash"
    load "../node_modules/bats-assert/load.bash"
fi

# Create a temporary workspace for tests
setup_temp_workspace() {
    export TEST_WORKSPACE
    TEST_WORKSPACE="$(mktemp -d)"
    cd "$TEST_WORKSPACE" || return 1
    mkdir -p docs/{requirements,specs,api}
    mkdir -p scripts
}

# Clean up temporary workspace
teardown_temp_workspace() {
    if [ -n "${TEST_WORKSPACE:-}" ] && [ -d "$TEST_WORKSPACE" ]; then
        rm -rf "$TEST_WORKSPACE"
    fi
}
