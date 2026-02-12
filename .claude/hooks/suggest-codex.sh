#!/bin/bash
#
# suggest-codex.sh - Codex delegation suggestion hook
# Suggests delegating to Codex before Edit/Write tool usage
#

# shellcheck disable=SC2034
tool_name="${CLAUDE_TOOL_NAME:-unknown}"

echo "**Implementation task detected**
   Multi-file edits or new implementations can be delegated to Codex for efficiency.

   To delegate:
   1. Run \`/implement <task description>\`
   2. Or copy instructions from .codex/AGENTS.md to Codex

   To continue with Claude: No action needed (Claude will implement directly)"

exit 0
