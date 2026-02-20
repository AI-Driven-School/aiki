#!/bin/bash
# quality-report.sh - Generate a quality report after pipeline execution
#
# Usage (called by pipeline-engine.sh):
#   bash quality-report.sh <feature> <slug> <project_dir> <total_duration> \
#       "<phases>" "<results>" "<retries>" "<durations>"
#
# Also callable standalone:
#   bash quality-report.sh --standalone <feature> <project_dir>

set -euo pipefail

# ── Colors (for terminal output) ────────────────────────────────────

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

format_duration() {
    local s=$1
    if [ "$s" -ge 60 ]; then
        echo "$((s / 60))m $((s % 60))s"
    else
        echo "${s}s"
    fi
}

# ── Generate report from pipeline data ──────────────────────────────

generate_report() {
    local feature="$1"
    local feature_slug="$2"
    local project_dir="$3"
    local total_duration="$4"
    local phases_str="$5"
    local results_str="$6"
    local retries_str="$7"
    local durations_str="$8"

    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local date_slug
    date_slug=$(date '+%Y%m%d-%H%M%S')

    # Parse space-separated arrays
    IFS=' ' read -ra phases <<< "$phases_str"
    IFS=' ' read -ra results <<< "$results_str"
    IFS=' ' read -ra retries <<< "$retries_str"
    IFS=' ' read -ra durations <<< "$durations_str"

    # Count results
    local pass_count=0 fixable_count=0 fail_count=0 skip_count=0
    local total_retries=0
    for i in "${!results[@]}"; do
        case "${results[$i]}" in
            PASS)    pass_count=$((pass_count + 1)) ;;
            FIXABLE) fixable_count=$((fixable_count + 1)) ;;
            FAIL)    fail_count=$((fail_count + 1)) ;;
            SKIP)    skip_count=$((skip_count + 1)) ;;
        esac
        total_retries=$((total_retries + ${retries[$i]:-0}))
    done

    # Determine overall status
    local overall_status="PASSED"
    local overall_emoji="✅"
    if [ "$fail_count" -gt 0 ]; then
        overall_status="FAILED"
        overall_emoji="❌"
    elif [ "$fixable_count" -gt 0 ]; then
        overall_status="PASSED (with warnings)"
        overall_emoji="⚠️"
    fi

    # Compute quality score (same formula as pipeline-engine.sh)
    local total_weight=0
    local weighted_sum=0
    for i in "${!phases[@]}"; do
        local r="${results[$i]}"
        if [ "$r" = "SKIP" ]; then continue; fi
        local w=15
        case "${phases[$i]}" in
            implement) w=30 ;;
            test)      w=25 ;;
        esac
        local s=0
        case "$r" in
            PASS)    s=100 ;;
            FIXABLE) s=70 ;;
            FAIL)    s=0 ;;
        esac
        local pen=$(( ${retries[$i]:-0} * 5 ))
        if [ "$pen" -gt "$s" ]; then s=0; else s=$((s - pen)); fi
        weighted_sum=$((weighted_sum + s * w))
        total_weight=$((total_weight + w))
    done
    local quality_score=0
    if [ "$total_weight" -gt 0 ]; then
        quality_score=$((weighted_sum / total_weight))
    fi

    # Build report
    local report_dir="${project_dir}/.claude/docs/reports"
    mkdir -p "$report_dir"
    local report_file="${report_dir}/${feature_slug}-${date_slug}.md"

    cat > "$report_file" << EOF
# Quality Report: ${feature}

**Date**: ${timestamp}
**Status**: ${overall_emoji} ${overall_status}
**Duration**: $(format_duration "$total_duration")
**Quality Score**: ${quality_score}/100

---

## Phase Results

| Phase | Result | Retries | Duration |
|-------|--------|---------|----------|
EOF

    for i in "${!phases[@]}"; do
        local result_emoji=""
        case "${results[$i]}" in
            PASS)    result_emoji="✅" ;;
            FIXABLE) result_emoji="⚠️" ;;
            FAIL)    result_emoji="❌" ;;
            SKIP)    result_emoji="⏭️" ;;
        esac
        local dur_str
        dur_str=$(format_duration "${durations[$i]:-0}")
        echo "| ${phases[$i]} | ${result_emoji} ${results[$i]} | ${retries[$i]:-0} | ${dur_str} |" >> "$report_file"
    done

    cat >> "$report_file" << EOF

---

## Summary

- **Phases run**: ${#phases[@]}
- **Passed**: ${pass_count}
- **Warnings**: ${fixable_count}
- **Failed**: ${fail_count}
- **Skipped**: ${skip_count}
- **Total auto-fix retries**: ${total_retries}

EOF

    # Add auto-fix details if any retries occurred
    if [ "$total_retries" -gt 0 ]; then
        cat >> "$report_file" << EOF
## Auto-Fix Activity

${total_retries} auto-fix attempts were made during this pipeline run.

EOF
        for i in "${!phases[@]}"; do
            if [ "${retries[$i]:-0}" -gt 0 ]; then
                echo "- **${phases[$i]}**: ${retries[$i]} retries" >> "$report_file"
            fi
        done
        echo "" >> "$report_file"
    fi

    # Add quality score section
    local score_emoji="🟢"
    if [ "$quality_score" -lt 50 ]; then
        score_emoji="🔴"
    elif [ "$quality_score" -lt 80 ]; then
        score_emoji="🟡"
    fi
    cat >> "$report_file" << EOF
## Quality Score

${score_emoji} **${quality_score}/100**

| Metric | Value |
|--------|-------|
| Phases passed | ${pass_count} |
| Phases with warnings | ${fixable_count} |
| Phases failed | ${fail_count} |
| Total retries | ${total_retries} |

EOF

    # Add artifact inventory
    cat >> "$report_file" << EOF
## Artifacts

| Artifact | Path | Exists |
|----------|------|--------|
| Requirements | docs/requirements/${feature_slug}.md | $([ -f "${project_dir}/docs/requirements/${feature_slug}.md" ] && echo "✅" || echo "❌") |
| Design Spec | docs/specs/${feature_slug}.md | $([ -f "${project_dir}/docs/specs/${feature_slug}.md" ] && echo "✅" || echo "❌") |
| API Spec | docs/api/${feature_slug}.yaml | $([ -f "${project_dir}/docs/api/${feature_slug}.yaml" ] && echo "✅" || echo "❌") |
| Review | docs/reviews/${feature_slug}.md | $([ -f "${project_dir}/docs/reviews/${feature_slug}.md" ] && echo "✅" || echo "❌") |

---

*Generated by ai4dev pipeline-engine*
EOF

    echo -e "${GREEN}Report saved:${NC} ${report_file}"
    echo "$report_file"
}

# ── Standalone mode ─────────────────────────────────────────────────
# Generate a report by scanning existing artifacts (not from pipeline data)

generate_standalone_report() {
    local feature="$1"
    local project_dir="${2:-$PWD}"

    local feature_slug
    if echo "$feature" | grep -q '[^a-zA-Z0-9 -]'; then
        feature_slug=$(echo "$feature" | sed 's/ /-/g')
    else
        feature_slug=$(echo "$feature" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')
    fi

    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local date_slug
    date_slug=$(date '+%Y%m%d-%H%M%S')

    local report_dir="${project_dir}/.claude/docs/reports"
    mkdir -p "$report_dir"
    local report_file="${report_dir}/${feature_slug}-${date_slug}.md"

    cat > "$report_file" << EOF
# Quality Report: ${feature}

**Date**: ${timestamp}
**Mode**: Standalone scan

---

## Artifact Inventory

| Artifact | Path | Status |
|----------|------|--------|
| Requirements | docs/requirements/${feature_slug}.md | $([ -f "${project_dir}/docs/requirements/${feature_slug}.md" ] && echo "✅ Found" || echo "❌ Missing") |
| Design Spec | docs/specs/${feature_slug}.md | $([ -f "${project_dir}/docs/specs/${feature_slug}.md" ] && echo "✅ Found" || echo "❌ Missing") |
| API Spec | docs/api/${feature_slug}.yaml | $([ -f "${project_dir}/docs/api/${feature_slug}.yaml" ] && echo "✅ Found" || echo "❌ Missing") |
| Review | docs/reviews/${feature_slug}.md | $([ -f "${project_dir}/docs/reviews/${feature_slug}.md" ] && echo "✅ Found" || echo "❌ Missing") |

EOF

    # Check review verdict if review exists
    local review_file="${project_dir}/docs/reviews/${feature_slug}.md"
    if [ -f "$review_file" ]; then
        local verdict
        verdict=$(grep -iE '(APPROVED|NEEDS CHANGES|REJECTED)' "$review_file" | head -1 || true)
        if [ -n "$verdict" ]; then
            echo "## Review Verdict" >> "$report_file"
            echo "" >> "$report_file"
            echo "$verdict" >> "$report_file"
            echo "" >> "$report_file"
        fi
    fi

    echo "---" >> "$report_file"
    echo "" >> "$report_file"
    echo "*Generated by ai4dev quality-report (standalone)*" >> "$report_file"

    echo -e "${GREEN}Report saved:${NC} ${report_file}"
}

# ── CLI ─────────────────────────────────────────────────────────────

main() {
    if [ $# -lt 1 ]; then
        echo "Usage:"
        echo "  quality-report.sh <feature> <slug> <dir> <duration> <phases> <results> <retries> <durations>"
        echo "  quality-report.sh --standalone <feature> [project_dir]"
        exit 0
    fi

    if [ "$1" = "--standalone" ]; then
        shift
        generate_standalone_report "$@"
    else
        generate_report "$@"
    fi
}

main "$@"
