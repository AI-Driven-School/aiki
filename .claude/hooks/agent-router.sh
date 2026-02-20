#!/bin/bash
#
# agent-router.sh v2 - Context-aware AI Router for Claude Code Orchestra
#
# Three routing signals (highest priority first):
#   1. Phase awareness  - if pipeline is running, route by phase
#   2. Artifact check   - enforce design-first if artifacts missing
#   3. Tool availability - fallback if Codex/Gemini not installed
#
# Keyword matching is lowest-priority fallback.
#

input=$(cat)
input_lower=$(echo "$input" | tr '[:upper:]' '[:lower:]')

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
output=""

# ── Signal 1: Phase awareness ──────────────────────────────────────
# If the pipeline engine is currently running, the active phase is stored
# in .claude/.pipeline_phase. Route automatically by phase.

PHASE_FILE="${PROJECT_DIR}/.claude/.pipeline_phase"
if [ -f "$PHASE_FILE" ]; then
    phase=$(cat "$PHASE_FILE")
    case "$phase" in
        requirements|design|review)
            output="**Auto-routing (pipeline)**: Phase '${phase}' → Claude is handling this."
            ;;
        implement|test)
            if command -v codex &>/dev/null; then
                output="**Auto-routing (pipeline)**: Phase '${phase}' → Delegated to Codex."
            else
                output="**Auto-routing (pipeline)**: Phase '${phase}' → Claude (Codex not available)."
            fi
            ;;
    esac
    if [ -n "$output" ]; then
        echo "$output"
        exit 0
    fi
fi

# ── Signal 2: Artifact check (design-first enforcement) ────────────
# If the user asks for implementation but requirements/specs don't exist,
# warn them to design first.

impl_keywords="実装|implement|コード|code|作成|create|build|追加|add"
if echo "$input_lower" | grep -qiE "$impl_keywords"; then
    # Extract a likely feature name from the input (first quoted string or last word)
    feature_hint=$(echo "$input" | grep -oE '"[^"]+"' | head -1 | tr -d '"')
    if [ -z "$feature_hint" ]; then
        feature_hint=$(echo "$input" | awk '{print $NF}')
    fi
    feature_slug=$(echo "$feature_hint" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')

    missing_artifacts=""
    if [ -n "$feature_slug" ] && [ ${#feature_slug} -gt 1 ]; then
        if [ ! -f "${PROJECT_DIR}/docs/requirements/${feature_slug}.md" ]; then
            missing_artifacts="requirements"
        fi
        if [ ! -f "${PROJECT_DIR}/docs/specs/${feature_slug}.md" ]; then
            if [ -n "$missing_artifacts" ]; then
                missing_artifacts="${missing_artifacts}, specs"
            else
                missing_artifacts="specs"
            fi
        fi
    fi

    if [ -n "$missing_artifacts" ]; then
        output="**Design-first warning**: Missing ${missing_artifacts} for '${feature_slug}'.
   Run \`/project ${feature_hint}\` for the full pipeline, or:
   - \`/requirements\` to generate requirements first
   - \`/spec\` to generate design specs"
    fi
fi

# ── Signal 3: Tool availability ────────────────────────────────────
# Check what tools are actually available and adjust suggestions.

has_codex=false
has_gemini=false
has_grok_key=false

command -v codex &>/dev/null && has_codex=true
command -v gemini &>/dev/null && has_gemini=true
[ -n "${XAI_API_KEY:-}" ] && has_grok_key=true

# ── Fallback: Keyword matching ─────────────────────────────────────
# Only fires if no higher-priority signal produced output.

codex_keywords="実装|implement|新規|create|追加|add|修正|fix|変更|change|テスト|test|コード|code|作成|build"
gemini_keywords="調査|research|分析|analyze|比較|compare|ライブラリ|library|フレームワーク|framework|選定|ベストプラクティス|best practice|レビュー|review"
grok_keywords="トレンド|trend|x検索|x search|sns|twitter|バズ|buzz|バイラル|viral|リアルタイム|realtime|real-time|最新|latest|話題|投稿ネタ|post ideas|世論|sentiment|反応|reaction"

keyword_suggestions=""

if echo "$input_lower" | grep -qiE "$codex_keywords"; then
    if [ "$has_codex" = "true" ]; then
        keyword_suggestions="**Codex suggestion**: Implementation task detected.
   Use \`/implement\` to delegate to Codex (ChatGPT Pro: \$0)."
    else
        keyword_suggestions="**Implementation task detected**: Codex not installed.
   Claude will handle implementation directly.
   Install Codex: \`npm install -g @openai/codex\`"
    fi
fi

if echo "$input_lower" | grep -qiE "$grok_keywords"; then
    local_note=""
    if [ "$has_grok_key" != "true" ]; then
        local_note=" (XAI_API_KEY not set)"
    fi
    if [ -n "$keyword_suggestions" ]; then
        keyword_suggestions="${keyword_suggestions}

"
    fi
    keyword_suggestions="${keyword_suggestions}**Grok suggestion**: Real-time/trend research task detected${local_note}.
   See .grok/GROK.md for request templates."
fi

if echo "$input_lower" | grep -qiE "$gemini_keywords"; then
    local_note=""
    if [ "$has_gemini" != "true" ]; then
        local_note=" (Gemini CLI not installed)"
    fi
    if [ -n "$keyword_suggestions" ]; then
        keyword_suggestions="${keyword_suggestions}

"
    fi
    keyword_suggestions="${keyword_suggestions}**Gemini suggestion**: Research/analysis task detected${local_note}.
   Gemini (free) excels at large-scale analysis.
   See .gemini/GEMINI.md for request templates."
fi

# ── Compose final output ───────────────────────────────────────────

if [ -n "$output" ] && [ -n "$keyword_suggestions" ]; then
    echo "${output}

${keyword_suggestions}"
elif [ -n "$output" ]; then
    echo "$output"
elif [ -n "$keyword_suggestions" ]; then
    echo "$keyword_suggestions"
fi

exit 0
