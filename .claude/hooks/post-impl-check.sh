#!/bin/bash
#
# post-impl-check.sh - Post-implementation check hook
# Suggests review or testing after Edit/Write tool usage
#

# Track edit count (cumulative within session)
COUNTER_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/.edit_counter"

# Read and increment counter
if [ -f "$COUNTER_FILE" ]; then
    count=$(cat "$COUNTER_FILE")
    count=$((count + 1))
else
    count=1
fi
echo "$count" > "$COUNTER_FILE"

# Suggest review every 5 edits
if [ $((count % 5)) -eq 0 ]; then
    echo "**Review checkpoint**
   $count file edits completed.

   Recommended actions:
   - Run \`/review\` for code review
   - Run \`git diff\` to check changes
   - Run tests to verify behavior"
fi

exit 0
