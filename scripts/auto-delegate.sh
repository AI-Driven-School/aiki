#!/bin/bash

# auto-delegate.sh - Auto-delegation script for Codex tasks
# Usage: ./scripts/auto-delegate.sh <command> [args...]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="$PROJECT_ROOT/.codex-tasks"

# Load sensitive file filter
if [ -f "$SCRIPT_DIR/lib/sensitive-filter.sh" ]; then
    # shellcheck source=lib/sensitive-filter.sh
    source "$SCRIPT_DIR/lib/sensitive-filter.sh"
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Timestamp
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Codex is installed
check_codex() {
    if ! command -v codex &> /dev/null; then
        print_error "Codex CLI is not installed."
        echo ""
        echo "Install with: npm install -g @openai/codex"
        echo "Or use ChatGPT Pro at: https://chatgpt.com"
        exit 1
    fi
}

# Code review
do_review() {
    print_info "Starting code review..."
    local output_file="$OUTPUT_DIR/review-$TIMESTAMP.txt"

    if command -v codex &> /dev/null; then
        codex review --uncommitted 2>&1 | tee "$output_file"
    else
        # ChatGPT Proを使う場合のガイド
        print_warning "Codex CLI not found. Please use ChatGPT Pro manually."
        echo ""
        echo "1. Open https://chatgpt.com"
        echo "2. Copy the following prompt:"
        echo ""
        echo "---"
        echo "Please review the following code changes:"
        echo ""
        git diff --staged 2>/dev/null || git diff
        echo "---"
    fi

    print_success "Review output saved to: $output_file"
}

# Test creation
do_test() {
    local target_file="$1"
    print_info "Creating tests for: ${target_file:-all files}"
    local output_file="$OUTPUT_DIR/test-$TIMESTAMP.txt"

    local prompt="Create comprehensive unit tests for the following code. Include edge cases and error scenarios."

    if [ -n "$target_file" ]; then
        if type is_sensitive_file &>/dev/null && is_sensitive_file "$target_file"; then
            print_error "Refusing to send sensitive file to external AI: $target_file"
            print_warning "Use --force flag in delegate.sh to bypass this check."
            exit 1
        fi
        prompt="$prompt\n\nFile: $target_file\n\n$(cat "$target_file")"
    fi

    if command -v codex &> /dev/null; then
        echo -e "$prompt" | codex exec --full-auto 2>&1 | tee "$output_file"
    else
        print_warning "Codex CLI not found. Prompt saved to: $output_file"
        echo -e "$prompt" > "$output_file"
        echo ""
        echo "Use this prompt with ChatGPT Pro to generate tests."
    fi

    print_success "Test output saved to: $output_file"
}

# Documentation generation
do_docs() {
    print_info "Generating documentation..."
    local output_file="$OUTPUT_DIR/docs-$TIMESTAMP.txt"

    local prompt
    prompt="Generate comprehensive documentation for this project. Include:
1. Project overview
2. Installation instructions
3. Usage examples
4. API reference (if applicable)
5. Configuration options

Project structure:
$(find . -type f -name "*.py" -o -name "*.ts" -o -name "*.tsx" | head -50)"

    if command -v codex &> /dev/null; then
        echo -e "$prompt" | codex exec --full-auto 2>&1 | tee "$output_file"
    else
        print_warning "Codex CLI not found. Prompt saved to: $output_file"
        echo -e "$prompt" > "$output_file"
    fi

    print_success "Docs output saved to: $output_file"
}

# Refactoring
do_refactor() {
    local target_file="$1"
    print_info "Refactoring: ${target_file:-current changes}"
    local output_file="$OUTPUT_DIR/refactor-$TIMESTAMP.txt"

    local prompt="Refactor the following code to improve:
1. Code readability
2. Performance (where applicable)
3. Best practices adherence
4. Type safety (for TypeScript)

Keep the same functionality."

    if [ -n "$target_file" ]; then
        if type is_sensitive_file &>/dev/null && is_sensitive_file "$target_file"; then
            print_error "Refusing to send sensitive file to external AI: $target_file"
            print_warning "Use --force flag in delegate.sh to bypass this check."
            exit 1
        fi
        prompt="$prompt\n\nFile: $target_file\n\n$(cat "$target_file")"
    fi

    if command -v codex &> /dev/null; then
        echo -e "$prompt" | codex exec --full-auto 2>&1 | tee "$output_file"
    else
        print_warning "Codex CLI not found. Prompt saved to: $output_file"
        echo -e "$prompt" > "$output_file"
    fi

    print_success "Refactor output saved to: $output_file"
}

# Custom task
do_custom() {
    local task="$1"
    print_info "Running custom task: $task"
    local output_file="$OUTPUT_DIR/custom-$TIMESTAMP.txt"

    if command -v codex &> /dev/null; then
        codex exec --full-auto "$task" 2>&1 | tee "$output_file"
    else
        print_warning "Codex CLI not found. Task saved to: $output_file"
        echo "$task" > "$output_file"
    fi

    print_success "Custom task output saved to: $output_file"
}

# Background execution
do_background() {
    local task="$1"
    print_info "Running in background: $task"
    local output_file="$OUTPUT_DIR/background-$TIMESTAMP.txt"

    if command -v codex &> /dev/null; then
        nohup codex exec --full-auto "$task" > "$output_file" 2>&1 &
        local pid=$!
        print_success "Background task started (PID: $pid)"
        print_info "Output will be saved to: $output_file"
        print_info "Check progress: tail -f $output_file"
    else
        print_error "Codex CLI is required for background tasks"
        exit 1
    fi
}

# Show help
show_help() {
    echo "Usage: $0 <command> [args...]"
    echo ""
    echo "Commands:"
    echo "  review              Review uncommitted code changes"
    echo "  test [file]         Create unit tests (optionally for specific file)"
    echo "  docs                Generate project documentation"
    echo "  refactor [file]     Refactor code (optionally specific file)"
    echo "  custom <task>       Run a custom task"
    echo "  background <task>   Run a task in background"
    echo ""
    echo "Examples:"
    echo "  $0 review"
    echo "  $0 test backend/app/services/auth_service.py"
    echo "  $0 custom 'Add error handling to all API endpoints'"
    echo "  $0 background 'Refactor entire codebase'"
}

# Main
case "${1:-help}" in
    review)
        do_review
        ;;
    test)
        do_test "$2"
        ;;
    docs)
        do_docs
        ;;
    refactor)
        do_refactor "$2"
        ;;
    custom)
        if [ -z "$2" ]; then
            print_error "Custom task requires a task description"
            exit 1
        fi
        do_custom "$2"
        ;;
    background)
        if [ -z "$2" ]; then
            print_error "Background task requires a task description"
            exit 1
        fi
        do_background "$2"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
