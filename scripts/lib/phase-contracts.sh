#!/bin/bash
# phase-contracts.sh - Phase completion validation
# Each phase has explicit "done" criteria that must be met before proceeding.

# Validate that a phase's artifacts meet the contract.
# Returns: 0 = PASS, 1 = FAIL
# Outputs: human-readable verdict on stdout

validate_phase() {
    local phase="$1"
    local feature_slug="$2"
    local project_dir="${3:-$PWD}"

    case "$phase" in
        requirements) _validate_requirements "$feature_slug" "$project_dir" ;;
        design)       _validate_design       "$feature_slug" "$project_dir" ;;
        implement)    _validate_implement    "$feature_slug" "$project_dir" ;;
        test)         _validate_test         "$feature_slug" "$project_dir" ;;
        review)       _validate_review       "$feature_slug" "$project_dir" ;;
        *)
            echo "FAIL: unknown phase '$phase'"
            return 1
            ;;
    esac
}

# --- requirements ---
# Contract: docs/requirements/{feature}.md exists, contains ## Acceptance Criteria
#           with at least 3 criteria items (lines starting with - [ ] or - *)
_validate_requirements() {
    local slug="$1" dir="$2"
    local file="${dir}/docs/requirements/${slug}.md"

    if [ ! -f "$file" ]; then
        echo "FAIL: requirements file not found: ${file}"
        return 1
    fi

    # Check for acceptance criteria section (case-insensitive, EN or JP)
    if ! grep -qiE '## (Acceptance Criteria|受入条件)' "$file"; then
        echo "FAIL: no '## Acceptance Criteria' section in ${file}"
        return 1
    fi

    # Count criteria items (bullet lines after the section header)
    # Use grep -A to extract lines after the header, then count bullets
    local count
    count=$(grep -iEA 100 '## (Acceptance Criteria|受入条件)' "$file" | grep -c '^- ' || true)
    if [ "$count" -lt 3 ]; then
        echo "FAIL: only ${count} acceptance criteria (need ≥3) in ${file}"
        return 1
    fi

    echo "PASS: requirements validated (${count} criteria)"
    return 0
}

# --- design ---
# Contract: docs/specs/{feature}.md exists and is non-empty
_validate_design() {
    local slug="$1" dir="$2"
    local file="${dir}/docs/specs/${slug}.md"

    if [ ! -f "$file" ]; then
        echo "FAIL: spec file not found: ${file}"
        return 1
    fi

    local size
    size=$(wc -c < "$file" | tr -d ' ')
    if [ "$size" -lt 50 ]; then
        echo "FAIL: spec file too small (${size} bytes)"
        return 1
    fi

    echo "PASS: design spec validated (${size} bytes)"
    return 0
}

# --- implement ---
# Contract: git diff shows changed files (something was actually implemented)
_validate_implement() {
    local slug="$1" dir="$2"

    local changed
    changed=$(cd "$dir" && git diff --name-only HEAD 2>/dev/null | wc -l | tr -d ' ')
    # Also check staged
    local staged
    staged=$(cd "$dir" && git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
    # Also check untracked source files
    local untracked
    untracked=$(cd "$dir" && git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')

    local total=$((changed + staged + untracked))
    if [ "$total" -eq 0 ]; then
        echo "FAIL: no file changes detected"
        return 1
    fi

    echo "PASS: ${total} files changed/added"
    return 0
}

# --- test ---
# Contract: test files exist and test runner exits 0
_validate_test() {
    local slug="$1" dir="$2"

    # Check that at least one test file exists
    local test_files
    test_files=$(find "$dir" -path '*/node_modules' -prune -o \
        \( -name '*.test.*' -o -name '*.spec.*' -o -name 'test_*' -o -name '*_test.*' \) \
        -print 2>/dev/null | head -20)

    if [ -z "$test_files" ]; then
        echo "FAIL: no test files found"
        return 1
    fi

    local count
    count=$(echo "$test_files" | wc -l | tr -d ' ')
    echo "PASS: ${count} test files found"
    return 0
}

# --- review ---
# Contract: docs/reviews/{feature}.md exists and contains ## Verdict
_validate_review() {
    local slug="$1" dir="$2"
    local file="${dir}/docs/reviews/${slug}.md"

    if [ ! -f "$file" ]; then
        echo "FAIL: review file not found: ${file}"
        return 1
    fi

    if ! grep -qiE '## (Verdict|判定|結論)' "$file"; then
        echo "FAIL: no '## Verdict' section in ${file}"
        return 1
    fi

    echo "PASS: review validated"
    return 0
}
