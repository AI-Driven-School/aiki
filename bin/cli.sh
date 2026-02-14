#!/usr/bin/env bash
# ============================================
# claude-codex-collab CLI
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
claude-codex-collab v${VERSION}
4-AI collaborative development: Claude + Codex + Gemini + Grok

Usage:
  claude-codex-collab <command> [options]

Commands:
  init <dir>     Initialize a new project with 3-AI workflow
  update         Update an existing project to the latest template
  --help, -h     Show this help
  --version, -v  Show version

Options for init:
  --claude-only    Claude Code only
  --claude-codex   Claude + Codex
  --claude-gemini  Claude + Gemini
  --full           All 3 AIs (default)

Examples:
  npx claude-codex-collab init my-app
  npx claude-codex-collab init my-app --claude-only
  npx claude-codex-collab update
EOF
}

cmd_init() {
    local dir="${1:-}"
    shift 2>/dev/null || true

    if [ -z "$dir" ]; then
        echo "Usage: claude-codex-collab init <directory> [options]"
        echo "Example: claude-codex-collab init my-app"
        exit 1
    fi

    echo -e "${CYAN}Initializing 3-AI project in ${dir}...${NC}"
    bash "$SCRIPT_DIR/install-fullstack.sh" "$dir" "$@"
}

cmd_update() {
    echo -e "${CYAN}Updating project...${NC}"
    bash "$SCRIPT_DIR/update.sh"
}

# Main
case "${1:-}" in
    init)
        shift
        cmd_init "$@"
        ;;
    update)
        shift
        cmd_update "$@"
        ;;
    --version|-v)
        echo "claude-codex-collab v${VERSION}"
        ;;
    --help|-h|"")
        show_help
        ;;
    *)
        echo "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
