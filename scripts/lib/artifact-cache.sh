#!/bin/bash
# artifact-cache.sh - Hash-based artifact cache for pipeline phase skipping
#
# Caches phase outputs by hashing inputs (phase name + feature + knowledge context).
# On cache hit, the phase can be skipped entirely.
#
# Functions:
#   compute_cache_key()  - Generate input hash for a phase
#   cache_hit()          - Check if cached output is still valid
#   cache_record()       - Record successful phase output
#   cache_clear()        - Clear cache for a feature or all

CACHE_DIR="${PROJECT_DIR:-.}/.claude/.artifact-cache"

# Compute a cache key from phase inputs
# Usage: compute_cache_key <phase> <feature_slug> [extra_context]
compute_cache_key() {
    local phase="$1"
    local feature_slug="$2"
    local extra_context="${3:-}"

    local input="${phase}:${feature_slug}"

    # Include relevant artifact contents in hash
    case "$phase" in
        requirements)
            # Include existing requirements file content for change detection
            local req_file="${PROJECT_DIR}/docs/requirements/${feature_slug}.md"
            if [ -f "$req_file" ]; then
                input="${input}:$(cat "$req_file" 2>/dev/null)"
            fi
            ;;
        design)
            local req_file="${PROJECT_DIR}/docs/requirements/${feature_slug}.md"
            if [ -f "$req_file" ]; then
                input="${input}:$(cat "$req_file" 2>/dev/null)"
            fi
            ;;
        implement)
            local spec_file="${PROJECT_DIR}/docs/specs/${feature_slug}.md"
            local api_file="${PROJECT_DIR}/docs/api/${feature_slug}.yaml"
            [ -f "$spec_file" ] && input="${input}:$(cat "$spec_file" 2>/dev/null)"
            [ -f "$api_file" ] && input="${input}:$(cat "$api_file" 2>/dev/null)"
            ;;
        test)
            local spec_file="${PROJECT_DIR}/docs/specs/${feature_slug}.md"
            [ -f "$spec_file" ] && input="${input}:$(cat "$spec_file" 2>/dev/null)"
            # Include src directory hash if it exists
            if [ -d "${PROJECT_DIR}/src" ]; then
                local src_hash
                src_hash=$(find "${PROJECT_DIR}/src" -type f -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' 2>/dev/null | sort | xargs cat 2>/dev/null | head -c 50000)
                input="${input}:${src_hash}"
            fi
            ;;
        review)
            # Review always runs (not cacheable by default)
            echo "NO_CACHE"
            return
            ;;
    esac

    # Add knowledge context if provided
    if [ -n "$extra_context" ]; then
        input="${input}:${extra_context}"
    fi

    # Compute hash (prefer shasum, fallback to sha256sum)
    if command -v shasum &>/dev/null; then
        echo "$input" | shasum -a 256 | cut -d' ' -f1
    elif command -v sha256sum &>/dev/null; then
        echo "$input" | sha256sum | cut -d' ' -f1
    else
        # Fallback: use cksum (always available)
        echo "$input" | cksum | cut -d' ' -f1
    fi
}

# Check if cache hit for a phase
# Returns 0 if cache hit (phase can be skipped), 1 if miss
cache_hit() {
    local phase="$1"
    local feature_slug="$2"
    local cache_key="$3"

    if [ "$cache_key" = "NO_CACHE" ]; then
        return 1
    fi

    local meta_file="${CACHE_DIR}/${feature_slug}/${phase}.meta"

    if [ ! -f "$meta_file" ]; then
        return 1
    fi

    local stored_key
    stored_key=$(head -1 "$meta_file" 2>/dev/null)

    if [ "$stored_key" = "$cache_key" ]; then
        # Verify artifacts still exist
        local artifact_list
        artifact_list=$(tail -n +2 "$meta_file" 2>/dev/null)
        if [ -n "$artifact_list" ]; then
            while IFS= read -r artifact; do
                [ -z "$artifact" ] && continue
                if [ ! -f "$artifact" ]; then
                    return 1
                fi
            done <<< "$artifact_list"
        fi
        return 0
    fi

    return 1
}

# Record a successful phase execution in cache
cache_record() {
    local phase="$1"
    local feature_slug="$2"
    local cache_key="$3"

    if [ "$cache_key" = "NO_CACHE" ]; then
        return 0
    fi

    local cache_phase_dir="${CACHE_DIR}/${feature_slug}"
    mkdir -p "$cache_phase_dir"

    local meta_file="${cache_phase_dir}/${phase}.meta"

    # Write cache key and list of output artifacts
    echo "$cache_key" > "$meta_file"

    # Record output artifacts by phase
    case "$phase" in
        requirements)
            echo "${PROJECT_DIR}/docs/requirements/${feature_slug}.md" >> "$meta_file"
            ;;
        design)
            echo "${PROJECT_DIR}/docs/specs/${feature_slug}.md" >> "$meta_file"
            echo "${PROJECT_DIR}/docs/api/${feature_slug}.yaml" >> "$meta_file"
            ;;
        implement)
            # Track src directory timestamp instead of individual files
            echo "${PROJECT_DIR}/docs/specs/${feature_slug}.md" >> "$meta_file"
            ;;
        test)
            echo "${PROJECT_DIR}/docs/specs/${feature_slug}.md" >> "$meta_file"
            ;;
    esac
}

# Clear cache for a feature or all
cache_clear() {
    local feature_slug="${1:-}"

    if [ -n "$feature_slug" ]; then
        rm -rf "${CACHE_DIR}/${feature_slug}"
    else
        rm -rf "$CACHE_DIR"
    fi
}
