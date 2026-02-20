#!/bin/bash
#
# post-impl-check.sh - Post-implementation check hook
# Every 5 edits, runs real lint/typecheck gates instead of just counting.
#

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"

# Track edit count (cumulative within session)
COUNTER_FILE="${PROJECT_DIR}/.claude/.edit_counter"

# Read and increment counter
if [ -f "$COUNTER_FILE" ]; then
    count=$(cat "$COUNTER_FILE")
    count=$((count + 1))
else
    count=1
fi
echo "$count" > "$COUNTER_FILE"

# Only act every 5 edits
if [ $((count % 5)) -ne 0 ]; then
    exit 0
fi

# ── Load quality gates if available ─────────────────────────────────

QUALITY_GATES=""
# Walk up from hooks dir to find scripts/lib/quality-gates.sh
for candidate in \
    "${PROJECT_DIR}/scripts/lib/quality-gates.sh" \
    "${SCRIPT_DIR}/../../scripts/lib/quality-gates.sh"; do
    if [ -f "$candidate" ]; then
        QUALITY_GATES="$candidate"
        break
    fi
done

if [ -n "$QUALITY_GATES" ]; then
    # Load sensitive filter for security checks
    for sf_candidate in \
        "${PROJECT_DIR}/scripts/lib/sensitive-filter.sh" \
        "${SCRIPT_DIR}/../../scripts/lib/sensitive-filter.sh"; do
        if [ -f "$sf_candidate" ]; then
            # shellcheck source=../../scripts/lib/sensitive-filter.sh
            source "$sf_candidate"
            break
        fi
    done

    # shellcheck source=../../scripts/lib/quality-gates.sh
    source "$QUALITY_GATES"

    gate_exit=0
    gate_output=$(gate_implement "$PROJECT_DIR" 2>&1) || gate_exit=$?

    # Strip ---DETAILS--- for display (keep summary only)
    gate_summary=$(echo "$gate_output" | sed '/---DETAILS---/,$d')

    case $gate_exit in
        0)
            echo "**Quality check** (${count} edits)
   All checks passed: ${gate_summary}"
            exit 0
            ;;
        1)
            echo "**Quality check** (${count} edits)
   ⚠ Auto-fixable issues found:
   ${gate_summary}

   Run \`/review\` or let the pipeline auto-fix these."
            exit 0
            ;;
        2)
            echo "**Quality check** (${count} edits)
   ✗ BLOCKING: Issues require immediate attention:
   ${gate_summary}

   This edit is BLOCKED until the issues are resolved.
   Fix the reported errors before continuing."
            exit 2
            ;;
    esac
else
    # Fallback: simple count-based suggestion
    echo "**Review checkpoint**
   $count file edits completed.

   Recommended actions:
   - Run \`/review\` for code review
   - Run \`git diff\` to check changes
   - Run tests to verify behavior"
fi

exit 0
