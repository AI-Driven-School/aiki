#!/bin/bash
# quality-gates.sh - Run real tools (lint, typecheck, test) as quality gates
#
# Each gate_* function prints a verdict line and returns:
#   0 = PASS      (all clear)
#   1 = FIXABLE   (errors exist but are auto-fixable)
#   2 = FAIL      (hard failure, needs human)
#
# The verdict line format is:
#   PASS|FIXABLE|FAIL <details>

GATE_PASS=0
GATE_FIXABLE=1
GATE_FAIL=2

# ── Detect project tooling ──────────────────────────────────────────

_detect_package_manager() {
    local dir="$1"
    if [ -f "${dir}/pnpm-lock.yaml" ]; then echo "pnpm"
    elif [ -f "${dir}/yarn.lock" ]; then echo "yarn"
    elif [ -f "${dir}/package-lock.json" ] || [ -f "${dir}/package.json" ]; then echo "npm"
    else echo ""
    fi
}

_has_npm_script() {
    local dir="$1" script="$2"
    [ -f "${dir}/package.json" ] && grep -q "\"${script}\"" "${dir}/package.json" 2>/dev/null
}

_detect_test_runner() {
    local dir="$1"
    if _has_npm_script "$dir" "test"; then echo "npm_test"
    elif [ -f "${dir}/pytest.ini" ] || [ -f "${dir}/pyproject.toml" ] || [ -f "${dir}/setup.cfg" ]; then echo "pytest"
    elif ls "${dir}"/*.go &>/dev/null; then echo "go_test"
    elif ls "${dir}"/tests/*.bats &>/dev/null; then echo "bats"
    else echo ""
    fi
}

# ── Diff-aware helpers ─────────────────────────────────────────────
# Identify changed files to scope lint/typecheck to changed files only.

_get_changed_files() {
    local dir="$1"
    local ext_filter="${2:-}"  # optional extension filter e.g. "ts,tsx,js,jsx"
    local files=""
    files=$(cd "$dir" && {
        git diff --name-only HEAD 2>/dev/null
        git diff --cached --name-only 2>/dev/null
        git ls-files --others --exclude-standard 2>/dev/null
    } | sort -u)

    if [ -n "$ext_filter" ] && [ -n "$files" ]; then
        local filtered=""
        IFS=',' read -ra exts <<< "$ext_filter"
        while IFS= read -r f; do
            [ -z "$f" ] && continue
            for ext in "${exts[@]}"; do
                case "$f" in
                    *."$ext") filtered="${filtered}${f}"$'\n' ;;
                esac
            done
        done <<< "$files"
        echo "$filtered"
    else
        echo "$files"
    fi
}

_has_config_change() {
    local dir="$1"
    local changed
    changed=$(_get_changed_files "$dir")
    echo "$changed" | grep -qE '(tsconfig|\.eslintrc|eslint\.config|package\.json|pyproject\.toml|setup\.cfg)' 2>/dev/null
}

# ── Parallel gate sub-functions ────────────────────────────────────

_gate_lint() {
    local dir="$1"
    local pm="$2"
    local changed_files="$3"

    if [ -n "$pm" ] && _has_npm_script "$dir" "lint"; then
        local lint_out
        # If eslint and only specific files changed (no config change), scope to files
        if [ -n "$changed_files" ] && ! _has_config_change "$dir"; then
            local js_files
            js_files=$(_get_changed_files "$dir" "ts,tsx,js,jsx")
            if [ -n "$js_files" ] && _has_npm_script "$dir" "lint"; then
                # Try file-scoped lint; fallback to full lint
                lint_out=$(cd "$dir" && echo "$js_files" | xargs $pm run lint -- 2>&1) || true
                if [ -z "$lint_out" ]; then
                    lint_out=$(cd "$dir" && $pm run lint 2>&1) || true
                fi
            else
                lint_out=$(cd "$dir" && $pm run lint 2>&1) || true
            fi
        else
            lint_out=$(cd "$dir" && $pm run lint 2>&1) || true
        fi
        local lint_exit=$?
        if [ $lint_exit -ne 0 ] || echo "$lint_out" | grep -qiE 'error|✖'; then
            local lint_errors
            lint_errors=$(echo "$lint_out" | grep -ciE 'error' || true)
            local lint_warnings
            lint_warnings=$(echo "$lint_out" | grep -ciE 'warning' || true)
            echo "STATUS:FIXABLE"
            echo "DETAIL:lint: ${lint_errors} errors, ${lint_warnings} warnings; "
            echo "RAW:[lint]"
            echo "$lint_out" | head -30
        else
            echo "STATUS:CLEAN"
            echo "DETAIL:lint: clean; "
        fi
    elif command -v shellcheck &>/dev/null; then
        local sh_files
        if [ -n "$changed_files" ] && ! _has_config_change "$dir"; then
            sh_files=$(_get_changed_files "$dir" "sh")
        else
            sh_files=$(find "$dir" -maxdepth 3 -name '*.sh' ! -path '*/node_modules/*' 2>/dev/null)
        fi
        if [ -n "$sh_files" ]; then
            local sc_out
            sc_out=$(echo "$sh_files" | xargs shellcheck 2>&1) || true
            if [ -n "$sc_out" ]; then
                local sc_count
                sc_count=$(echo "$sc_out" | grep -c 'SC[0-9]' || true)
                echo "STATUS:FIXABLE"
                echo "DETAIL:shellcheck: ${sc_count} issues; "
                echo "RAW:[shellcheck]"
                echo "$sc_out" | head -30
            else
                echo "STATUS:CLEAN"
                echo "DETAIL:shellcheck: clean; "
            fi
        fi
    fi
}

_gate_typecheck() {
    local dir="$1"
    local changed_files="$2"

    if [ -f "${dir}/tsconfig.json" ] && command -v npx &>/dev/null; then
        local tsc_out
        # tsc --noEmit doesn't support file scoping well, run full unless config changed
        tsc_out=$(cd "$dir" && npx tsc --noEmit 2>&1) || true
        local tsc_exit=$?
        if [ $tsc_exit -ne 0 ]; then
            local tsc_errors
            tsc_errors=$(echo "$tsc_out" | grep -c 'error TS' || true)
            echo "STATUS:ERROR"
            echo "DETAIL:typecheck: ${tsc_errors} errors; "
            echo "RAW:[typecheck]"
            echo "$tsc_out" | head -30
        else
            echo "STATUS:CLEAN"
            echo "DETAIL:typecheck: clean; "
        fi
    elif command -v mypy &>/dev/null && [ -d "${dir}/src" ]; then
        local mypy_out
        mypy_out=$(cd "$dir" && mypy src/ 2>&1) || true
        if echo "$mypy_out" | grep -q 'error:'; then
            local mypy_errors
            mypy_errors=$(echo "$mypy_out" | grep -c 'error:' || true)
            echo "STATUS:ERROR"
            echo "DETAIL:mypy: ${mypy_errors} errors; "
            echo "RAW:[mypy]"
            echo "$mypy_out" | head -30
        else
            echo "STATUS:CLEAN"
            echo "DETAIL:mypy: clean; "
        fi
    fi
}

_gate_audit() {
    local dir="$1"

    if [ -f "${dir}/package.json" ] && command -v npm &>/dev/null; then
        local audit_out
        audit_out=$(cd "$dir" && npm audit --json 2>/dev/null) || true
        if [ -n "$audit_out" ]; then
            local critical_count high_count
            critical_count=$(echo "$audit_out" | grep -c '"severity":"critical"' 2>/dev/null || echo "0")
            high_count=$(echo "$audit_out" | grep -c '"severity":"high"' 2>/dev/null || echo "0")
            if [ "$critical_count" -gt 0 ] || [ "$high_count" -gt 0 ]; then
                echo "STATUS:ERROR"
                echo "DETAIL:npm-audit: ${critical_count} critical, ${high_count} high; "
                echo "RAW:[npm-audit]"
                echo "$audit_out" | head -30
            else
                echo "STATUS:CLEAN"
                echo "DETAIL:npm-audit: clean; "
            fi
        fi
    fi
}

_gate_secrets() {
    local dir="$1"

    # Secret detection in staged/unstaged changes
    local diff_content
    diff_content=$(cd "$dir" && git diff HEAD 2>/dev/null; cd "$dir" && git diff --cached 2>/dev/null)
    if [ -n "$diff_content" ]; then
        local secret_hits
        secret_hits=$(echo "$diff_content" | grep -nE '(AKIA[0-9A-Z]{16}|ghp_[a-zA-Z0-9]{36}|sk-[a-zA-Z0-9]{32,}|BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY|password\s*=\s*['\''"][^'\''"]{8,}|xox[baprs]-[a-zA-Z0-9-]+|sk_live_[a-zA-Z0-9]+|rk_live_[a-zA-Z0-9]+|SG\.[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+|AIza[0-9A-Za-z_-]{35}|eyJ[a-zA-Z0-9_-]+\.eyJ[a-zA-Z0-9_-]+)' 2>/dev/null | head -10)
        if [ -n "$secret_hits" ]; then
            echo "STATUS:ERROR"
            echo "DETAIL:secrets: potential secrets detected; "
            echo "RAW:[secrets]"
            echo "$secret_hits"
        fi
    fi

    # Scan untracked files for secrets (not covered by git diff)
    local untracked_files
    untracked_files=$(cd "$dir" && git ls-files --others --exclude-standard 2>/dev/null)
    if [ -n "$untracked_files" ]; then
        local untracked_secrets=""
        while IFS= read -r ufile; do
            [ -z "$ufile" ] && continue
            [ -f "${dir}/${ufile}" ] || continue
            # Skip binary files and large files (>100KB)
            local fsize
            fsize=$(wc -c < "${dir}/${ufile}" 2>/dev/null | tr -d ' ')
            [ "${fsize:-0}" -gt 102400 ] && continue
            # Check if text file
            if file "${dir}/${ufile}" 2>/dev/null | grep -q text; then
                local uhits
                uhits=$(grep -nE '(AKIA[0-9A-Z]{16}|ghp_[a-zA-Z0-9]{36}|sk-[a-zA-Z0-9]{32,}|BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY|password\s*=\s*['\''"][^'\''"]{8,}|xox[baprs]-[a-zA-Z0-9-]+|sk_live_[a-zA-Z0-9]+|rk_live_[a-zA-Z0-9]+|SG\.[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+|AIza[0-9A-Za-z_-]{35}|eyJ[a-zA-Z0-9_-]+\.eyJ[a-zA-Z0-9_-]+)' "${dir}/${ufile}" 2>/dev/null | head -5)
                if [ -n "$uhits" ]; then
                    untracked_secrets="${untracked_secrets}${ufile}: ${uhits}
"
                fi
            fi
        done <<< "$untracked_files"
        if [ -n "$untracked_secrets" ]; then
            echo "STATUS:ERROR"
            echo "DETAIL:untracked-secrets: secrets in untracked files; "
            echo "RAW:[untracked-secrets]"
            echo "$untracked_secrets"
        fi
    fi

    # Sensitive file check (staged files)
    local staged_files
    staged_files=$(cd "$dir" && git diff --cached --name-only 2>/dev/null)
    if [ -n "$staged_files" ] && type is_sensitive_file &>/dev/null; then
        local sensitive_found=""
        while IFS= read -r sfile; do
            [ -z "$sfile" ] && continue
            if is_sensitive_file "$sfile"; then
                sensitive_found="${sensitive_found}${sfile} "
            fi
        done <<< "$staged_files"
        if [ -n "$sensitive_found" ]; then
            echo "STATUS:ERROR"
            echo "DETAIL:sensitive-files: ${sensitive_found}; "
            echo "RAW:[sensitive-files]"
            echo "Staged sensitive files: ${sensitive_found}"
        fi
    fi
}

# ── gate_implement ──────────────────────────────────────────────────
# Runs lint, typecheck, audit, and secrets in parallel.

gate_implement() {
    local dir="${1:-$PWD}"
    local errors=0
    local fixable=0
    local details=""
    local raw_output=""

    # 1. Check that files actually changed
    local changed
    changed=$(cd "$dir" && git diff --name-only HEAD 2>/dev/null | wc -l | tr -d ' ')
    local staged
    staged=$(cd "$dir" && git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
    local untracked
    untracked=$(cd "$dir" && git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
    local total=$((changed + staged + untracked))

    if [ "$total" -eq 0 ]; then
        echo "FAIL: no file changes detected"
        return $GATE_FAIL
    fi

    local pm
    pm=$(_detect_package_manager "$dir")

    local changed_files
    changed_files=$(_get_changed_files "$dir")

    # 2. Run lint, typecheck, audit, secrets in parallel
    local tmpdir
    tmpdir=$(mktemp -d)

    _gate_lint "$dir" "$pm" "$changed_files" > "${tmpdir}/lint" 2>&1 &
    local pid_lint=$!
    _gate_typecheck "$dir" "$changed_files" > "${tmpdir}/tsc" 2>&1 &
    local pid_tsc=$!
    _gate_audit "$dir" > "${tmpdir}/audit" 2>&1 &
    local pid_audit=$!
    _gate_secrets "$dir" > "${tmpdir}/secrets" 2>&1 &
    local pid_secrets=$!

    wait $pid_lint $pid_tsc $pid_audit $pid_secrets 2>/dev/null || true

    # 3. Aggregate results
    for result_file in "${tmpdir}/lint" "${tmpdir}/tsc" "${tmpdir}/audit" "${tmpdir}/secrets"; do
        [ -f "$result_file" ] || continue
        local content
        content=$(cat "$result_file")
        [ -z "$content" ] && continue

        if echo "$content" | grep -q 'STATUS:ERROR'; then
            errors=1
        fi
        if echo "$content" | grep -q 'STATUS:FIXABLE'; then
            fixable=1
        fi

        local detail_line
        detail_line=$(echo "$content" | grep '^DETAIL:' | sed 's/^DETAIL://')
        [ -n "$detail_line" ] && details="${details}${detail_line}"

        local raw_line
        raw_line=$(echo "$content" | sed -n '/^RAW:/,$p' | sed '1s/^RAW://')
        [ -n "$raw_line" ] && raw_output="${raw_output}${raw_line}
"
    done

    rm -rf "$tmpdir"

    # 4. Ruff (Python linter) - runs inline (fast)
    if command -v ruff &>/dev/null && [ -d "${dir}/src" ]; then
        local ruff_out
        ruff_out=$(cd "$dir" && ruff check src/ 2>&1) || true
        if [ -n "$ruff_out" ] && echo "$ruff_out" | grep -qE '[0-9]+ (error|issue)'; then
            details="${details}ruff: issues found; "
            raw_output="${raw_output}[ruff]
$(echo "$ruff_out" | head -30)
"
            fixable=1
        fi
    fi

    # Verdict (with ---DETAILS--- separator for auto_fix context)
    if [ "$errors" -gt 0 ]; then
        printf "FAIL: %s\n---DETAILS---\n%s" "$details" "$raw_output"
        return $GATE_FAIL
    elif [ "$fixable" -gt 0 ]; then
        printf "FIXABLE: %s\n---DETAILS---\n%s" "$details" "$raw_output"
        return $GATE_FIXABLE
    else
        echo "PASS: ${total} files changed. ${details:-all checks clean}"
        return $GATE_PASS
    fi
}

# ── gate_test ───────────────────────────────────────────────────────
# Detects and runs the project's test suite.

gate_test() {
    local dir="${1:-$PWD}"
    local runner
    runner=$(_detect_test_runner "$dir")

    if [ -z "$runner" ]; then
        echo "PASS: no test runner detected (skipped)"
        return $GATE_PASS
    fi

    local test_out=""
    local test_exit=0

    case "$runner" in
        npm_test)
            local pm
            pm=$(_detect_package_manager "$dir")
            test_out=$(cd "$dir" && $pm test 2>&1) || test_exit=$?
            ;;
        pytest)
            test_out=$(cd "$dir" && python -m pytest 2>&1) || test_exit=$?
            ;;
        go_test)
            test_out=$(cd "$dir" && go test ./... 2>&1) || test_exit=$?
            ;;
        bats)
            if command -v bats &>/dev/null; then
                test_out=$(cd "$dir" && bats tests/ 2>&1) || test_exit=$?
            else
                echo "PASS: bats not installed (skipped)"
                return $GATE_PASS
            fi
            ;;
    esac

    if [ "$test_exit" -ne 0 ]; then
        # Extract failure summary with details
        local fail_count
        fail_count=$(echo "$test_out" | grep -ciE '(fail|error|✗)' || true)
        local test_details
        test_details=$(echo "$test_out" | head -50)
        printf "FIXABLE: %s test failures (runner: %s)\n---DETAILS---\n%s" "$fail_count" "$runner" "$test_details"
        return $GATE_FIXABLE
    fi

    # Tests passed - now check coverage
    local coverage_pct=""
    local coverage_threshold="${GATE_COVERAGE_THRESHOLD:-60}"

    # Try lcov.info (Jest/nyc/Istanbul/c8)
    if [ -z "$coverage_pct" ] && [ -f "${dir}/coverage/lcov.info" ]; then
        local lf lh
        lf=$(grep -c '^LF:' "${dir}/coverage/lcov.info" 2>/dev/null || echo "0")
        lh=$(grep -c '^LH:' "${dir}/coverage/lcov.info" 2>/dev/null || echo "0")
        local total_lines=0 hit_lines=0
        while IFS= read -r line; do
            case "$line" in
                LF:*) total_lines=$((total_lines + ${line#LF:})) ;;
                LH:*) hit_lines=$((hit_lines + ${line#LH:})) ;;
            esac
        done < "${dir}/coverage/lcov.info"
        if [ "$total_lines" -gt 0 ]; then
            coverage_pct=$((hit_lines * 100 / total_lines))
        fi
    fi

    # Try coverage-summary.json (Jest --coverage --json)
    if [ -z "$coverage_pct" ] && [ -f "${dir}/coverage/coverage-summary.json" ]; then
        coverage_pct=$(grep -o '"pct":[0-9.]*' "${dir}/coverage/coverage-summary.json" 2>/dev/null | head -1 | sed 's/"pct"://' | sed 's/\..*//')
    fi

    # Try Python coverage.py
    if [ -z "$coverage_pct" ] && [ -f "${dir}/.coverage" ] && command -v coverage &>/dev/null; then
        coverage_pct=$(cd "$dir" && coverage report --format=total 2>/dev/null | tr -d '[:space:]' | sed 's/%.*//')
    fi

    # Try Go coverage
    if [ -z "$coverage_pct" ] && [ -f "${dir}/coverage.out" ] && command -v go &>/dev/null; then
        local go_cov
        go_cov=$(cd "$dir" && go tool cover -func=coverage.out 2>/dev/null | grep total | sed -E 's/.*\s([0-9]+)\.[0-9]+%.*/\1/')
        if [ -n "$go_cov" ]; then
            coverage_pct="$go_cov"
        fi
    fi

    # Coverage auto-fallback: re-run with --coverage if no data found
    if [ -z "$coverage_pct" ] && [ "$runner" = "npm_test" ] && _has_npm_script "$dir" "test"; then
        local pm_cov
        pm_cov=$(_detect_package_manager "$dir")
        local cov_out
        cov_out=$(cd "$dir" && $pm_cov test -- --coverage 2>&1) || true
        # Re-check lcov.info
        if [ -f "${dir}/coverage/lcov.info" ]; then
            local total_lines=0 hit_lines=0
            while IFS= read -r line; do
                case "$line" in
                    LF:*) total_lines=$((total_lines + ${line#LF:})) ;;
                    LH:*) hit_lines=$((hit_lines + ${line#LH:})) ;;
                esac
            done < "${dir}/coverage/lcov.info"
            if [ "$total_lines" -gt 0 ]; then
                coverage_pct=$((hit_lines * 100 / total_lines))
            fi
        fi
        # Re-check coverage-summary.json
        if [ -z "$coverage_pct" ] && [ -f "${dir}/coverage/coverage-summary.json" ]; then
            coverage_pct=$(grep -o '"pct":[0-9.]*' "${dir}/coverage/coverage-summary.json" 2>/dev/null | head -1 | sed 's/"pct"://' | sed 's/\..*//')
        fi
    fi

    # Evaluate coverage against threshold
    if [ -n "$coverage_pct" ] && [ "$coverage_pct" -lt "$coverage_threshold" ] 2>/dev/null; then
        printf "FIXABLE: tests passed but coverage %s%% < %s%% threshold (runner: %s)\n---DETAILS---\nCoverage: %s%%\nThreshold: %s%%\nAdd more tests to improve coverage." "$coverage_pct" "$coverage_threshold" "$runner" "$coverage_pct" "$coverage_threshold"
        return $GATE_FIXABLE
    fi

    if [ -n "$coverage_pct" ]; then
        echo "PASS: all tests passed, coverage ${coverage_pct}% (runner: ${runner})"
    else
        echo "PASS: all tests passed (runner: ${runner})"
    fi
    return $GATE_PASS
}

# ── gate_design ─────────────────────────────────────────────────────
# Validates design spec structure and OpenAPI YAML.

gate_design() {
    local feature_slug="$1"
    local dir="${2:-$PWD}"
    local errors=0
    local fixable=0
    local details=""
    local raw_output=""

    local spec_file="${dir}/docs/specs/${feature_slug}.md"
    local api_file=""
    # Try .yaml then .yml
    for ext in yaml yml; do
        if [ -f "${dir}/docs/api/${feature_slug}.${ext}" ]; then
            api_file="${dir}/docs/api/${feature_slug}.${ext}"
            break
        fi
    done

    # 1. Spec file structure validation
    if [ -f "$spec_file" ]; then
        local spec_size
        spec_size=$(wc -c < "$spec_file" | tr -d ' ')
        if [ "$spec_size" -lt 100 ]; then
            details="${details}spec: too small (${spec_size} bytes, need 100+); "
            raw_output="${raw_output}[spec-size]
File: ${spec_file} (${spec_size} bytes, minimum 100)
"
            fixable=1
        else
            # Check for required sections (need at least 2)
            local section_count=0
            for section_pattern in '## Component' '## State' '## Interaction' '## コンポーネント' '## 状態' '## インタラクション' '## Layout' '## レイアウト' '## Error' '## エラー'; do
                if grep -qi "$section_pattern" "$spec_file" 2>/dev/null; then
                    section_count=$((section_count + 1))
                fi
            done
            if [ "$section_count" -lt 2 ]; then
                details="${details}spec: only ${section_count} required sections (need 2+); "
                raw_output="${raw_output}[spec-sections]
File: ${spec_file}
Found ${section_count} of required sections (Component/State/Interaction/Layout/Error).
Need at least 2.
"
                fixable=1
            else
                details="${details}spec: OK (${section_count} sections); "
            fi
        fi
    else
        details="${details}spec: file missing; "
        fixable=1
    fi

    # 2. OpenAPI YAML validation
    if [ -n "$api_file" ] && [ -f "$api_file" ]; then
        # Try python3 YAML validation first, fallback to grep
        if command -v python3 &>/dev/null; then
            local yaml_out
            yaml_out=$(python3 -c "
import yaml, sys
try:
    with open('${api_file}') as f:
        doc = yaml.safe_load(f)
    if not isinstance(doc, dict):
        print('ERROR: not a YAML mapping')
        sys.exit(1)
    missing = [k for k in ('openapi','paths') if k not in doc]
    if missing:
        print('ERROR: missing keys: ' + ', '.join(missing))
        sys.exit(1)
    print('OK')
except yaml.YAMLError as e:
    print('ERROR: ' + str(e))
    sys.exit(1)
" 2>&1) || true
            if echo "$yaml_out" | grep -q 'ERROR'; then
                details="${details}api-yaml: ${yaml_out}; "
                raw_output="${raw_output}[api-yaml]
${yaml_out}
"
                errors=1
            else
                details="${details}api-yaml: valid; "
            fi
        else
            # Grep fallback: check for key markers
            local has_openapi has_paths
            has_openapi=$(grep -c '^openapi:' "$api_file" 2>/dev/null || echo "0")
            has_paths=$(grep -c '^paths:' "$api_file" 2>/dev/null || echo "0")
            if [ "$has_openapi" -eq 0 ] || [ "$has_paths" -eq 0 ]; then
                details="${details}api-yaml: missing openapi/paths keys; "
                raw_output="${raw_output}[api-yaml]
Missing required keys. Found openapi: ${has_openapi}, paths: ${has_paths}
"
                errors=1
            else
                details="${details}api-yaml: structure OK; "
            fi
        fi
    elif [ -z "$api_file" ]; then
        details="${details}api-yaml: file missing; "
        fixable=1
    fi

    # 3. Cross-reference: spec /api/* paths should exist in API YAML
    if [ -f "$spec_file" ] && [ -n "$api_file" ] && [ -f "$api_file" ]; then
        local spec_api_paths
        spec_api_paths=$(grep -oE '/api/[a-zA-Z0-9_/-]+' "$spec_file" 2>/dev/null | sort -u)
        if [ -n "$spec_api_paths" ]; then
            local missing_paths=""
            while IFS= read -r api_path; do
                [ -z "$api_path" ] && continue
                if ! grep -qF "$api_path" "$api_file" 2>/dev/null; then
                    missing_paths="${missing_paths}${api_path} "
                fi
            done <<< "$spec_api_paths"
            if [ -n "$missing_paths" ]; then
                details="${details}cross-ref: paths in spec but not in API YAML: ${missing_paths}; "
                raw_output="${raw_output}[cross-reference]
Paths referenced in spec but missing from API YAML:
${missing_paths}
"
                fixable=1
            else
                details="${details}cross-ref: OK; "
            fi
        fi
    fi

    # Verdict
    if [ "$errors" -gt 0 ]; then
        printf "FAIL: %s\n---DETAILS---\n%s" "$details" "$raw_output"
        return $GATE_FAIL
    elif [ "$fixable" -gt 0 ]; then
        printf "FIXABLE: %s\n---DETAILS---\n%s" "$details" "$raw_output"
        return $GATE_FIXABLE
    else
        echo "PASS: ${details:-design checks clean}"
        return $GATE_PASS
    fi
}

# ── gate_review ─────────────────────────────────────────────────────
# Parses the review file for the verdict.

gate_review() {
    local feature_slug="$1"
    local dir="${2:-$PWD}"
    local file="${dir}/docs/reviews/${feature_slug}.md"

    if [ ! -f "$file" ]; then
        echo "FAIL: review file not found: ${file}"
        return $GATE_FAIL
    fi

    # Extract verdict
    local verdict
    verdict=$(grep -iE '(APPROVED|NEEDS CHANGES|REJECTED)' "$file" | head -1)

    if echo "$verdict" | grep -qi 'APPROVED'; then
        echo "PASS: review approved"
        return $GATE_PASS
    elif echo "$verdict" | grep -qi 'NEEDS CHANGES'; then
        # Extract change requests for auto-fix context
        local changes
        changes=$(sed -nE '/## (改善|Improvement|Suggestion|変更)/,/^## /p' "$file" | head -20)
        echo "FIXABLE: review needs changes - ${changes:-see review file}"
        return $GATE_FIXABLE
    elif echo "$verdict" | grep -qi 'REJECTED'; then
        echo "FAIL: review rejected"
        return $GATE_FAIL
    else
        echo "FAIL: no verdict found in review"
        return $GATE_FAIL
    fi
}

# ── gate_requirements ───────────────────────────────────────────────
# Validates requirements document quality.

gate_requirements() {
    local feature_slug="$1"
    local dir="${2:-$PWD}"
    local file="${dir}/docs/requirements/${feature_slug}.md"

    if [ ! -f "$file" ]; then
        echo "FIXABLE: requirements file not found: ${file}"
        return $GATE_FIXABLE
    fi

    local details=""
    local fixable=0
    local raw_output=""

    # 1. File size check (minimum 200 bytes)
    local file_size
    file_size=$(wc -c < "$file" | tr -d ' ')
    if [ "$file_size" -lt 200 ]; then
        details="${details}size: too small (${file_size} bytes, need 200+); "
        raw_output="${raw_output}[size]
File: ${file} (${file_size} bytes, minimum 200)
"
        fixable=1
    fi

    # 2. User story format (AS A / I WANT / SO THAT)
    local story_count=0
    story_count=$(grep -ciE '(AS A|I WANT|SO THAT)' "$file" 2>/dev/null || echo "0")
    if [ "$story_count" -lt 2 ]; then
        details="${details}user-stories: insufficient (found ${story_count} markers, need AS A/I WANT/SO THAT); "
        raw_output="${raw_output}[user-stories]
Found ${story_count} user story markers. Need AS A / I WANT / SO THAT format.
"
        fixable=1
    fi

    # 3. Acceptance criteria (3+ items)
    local criteria_count=0
    criteria_count=$(grep -cE '^\s*-\s*\[' "$file" 2>/dev/null || echo "0")
    if [ "$criteria_count" -lt 3 ]; then
        details="${details}acceptance-criteria: only ${criteria_count} (need 3+); "
        raw_output="${raw_output}[acceptance-criteria]
Found ${criteria_count} acceptance criteria (checkbox items). Need at least 3.
"
        fixable=1
    fi

    # 4. Non-functional requirements section
    local has_nfr=false
    if grep -qiE '(非機能|non-?functional|パフォーマンス|performance|security|セキュリティ|accessibility|アクセシビリティ)' "$file" 2>/dev/null; then
        has_nfr=true
    fi
    if [ "$has_nfr" = "false" ]; then
        details="${details}non-functional: section missing; "
        raw_output="${raw_output}[non-functional]
No non-functional requirements section found. Add performance, security, or accessibility requirements.
"
        fixable=1
    fi

    # Verdict
    if [ "$fixable" -gt 0 ]; then
        printf "FIXABLE: %s\n---DETAILS---\n%s" "$details" "$raw_output"
        return $GATE_FIXABLE
    else
        echo "PASS: requirements quality checks passed (${file_size} bytes, ${criteria_count} criteria)"
        return $GATE_PASS
    fi
}

# ── gate_deploy ─────────────────────────────────────────────────────
# Validates deploy readiness: review approved, no FAIL phases, no secrets.

gate_deploy() {
    local feature_slug="$1"
    local dir="${2:-$PWD}"
    local errors=0
    local details=""
    local raw_output=""

    # 1. Review APPROVED check
    local review_file="${dir}/docs/reviews/${feature_slug}.md"
    if [ -f "$review_file" ]; then
        if grep -qi 'APPROVED' "$review_file" 2>/dev/null; then
            details="${details}review: APPROVED; "
        else
            details="${details}review: not approved; "
            raw_output="${raw_output}[review]
Review file exists but does not contain APPROVED verdict.
"
            errors=$((errors + 1))
        fi
    else
        details="${details}review: file missing; "
        raw_output="${raw_output}[review]
Review file not found: ${review_file}
"
        errors=$((errors + 1))
    fi

    # 2. No FAIL phases in latest pipeline run (metrics.jsonl)
    local metrics_file="${dir}/.claude/docs/metrics.jsonl"
    if [ -f "$metrics_file" ]; then
        local latest_run
        latest_run=$(grep "\"feature\":\"${feature_slug}\"" "$metrics_file" 2>/dev/null | tail -1)
        if [ -n "$latest_run" ] && echo "$latest_run" | grep -q '"result":"FAIL"'; then
            details="${details}metrics: FAIL phases in latest run; "
            raw_output="${raw_output}[metrics]
Latest pipeline run contains FAIL phases. Fix all failures before deploying.
"
            errors=$((errors + 1))
        else
            details="${details}metrics: clean; "
        fi
    fi

    # 3. No secrets in uncommitted changes
    local secret_check
    secret_check=$(_gate_secrets "$dir" 2>/dev/null)
    if echo "$secret_check" | grep -q 'STATUS:ERROR'; then
        details="${details}secrets: detected in uncommitted changes; "
        raw_output="${raw_output}[secrets]
$(echo "$secret_check" | sed -n '/^RAW:/,$p' | sed '1s/^RAW://')
"
        errors=$((errors + 1))
    else
        details="${details}secrets: clean; "
    fi

    if [ "$errors" -gt 0 ]; then
        printf "FAIL: %s\n---DETAILS---\n%s" "$details" "$raw_output"
        return $GATE_FAIL
    fi
    echo "PASS: deploy safety checks passed (${details})"
    return $GATE_PASS
}

# ── gate_for_phase ──────────────────────────────────────────────────
# Dispatch to the correct gate for a given phase name.

gate_for_phase() {
    local phase="$1"
    local feature_slug="$2"
    local dir="${3:-$PWD}"

    case "$phase" in
        implement)    gate_implement "$dir" ;;
        test)         gate_test "$dir" ;;
        review)       gate_review "$feature_slug" "$dir" ;;
        design)       gate_design "$feature_slug" "$dir" ;;
        requirements) gate_requirements "$feature_slug" "$dir" ;;
        deploy)       gate_deploy "$feature_slug" "$dir" ;;
        *)            echo "PASS: unknown phase '$phase' (no gate)"; return 0 ;;
    esac
}
