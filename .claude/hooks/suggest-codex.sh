#!/bin/bash
#
# suggest-codex.sh - Codex委譲提案フック
# Edit/Write ツール使用前に、Codexへの委譲を提案
#

# 環境変数から情報取得
# shellcheck disable=SC2034
tool_name="${CLAUDE_TOOL_NAME:-unknown}"

# 大規模な編集の場合のみ提案（小さな修正はClaudeで直接実行）
# この判定は将来的により洗練させる

echo "📝 **実装タスク検出**
   複数ファイルの編集や新規実装は、Codexに委譲すると効率的です。

   委譲する場合:
   1. \`/implement <タスク説明>\` を実行
   2. または .codex/AGENTS.md の指示をCodexにコピー

   このまま続行する場合: 特に操作不要（Claudeが実装します）"

exit 0
