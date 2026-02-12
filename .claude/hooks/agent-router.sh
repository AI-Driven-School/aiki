#!/bin/bash
#
# agent-router.sh - AI Router for Claude Code Orchestra
# Analyzes user input and suggests the appropriate AI
#

# Read input from stdin
input=$(cat)

# Convert to lowercase for matching
input_lower=$(echo "$input" | tr '[:upper:]' '[:lower:]')

# Codex suggestion keywords (implementation tasks)
codex_keywords="実装|implement|新規|create|追加|add|修正|fix|変更|change|テスト|test|コード|code|作成|build"

# Gemini suggestion keywords (research/analysis tasks)
gemini_keywords="調査|research|分析|analyze|比較|compare|ライブラリ|library|フレームワーク|framework|選定|ベストプラクティス|best practice|トレンド|trend|レビュー|review"

# Prepare output
output=""

# Detect Codex keywords
if echo "$input_lower" | grep -qiE "$codex_keywords"; then
    output="**Codex suggestion**: This looks like an implementation task.
   Use \`/implement\` to delegate to Codex for efficiency.
   (ChatGPT Pro: \$0, parallel execution supported)"
fi

# Detect Gemini keywords
if echo "$input_lower" | grep -qiE "$gemini_keywords"; then
    if [ -n "$output" ]; then
        output="$output

"
    fi
    output="${output}**Gemini suggestion**: This looks like a research/analysis task.
   Gemini (free) excels at large-scale information gathering.
   See .gemini/GEMINI.md for request templates."
fi

# Only output if there are suggestions
if [ -n "$output" ]; then
    echo "$output"
fi

exit 0
