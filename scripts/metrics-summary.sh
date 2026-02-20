#!/bin/bash
# metrics-summary.sh - Analyze metrics.jsonl and produce summary reports
#
# Reads .claude/docs/metrics.jsonl and outputs:
#   - Total run count, average duration, average/max/min quality score
#   - Recent 10 quality score trend
#   - Per-phase average duration and PASS/FIXABLE/FAIL counts
#   - Retry-heavy phases (improvement targets)
#
# Usage:
#   bash scripts/metrics-summary.sh [project_dir]
#
# macOS compatible (no grep -P, uses sed -E)

set -euo pipefail

# ── Colors ──────────────────────────────────────────────────────────

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ── Helpers ─────────────────────────────────────────────────────────

format_duration() {
    local s=$1
    if [ "$s" -ge 60 ]; then
        echo "$((s / 60))m $((s % 60))s"
    else
        echo "${s}s"
    fi
}

# ── Main ────────────────────────────────────────────────────────────

main() {
    local project_dir="${1:-$PWD}"
    local metrics_file="${project_dir}/.claude/docs/metrics.jsonl"

    if [ ! -f "$metrics_file" ]; then
        echo -e "${RED}No metrics file found at: ${metrics_file}${NC}"
        echo "Run the pipeline first to generate metrics."
        exit 1
    fi

    local total_runs=0
    local total_duration_sum=0
    local total_score_sum=0
    local score_count=0
    local max_score=0
    local min_score=100
    local recent_scores=""

    # Per-phase tracking (simple counters via temp files for portability)
    local tmpdir
    tmpdir=$(mktemp -d)
    trap "rm -rf $tmpdir" EXIT

    # Initialize phase counters
    for phase in requirements design implement test review; do
        echo "0" > "${tmpdir}/${phase}_duration_sum"
        echo "0" > "${tmpdir}/${phase}_count"
        echo "0" > "${tmpdir}/${phase}_pass"
        echo "0" > "${tmpdir}/${phase}_fixable"
        echo "0" > "${tmpdir}/${phase}_fail"
        echo "0" > "${tmpdir}/${phase}_retries"
    done

    # Parse each JSONL line
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        total_runs=$((total_runs + 1))

        # Extract top-level fields using sed (no jq dependency)
        local duration
        duration=$(echo "$line" | sed -E 's/.*"total_duration":([0-9]+).*/\1/' 2>/dev/null || echo "0")
        if echo "$duration" | grep -qE '^[0-9]+$'; then
            total_duration_sum=$((total_duration_sum + duration))
        fi

        local score
        score=$(echo "$line" | sed -E 's/.*"quality_score":([0-9]+).*/\1/' 2>/dev/null || echo "")
        if echo "$score" | grep -qE '^[0-9]+$'; then
            total_score_sum=$((total_score_sum + score))
            score_count=$((score_count + 1))
            if [ "$score" -gt "$max_score" ]; then max_score=$score; fi
            if [ "$score" -lt "$min_score" ]; then min_score=$score; fi
            recent_scores="${recent_scores}${score} "
        fi

        # Extract phases array entries
        # Simple approach: extract each phase object with sed
        local phases_str
        phases_str=$(echo "$line" | sed -E 's/.*"phases":\[([^]]*)\].*/\1/' 2>/dev/null || echo "")
        if [ -n "$phases_str" ] && [ "$phases_str" != "$line" ]; then
            # Split by },{ and process each phase
            echo "$phases_str" | sed 's/},{/}\n{/g' | while IFS= read -r pentry; do
                local pname presult pretries pdur
                pname=$(echo "$pentry" | sed -E 's/.*"name":"([^"]+)".*/\1/')
                presult=$(echo "$pentry" | sed -E 's/.*"result":"([^"]+)".*/\1/')
                pretries=$(echo "$pentry" | sed -E 's/.*"retries":([0-9]+).*/\1/' || echo "0")
                pdur=$(echo "$pentry" | sed -E 's/.*"duration":([0-9]+).*/\1/' || echo "0")

                if [ -f "${tmpdir}/${pname}_count" ]; then
                    local cur
                    cur=$(cat "${tmpdir}/${pname}_count")
                    echo $((cur + 1)) > "${tmpdir}/${pname}_count"

                    cur=$(cat "${tmpdir}/${pname}_duration_sum")
                    echo $((cur + pdur)) > "${tmpdir}/${pname}_duration_sum"

                    if echo "$pretries" | grep -qE '^[0-9]+$'; then
                        cur=$(cat "${tmpdir}/${pname}_retries")
                        echo $((cur + pretries)) > "${tmpdir}/${pname}_retries"
                    fi

                    case "$presult" in
                        PASS)    cur=$(cat "${tmpdir}/${pname}_pass"); echo $((cur + 1)) > "${tmpdir}/${pname}_pass" ;;
                        FIXABLE) cur=$(cat "${tmpdir}/${pname}_fixable"); echo $((cur + 1)) > "${tmpdir}/${pname}_fixable" ;;
                        FAIL)    cur=$(cat "${tmpdir}/${pname}_fail"); echo $((cur + 1)) > "${tmpdir}/${pname}_fail" ;;
                    esac
                fi
            done
        fi
    done < "$metrics_file"

    if [ "$total_runs" -eq 0 ]; then
        echo -e "${YELLOW}No metrics data found in ${metrics_file}${NC}"
        exit 0
    fi

    # ── Output Report ───────────────────────────────────────────────

    echo ""
    echo -e "${BOLD}${CYAN}━━━ Metrics Summary ━━━${NC}"
    echo ""

    # Overall stats
    local avg_duration=$((total_duration_sum / total_runs))
    echo -e "  ${BOLD}Total runs:${NC}       ${total_runs}"
    echo -e "  ${BOLD}Avg duration:${NC}     $(format_duration $avg_duration)"

    if [ "$score_count" -gt 0 ]; then
        local avg_score=$((total_score_sum / score_count))
        local score_color="$GREEN"
        if [ "$avg_score" -lt 50 ]; then score_color="$RED"
        elif [ "$avg_score" -lt 80 ]; then score_color="$YELLOW"; fi

        echo -e "  ${BOLD}Avg quality:${NC}      ${score_color}${avg_score}/100${NC}"
        echo -e "  ${BOLD}Best score:${NC}       ${GREEN}${max_score}/100${NC}"
        echo -e "  ${BOLD}Worst score:${NC}      ${RED}${min_score}/100${NC}"
    else
        echo -e "  ${BOLD}Quality scores:${NC}   ${DIM}no data${NC}"
    fi

    # Recent 10 quality score trend
    echo ""
    echo -e "  ${BOLD}Recent quality trend (last 10):${NC}"
    # shellcheck disable=SC2086
    local trend_scores
    trend_scores=$(echo $recent_scores | tr ' ' '\n' | tail -10)
    if [ -n "$trend_scores" ]; then
        local trend_line="  "
        while IFS= read -r s; do
            [ -z "$s" ] && continue
            local bar=""
            local sc="$GREEN"
            if [ "$s" -lt 50 ]; then sc="$RED"
            elif [ "$s" -lt 80 ]; then sc="$YELLOW"; fi
            # Simple bar: one block per 10 points
            local blocks=$((s / 10))
            local j=0
            while [ "$j" -lt "$blocks" ]; do
                bar="${bar}█"
                j=$((j + 1))
            done
            trend_line="${trend_line}${sc}${bar}${NC} ${s} "
        done <<< "$trend_scores"
        echo -e "$trend_line"
    fi

    # Per-phase stats
    echo ""
    echo -e "  ${BOLD}Phase Statistics:${NC}"
    printf "  ${BOLD}%-15s %-10s %-8s %-8s %-8s %-10s %-8s${NC}\n" "Phase" "Runs" "PASS" "FIXABLE" "FAIL" "Avg Time" "Retries"
    printf "  %-15s %-10s %-8s %-8s %-8s %-10s %-8s\n" "───────────────" "──────────" "────────" "────────" "────────" "──────────" "────────"

    for phase in requirements design implement test review; do
        local pc pp pf pfx pdsum pr
        pc=$(cat "${tmpdir}/${phase}_count" 2>/dev/null || echo "0")
        if [ "$pc" -eq 0 ]; then continue; fi
        pp=$(cat "${tmpdir}/${phase}_pass" 2>/dev/null || echo "0")
        pfx=$(cat "${tmpdir}/${phase}_fixable" 2>/dev/null || echo "0")
        pf=$(cat "${tmpdir}/${phase}_fail" 2>/dev/null || echo "0")
        pdsum=$(cat "${tmpdir}/${phase}_duration_sum" 2>/dev/null || echo "0")
        pr=$(cat "${tmpdir}/${phase}_retries" 2>/dev/null || echo "0")
        local pavg=$((pdsum / pc))

        printf "  %-15s %-10s ${GREEN}%-8s${NC} ${YELLOW}%-8s${NC} ${RED}%-8s${NC} %-10s %-8s\n" \
            "$phase" "$pc" "$pp" "$pfx" "$pf" "$(format_duration $pavg)" "$pr"
    done

    # Retry-heavy phases (improvement targets)
    echo ""
    echo -e "  ${BOLD}Improvement Targets (high retry phases):${NC}"
    local found_target=false
    for phase in requirements design implement test review; do
        local pr
        pr=$(cat "${tmpdir}/${phase}_retries" 2>/dev/null || echo "0")
        local pc
        pc=$(cat "${tmpdir}/${phase}_count" 2>/dev/null || echo "0")
        if [ "$pc" -gt 0 ] && [ "$pr" -gt 0 ]; then
            local retry_rate=$((pr * 100 / pc))
            if [ "$retry_rate" -gt 30 ]; then
                echo -e "  ${YELLOW}→ ${phase}${NC}: ${pr} retries across ${pc} runs (${retry_rate}% retry rate)"
                found_target=true
            fi
        fi
    done
    if [ "$found_target" = "false" ]; then
        echo -e "  ${GREEN}No high-retry phases detected${NC}"
    fi

    echo ""
    echo -e "${DIM}  Data source: ${metrics_file}${NC}"
    echo ""
}

main "$@"
