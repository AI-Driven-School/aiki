#!/usr/bin/env bash
# ============================================
# aiki CLI
# ============================================
set -euo pipefail

VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

show_help() {
    cat << EOF
aiki v${VERSION}
4-AI collaborative development: Claude + Codex + Gemini + Grok

Usage:
  aiki <command> [options]
  aiki "<feature>"              Run pipeline for feature
  aiki "<feature>" --demo       Run 25-second demo mode

Commands:
  init <dir>     Initialize a new project with 4-AI workflow
  run <feature>  Run the pipeline for a feature
  update         Update an existing project to the latest template
  --help, -h     Show this help
  --version, -v  Show version

Options for init:
  --claude-only    Claude Code only
  --claude-codex   Claude + Codex
  --claude-gemini  Claude + Gemini
  --full           All 4 AIs (default)

Options for run / "<feature>":
  --demo           Run scripted 25-second demo mode
  --dry-run        Simulate without executing phases
  --auto           Auto-approve all prompts
  --report         Generate quality report

Examples:
  npx aiki init my-app
  npx aiki "ECサイトのカート機能"
  npx aiki "auth" --demo
  npx aiki run "auth" --auto
  npx aiki update
EOF
}

cmd_init() {
    local dir="${1:-}"
    shift 2>/dev/null || true

    if [ -z "$dir" ]; then
        echo "Usage: aiki init <directory> [options]"
        echo "Example: aiki init my-app"
        exit 1
    fi

    echo -e "${CYAN}Initializing 4-AI project in ${dir}...${NC}"
    bash "$SCRIPT_DIR/install-fullstack.sh" "$dir" "$@"
}

cmd_update() {
    echo -e "${CYAN}Updating project...${NC}"
    bash "$SCRIPT_DIR/update.sh"
}

cmd_run() {
    local feature=""
    local demo_mode=false
    local pass_args=()

    for arg in "$@"; do
        case "$arg" in
            --demo) demo_mode=true ;;
            --dry-run|--auto|--report|--no-cache|--escalate-to-github)
                pass_args+=("$arg") ;;
            --lang=*|--max-retries=*|--phases=*|--autofix-budget=*)
                pass_args+=("$arg") ;;
            -*)
                echo "Unknown option: $arg"
                exit 1
                ;;
            *)
                if [ -z "$feature" ]; then
                    feature="$arg"
                fi
                ;;
        esac
    done

    if [ -z "$feature" ]; then
        echo "Usage: aiki run <feature> [options]"
        echo "Example: aiki run \"user-auth\" --auto"
        exit 1
    fi

    if [ "$demo_mode" = "true" ]; then
        exec bash "${SCRIPT_DIR}/scripts/demo-mode.sh" "$feature"
    else
        if [ ${#pass_args[@]} -eq 0 ]; then
            exec bash "${SCRIPT_DIR}/scripts/pipeline-engine.sh" "$feature"
        else
            exec bash "${SCRIPT_DIR}/scripts/pipeline-engine.sh" "$feature" "${pass_args[@]}"
        fi
    fi
}

# Main
case "${1:-}" in
    init)
        shift
        cmd_init "$@"
        ;;
    run)
        shift
        cmd_run "$@"
        ;;
    update)
        shift
        cmd_update "$@"
        ;;
    --version|-v)
        echo "aiki v${VERSION}"
        ;;
    --help|-h|"")
        show_help
        ;;
    -*)
        echo "Unknown option: $1"
        echo ""
        show_help
        exit 1
        ;;
    *)
        # Treat unknown commands as feature names for pipeline execution
        cmd_run "$@"
        ;;
esac
