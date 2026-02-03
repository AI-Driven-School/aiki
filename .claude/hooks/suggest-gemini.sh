#!/bin/bash
#
# suggest-gemini.sh - Gemini委譲提案フック
# WebSearch/WebFetch ツール使用前に、Geminiへの委譲を提案
#

echo "🌐 **Web調査タスク検出**
   大規模な調査・比較分析はGemini（無料）が得意です。

   Geminiに依頼する場合:
   1. .gemini/GEMINI.md の指示テンプレートを使用
   2. 調査結果を .claude/docs/research/ に保存するよう依頼

   このまま続行する場合: 特に操作不要（Claudeが検索します）"

exit 0
