#!/usr/bin/env bats

load helpers

setup() {
    source "$PROJECT_ROOT/scripts/lib/sensitive-filter.sh"
}

# ===== is_sensitive_file tests =====

@test "is_sensitive_file: detects .env files" {
    run is_sensitive_file ".env"
    [ "$status" -eq 0 ]
}

@test "is_sensitive_file: detects .env.local" {
    run is_sensitive_file ".env.local"
    [ "$status" -eq 0 ]
}

@test "is_sensitive_file: detects .env.production" {
    run is_sensitive_file ".env.production"
    [ "$status" -eq 0 ]
}

@test "is_sensitive_file: detects PEM files" {
    run is_sensitive_file "server.pem"
    [ "$status" -eq 0 ]
}

@test "is_sensitive_file: detects KEY files" {
    run is_sensitive_file "private.key"
    [ "$status" -eq 0 ]
}

@test "is_sensitive_file: detects id_rsa" {
    run is_sensitive_file "id_rsa"
    [ "$status" -eq 0 ]
}

@test "is_sensitive_file: detects credentials.json" {
    run is_sensitive_file "credentials.json"
    [ "$status" -eq 0 ]
}

@test "is_sensitive_file: detects files with 'secret' in name" {
    run is_sensitive_file "my-secret-config.yaml"
    [ "$status" -eq 0 ]
}

@test "is_sensitive_file: passes normal TypeScript file" {
    run is_sensitive_file "src/app.ts"
    [ "$status" -eq 1 ]
}

@test "is_sensitive_file: passes normal JavaScript file" {
    run is_sensitive_file "src/index.js"
    [ "$status" -eq 1 ]
}

@test "is_sensitive_file: passes markdown files" {
    run is_sensitive_file "README.md"
    [ "$status" -eq 1 ]
}

@test "is_sensitive_file: passes package.json" {
    run is_sensitive_file "package.json"
    [ "$status" -eq 1 ]
}

# ===== filter_sensitive_files tests =====

@test "filter_sensitive_files: removes sensitive files from list" {
    local input="src/app.ts
.env
src/utils.ts
private.key
README.md"
    run filter_sensitive_files "$input"
    [ "$status" -eq 0 ]
    [[ "$output" == *"src/app.ts"* ]]
    [[ "$output" == *"src/utils.ts"* ]]
    [[ "$output" == *"README.md"* ]]
    [[ "$output" != *".env"* ]] || [[ "$output" == *"BLOCKED"* ]] || [[ "$output" == *"FILTER"* ]]
}

@test "filter_sensitive_files: passes all safe files through" {
    local input="src/app.ts
src/index.js
package.json"
    result=$(filter_sensitive_files "$input" 2>/dev/null)
    [ "$(echo "$result" | wc -l | tr -d ' ')" -eq 3 ]
}

# ===== safe_cat tests =====

@test "safe_cat: blocks sensitive file" {
    local tmpfile
    tmpfile=$(mktemp /tmp/test.env.XXXXXX)
    # Rename to match .env pattern
    local envfile="${tmpfile%.XXXXXX}.env"
    mv "$tmpfile" "$envfile" 2>/dev/null || envfile="$tmpfile"
    echo "SECRET=value" > "$envfile"

    run safe_cat "$envfile"
    [ "$status" -eq 1 ]
    rm -f "$envfile"
}

@test "safe_cat: reads normal file" {
    local tmpfile
    tmpfile=$(mktemp /tmp/testfile_normal.XXXXXX)
    echo "hello world" > "$tmpfile"

    run safe_cat "$tmpfile"
    [ "$status" -eq 0 ]
    [[ "$output" == *"hello world"* ]]
    rm -f "$tmpfile"
}

@test "safe_cat: force mode bypasses filter" {
    local tmpfile
    tmpfile=$(mktemp /tmp/test_credential_file.XXXXXX)
    echo "SECRET=value" > "$tmpfile"

    FORCE_SEND=true run safe_cat "$tmpfile"
    [ "$status" -eq 0 ]
    rm -f "$tmpfile"
}
