#!/bin/bash
# knowledge-loop.sh - Extract patterns from past reviews, accumulate knowledge
#
# Functions:
#   extract_review_patterns()  - Parse review files for recurring issues
#   get_knowledge_context()    - Build unified context from all knowledge sources
#   update_review_patterns()   - Persist extracted patterns to review-patterns.md

# ── Extract patterns from review files ──────────────────────────────
# Scans docs/reviews/*.md for lines marked with issue indicators
# (emoji markers, "FAIL", "NEEDS CHANGES", bullet items under improvement sections)

extract_review_patterns() {
    local project_dir="${1:-$PWD}"
    local reviews_dir="${project_dir}/docs/reviews"

    if [ ! -d "$reviews_dir" ]; then
        return 0
    fi

    local patterns=""

    for review_file in "$reviews_dir"/*.md; do
        [ -f "$review_file" ] || continue
        local basename
        basename=$(basename "$review_file" .md)

        # Extract lines with issue markers (red/yellow circles, X marks, FAIL)
        local issues
        issues=$(grep -E '(🔴|🟡|✗|FAIL|NEEDS CHANGES|要改善|改善提案)' "$review_file" 2>/dev/null | head -10)

        # Extract improvement suggestions section
        local suggestions
        suggestions=$(sed -nE '/## (改善|Improvement|Suggestion|提案)/,/^## /{ /^- /p; }' "$review_file" 2>/dev/null | head -10)

        if [ -n "$issues" ] || [ -n "$suggestions" ]; then
            patterns="${patterns}### ${basename}
"
            [ -n "$issues" ] && patterns="${patterns}${issues}
"
            [ -n "$suggestions" ] && patterns="${patterns}${suggestions}
"
            patterns="${patterns}
"
        fi
    done

    echo "$patterns"
}

# ── Build unified knowledge context ─────────────────────────────────
# Combines:
#   1. Past review patterns (docs/reviews/)
#   2. Design decisions (docs/decisions/)
#   3. Design principles (.claude/docs/DESIGN.md)
#   4. Accumulated patterns (.claude/docs/review-patterns.md)

get_knowledge_context() {
    local project_dir="${1:-$PWD}"
    local context=""
    local max_size=3000  # Cap context to avoid prompt bloat

    # 1. Accumulated review patterns (most relevant)
    local patterns_file="${project_dir}/.claude/docs/review-patterns.md"
    if [ -f "$patterns_file" ]; then
        local patterns_content
        patterns_content=$(head -c 1000 "$patterns_file")
        if [ -n "$patterns_content" ]; then
            context="${context}## Past Review Patterns
${patterns_content}

"
        fi
    fi

    # 2. Recent design decisions (last 5)
    local decisions_dir="${project_dir}/docs/decisions"
    if [ -d "$decisions_dir" ]; then
        local recent_decisions
        recent_decisions=$(ls -t "$decisions_dir"/*.md 2>/dev/null | head -5)
        if [ -n "$recent_decisions" ]; then
            context="${context}## Recent Decisions
"
            while IFS= read -r dec_file; do
                [ -f "$dec_file" ] || continue
                local dec_title
                dec_title=$(head -1 "$dec_file" | sed 's/^#* *//')
                context="${context}- ${dec_title}
"
            done <<< "$recent_decisions"
            context="${context}
"
        fi
    fi

    # 3. Design principles
    local design_file="${project_dir}/.claude/docs/DESIGN.md"
    if [ -f "$design_file" ]; then
        local design_excerpt
        design_excerpt=$(head -c 800 "$design_file")
        if [ -n "$design_excerpt" ]; then
            context="${context}## Design Principles
${design_excerpt}

"
        fi
    fi

    # 4. Live-extracted review patterns (supplement accumulated ones)
    local live_patterns
    live_patterns=$(extract_review_patterns "$project_dir" 2>/dev/null)
    if [ -n "$live_patterns" ]; then
        context="${context}## Recent Review Issues
${live_patterns}
"
    fi

    # Truncate to max size
    echo "$context" | head -c "$max_size"
}

# ── Persist patterns ────────────────────────────────────────────────
# Call after a review phase to accumulate patterns for future use.

update_review_patterns() {
    local project_dir="${1:-$PWD}"
    local patterns_file="${project_dir}/.claude/docs/review-patterns.md"

    mkdir -p "$(dirname "$patterns_file")"

    local new_patterns
    new_patterns=$(extract_review_patterns "$project_dir" 2>/dev/null)

    if [ -z "$new_patterns" ]; then
        return 0
    fi

    # Deduplicate: skip lines whose first 40 chars already exist in the file
    local deduped_patterns=""
    if [ -f "$patterns_file" ]; then
        local existing_content
        existing_content=$(cat "$patterns_file")
        while IFS= read -r line; do
            [ -z "$line" ] && continue
            # Skip markdown headers and separators (always allow)
            case "$line" in
                "###"*|"---"*|"Updated:"*) deduped_patterns="${deduped_patterns}${line}
" ; continue ;;
            esac
            # Check first 40 chars for dedup
            local prefix="${line:0:40}"
            if [ -n "$prefix" ] && echo "$existing_content" | grep -qF "$prefix" 2>/dev/null; then
                continue  # duplicate, skip
            fi
            deduped_patterns="${deduped_patterns}${line}
"
        done <<< "$new_patterns"
    else
        deduped_patterns="$new_patterns"
    fi

    if [ -z "$deduped_patterns" ]; then
        return 0
    fi

    # Append with timestamp, keeping file under 5000 lines
    {
        echo ""
        echo "---"
        echo "Updated: $(date '+%Y-%m-%d %H:%M')"
        echo ""
        echo "$deduped_patterns"
    } >> "$patterns_file"

    # Trim to last 5000 lines
    local line_count
    line_count=$(wc -l < "$patterns_file" | tr -d ' ')
    if [ "$line_count" -gt 5000 ]; then
        local tmp
        tmp=$(mktemp)
        tail -5000 "$patterns_file" > "$tmp"
        mv "$tmp" "$patterns_file"
    fi
}
