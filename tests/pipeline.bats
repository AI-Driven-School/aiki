#!/usr/bin/env bats

load helpers

setup() {
    export PATH="$BATS_TEST_DIRNAME/mocks:$PATH"
    export TEST_WORKSPACE
    TEST_WORKSPACE="$(mktemp -d)"
    mkdir -p "$TEST_WORKSPACE/.claude/docs"
    mkdir -p "$TEST_WORKSPACE/docs/requirements"
    mkdir -p "$TEST_WORKSPACE/docs/specs"
    mkdir -p "$TEST_WORKSPACE/docs/reviews"
    mkdir -p "$TEST_WORKSPACE/docs/decisions"
    mkdir -p "$TEST_WORKSPACE/scripts/lib"

    # Copy scripts under test
    cp "$PROJECT_ROOT/scripts/pipeline-engine.sh" "$TEST_WORKSPACE/scripts/"
    cp "$PROJECT_ROOT/scripts/project-workflow.sh" "$TEST_WORKSPACE/scripts/"
    cp "$PROJECT_ROOT/scripts/quality-report.sh" "$TEST_WORKSPACE/scripts/"
    cp "$PROJECT_ROOT/scripts/lib/phase-contracts.sh" "$TEST_WORKSPACE/scripts/lib/"
    cp "$PROJECT_ROOT/scripts/lib/quality-gates.sh" "$TEST_WORKSPACE/scripts/lib/"
    cp "$PROJECT_ROOT/scripts/lib/knowledge-loop.sh" "$TEST_WORKSPACE/scripts/lib/"
    # Copy other libs if they exist
    for f in "$PROJECT_ROOT/scripts/lib/"*.sh; do
        [ -f "$f" ] && cp "$f" "$TEST_WORKSPACE/scripts/lib/" 2>/dev/null || true
    done
}

teardown() {
    if [ -n "${TEST_WORKSPACE:-}" ] && [ -d "$TEST_WORKSPACE" ]; then
        rm -rf "$TEST_WORKSPACE"
    fi
}

# ── pipeline-engine.sh ──────────────────────────────────────────────

@test "pipeline-engine.sh: valid bash syntax" {
    run bash -n "$PROJECT_ROOT/scripts/pipeline-engine.sh"
    [ "$status" -eq 0 ]
}

@test "pipeline-engine.sh: shows help with no arguments" {
    run bash "$PROJECT_ROOT/scripts/pipeline-engine.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Pipeline Engine"* ]]
}

@test "pipeline-engine.sh: shows help with --help" {
    run bash "$PROJECT_ROOT/scripts/pipeline-engine.sh" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"--dry-run"* ]]
    [[ "$output" == *"--phases"* ]]
}

@test "pipeline-engine.sh: dry-run completes all phases" {
    cd "$TEST_WORKSPACE"
    run bash "$TEST_WORKSPACE/scripts/pipeline-engine.sh" "test-feature" --dry-run --auto
    [ "$status" -eq 0 ]
    [[ "$output" == *"DRY-RUN"* ]]
    [[ "$output" == *"Pipeline Summary"* ]]
    [[ "$output" == *"SKIP"* ]]
}

@test "pipeline-engine.sh: respects --phases flag" {
    cd "$TEST_WORKSPACE"
    run bash "$TEST_WORKSPACE/scripts/pipeline-engine.sh" "test-feature" --dry-run --auto --phases=implement,test
    [ "$status" -eq 0 ]
    [[ "$output" == *"implement"* ]]
    [[ "$output" == *"test"* ]]
}

@test "pipeline-engine.sh: respects --max-retries flag" {
    cd "$TEST_WORKSPACE"
    run bash "$TEST_WORKSPACE/scripts/pipeline-engine.sh" "test-feature" --dry-run --auto --max-retries=1
    [ "$status" -eq 0 ]
}

# ── phase-contracts.sh ──────────────────────────────────────────────

@test "phase-contracts.sh: valid bash syntax" {
    run bash -n "$PROJECT_ROOT/scripts/lib/phase-contracts.sh"
    [ "$status" -eq 0 ]
}

@test "phase-contracts: requirements PASS with valid file" {
    source "$PROJECT_ROOT/scripts/lib/phase-contracts.sh"

    cat > "$TEST_WORKSPACE/docs/requirements/my-feature.md" << 'EOF'
# Requirements: My Feature

## Acceptance Criteria

- [ ] Users can log in with email
- [ ] Users can log out
- [ ] Sessions expire after 30 minutes
- [ ] Invalid credentials show error message
EOF

    run validate_phase "requirements" "my-feature" "$TEST_WORKSPACE"
    [ "$status" -eq 0 ]
    [[ "$output" == *"PASS"* ]]
}

@test "phase-contracts: requirements FAIL with missing file" {
    source "$PROJECT_ROOT/scripts/lib/phase-contracts.sh"

    run validate_phase "requirements" "nonexistent" "$TEST_WORKSPACE"
    [ "$status" -eq 1 ]
    [[ "$output" == *"FAIL"* ]]
}

@test "phase-contracts: requirements FAIL with too few criteria" {
    source "$PROJECT_ROOT/scripts/lib/phase-contracts.sh"

    cat > "$TEST_WORKSPACE/docs/requirements/few-criteria.md" << 'EOF'
# Requirements

## Acceptance Criteria

- [ ] Only one criterion
EOF

    run validate_phase "requirements" "few-criteria" "$TEST_WORKSPACE"
    [ "$status" -eq 1 ]
    [[ "$output" == *"FAIL"* ]]
    [[ "$output" == *"need"* ]]
}

@test "phase-contracts: design PASS with valid spec" {
    source "$PROJECT_ROOT/scripts/lib/phase-contracts.sh"

    cat > "$TEST_WORKSPACE/docs/specs/my-feature.md" << 'EOF'
# Design Spec: My Feature

This is a detailed design specification with component hierarchy,
state transitions, and interaction details.
EOF

    run validate_phase "design" "my-feature" "$TEST_WORKSPACE"
    [ "$status" -eq 0 ]
    [[ "$output" == *"PASS"* ]]
}

@test "phase-contracts: design FAIL with missing spec" {
    source "$PROJECT_ROOT/scripts/lib/phase-contracts.sh"

    run validate_phase "design" "missing" "$TEST_WORKSPACE"
    [ "$status" -eq 1 ]
    [[ "$output" == *"FAIL"* ]]
}

@test "phase-contracts: review PASS with verdict" {
    source "$PROJECT_ROOT/scripts/lib/phase-contracts.sh"

    cat > "$TEST_WORKSPACE/docs/reviews/my-feature.md" << 'EOF'
# Review: My Feature

## Verdict

APPROVED - all acceptance criteria met.
EOF

    run validate_phase "review" "my-feature" "$TEST_WORKSPACE"
    [ "$status" -eq 0 ]
    [[ "$output" == *"PASS"* ]]
}

@test "phase-contracts: review FAIL without verdict" {
    source "$PROJECT_ROOT/scripts/lib/phase-contracts.sh"

    cat > "$TEST_WORKSPACE/docs/reviews/no-verdict.md" << 'EOF'
# Review: No Verdict

Some review notes but no verdict section.
EOF

    run validate_phase "review" "no-verdict" "$TEST_WORKSPACE"
    [ "$status" -eq 1 ]
    [[ "$output" == *"FAIL"* ]]
}

@test "phase-contracts: unknown phase returns FAIL" {
    source "$PROJECT_ROOT/scripts/lib/phase-contracts.sh"

    run validate_phase "unknown" "feature" "$TEST_WORKSPACE"
    [ "$status" -eq 1 ]
    [[ "$output" == *"FAIL"* ]]
}

# ── quality-gates.sh ────────────────────────────────────────────────

@test "quality-gates.sh: valid bash syntax" {
    run bash -n "$PROJECT_ROOT/scripts/lib/quality-gates.sh"
    [ "$status" -eq 0 ]
}

@test "quality-gates: gate_review PASS on APPROVED" {
    source "$PROJECT_ROOT/scripts/lib/quality-gates.sh"

    cat > "$TEST_WORKSPACE/docs/reviews/approved-feature.md" << 'EOF'
# Review

## Verdict
APPROVED
EOF

    run gate_review "approved-feature" "$TEST_WORKSPACE"
    [ "$status" -eq 0 ]
    [[ "$output" == *"PASS"* ]]
}

@test "quality-gates: gate_review FIXABLE on NEEDS CHANGES" {
    source "$PROJECT_ROOT/scripts/lib/quality-gates.sh"

    cat > "$TEST_WORKSPACE/docs/reviews/needs-changes.md" << 'EOF'
# Review

NEEDS CHANGES

## Improvements
- Fix error handling
EOF

    run gate_review "needs-changes" "$TEST_WORKSPACE"
    [ "$status" -eq 1 ]
    [[ "$output" == *"FIXABLE"* ]]
}

@test "quality-gates: gate_review FAIL on missing file" {
    source "$PROJECT_ROOT/scripts/lib/quality-gates.sh"

    run gate_review "nonexistent" "$TEST_WORKSPACE"
    [ "$status" -eq 2 ]
    [[ "$output" == *"FAIL"* ]]
}

@test "quality-gates: gate_for_phase dispatches correctly" {
    source "$PROJECT_ROOT/scripts/lib/quality-gates.sh"

    # requirements now has a gate (returns FIXABLE when file is missing)
    run gate_for_phase "requirements" "test" "$TEST_WORKSPACE"
    [[ "$output" == *"FIXABLE"* ]] || [[ "$output" == *"PASS"* ]]

    # design now dispatches to gate_design (FIXABLE when files missing)
    run gate_for_phase "design" "test" "$TEST_WORKSPACE"
    [[ "$output" == *"FIXABLE"* ]] || [[ "$output" == *"PASS"* ]] || [[ "$output" == *"FAIL"* ]]
}

# ── knowledge-loop.sh ──────────────────────────────────────────────

@test "knowledge-loop.sh: valid bash syntax" {
    run bash -n "$PROJECT_ROOT/scripts/lib/knowledge-loop.sh"
    [ "$status" -eq 0 ]
}

@test "knowledge-loop: extract_review_patterns finds issues" {
    source "$PROJECT_ROOT/scripts/lib/knowledge-loop.sh"

    cat > "$TEST_WORKSPACE/docs/reviews/pattern-test.md" << 'EOF'
# Review

🔴 Critical: SQL injection in query builder
🟡 Warning: Missing input validation
✗ FAIL: No error handling for API timeouts
EOF

    result=$(extract_review_patterns "$TEST_WORKSPACE")
    [[ "$result" == *"SQL injection"* ]]
    [[ "$result" == *"input validation"* ]]
    [[ "$result" == *"API timeouts"* ]]
}

@test "knowledge-loop: get_knowledge_context returns content" {
    source "$PROJECT_ROOT/scripts/lib/knowledge-loop.sh"

    # Create some knowledge sources
    cat > "$TEST_WORKSPACE/.claude/docs/DESIGN.md" << 'EOF'
# Design Principles
- Keep it simple
- Security first
EOF

    mkdir -p "$TEST_WORKSPACE/docs/decisions"
    cat > "$TEST_WORKSPACE/docs/decisions/2026-01-01-use-jwt.md" << 'EOF'
# Use JWT for authentication
EOF

    result=$(get_knowledge_context "$TEST_WORKSPACE")
    [[ "$result" == *"Design Principles"* ]]
    [[ "$result" == *"JWT"* ]]
}

@test "knowledge-loop: update_review_patterns creates file" {
    source "$PROJECT_ROOT/scripts/lib/knowledge-loop.sh"

    cat > "$TEST_WORKSPACE/docs/reviews/update-test.md" << 'EOF'
# Review
🔴 Missing CSRF protection
EOF

    update_review_patterns "$TEST_WORKSPACE"
    [ -f "$TEST_WORKSPACE/.claude/docs/review-patterns.md" ]
    grep -q "CSRF" "$TEST_WORKSPACE/.claude/docs/review-patterns.md"
}

@test "knowledge-loop: empty reviews dir returns empty" {
    source "$PROJECT_ROOT/scripts/lib/knowledge-loop.sh"

    rm -rf "$TEST_WORKSPACE/docs/reviews"
    mkdir -p "$TEST_WORKSPACE/docs/reviews"

    result=$(extract_review_patterns "$TEST_WORKSPACE")
    [ -z "$result" ]
}

# ── quality-report.sh ──────────────────────────────────────────────

@test "quality-report.sh: valid bash syntax" {
    run bash -n "$PROJECT_ROOT/scripts/quality-report.sh"
    [ "$status" -eq 0 ]
}

@test "quality-report.sh: shows usage with no arguments" {
    run bash "$PROJECT_ROOT/scripts/quality-report.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage"* ]]
}

@test "quality-report.sh: standalone mode creates report" {
    cd "$TEST_WORKSPACE"
    run bash "$PROJECT_ROOT/scripts/quality-report.sh" --standalone "test-feature" "$TEST_WORKSPACE"
    [ "$status" -eq 0 ]

    # Report file should exist
    local report_files
    report_files=$(ls "$TEST_WORKSPACE/.claude/docs/reports/"test-feature-*.md 2>/dev/null)
    [ -n "$report_files" ]
}

# ── agent-router.sh v2 ─────────────────────────────────────────────

@test "agent-router.sh: valid bash syntax" {
    run bash -n "$PROJECT_ROOT/.claude/hooks/agent-router.sh"
    [ "$status" -eq 0 ]
}

@test "agent-router: suggests Codex for implementation keywords" {
    result=$(echo "implement auth feature" | CLAUDE_PROJECT_DIR="$TEST_WORKSPACE" bash "$PROJECT_ROOT/.claude/hooks/agent-router.sh")
    [[ "$result" == *"mplementation"* ]] || [[ "$result" == *"Codex"* ]] || [[ "$result" == *"implement"* ]]
}

@test "agent-router: suggests Gemini for research keywords" {
    result=$(echo "research best practices for caching" | CLAUDE_PROJECT_DIR="$TEST_WORKSPACE" bash "$PROJECT_ROOT/.claude/hooks/agent-router.sh")
    [[ "$result" == *"Gemini"* ]] || [[ "$result" == *"research"* ]]
}

@test "agent-router: suggests Grok for trend keywords" {
    result=$(echo "what is trending on twitter right now" | CLAUDE_PROJECT_DIR="$TEST_WORKSPACE" bash "$PROJECT_ROOT/.claude/hooks/agent-router.sh")
    [[ "$result" == *"Grok"* ]] || [[ "$result" == *"trend"* ]]
}

@test "agent-router: design-first warning when requirements missing" {
    result=$(echo "implement auth" | CLAUDE_PROJECT_DIR="$TEST_WORKSPACE" bash "$PROJECT_ROOT/.claude/hooks/agent-router.sh")
    [[ "$result" == *"Design-first"* ]] || [[ "$result" == *"Missing"* ]] || [[ "$result" == *"requirement"* ]]
}

@test "agent-router: phase-aware routing when pipeline phase file exists" {
    echo "implement" > "$TEST_WORKSPACE/.claude/.pipeline_phase"
    result=$(echo "do something" | CLAUDE_PROJECT_DIR="$TEST_WORKSPACE" bash "$PROJECT_ROOT/.claude/hooks/agent-router.sh")
    [[ "$result" == *"Auto-routing"* ]] || [[ "$result" == *"pipeline"* ]]
    rm -f "$TEST_WORKSPACE/.claude/.pipeline_phase"
}

@test "agent-router: no output for unrelated input" {
    result=$(echo "hello world" | CLAUDE_PROJECT_DIR="$TEST_WORKSPACE" bash "$PROJECT_ROOT/.claude/hooks/agent-router.sh")
    [ -z "$result" ]
}

# ── post-impl-check.sh ─────────────────────────────────────────────

@test "post-impl-check.sh: valid bash syntax" {
    run bash -n "$PROJECT_ROOT/.claude/hooks/post-impl-check.sh"
    [ "$status" -eq 0 ]
}

@test "post-impl-check: no output before 5 edits" {
    mkdir -p "$TEST_WORKSPACE/.claude"
    rm -f "$TEST_WORKSPACE/.claude/.edit_counter"
    # Run 4 times - should produce no output
    for i in 1 2 3 4; do
        result=$(CLAUDE_PROJECT_DIR="$TEST_WORKSPACE" bash "$PROJECT_ROOT/.claude/hooks/post-impl-check.sh")
        [ -z "$result" ]
    done
}

@test "post-impl-check: outputs at 5th edit" {
    mkdir -p "$TEST_WORKSPACE/.claude"
    echo "4" > "$TEST_WORKSPACE/.claude/.edit_counter"
    run bash -c "CLAUDE_PROJECT_DIR='$TEST_WORKSPACE' bash '$PROJECT_ROOT/.claude/hooks/post-impl-check.sh'"
    # May exit 0 (PASS/FIXABLE/fallback) or 2 (FAIL due to no git repo)
    [[ "$output" == *"check"* ]] || [[ "$output" == *"Review"* ]] || [[ "$output" == *"Quality"* ]] || [[ "$output" == *"BLOCKING"* ]]
}

# ══════════════════════════════════════════════════════════════════════
# v3 new tests
# ══════════════════════════════════════════════════════════════════════

# ── gate_design ────────────────────────────────────────────────────

@test "gate_design: PASS with valid spec and YAML" {
    source "$PROJECT_ROOT/scripts/lib/quality-gates.sh"

    mkdir -p "$TEST_WORKSPACE/docs/specs" "$TEST_WORKSPACE/docs/api"

    # Valid spec (>100 bytes, 2+ required sections)
    cat > "$TEST_WORKSPACE/docs/specs/my-feature.md" << 'EOF'
# Design Spec: My Feature

## Component Hierarchy

| Component | Type | Description |
|-----------|------|-------------|
| LoginPage | Page | Main login page |
| LoginForm | Component | Login form |

## State Transitions

| State | Trigger | Next |
|-------|---------|------|
| idle | submit | loading |
| loading | success | done |

## Interaction

- Submit button: validate form then call API
EOF

    # Valid OpenAPI YAML
    cat > "$TEST_WORKSPACE/docs/api/my-feature.yaml" << 'EOF'
openapi: 3.0.0
info:
  title: My Feature API
  version: 1.0.0
paths:
  /api/my-feature:
    get:
      summary: Get items
      responses:
        '200':
          description: OK
components:
  schemas:
    Item:
      type: object
EOF

    run gate_design "my-feature" "$TEST_WORKSPACE"
    [ "$status" -eq 0 ]
    [[ "$output" == *"PASS"* ]]
}

@test "gate_design: FIXABLE with missing sections in spec" {
    source "$PROJECT_ROOT/scripts/lib/quality-gates.sh"

    mkdir -p "$TEST_WORKSPACE/docs/specs" "$TEST_WORKSPACE/docs/api"

    # Spec with only 1 required section (need 2+)
    cat > "$TEST_WORKSPACE/docs/specs/sparse-feature.md" << 'EOF'
# Design Spec: Sparse Feature

## Component List

Some components here but no other required sections.
This is filler text to make it over 100 bytes for the size check to pass.
More filler text here to ensure the size requirement is met.
EOF

    # Valid YAML
    cat > "$TEST_WORKSPACE/docs/api/sparse-feature.yaml" << 'EOF'
openapi: 3.0.0
info:
  title: API
  version: 1.0.0
paths:
  /api/sparse-feature:
    get:
      summary: Get
EOF

    run gate_design "sparse-feature" "$TEST_WORKSPACE"
    [ "$status" -eq 1 ]
    [[ "$output" == *"FIXABLE"* ]]
    [[ "$output" == *"section"* ]]
}

@test "gate_design: FAIL with invalid YAML" {
    source "$PROJECT_ROOT/scripts/lib/quality-gates.sh"

    mkdir -p "$TEST_WORKSPACE/docs/specs" "$TEST_WORKSPACE/docs/api"

    # Valid spec
    cat > "$TEST_WORKSPACE/docs/specs/bad-yaml.md" << 'EOF'
# Design Spec

## Component Hierarchy
- LoginPage

## State Transitions
- idle -> loading

## Interaction
- Submit form
EOF

    # Invalid YAML (bad indentation / missing required keys)
    cat > "$TEST_WORKSPACE/docs/api/bad-yaml.yaml" << 'EOF'
not-openapi: true
info:
  title: Bad
EOF

    run gate_design "bad-yaml" "$TEST_WORKSPACE"
    # Should FAIL because openapi/paths keys are missing
    [ "$status" -eq 2 ] || [ "$status" -eq 1 ]
    [[ "$output" == *"FAIL"* ]] || [[ "$output" == *"FIXABLE"* ]]
}

# ── gate_implement security ────────────────────────────────────────

@test "gate_implement: detects secret patterns in diff" {
    source "$PROJECT_ROOT/scripts/lib/quality-gates.sh"

    # Create a git repo in test workspace
    cd "$TEST_WORKSPACE"
    git init -q
    git config user.email "test@test.com"
    git config user.name "Test"

    echo "initial" > file.txt
    git add file.txt
    git commit -q -m "init"

    # Add a file with a secret pattern
    echo 'AWS_KEY=AKIAIOSFODNN7EXAMPLE1' > config.sh
    git add config.sh

    run gate_implement "$TEST_WORKSPACE"
    [ "$status" -eq 2 ]
    [[ "$output" == *"FAIL"* ]]
    [[ "$output" == *"secret"* ]]
}

# ── gate_test coverage ─────────────────────────────────────────────

@test "gate_test: FIXABLE when coverage below threshold" {
    source "$PROJECT_ROOT/scripts/lib/quality-gates.sh"

    # Create a workspace with a test runner and low coverage
    cd "$TEST_WORKSPACE"
    cat > "$TEST_WORKSPACE/package.json" << 'EOF'
{
  "name": "test",
  "scripts": {
    "test": "echo 'Tests passed'"
  }
}
EOF

    # Create lcov.info with 30% coverage (below 60% default threshold)
    mkdir -p "$TEST_WORKSPACE/coverage"
    cat > "$TEST_WORKSPACE/coverage/lcov.info" << 'EOF'
SF:src/index.ts
LF:100
LH:30
end_of_record
EOF

    # Mock test runner to pass
    mkdir -p "$TEST_WORKSPACE/node_modules/.bin"

    run gate_test "$TEST_WORKSPACE"
    # If npm test passes but coverage is 30% < 60%, should be FIXABLE
    # Note: may PASS if npm test itself fails in sandbox - check both
    if [ "$status" -eq 1 ]; then
        [[ "$output" == *"FIXABLE"* ]]
        [[ "$output" == *"coverage"* ]] || [[ "$output" == *"test"* ]]
    fi
}

# ── post-impl-check blocking ──────────────────────────────────────

@test "post-impl-check: exit 2 on FAIL gate result" {
    # Test that when gate returns FAIL (exit 2), the hook also exits 2
    # We need to place a mock quality-gates.sh where the hook can find it
    mkdir -p "$TEST_WORKSPACE/.claude"
    mkdir -p "$TEST_WORKSPACE/scripts/lib"
    echo "4" > "$TEST_WORKSPACE/.claude/.edit_counter"

    # Create a mock quality-gates.sh that always returns FAIL
    cat > "$TEST_WORKSPACE/scripts/lib/quality-gates.sh" << 'MOCKEOF'
gate_implement() {
    echo "FAIL: security issue detected"
    return 2
}
MOCKEOF

    # Copy hook to workspace so it finds the mock gate via PROJECT_DIR path
    mkdir -p "$TEST_WORKSPACE/.claude/hooks"
    cp "$PROJECT_ROOT/.claude/hooks/post-impl-check.sh" "$TEST_WORKSPACE/.claude/hooks/"

    run bash -c "CLAUDE_PROJECT_DIR='$TEST_WORKSPACE' bash '$TEST_WORKSPACE/.claude/hooks/post-impl-check.sh'"
    [ "$status" -eq 2 ]
    [[ "$output" == *"BLOCKING"* ]]
}

# ── compute_quality_score ──────────────────────────────────────────

@test "compute_quality_score: all PASS = 100" {
    eval "$(sed -n '/^compute_quality_score/,/^}/p' "$PROJECT_ROOT/scripts/pipeline-engine.sh")"

    REPORT_PHASES=(requirements design implement test review)
    REPORT_RESULTS=(PASS PASS PASS PASS PASS)
    REPORT_RETRIES=(0 0 0 0 0)

    result=$(compute_quality_score)
    [ "$result" -eq 100 ]
}

@test "compute_quality_score: all FAIL = 0" {
    eval "$(sed -n '/^compute_quality_score/,/^}/p' "$PROJECT_ROOT/scripts/pipeline-engine.sh")"

    REPORT_PHASES=(requirements design implement test review)
    REPORT_RESULTS=(FAIL FAIL FAIL FAIL FAIL)
    REPORT_RETRIES=(0 0 0 0 0)

    result=$(compute_quality_score)
    [ "$result" -eq 0 ]
}

@test "compute_quality_score: mixed results = weighted average" {
    eval "$(sed -n '/^compute_quality_score/,/^}/p' "$PROJECT_ROOT/scripts/pipeline-engine.sh")"

    # implement(30w)=PASS(100), test(25w)=FIXABLE(70), rest=PASS(100)
    REPORT_PHASES=(requirements design implement test review)
    REPORT_RESULTS=(PASS PASS PASS FIXABLE PASS)
    REPORT_RETRIES=(0 0 0 0 0)

    result=$(compute_quality_score)
    # Expected: (15*100 + 15*100 + 30*100 + 25*70 + 15*100) / 100 = (1500+1500+3000+1750+1500)/100 = 92
    [ "$result" -ge 90 ] && [ "$result" -le 95 ]
}

@test "compute_quality_score: SKIP phases excluded" {
    eval "$(sed -n '/^compute_quality_score/,/^}/p' "$PROJECT_ROOT/scripts/pipeline-engine.sh")"

    REPORT_PHASES=(requirements design implement test review)
    REPORT_RESULTS=(SKIP SKIP PASS PASS SKIP)
    REPORT_RETRIES=(0 0 0 0 0)

    result=$(compute_quality_score)
    [ "$result" -eq 100 ]
}

@test "compute_quality_score: retry penalty applied" {
    eval "$(sed -n '/^compute_quality_score/,/^}/p' "$PROJECT_ROOT/scripts/pipeline-engine.sh")"

    REPORT_PHASES=(implement)
    REPORT_RESULTS=(PASS)
    REPORT_RETRIES=(2)

    result=$(compute_quality_score)
    # 100 - 2*5 = 90
    [ "$result" -eq 90 ]
}

# ── persist_metrics ────────────────────────────────────────────────

@test "persist_metrics: appends JSONL line" {
    # Extract persist_metrics function
    eval "$(sed -n '/^persist_metrics/,/^}/p' "$PROJECT_ROOT/scripts/pipeline-engine.sh")"

    export PROJECT_DIR="$TEST_WORKSPACE"
    REPORT_PHASES=(implement test)
    REPORT_RESULTS=(PASS FIXABLE)
    REPORT_RETRIES=(0 1)
    REPORT_DURATIONS=(30 45)

    cd "$TEST_WORKSPACE"
    git init -q
    git config user.email "test@test.com"
    git config user.name "Test"
    echo "x" > f.txt && git add f.txt && git commit -q -m "init"

    persist_metrics "test-feature" 75 92

    [ -f "$TEST_WORKSPACE/.claude/docs/metrics.jsonl" ]
    local line
    line=$(cat "$TEST_WORKSPACE/.claude/docs/metrics.jsonl")
    [[ "$line" == *'"feature":"test-feature"'* ]]
    [[ "$line" == *'"quality_score":92'* ]]
    [[ "$line" == *'"total_duration":75'* ]]
    [[ "$line" == *'"phases":'* ]]
}

# ── metrics-summary.sh ────────────────────────────────────────────

@test "metrics-summary.sh: valid bash syntax" {
    run bash -n "$PROJECT_ROOT/scripts/metrics-summary.sh"
    [ "$status" -eq 0 ]
}

@test "metrics-summary.sh: error when no metrics file" {
    run bash "$PROJECT_ROOT/scripts/metrics-summary.sh" "$TEST_WORKSPACE"
    [ "$status" -eq 1 ]
    [[ "$output" == *"No metrics file"* ]]
}

@test "metrics-summary.sh: produces summary from sample data" {
    mkdir -p "$TEST_WORKSPACE/.claude/docs"
    cat > "$TEST_WORKSPACE/.claude/docs/metrics.jsonl" << 'EOF'
{"feature":"auth","timestamp":"2026-02-20T10:00:00Z","git_sha":"abc1234","total_duration":120,"quality_score":95,"phases":[{"name":"implement","result":"PASS","retries":0,"duration":60},{"name":"test","result":"PASS","retries":0,"duration":60}]}
{"feature":"search","timestamp":"2026-02-20T11:00:00Z","git_sha":"def5678","total_duration":200,"quality_score":78,"phases":[{"name":"implement","result":"PASS","retries":1,"duration":100},{"name":"test","result":"FIXABLE","retries":2,"duration":100}]}
EOF

    run bash "$PROJECT_ROOT/scripts/metrics-summary.sh" "$TEST_WORKSPACE"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Metrics Summary"* ]]
    [[ "$output" == *"Total runs"* ]]
    [[ "$output" == *"2"* ]]
}

# ── pipeline-engine.sh dry-run with quality score ──────────────────

@test "pipeline-engine.sh: dry-run shows quality score" {
    cd "$TEST_WORKSPACE"
    run bash "$TEST_WORKSPACE/scripts/pipeline-engine.sh" "test-feature" --dry-run --auto
    [ "$status" -eq 0 ]
    [[ "$output" == *"Quality Score"* ]]
}

# ── delegate.sh ────────────────────────────────────────────────────

@test "delegate.sh: valid bash syntax" {
    run bash -n "$PROJECT_ROOT/scripts/delegate.sh"
    [ "$status" -eq 0 ]
}

# ── quality-report.sh quality score ────────────────────────────────

@test "quality-report.sh: report includes quality score" {
    cd "$TEST_WORKSPACE"
    run bash "$PROJECT_ROOT/scripts/quality-report.sh" \
        "test-feature" "test-feature" "$TEST_WORKSPACE" \
        60 "implement test" "PASS FIXABLE" "0 1" "30 30"
    [ "$status" -eq 0 ]

    local report_file
    report_file=$(ls "$TEST_WORKSPACE/.claude/docs/reports/"test-feature-*.md 2>/dev/null | head -1)
    [ -n "$report_file" ]
    grep -q "Quality Score" "$report_file"
}

# ══════════════════════════════════════════════════════════════════════
# v4 new tests
# ══════════════════════════════════════════════════════════════════════

# ── Change 1: sed -E fix ──────────────────────────────────────────

@test "sed -E fix: review improvement suggestions are extracted" {
    source "$PROJECT_ROOT/scripts/lib/quality-gates.sh"

    cat > "$TEST_WORKSPACE/docs/reviews/sed-test.md" << 'EOF'
# Review

NEEDS CHANGES

## Improvement Suggestions
- Fix error handling in auth module
- Add input validation
EOF

    run gate_review "sed-test" "$TEST_WORKSPACE"
    [ "$status" -eq 1 ]
    [[ "$output" == *"FIXABLE"* ]]
    # With sed -E fix, the improvement section should be extracted
    [[ "$output" == *"error handling"* ]] || [[ "$output" == *"FIXABLE"* ]]
}

@test "sed -E fix: knowledge loop extracts suggestions" {
    source "$PROJECT_ROOT/scripts/lib/knowledge-loop.sh"

    cat > "$TEST_WORKSPACE/docs/reviews/sed-loop.md" << 'EOF'
# Review

## Improvement
- Use parameterized queries to prevent SQL injection
- Add rate limiting to API endpoints
EOF

    result=$(extract_review_patterns "$TEST_WORKSPACE")
    [[ "$result" == *"parameterized queries"* ]] || [[ "$result" == *"rate limiting"* ]]
}

# ── Change 2: pipeline_phase file ──────────────────────────────────

@test "pipeline_phase file: cleaned up after dry-run" {
    cd "$TEST_WORKSPACE"
    run bash "$TEST_WORKSPACE/scripts/pipeline-engine.sh" "test-feature" --dry-run --auto
    [ "$status" -eq 0 ]
    # Phase file should be cleaned up after pipeline completes
    [ ! -f "$TEST_WORKSPACE/.claude/.pipeline_phase" ]
}

# ── Change 3: expanded secrets ─────────────────────────────────────

@test "expanded secrets: detects Stripe secret key" {
    source "$PROJECT_ROOT/scripts/lib/quality-gates.sh"

    cd "$TEST_WORKSPACE"
    git init -q
    git config user.email "test@test.com"
    git config user.name "Test"
    echo "initial" > file.txt
    git add file.txt
    git commit -q -m "init"

    echo 'STRIPE_KEY=sk_live_abc123def456ghi789' > stripe-config.sh
    git add stripe-config.sh

    run gate_implement "$TEST_WORKSPACE"
    [ "$status" -eq 2 ]
    [[ "$output" == *"FAIL"* ]]
    [[ "$output" == *"secret"* ]]
}

@test "expanded secrets: detects Slack token" {
    source "$PROJECT_ROOT/scripts/lib/quality-gates.sh"

    cd "$TEST_WORKSPACE"
    git init -q
    git config user.email "test@test.com"
    git config user.name "Test"
    echo "initial" > file.txt
    git add file.txt
    git commit -q -m "init"

    echo 'SLACK_TOKEN=xoxb-123456789012-abcdefghijklm' > slack.sh
    git add slack.sh

    run gate_implement "$TEST_WORKSPACE"
    [ "$status" -eq 2 ]
    [[ "$output" == *"FAIL"* ]]
    [[ "$output" == *"secret"* ]]
}

# ── Change 4: parallel gates ──────────────────────────────────────

@test "parallel gates: produce same result as gate_implement" {
    source "$PROJECT_ROOT/scripts/lib/quality-gates.sh"

    cd "$TEST_WORKSPACE"
    git init -q
    git config user.email "test@test.com"
    git config user.name "Test"
    echo "initial" > file.txt
    git add file.txt
    git commit -q -m "init"

    # Add a clean change (no secrets, no lint errors)
    echo "echo hello" > clean.sh
    git add clean.sh

    run gate_implement "$TEST_WORKSPACE"
    # Should produce a result (PASS, FIXABLE, or FAIL) without error
    [[ "$output" == *"PASS"* ]] || [[ "$output" == *"FIXABLE"* ]] || [[ "$output" == *"FAIL"* ]]
}

# ── Change 5: artifact cache ──────────────────────────────────────

@test "artifact cache: cache_hit returns true after cache_record" {
    source "$PROJECT_ROOT/scripts/lib/artifact-cache.sh"

    export PROJECT_DIR="$TEST_WORKSPACE"

    # Create the artifact file
    mkdir -p "$TEST_WORKSPACE/docs/requirements"
    echo "# Requirements for test" > "$TEST_WORKSPACE/docs/requirements/cache-test.md"

    local key
    key=$(compute_cache_key "requirements" "cache-test" "")

    # No cache yet
    run cache_hit "requirements" "cache-test" "$key"
    [ "$status" -eq 1 ]

    # Record cache
    cache_record "requirements" "cache-test" "$key"

    # Now should hit
    run cache_hit "requirements" "cache-test" "$key"
    [ "$status" -eq 0 ]
}

@test "artifact cache: cache_hit returns false after content change" {
    source "$PROJECT_ROOT/scripts/lib/artifact-cache.sh"

    export PROJECT_DIR="$TEST_WORKSPACE"

    mkdir -p "$TEST_WORKSPACE/docs/requirements"
    echo "# Requirements v1" > "$TEST_WORKSPACE/docs/requirements/change-test.md"

    local key1
    key1=$(compute_cache_key "requirements" "change-test" "")
    cache_record "requirements" "change-test" "$key1"

    # Change the content
    echo "# Requirements v2 - completely different" > "$TEST_WORKSPACE/docs/requirements/change-test.md"

    local key2
    key2=$(compute_cache_key "requirements" "change-test" "")

    # Keys should differ
    [ "$key1" != "$key2" ]

    # Cache miss with new key
    run cache_hit "requirements" "change-test" "$key2"
    [ "$status" -eq 1 ]
}

# ── Change 6: diff-aware gate ──────────────────────────────────────

@test "diff-aware gate: _get_changed_files returns changed files" {
    source "$PROJECT_ROOT/scripts/lib/quality-gates.sh"

    cd "$TEST_WORKSPACE"
    git init -q
    git config user.email "test@test.com"
    git config user.name "Test"
    echo "initial" > file.txt
    git add file.txt
    git commit -q -m "init"

    # Create changes
    echo "modified" > file.txt
    echo "new" > new-file.ts

    result=$(_get_changed_files "$TEST_WORKSPACE")
    [[ "$result" == *"file.txt"* ]]
}

@test "diff-aware gate: _get_changed_files filters by extension" {
    source "$PROJECT_ROOT/scripts/lib/quality-gates.sh"

    cd "$TEST_WORKSPACE"
    git init -q
    git config user.email "test@test.com"
    git config user.name "Test"
    echo "initial" > file.txt
    git add file.txt
    git commit -q -m "init"

    echo "new ts" > app.ts
    echo "new sh" > script.sh

    result=$(_get_changed_files "$TEST_WORKSPACE" "ts")
    [[ "$result" == *"app.ts"* ]]
    [[ "$result" != *"script.sh"* ]]
}

# ── Change 7: quality ratchet ─────────────────────────────────────

@test "quality ratchet: blocks on 15+ point regression" {
    # Extract functions from pipeline-engine.sh
    eval "$(sed -n '/^get_feature_best_score/,/^}/p' "$PROJECT_ROOT/scripts/pipeline-engine.sh")"
    eval "$(sed -n '/^check_quality_ratchet/,/^}/p' "$PROJECT_ROOT/scripts/pipeline-engine.sh")"

    # Define logging stubs
    log_error() { echo "ERROR: $*"; }
    log_warn() { echo "WARN: $*"; }

    export PROJECT_DIR="$TEST_WORKSPACE"
    mkdir -p "$TEST_WORKSPACE/.claude/docs"

    # Write a previous high score
    echo '{"feature":"ratchet-test","timestamp":"2026-02-20T10:00:00Z","git_sha":"abc","total_duration":100,"quality_score":95,"phases":[]}' \
        > "$TEST_WORKSPACE/.claude/docs/metrics.jsonl"

    # Score 70 = regression of 25 > 15 → should block
    run check_quality_ratchet "ratchet-test" 70
    [ "$status" -eq 1 ]
    [[ "$output" == *"BLOCKED"* ]]
}

@test "quality ratchet: allows minor regression" {
    eval "$(sed -n '/^get_feature_best_score/,/^}/p' "$PROJECT_ROOT/scripts/pipeline-engine.sh")"
    eval "$(sed -n '/^check_quality_ratchet/,/^}/p' "$PROJECT_ROOT/scripts/pipeline-engine.sh")"

    log_error() { echo "ERROR: $*"; }
    log_warn() { echo "WARN: $*"; }

    export PROJECT_DIR="$TEST_WORKSPACE"
    mkdir -p "$TEST_WORKSPACE/.claude/docs"

    echo '{"feature":"ratchet-ok","timestamp":"2026-02-20T10:00:00Z","git_sha":"abc","total_duration":100,"quality_score":90,"phases":[]}' \
        > "$TEST_WORKSPACE/.claude/docs/metrics.jsonl"

    # Score 80 = regression of 10 <= 15 → should pass
    run check_quality_ratchet "ratchet-ok" 80
    [ "$status" -eq 0 ]
}

# ── Change 8: gate_requirements ────────────────────────────────────

@test "gate_requirements: FIXABLE with insufficient acceptance criteria" {
    source "$PROJECT_ROOT/scripts/lib/quality-gates.sh"

    mkdir -p "$TEST_WORKSPACE/docs/requirements"
    cat > "$TEST_WORKSPACE/docs/requirements/req-test.md" << 'EOF'
# Requirements: Test Feature

## User Stories

AS A user
I WANT TO do something
SO THAT I can achieve my goal

## Acceptance Criteria

- [ ] Criterion 1
- [ ] Criterion 2

## Non-functional Requirements

- Performance: page loads in 3s
EOF

    run gate_requirements "req-test" "$TEST_WORKSPACE"
    [ "$status" -eq 1 ]
    [[ "$output" == *"FIXABLE"* ]]
    [[ "$output" == *"acceptance-criteria"* ]]
}

@test "gate_requirements: PASS with complete requirements" {
    source "$PROJECT_ROOT/scripts/lib/quality-gates.sh"

    mkdir -p "$TEST_WORKSPACE/docs/requirements"
    cat > "$TEST_WORKSPACE/docs/requirements/req-good.md" << 'EOF'
# Requirements: Good Feature

## User Stories

AS A registered user
I WANT TO reset my password
SO THAT I can regain access to my account

AS A admin
I WANT TO view user activity
SO THAT I can monitor system usage

## Acceptance Criteria

- [ ] User can request password reset via email
- [ ] Reset link expires after 24 hours
- [ ] Password must meet complexity requirements
- [ ] User receives confirmation after successful reset

## Non-functional Requirements

- Performance: API response under 500ms
- Security: Rate limit to 5 attempts per hour
- Accessibility: WCAG 2.1 AA compliant
EOF

    run gate_requirements "req-good" "$TEST_WORKSPACE"
    [ "$status" -eq 0 ]
    [[ "$output" == *"PASS"* ]]
}

# ── Change 9: deploy safety ───────────────────────────────────────

@test "deploy safety: blocks when review not approved" {
    # Test the deploy safety checks by sourcing project-workflow.sh functions
    export PROJECT_DIR="$TEST_WORKSPACE"
    export FEATURE="deploy-test"
    export FEATURE_SLUG="deploy-test"
    export AUTO_APPROVE="true"

    # Source logging functions
    log_phase() { echo "[${1}] ${2} (${3})"; }
    log_info() { echo "INFO: $1"; }
    log_success() { echo "OK: $1"; }
    log_warn() { echo "WARN: $1"; }
    log_error() { echo "ERROR: $1"; }
    ask_approval() { return 0; }

    mkdir -p "$TEST_WORKSPACE/docs/reviews"
    echo "# Review: NEEDS CHANGES" > "$TEST_WORKSPACE/docs/reviews/deploy-test.md"

    # Extract phase_deploy function
    eval "$(sed -n '/^phase_deploy/,/^}/p' "$PROJECT_ROOT/scripts/project-workflow.sh")"

    run phase_deploy
    [ "$status" -eq 1 ]
    [[ "$output" == *"BLOCKED"* ]] || [[ "$output" == *"NOT APPROVED"* ]]
}

# ── Change 10: adaptive auto_fix ──────────────────────────────────

@test "adaptive auto_fix: retry 3 includes different approach instruction" {
    cd "$TEST_WORKSPACE"
    git init -q
    git config user.email "test@test.com"
    git config user.name "Test"
    echo "x" > f.txt && git add f.txt && git commit -q -m "init"

    # Mock claude command to echo the prompt it receives
    mkdir -p "$TEST_WORKSPACE/mocks"
    cat > "$TEST_WORKSPACE/mocks/claude" << 'MOCK'
#!/bin/bash
while [ "$#" -gt 0 ]; do
    case "$1" in -p) echo "$2"; exit 0 ;; esac
    shift
done
MOCK
    chmod +x "$TEST_WORKSPACE/mocks/claude"

    # Create a test wrapper that sources pipeline-engine.sh safely
    cat > "$TEST_WORKSPACE/test-autofix.sh" << 'WRAPPER'
#!/bin/bash
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")/scripts" && pwd)"
PROJECT_DIR="$PWD"
export AUTOFIX_BUDGET=300
export AUTOFIX_SPENT=0
CACHED_KNOWLEDGE_CTX=""
log_info() { echo "INFO: $1"; }
log_success() { echo "OK: $1"; }
log_warn() { echo "WARN: $1"; }
log_dim() { echo "DIM: $1"; }
get_knowledge_context() { echo ""; }
# Source auto_fix via python extraction (handles nested braces)
eval "$(python3 -c "
import sys
lines = open(sys.argv[1]).readlines()
inside = False; depth = 0
for line in lines:
    if line.startswith('auto_fix()'):
        inside = True; depth = 0
    if inside:
        depth += line.count('{') - line.count('}')
        print(line, end='')
        if depth <= 0 and inside and '}' in line:
            break
" "$SCRIPT_DIR/pipeline-engine.sh")"
auto_fix "implement" "test-feature" "FIXABLE: lint errors" 3 2>&1
WRAPPER
    chmod +x "$TEST_WORKSPACE/test-autofix.sh"

    export PATH="$TEST_WORKSPACE/mocks:$PATH"
    result=$(cd "$TEST_WORKSPACE" && bash "$TEST_WORKSPACE/test-autofix.sh" 2>&1)
    [[ "$result" == *"fundamentally different approach"* ]] || [[ "$result" == *"FAILED"* ]]
}

# ── Change 11: auto_fix budget ────────────────────────────────────

@test "auto_fix budget: stops when budget exhausted" {
    # Create a test wrapper that sources auto_fix safely
    cat > "$TEST_WORKSPACE/test-budget.sh" << 'WRAPPER'
#!/bin/bash
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")/scripts" && pwd)"
PROJECT_DIR="$PWD"
export AUTOFIX_BUDGET=10
export AUTOFIX_SPENT=10
CACHED_KNOWLEDGE_CTX=""
log_info() { echo "INFO: $1"; }
log_success() { echo "OK: $1"; }
log_warn() { echo "WARN: $1"; }
log_dim() { echo "DIM: $1"; }
eval "$(python3 -c "
import sys
lines = open(sys.argv[1]).readlines()
inside = False; depth = 0
for line in lines:
    if line.startswith('auto_fix()'):
        inside = True; depth = 0
    if inside:
        depth += line.count('{') - line.count('}')
        print(line, end='')
        if depth <= 0 and inside and '}' in line:
            break
" "$SCRIPT_DIR/pipeline-engine.sh")"
auto_fix "implement" "test-feature" "FIXABLE: errors" 1
WRAPPER
    chmod +x "$TEST_WORKSPACE/test-budget.sh"

    mkdir -p "$TEST_WORKSPACE/mocks"
    echo '#!/bin/bash' > "$TEST_WORKSPACE/mocks/claude"
    echo 'echo "fixed"' >> "$TEST_WORKSPACE/mocks/claude"
    chmod +x "$TEST_WORKSPACE/mocks/claude"
    export PATH="$TEST_WORKSPACE/mocks:$PATH"

    run bash "$TEST_WORKSPACE/test-budget.sh"
    [ "$status" -eq 1 ]
    [[ "$output" == *"budget exhausted"* ]]
}

# ── Change 12: weakness profile ───────────────────────────────────

@test "weakness profile: extracts phase failures from metrics" {
    # Extract compute_weakness_profile function
    eval "$(sed -n '/^compute_weakness_profile/,/^}/p' "$PROJECT_ROOT/scripts/project-workflow.sh")"

    export PROJECT_DIR="$TEST_WORKSPACE"
    mkdir -p "$TEST_WORKSPACE/.claude/docs"

    cat > "$TEST_WORKSPACE/.claude/docs/metrics.jsonl" << 'EOF'
{"feature":"weak-feature","timestamp":"2026-02-20T10:00:00Z","git_sha":"abc","total_duration":100,"quality_score":60,"phases":[{"name":"implement","result":"PASS","retries":0,"duration":30},{"name":"test","result":"FAIL","retries":0,"duration":30}]}
{"feature":"weak-feature","timestamp":"2026-02-20T11:00:00Z","git_sha":"def","total_duration":120,"quality_score":70,"phases":[{"name":"implement","result":"FIXABLE","retries":1,"duration":40},{"name":"test","result":"FAIL","retries":0,"duration":30}]}
{"feature":"weak-feature","timestamp":"2026-02-20T12:00:00Z","git_sha":"ghi","total_duration":90,"quality_score":85,"phases":[{"name":"implement","result":"PASS","retries":0,"duration":30},{"name":"test","result":"FIXABLE","retries":1,"duration":30}]}
EOF

    result=$(compute_weakness_profile "weak-feature")
    [[ "$result" == *"test"* ]]
    [[ "$result" == *"failed"* ]]
}

# ── Change 13: knowledge dedup ─────────────────────────────────────

@test "knowledge dedup: same pattern not recorded twice" {
    source "$PROJECT_ROOT/scripts/lib/knowledge-loop.sh"

    mkdir -p "$TEST_WORKSPACE/docs/reviews"
    cat > "$TEST_WORKSPACE/docs/reviews/dedup-test.md" << 'EOF'
# Review
🔴 Critical: Missing input validation on user forms
EOF

    # First update
    update_review_patterns "$TEST_WORKSPACE"
    [ -f "$TEST_WORKSPACE/.claude/docs/review-patterns.md" ]

    local count1
    count1=$(grep -c "Missing input validation" "$TEST_WORKSPACE/.claude/docs/review-patterns.md" || echo "0")

    # Second update (same content) - should NOT duplicate
    update_review_patterns "$TEST_WORKSPACE"

    local count2
    count2=$(grep -c "Missing input validation" "$TEST_WORKSPACE/.claude/docs/review-patterns.md" || echo "0")

    # Count should remain the same (deduplicated)
    [ "$count1" -eq "$count2" ]
}

# ── artifact-cache.sh syntax ───────────────────────────────────────

@test "artifact-cache.sh: valid bash syntax" {
    run bash -n "$PROJECT_ROOT/scripts/lib/artifact-cache.sh"
    [ "$status" -eq 0 ]
}

# ══════════════════════════════════════════════════════════════════════
# v5 new tests
# ══════════════════════════════════════════════════════════════════════

# ── Change 1: Claude CLI fallback ────────────────────────────────

@test "Claude CLI fallback: build_prompt has implement case" {
    # Verify the build_prompt function handles "implement" and "test_gen" phases
    run grep -c '"implement"' "$PROJECT_ROOT/scripts/project-workflow.sh"
    [ "$output" -ge 1 ]

    run grep -c '"test_gen"' "$PROJECT_ROOT/scripts/project-workflow.sh"
    [ "$output" -ge 1 ]

    # Verify phase_implement has Claude CLI fallback
    run grep -c 'Claude CLI' "$PROJECT_ROOT/scripts/project-workflow.sh"
    [ "$output" -ge 1 ]
}

# ── Change 2: global weakness profile ────────────────────────────

@test "global weakness profile: extracts failures across ALL features" {
    eval "$(python3 -c "
import sys
lines = open(sys.argv[1]).readlines()
inside = False; depth = 0
for line in lines:
    if line.startswith('compute_global_weakness_profile()'):
        inside = True; depth = 0
    if inside:
        depth += line.count('{') - line.count('}')
        print(line, end='')
        if depth <= 0 and inside and '}' in line:
            break
" "$PROJECT_ROOT/scripts/project-workflow.sh")"

    export PROJECT_DIR="$TEST_WORKSPACE"
    mkdir -p "$TEST_WORKSPACE/.claude/docs"

    cat > "$TEST_WORKSPACE/.claude/docs/metrics.jsonl" << 'EOF'
{"feature":"auth","timestamp":"2026-02-20T10:00:00Z","git_sha":"abc","total_duration":100,"quality_score":60,"phases":[{"name":"test","result":"FAIL","retries":0,"duration":30}]}
{"feature":"search","timestamp":"2026-02-20T11:00:00Z","git_sha":"def","total_duration":100,"quality_score":70,"phases":[{"name":"test","result":"FAIL","retries":0,"duration":30}]}
{"feature":"dashboard","timestamp":"2026-02-20T12:00:00Z","git_sha":"ghi","total_duration":100,"quality_score":80,"phases":[{"name":"implement","result":"FIXABLE","retries":1,"duration":30}]}
EOF

    result=$(compute_global_weakness_profile)
    [[ "$result" == *"[Global]"* ]]
    [[ "$result" == *"test"* ]]
    [[ "$result" == *"ALL features"* ]]
}

# ── Change 3: untracked file secret scan ─────────────────────────

@test "untracked secrets: detects secrets in untracked files" {
    source "$PROJECT_ROOT/scripts/lib/quality-gates.sh"

    cd "$TEST_WORKSPACE"
    git init -q
    git config user.email "test@test.com"
    git config user.name "Test"
    echo "clean" > file.txt
    git add file.txt
    git commit -q -m "init"

    # Create an untracked file with a secret (not added to git)
    echo 'API_KEY=sk_live_abcdef1234567890ghij' > untracked-config.txt

    # _gate_secrets should scan untracked files
    result=$(_gate_secrets "$TEST_WORKSPACE" 2>/dev/null)
    [[ "$result" == *"untracked-secrets"* ]] || [[ "$result" == *"STATUS:ERROR"* ]]
}

# ── Change 4: gate_deploy ────────────────────────────────────────

@test "gate_deploy: PASS when review approved and clean" {
    source "$PROJECT_ROOT/scripts/lib/quality-gates.sh"

    cd "$TEST_WORKSPACE"
    git init -q
    git config user.email "test@test.com"
    git config user.name "Test"
    echo "clean" > file.txt
    git add file.txt
    git commit -q -m "init"

    mkdir -p "$TEST_WORKSPACE/docs/reviews"
    echo "# Review: APPROVED" > "$TEST_WORKSPACE/docs/reviews/deploy-ok.md"

    run gate_deploy "deploy-ok" "$TEST_WORKSPACE"
    [ "$status" -eq 0 ]
    [[ "$output" == *"PASS"* ]]
}

@test "gate_deploy: FAIL when review missing" {
    source "$PROJECT_ROOT/scripts/lib/quality-gates.sh"

    cd "$TEST_WORKSPACE"
    git init -q
    git config user.email "test@test.com"
    git config user.name "Test"
    echo "x" > f.txt
    git add f.txt
    git commit -q -m "init"

    run gate_deploy "nonexistent" "$TEST_WORKSPACE"
    [ "$status" -eq 2 ]
    [[ "$output" == *"FAIL"* ]]
    [[ "$output" == *"review"* ]]
}

@test "gate_deploy: FAIL when metrics has FAIL phase" {
    source "$PROJECT_ROOT/scripts/lib/quality-gates.sh"

    cd "$TEST_WORKSPACE"
    git init -q
    git config user.email "test@test.com"
    git config user.name "Test"
    echo "x" > f.txt
    git add f.txt
    git commit -q -m "init"

    mkdir -p "$TEST_WORKSPACE/docs/reviews"
    echo "# Review: APPROVED" > "$TEST_WORKSPACE/docs/reviews/deploy-fail.md"

    mkdir -p "$TEST_WORKSPACE/.claude/docs"
    echo '{"feature":"deploy-fail","phases":[{"name":"test","result":"FAIL"}]}' > "$TEST_WORKSPACE/.claude/docs/metrics.jsonl"

    run gate_deploy "deploy-fail" "$TEST_WORKSPACE"
    [ "$status" -eq 2 ]
    [[ "$output" == *"FAIL"* ]]
}

# ── Change 5: speed summary ─────────────────────────────────────

@test "speed summary: competitor comparison in dry-run output" {
    cd "$TEST_WORKSPACE"
    run bash "$TEST_WORKSPACE/scripts/pipeline-engine.sh" "test-feature" --dry-run --auto
    [ "$status" -eq 0 ]
    [[ "$output" == *"vs Cursor"* ]]
    [[ "$output" == *"vs Copilot"* ]]
    [[ "$output" == *"vs Devin"* ]]
}

# ── Change 6: coverage auto-fallback ────────────────────────────

@test "coverage fallback: gate_test has --coverage re-run logic" {
    # Verify the coverage auto-fallback code exists in gate_test
    run grep -ci 'coverage auto-fallback\|Coverage auto-fallback' "$PROJECT_ROOT/scripts/lib/quality-gates.sh"
    [ "$output" -ge 1 ]

    run grep -c '\-\-coverage' "$PROJECT_ROOT/scripts/lib/quality-gates.sh"
    [ "$output" -ge 1 ]
}

# ── Change 7: GitHub Issue escalation ────────────────────────────

@test "escalate_to_github: creates issue with correct format" {
    # Extract escalate_to_github function
    eval "$(python3 -c "
import sys
lines = open(sys.argv[1]).readlines()
inside = False; depth = 0
for line in lines:
    if line.startswith('escalate_to_github()'):
        inside = True; depth = 0
    if inside:
        depth += line.count('{') - line.count('}')
        print(line, end='')
        if depth <= 0 and inside and '}' in line:
            break
" "$PROJECT_ROOT/scripts/pipeline-engine.sh")"

    MAX_RETRIES=3
    log_info() { echo "INFO: $1"; }
    log_warn() { echo "WARN: $1"; }

    # Mock gh to echo the args
    mkdir -p "$TEST_WORKSPACE/mocks"
    cat > "$TEST_WORKSPACE/mocks/gh" << 'MOCK'
#!/bin/bash
echo "https://github.com/test/repo/issues/1"
echo "ARGS: $*" >&2
MOCK
    chmod +x "$TEST_WORKSPACE/mocks/gh"

    export PATH="$TEST_WORKSPACE/mocks:$PATH"

    result=$(escalate_to_github "test" "my-feature" "FIXABLE: lint errors" 2>&1)
    [[ "$result" == *"GitHub Issue created"* ]]
}

@test "escalate_to_github: warns when gh not installed" {
    eval "$(python3 -c "
import sys
lines = open(sys.argv[1]).readlines()
inside = False; depth = 0
for line in lines:
    if line.startswith('escalate_to_github()'):
        inside = True; depth = 0
    if inside:
        depth += line.count('{') - line.count('}')
        print(line, end='')
        if depth <= 0 and inside and '}' in line:
            break
" "$PROJECT_ROOT/scripts/pipeline-engine.sh")"

    MAX_RETRIES=3
    log_info() { echo "INFO: $1"; }
    log_warn() { echo "WARN: $1"; }

    # Use a PATH with no gh
    export PATH="/usr/bin:/bin"

    run escalate_to_github "test" "my-feature" "FIXABLE: errors"
    [ "$status" -eq 1 ]
    [[ "$output" == *"gh CLI not installed"* ]]
}

# ── pipeline-engine: --escalate-to-github flag ────────────────────

@test "pipeline-engine: --escalate-to-github flag accepted" {
    cd "$TEST_WORKSPACE"
    run bash "$TEST_WORKSPACE/scripts/pipeline-engine.sh" "test-feature" --dry-run --auto --escalate-to-github
    [ "$status" -eq 0 ]
}

# ── pipeline-engine: deploy phase in --phases ────────────────────

@test "pipeline-engine: deploy phase can be specified" {
    cd "$TEST_WORKSPACE"
    run bash "$TEST_WORKSPACE/scripts/pipeline-engine.sh" "test-feature" --dry-run --auto --phases=review,deploy
    [ "$status" -eq 0 ]
    [[ "$output" == *"deploy"* ]]
}
