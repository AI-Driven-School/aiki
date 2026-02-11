#!/bin/bash
# ============================================
# Sensitive File Filter
# ============================================
# Prevents accidental sending of secrets/credentials
# to external AI services (Codex, Gemini).
#
# Usage:
#   source scripts/lib/sensitive-filter.sh
#   is_sensitive_file ".env"           # returns 0 (true)
#   is_sensitive_file "src/app.ts"     # returns 1 (false)
# ============================================

# Patterns that indicate sensitive files
SENSITIVE_PATTERNS=(
    "*.env"
    "*.env.*"
    ".env"
    ".env.local"
    ".env.production"
    ".env.development"
    "*.pem"
    "*.key"
    "*.p12"
    "*.pfx"
    "*.jks"
    "*.keystore"
    "*credential*"
    "*secret*"
    "id_rsa"
    "id_rsa.pub"
    "id_ed25519"
    "id_ed25519.pub"
    "*.gpg"
    ".npmrc"
    ".pypirc"
    ".netrc"
    ".htpasswd"
    "*.cert"
    "*.crt"
    "*.csr"
    "token.json"
    "credentials.json"
    "service-account*.json"
    ".aws/credentials"
    ".aws/config"
    "kube*config*"
)

# Color definitions (safe to re-define if already sourced)
_SF_RED='\033[0;31m'
_SF_YELLOW='\033[1;33m'
_SF_BOLD='\033[1m'
_SF_NC='\033[0m'

# Check if a file matches sensitive patterns
# Returns 0 (true) if sensitive, 1 (false) if safe
is_sensitive_file() {
    local filepath="$1"
    local basename
    basename=$(basename "$filepath")

    for pattern in "${SENSITIVE_PATTERNS[@]}"; do
        # Check basename against glob pattern
        # shellcheck disable=SC2254
        case "$basename" in
            $pattern)
                return 0
                ;;
        esac
        # Also check full path for patterns like .aws/credentials
        # shellcheck disable=SC2254
        case "$filepath" in
            *$pattern*)
                return 0
                ;;
        esac
    done

    return 1
}

# Filter a newline-separated file list, removing sensitive files
# Reads from stdin or first argument, outputs safe files to stdout
filter_sensitive_files() {
    local input="${1:-}"
    local blocked=0

    if [ -n "$input" ]; then
        while IFS= read -r filepath; do
            if [ -z "$filepath" ]; then continue; fi
            if is_sensitive_file "$filepath"; then
                blocked=$((blocked + 1))
                echo "[BLOCKED] $filepath" >&2
            else
                echo "$filepath"
            fi
        done <<< "$input"
    else
        while IFS= read -r filepath; do
            if [ -z "$filepath" ]; then continue; fi
            if is_sensitive_file "$filepath"; then
                blocked=$((blocked + 1))
                echo "[BLOCKED] $filepath" >&2
            else
                echo "$filepath"
            fi
        done
    fi

    if [ "$blocked" -gt 0 ]; then
        echo -e "${_SF_YELLOW}[FILTER] ${blocked} sensitive file(s) excluded${_SF_NC}" >&2
    fi
}

# Build find command exclusion arguments for sensitive patterns
# Usage: find . $(build_find_exclusions) -type f -name "*.ts"
build_find_exclusions() {
    local first=true
    for pattern in "${SENSITIVE_PATTERNS[@]}"; do
        if [ "$first" = true ]; then
            printf '! -name "%s"' "$pattern"
            first=false
        else
            printf ' ! -name "%s"' "$pattern"
        fi
    done
}

# Display warning banner when sending files to external AI
warn_external_ai_send() {
    local ai_name="$1"
    local file_count="${2:-unknown}"

    if [ "${FORCE_SEND:-false}" = "true" ]; then
        echo -e "${_SF_RED}${_SF_BOLD}!!!  FORCE MODE: Sending ${file_count} file(s) to ${ai_name} WITHOUT filtering  !!!${_SF_NC}" >&2
        echo -e "${_SF_RED}     Sensitive files may be included. You accepted this risk with --force.${_SF_NC}" >&2
        return 0
    fi

    echo -e "${_SF_YELLOW}${_SF_BOLD}========================================${_SF_NC}" >&2
    echo -e "${_SF_YELLOW}  Sending ${file_count} file(s) to ${ai_name}${_SF_NC}" >&2
    echo -e "${_SF_YELLOW}  Sensitive files are automatically filtered.${_SF_NC}" >&2
    echo -e "${_SF_YELLOW}  Use --force to bypass (not recommended).${_SF_NC}" >&2
    echo -e "${_SF_YELLOW}${_SF_BOLD}========================================${_SF_NC}" >&2
}

# Read file content safely (returns empty + warning if sensitive)
safe_cat() {
    local filepath="$1"
    if [ "${FORCE_SEND:-false}" != "true" ] && is_sensitive_file "$filepath"; then
        echo -e "${_SF_YELLOW}[BLOCKED] Refusing to read sensitive file: ${filepath}${_SF_NC}" >&2
        echo "[Content hidden: sensitive file]"
        return 1
    fi
    cat "$filepath"
}
