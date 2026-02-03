#!/bin/bash
#
# agent-router.sh - AI Router for Claude Code Orchestra
# ユーザー入力を解析し、適切なAIを提案する
#

# 入力を取得（stdinから）
input=$(cat)

# 小文字に変換して検索
input_lower=$(echo "$input" | tr '[:upper:]' '[:lower:]')

# Codex提案キーワード（実装系）
codex_keywords="実装|implement|新規|create|追加|add|修正|fix|変更|change|テスト|test|コード|code|作成|build"

# Gemini提案キーワード（調査・分析系）
gemini_keywords="調査|research|分析|analyze|比較|compare|ライブラリ|library|フレームワーク|framework|選定|ベストプラクティス|best practice|トレンド|trend|レビュー|review"

# 出力を準備
output=""

# Codexキーワード検出
if echo "$input_lower" | grep -qiE "$codex_keywords"; then
    output="💡 **Codex提案**: このタスクは実装系です。
   \`/implement\` でCodexに委譲すると効率的です。
   （ChatGPT Pro: \$0、並列実行可能）"
fi

# Geminiキーワード検出
if echo "$input_lower" | grep -qiE "$gemini_keywords"; then
    if [ -n "$output" ]; then
        output="$output

"
    fi
    output="${output}🔍 **Gemini提案**: このタスクは調査・分析系です。
   Gemini（無料）で大規模な情報収集が可能です。
   → .gemini/GEMINI.md を参照して依頼文を作成できます。"
fi

# 提案がある場合のみ出力
if [ -n "$output" ]; then
    echo "$output"
fi

exit 0
