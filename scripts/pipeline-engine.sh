#!/bin/bash
# pipeline-engine.sh - Closed-loop quality pipeline for ai4dev
#
# Runs phases sequentially, validates artifacts with phase-contracts,
# runs quality gates, and auto-retries fixable failures up to MAX_RETRIES.
#
# Usage:
#   bash scripts/pipeline-engine.sh <feature> [options]
#   bash scripts/pipeline-engine.sh --dry-run test-feature
#
# Options:
#   --dry-run       Simulate without executing phases
#   --auto          Auto-approve all prompts
#   --lang=LANG     Output language (ja|en, default: ja)
#   --max-retries=N Max auto-fix retries per phase (default: 3)
#   --phases=LIST   Comma-separated phase list (default: requirements,design,implement,test,review)
#   --report        Generate quality report after completion

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="${PWD}"

# Load libraries
# shellcheck source=lib/phase-contracts.sh
source "${SCRIPT_DIR}/lib/phase-contracts.sh"
# shellcheck source=lib/quality-gates.sh
source "${SCRIPT_DIR}/lib/quality-gates.sh"

# Load knowledge loop if available
if [ -f "${SCRIPT_DIR}/lib/knowledge-loop.sh" ]; then
    # shellcheck source=lib/knowledge-loop.sh
    source "${SCRIPT_DIR}/lib/knowledge-loop.sh"
fi

# Load artifact cache if available
if [ -f "${SCRIPT_DIR}/lib/artifact-cache.sh" ]; then
    # shellcheck source=lib/artifact-cache.sh
    source "${SCRIPT_DIR}/lib/artifact-cache.sh"
fi

# ── Configuration ───────────────────────────────────────────────────

MAX_RETRIES=3
DRY_RUN=false
AUTO_APPROVE=false
LANG_FLAG="ja"
GENERATE_REPORT=false
NO_CACHE=false
PHASES="requirements,design,implement,test,review"
AUTOFIX_BUDGET="${AUTOFIX_BUDGET:-300}"  # Total seconds allowed for auto_fix
AUTOFIX_SPENT=0                          # Time spent so far
CACHE_HITS=0                             # Number of phases skipped via cache
ESCALATE_GITHUB=false                    # Auto-create GitHub Issue on FIXABLE exhaust

# ── Colors ──────────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ── Logging ─────────────────────────────────────────────────────────

log_header()  { echo -e "\n${BOLD}${CYAN}━━━ $1 ━━━${NC}"; }
log_phase()   { echo -e "${BOLD}[${1}]${NC} ${CYAN}${2}${NC} ${PURPLE}(${3})${NC}"; }
log_info()    { echo -e "  ${CYAN}→${NC} $1"; }
log_success() { echo -e "  ${GREEN}✓${NC} $1"; }
log_warn()    { echo -e "  ${YELLOW}⚠${NC} $1"; }
log_error()   { echo -e "  ${RED}✗${NC} $1"; }
log_dim()     { echo -e "  ${DIM}$1${NC}"; }

# ── Tracking ────────────────────────────────────────────────────────

# Associative-array-like tracking via indexed arrays
# (bash 3 compat - no declare -A)
REPORT_PHASES=()
REPORT_RESULTS=()     # PASS / FIXABLE / FAIL / SKIP
REPORT_RETRIES=()     # retry count per phase
REPORT_DURATIONS=()   # seconds per phase
REPORT_DETAILS=()     # gate output
PIPELINE_START=""

record_phase() {
    local idx=${#REPORT_PHASES[@]}
    REPORT_PHASES[$idx]="$1"
    REPORT_RESULTS[$idx]="$2"
    REPORT_RETRIES[$idx]="$3"
    REPORT_DURATIONS[$idx]="$4"
    REPORT_DETAILS[$idx]="$5"
}

format_duration() {
    local s=$1
    if [ "$s" -ge 60 ]; then
        echo "$((s / 60))m $((s % 60))s"
    else
        echo "${s}s"
    fi
}

# ── Phase → AI mapping ─────────────────────────────────────────────

ai_for_phase() {
    case "$1" in
        requirements) echo "Claude" ;;
        design)       echo "Claude" ;;
        implement)    echo "Codex" ;;
        test)         echo "Codex" ;;
        review)       echo "Claude" ;;
        deploy)       echo "Claude" ;;
        *)            echo "Claude" ;;
    esac
}

# ── Run a single phase via project-workflow.sh ──────────────────────
# Delegates to project-workflow.sh --phase-only=N for the actual work.

phase_name_to_number() {
    case "$1" in
        requirements) echo 1 ;;
        design)       echo 2 ;;
        implement)    echo 3 ;;
        test)         echo 4 ;;
        review)       echo 5 ;;
        deploy)       echo 6 ;;
        *)            echo 0 ;;
    esac
}

run_phase() {
    local phase="$1"
    local feature="$2"
    local phase_num
    phase_num=$(phase_name_to_number "$phase")

    if [ "$phase_num" -eq 0 ]; then
        log_error "Unknown phase: $phase"
        return 1
    fi

    local workflow="${SCRIPT_DIR}/project-workflow.sh"
    if [ ! -f "$workflow" ]; then
        log_error "project-workflow.sh not found"
        return 1
    fi

    local flags="--from=${phase_num} --skip="
    # Build skip list: skip everything except the target phase
    local skip_list=""
    for n in 1 2 3 4 5 6; do
        if [ "$n" -ne "$phase_num" ]; then
            skip_list="${skip_list}${skip_list:+,}${n}"
        fi
    done
    flags="--from=1 --skip=${skip_list}"

    if [ "$AUTO_APPROVE" = "true" ]; then
        flags="${flags} --auto"
    fi
    flags="${flags} --lang=${LANG_FLAG}"

    # shellcheck disable=SC2086
    bash "$workflow" "$feature" $flags
}

# ── Auto-fix via Claude CLI (adaptive + budget-managed) ────────────

auto_fix() {
    local phase="$1"
    local feature="$2"
    local gate_output="$3"
    local retry_num="${4:-1}"

    if ! command -v claude &>/dev/null; then
        log_warn "Claude CLI not available, cannot auto-fix"
        return 1
    fi

    # Budget check: stop if we've exceeded the total auto_fix budget
    if [ "$AUTOFIX_SPENT" -ge "$AUTOFIX_BUDGET" ]; then
        log_warn "Auto-fix budget exhausted (${AUTOFIX_SPENT}s/${AUTOFIX_BUDGET}s)"
        return 1
    fi

    # Decreasing timeout per retry: 90s → 60s → 30s
    local timeout_secs=90
    case "$retry_num" in
        1) timeout_secs=90 ;;
        2) timeout_secs=60 ;;
        *) timeout_secs=30 ;;
    esac

    # Don't exceed remaining budget
    local remaining=$((AUTOFIX_BUDGET - AUTOFIX_SPENT))
    if [ "$timeout_secs" -gt "$remaining" ]; then
        timeout_secs="$remaining"
    fi

    if [ "$timeout_secs" -le 0 ]; then
        log_warn "Auto-fix budget exhausted (${AUTOFIX_SPENT}s/${AUTOFIX_BUDGET}s)"
        return 1
    fi

    # Extract detailed error info from ---DETAILS--- section
    local error_details=""
    if echo "$gate_output" | grep -qF -- '---DETAILS---'; then
        error_details=$(echo "$gate_output" | sed -n '/---DETAILS---/,$p' | tail -n +2)
    fi

    # Gather recent changes for context
    local recent_diff
    recent_diff=$(cd "$PROJECT_DIR" && git diff HEAD 2>/dev/null | head -200)
    local changed_files
    changed_files=$(cd "$PROJECT_DIR" && git diff --name-only HEAD 2>/dev/null)

    # Use cached knowledge context (avoid re-computation)
    local knowledge_ctx="${CACHED_KNOWLEDGE_CTX:-}"

    # Adaptive escalation based on retry number
    local escalation_context=""
    local escalation_instruction=""

    if [ "$retry_num" -ge 2 ]; then
        # Retry 2+: Add affected file contents
        local file_contents=""
        if [ -n "$changed_files" ]; then
            file_contents=$(echo "$changed_files" | head -5 | while IFS= read -r f; do
                [ -z "$f" ] && continue
                [ -f "${PROJECT_DIR}/${f}" ] || continue
                echo "--- ${f} ---"
                head -100 "${PROJECT_DIR}/${f}" 2>/dev/null
                echo ""
            done)
        fi
        escalation_context="
Full content of affected files (first 100 lines each):
${file_contents}
"
    fi

    if [ "$retry_num" -ge 3 ]; then
        # Retry 3: Instruct fundamentally different approach + full knowledge
        escalation_instruction="
IMPORTANT: The previous ${retry_num} fix attempts have FAILED. The same approach will not work.
Try a fundamentally different approach to resolve these issues.
Consider: reverting the problematic change, using an alternative API, restructuring the code, or simplifying the implementation.
"
        # Force full knowledge context on retry 3
        if [ -z "$knowledge_ctx" ] && type get_knowledge_context &>/dev/null; then
            knowledge_ctx=$(get_knowledge_context "$PROJECT_DIR" 2>/dev/null || true)
        fi
    fi

    local prompt="The quality gate for the '${phase}' phase reported issues (retry ${retry_num}):

$(echo "$gate_output" | sed '/---DETAILS---/,$d')

${error_details:+Detailed error output:
${error_details}
}
${changed_files:+Changed files:
${changed_files}
}
${recent_diff:+Recent diff (truncated):
${recent_diff}
}
${escalation_context}
${knowledge_ctx:+Past knowledge context:
${knowledge_ctx}
}
${escalation_instruction}
Please fix these issues. Focus only on the reported problems, do not make unrelated changes."

    log_info "Auto-fixing with Claude CLI (retry ${retry_num}, timeout ${timeout_secs}s, budget ${AUTOFIX_SPENT}/${AUTOFIX_BUDGET}s)..."

    local fix_start
    fix_start=$(date +%s)
    local fix_output
    if fix_output=$(timeout "$timeout_secs" claude -p "$prompt" 2>&1); then
        local fix_end
        fix_end=$(date +%s)
        local elapsed=$((fix_end - fix_start))
        AUTOFIX_SPENT=$((AUTOFIX_SPENT + elapsed))
        log_success "Auto-fix applied (${elapsed}s)"
        log_dim "$(echo "$fix_output" | tail -5)"
        return 0
    else
        local fix_end
        fix_end=$(date +%s)
        local elapsed=$((fix_end - fix_start))
        AUTOFIX_SPENT=$((AUTOFIX_SPENT + elapsed))
        log_warn "Auto-fix failed (${elapsed}s)"
        log_dim "$(echo "$fix_output" | tail -5)"
        return 1
    fi
}

# ── GitHub Issue escalation ───────────────────────────────────────

escalate_to_github() {
    local phase="$1"
    local feature="$2"
    local gate_output="$3"

    if ! command -v gh &>/dev/null; then
        log_warn "gh CLI not installed, cannot escalate to GitHub"
        return 1
    fi

    local title="[ai4dev] Auto-fix failed: ${phase} phase for '${feature}'"
    local body
    body=$(cat <<GHEOF
## Pipeline Auto-Fix Failure

**Feature**: ${feature}
**Phase**: ${phase}
**Max retries exhausted**: ${MAX_RETRIES}

### Gate Output
\`\`\`
$(echo "$gate_output" | head -50)
\`\`\`

### Action Required
Manual intervention needed to fix ${phase} phase issues.

---
*Auto-generated by ai4dev pipeline-engine*
GHEOF
)

    local issue_url
    if issue_url=$(gh issue create --title "$title" --body "$body" 2>&1); then
        log_info "GitHub Issue created: ${issue_url}"
        return 0
    else
        log_warn "Failed to create GitHub Issue: ${issue_url}"
        return 1
    fi
}

# ── Quality score computation ──────────────────────────────────────

compute_quality_score() {
    # Computes a weighted quality score 0-100 from pipeline phase results
    # Uses REPORT_PHASES, REPORT_RESULTS, REPORT_RETRIES arrays
    local total_weight=0
    local weighted_sum=0

    for i in "${!REPORT_PHASES[@]}"; do
        local phase="${REPORT_PHASES[$i]}"
        local result="${REPORT_RESULTS[$i]}"
        local retries="${REPORT_RETRIES[$i]}"

        # Skip excluded phases
        if [ "$result" = "SKIP" ]; then
            continue
        fi

        # Phase weights
        local weight=15
        case "$phase" in
            implement) weight=30 ;;
            test)      weight=25 ;;
            requirements|design|review) weight=15 ;;
        esac

        # Base score by result
        local score=0
        case "$result" in
            PASS)    score=100 ;;
            FIXABLE) score=70 ;;
            FAIL)    score=0 ;;
        esac

        # Retry penalty: -5 per retry (floor 0)
        local penalty=$((retries * 5))
        if [ "$penalty" -gt "$score" ]; then
            score=0
        else
            score=$((score - penalty))
        fi

        weighted_sum=$((weighted_sum + score * weight))
        total_weight=$((total_weight + weight))
    done

    if [ "$total_weight" -eq 0 ]; then
        echo "0"
        return
    fi

    echo $((weighted_sum / total_weight))
}

# ── Metrics persistence ────────────────────────────────────────────

persist_metrics() {
    local feature="$1"
    local total_duration="$2"
    local quality_score="$3"

    local metrics_file="${PROJECT_DIR}/.claude/docs/metrics.jsonl"
    mkdir -p "$(dirname "$metrics_file")"

    local timestamp
    timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
    local git_sha
    git_sha=$(cd "$PROJECT_DIR" && git rev-parse --short HEAD 2>/dev/null || echo "unknown")

    # Build phases JSON array via string concat (no jq dependency)
    local phases_json="["
    local first=true
    for i in "${!REPORT_PHASES[@]}"; do
        if [ "$first" = "true" ]; then
            first=false
        else
            phases_json="${phases_json},"
        fi
        phases_json="${phases_json}{\"name\":\"${REPORT_PHASES[$i]}\",\"result\":\"${REPORT_RESULTS[$i]}\",\"retries\":${REPORT_RETRIES[$i]},\"duration\":${REPORT_DURATIONS[$i]}}"
    done
    phases_json="${phases_json}]"

    # Append JSONL line
    printf '{"feature":"%s","timestamp":"%s","git_sha":"%s","total_duration":%s,"quality_score":%s,"phases":%s}\n' \
        "$feature" "$timestamp" "$git_sha" "$total_duration" "$quality_score" "$phases_json" \
        >> "$metrics_file"
}

# ── Quality ratchet ────────────────────────────────────────────────
# Prevents quality regression by comparing against the best previous score.

get_feature_best_score() {
    local feature="$1"
    local metrics_file="${PROJECT_DIR}/.claude/docs/metrics.jsonl"

    if [ ! -f "$metrics_file" ]; then
        echo "0"
        return
    fi

    # Extract quality_score for this feature, find max
    local best=0
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        # Match feature name and extract quality_score
        if echo "$line" | grep -q "\"feature\":\"${feature}\""; then
            local score
            score=$(echo "$line" | grep -oE '"quality_score":[0-9]+' | sed 's/"quality_score"://')
            if [ -n "$score" ] && [ "$score" -gt "$best" ] 2>/dev/null; then
                best="$score"
            fi
        fi
    done < "$metrics_file"

    echo "$best"
}

check_quality_ratchet() {
    local feature="$1"
    local current_score="$2"
    local max_regression="${3:-15}"

    local best_score
    best_score=$(get_feature_best_score "$feature")

    if [ "$best_score" -eq 0 ]; then
        # No previous score, no ratchet to enforce
        return 0
    fi

    local regression=$((best_score - current_score))

    if [ "$regression" -gt "$max_regression" ]; then
        log_error "Quality ratchet BLOCKED: score ${current_score}/100 (previous best: ${best_score}, regression: ${regression} > ${max_regression} allowed)"
        return 1
    fi

    if [ "$regression" -gt 0 ]; then
        log_warn "Quality regression: ${current_score}/100 (previous best: ${best_score}, regression: ${regression})"
    fi

    return 0
}

# ── Main pipeline loop ──────────────────────────────────────────────

run_pipeline() {
    local feature="$1"

    PIPELINE_START=$(date +%s)

    log_header "Pipeline: ${feature}"
    echo ""

    # Cache knowledge context once at pipeline start (Step 5)
    export CACHED_KNOWLEDGE_CTX=""
    if type get_knowledge_context &>/dev/null; then
        CACHED_KNOWLEDGE_CTX=$(get_knowledge_context "$PROJECT_DIR" 2>/dev/null || true)
        if [ -n "$CACHED_KNOWLEDGE_CTX" ]; then
            log_dim "Knowledge context cached ($(echo "$CACHED_KNOWLEDGE_CTX" | wc -c | tr -d ' ') bytes)"
        fi
    fi

    # Parse feature slug
    local feature_slug
    if echo "$feature" | grep -q '[^a-zA-Z0-9 -]'; then
        feature_slug=$(echo "$feature" | sed 's/ /-/g')
    else
        feature_slug=$(echo "$feature" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')
    fi

    IFS=',' read -ra phase_list <<< "$PHASES"

    local failed=false

    # Trap to clean up phase file on exit
    local phase_file="${PROJECT_DIR}/.claude/.pipeline_phase"
    mkdir -p "$(dirname "$phase_file")"
    trap 'rm -f "${PROJECT_DIR}/.claude/.pipeline_phase"' EXIT

    for phase in "${phase_list[@]}"; do
        local ai
        ai=$(ai_for_phase "$phase")
        local phase_start
        phase_start=$(date +%s)

        # Write current phase for agent-router.sh (Signal 1)
        echo "$phase" > "$phase_file"

        echo ""
        log_phase "$phase" "Starting..." "$ai"

        if [ "$DRY_RUN" = "true" ]; then
            log_dim "[DRY-RUN] skipping execution"
            local phase_end
            phase_end=$(date +%s)
            record_phase "$phase" "SKIP" 0 $((phase_end - phase_start)) "dry-run"
            continue
        fi

        # 0. Cache check: skip phase if inputs haven't changed
        if [ "$NO_CACHE" != "true" ] && type compute_cache_key &>/dev/null; then
            local cache_key
            cache_key=$(compute_cache_key "$phase" "$feature_slug" "$CACHED_KNOWLEDGE_CTX")
            if cache_hit "$phase" "$feature_slug" "$cache_key"; then
                log_dim "[CACHE HIT] Skipping phase (inputs unchanged)"
                CACHE_HITS=$((CACHE_HITS + 1))
                local phase_end
                phase_end=$(date +%s)
                record_phase "$phase" "PASS" 0 $((phase_end - phase_start)) "cache-hit"
                continue
            fi
        fi

        # 1. Run the phase
        if ! run_phase "$phase" "$feature"; then
            log_error "Phase execution failed"
            local phase_end
            phase_end=$(date +%s)
            record_phase "$phase" "FAIL" 0 $((phase_end - phase_start)) "execution error"
            failed=true
            break
        fi

        # 2. Validate artifact contract
        local contract_out
        contract_out=$(validate_phase "$phase" "$feature_slug" "$PROJECT_DIR" 2>&1) || true
        local contract_ok=$?

        if [ $contract_ok -ne 0 ]; then
            log_warn "Contract: ${contract_out}"
        else
            log_success "Contract: ${contract_out}"
        fi

        # 3. Run quality gate
        local gate_out
        gate_out=$(gate_for_phase "$phase" "$feature_slug" "$PROJECT_DIR" 2>&1) || true
        local gate_exit=$?

        local retries=0

        # 4. Retry loop for FIXABLE results (with adaptive escalation + budget)
        while [ $gate_exit -eq $GATE_FIXABLE ] && [ $retries -lt $MAX_RETRIES ]; do
            retries=$((retries + 1))
            log_warn "Gate: ${gate_out} (retry ${retries}/${MAX_RETRIES})"

            if auto_fix "$phase" "$feature" "$gate_out" "$retries"; then
                # Re-run gate after fix
                gate_out=$(gate_for_phase "$phase" "$feature_slug" "$PROJECT_DIR" 2>&1) || true
                gate_exit=$?
            else
                break
            fi
        done

        local phase_end
        phase_end=$(date +%s)
        local duration=$((phase_end - phase_start))

        # 5. Record result
        if [ $gate_exit -eq $GATE_PASS ]; then
            log_success "Gate: $(echo "$gate_out" | sed '/---DETAILS---/,$d')"
            record_phase "$phase" "PASS" "$retries" "$duration" "$gate_out"

            # Record cache on PASS
            if [ "$NO_CACHE" != "true" ] && type cache_record &>/dev/null; then
                local cache_key
                cache_key=$(compute_cache_key "$phase" "$feature_slug" "$CACHED_KNOWLEDGE_CTX")
                cache_record "$phase" "$feature_slug" "$cache_key"
            fi
        elif [ $gate_exit -eq $GATE_FIXABLE ]; then
            log_warn "Gate: $(echo "$gate_out" | sed '/---DETAILS---/,$d') (exhausted retries)"
            record_phase "$phase" "FIXABLE" "$retries" "$duration" "$gate_out"
            # Escalate to GitHub Issue if enabled
            if [ "$ESCALATE_GITHUB" = "true" ]; then
                escalate_to_github "$phase" "$feature" "$gate_out" || true
            fi
            # Continue to next phase but flag
        else
            log_error "Gate: $(echo "$gate_out" | sed '/---DETAILS---/,$d')"
            record_phase "$phase" "FAIL" "$retries" "$duration" "$gate_out"
            log_error "Pipeline stopped at '${phase}' phase"
            failed=true
            break
        fi

        # 6. Knowledge loop: auto-accumulate patterns after review phase
        if [ "$phase" = "review" ] && type update_review_patterns &>/dev/null; then
            update_review_patterns "$PROJECT_DIR" 2>/dev/null || true
            log_dim "Review patterns accumulated"
        fi
    done

    # Clean up phase file
    rm -f "$phase_file"

    local pipeline_end
    pipeline_end=$(date +%s)
    local total_duration=$((pipeline_end - PIPELINE_START))

    # Compute quality score
    local quality_score
    quality_score=$(compute_quality_score)

    # Quality ratchet: check for unacceptable regression
    if [ "$failed" != "true" ] && [ "$DRY_RUN" != "true" ]; then
        if ! check_quality_ratchet "$feature" "$quality_score"; then
            failed=true
        fi
    fi

    # Summary
    echo ""
    log_header "Pipeline Summary"
    echo ""
    printf "  ${BOLD}%-15s %-10s %-8s %-10s${NC}\n" "Phase" "Result" "Retries" "Duration"
    printf "  %-15s %-10s %-8s %-10s\n" "───────────────" "──────────" "────────" "──────────"

    for i in "${!REPORT_PHASES[@]}"; do
        local color="$NC"
        case "${REPORT_RESULTS[$i]}" in
            PASS) color="$GREEN" ;;
            FIXABLE) color="$YELLOW" ;;
            FAIL) color="$RED" ;;
            SKIP) color="$DIM" ;;
        esac
        printf "  %-15s ${color}%-10s${NC} %-8s %-10s\n" \
            "${REPORT_PHASES[$i]}" \
            "${REPORT_RESULTS[$i]}" \
            "${REPORT_RETRIES[$i]}" \
            "$(format_duration "${REPORT_DURATIONS[$i]}")"
    done

    echo ""
    echo -e "  ${BOLD}Total:${NC} $(format_duration $total_duration)"

    # Display quality score with color
    local score_color="$GREEN"
    if [ "$quality_score" -lt 50 ]; then
        score_color="$RED"
    elif [ "$quality_score" -lt 80 ]; then
        score_color="$YELLOW"
    fi
    echo -e "  ${BOLD}Quality Score:${NC} ${score_color}${quality_score}/100${NC}"

    # Speed improvement summary
    local total_phases=${#phase_list[@]}
    if [ "$CACHE_HITS" -gt 0 ] && [ "$total_phases" -gt 0 ]; then
        echo ""
        echo -e "  ${BOLD}Cache hits:${NC}  ${CACHE_HITS}/${total_phases} phases skipped"
        # Estimate speed gain: assume cached phases save ~60s each
        local estimated_saved=$((CACHE_HITS * 60))
        if [ "$total_duration" -gt 0 ]; then
            local full_estimate=$((total_duration + estimated_saved))
            local speed_gain_x10=$((full_estimate * 10 / total_duration))
            local speed_whole=$((speed_gain_x10 / 10))
            local speed_frac=$((speed_gain_x10 % 10))
            echo -e "  ${BOLD}Speed gain:${NC}  ~${speed_whole}.${speed_frac}x faster (estimated)"
        fi
    fi

    # Competitor comparison
    echo ""
    echo -e "  ${DIM}vs Cursor:   No pipeline, no cache, no quality ratchet${NC}"
    echo -e "  ${DIM}vs Copilot:  No multi-AI routing, no auto-fix loop${NC}"
    echo -e "  ${DIM}vs Devin:    \$500/mo vs \$0 (Codex) + usage-based${NC}"
    echo ""

    if [ "$failed" = "true" ]; then
        log_error "Pipeline FAILED"
        echo ""
        # Persist metrics even on failure (Step 12)
        persist_metrics "$feature" "$total_duration" "$quality_score"
        return 1
    else
        log_success "Pipeline PASSED"
        echo ""
    fi

    # Persist metrics (Step 12)
    persist_metrics "$feature" "$total_duration" "$quality_score"

    # Generate report if requested
    if [ "$GENERATE_REPORT" = "true" ]; then
        if [ -f "${SCRIPT_DIR}/quality-report.sh" ]; then
            bash "${SCRIPT_DIR}/quality-report.sh" "$feature" "$feature_slug" "$PROJECT_DIR" \
                "$total_duration" "${REPORT_PHASES[*]}" "${REPORT_RESULTS[*]}" \
                "${REPORT_RETRIES[*]}" "${REPORT_DURATIONS[*]}"
        fi
    fi

    return 0
}

# ── CLI ─────────────────────────────────────────────────────────────

show_help() {
    cat << 'EOF'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Pipeline Engine - ai4dev Quality Pipeline
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Usage:
  pipeline-engine.sh <feature> [options]

Options:
  --dry-run            Simulate without executing
  --auto               Auto-approve all prompts
  --no-cache           Disable artifact cache (force re-run all phases)
  --lang=LANG          Output language (ja|en)
  --max-retries=N      Max auto-fix retries (default: 3)
  --phases=LIST        Phases to run (default: requirements,design,implement,test,review)
  --autofix-budget=N   Total seconds for auto-fix (default: 300)
  --escalate-to-github Auto-create GitHub Issue on FIXABLE retry exhaust
  --report             Generate quality report
  --help               Show this help

Examples:
  pipeline-engine.sh "user-auth"
  pipeline-engine.sh --dry-run test-feature
  pipeline-engine.sh "search" --auto --report
  pipeline-engine.sh "api" --phases=implement,test --max-retries=2

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
}

main() {
    local feature=""

    for arg in "$@"; do
        case "$arg" in
            --help|-h) show_help; exit 0 ;;
        esac
    done

    if [ $# -lt 1 ]; then
        show_help
        exit 0
    fi

    # Parse arguments
    for arg in "$@"; do
        case "$arg" in
            --dry-run)        DRY_RUN=true ;;
            --auto)           AUTO_APPROVE=true ;;
            --report)         GENERATE_REPORT=true ;;
            --no-cache)       NO_CACHE=true ;;
            --lang=*)         LANG_FLAG="${arg#--lang=}" ;;
            --max-retries=*)  MAX_RETRIES="${arg#--max-retries=}" ;;
            --phases=*)       PHASES="${arg#--phases=}" ;;
            --autofix-budget=*) AUTOFIX_BUDGET="${arg#--autofix-budget=}" ;;
            --escalate-to-github) ESCALATE_GITHUB=true ;;
            --help|-h)        ;; # already handled
            -*)               log_warn "Unknown option: $arg" ;;
            *)
                if [ -z "$feature" ]; then
                    feature="$arg"
                fi
                ;;
        esac
    done

    if [ -z "$feature" ]; then
        log_error "Feature name required"
        show_help
        exit 1
    fi

    run_pipeline "$feature"
}

main "$@"
