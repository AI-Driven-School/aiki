#!/bin/bash
#
# post-impl-check.sh - 実装後チェックフック
# Edit/Write ツール使用後に、レビューやテストを提案
#

# 編集回数をトラッキング（セッション中の累積）
COUNTER_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/.edit_counter"

# カウンターを読み込み・インクリメント
if [ -f "$COUNTER_FILE" ]; then
    count=$(cat "$COUNTER_FILE")
    count=$((count + 1))
else
    count=1
fi
echo "$count" > "$COUNTER_FILE"

# 5回の編集ごとにレビュー提案
if [ $((count % 5)) -eq 0 ]; then
    echo "✅ **レビュータイミング**
   $count 件のファイル編集が完了しました。

   推奨アクション:
   - \`/review\` でコードレビューを実行
   - \`git diff\` で変更内容を確認
   - テストを実行して動作確認"
fi

exit 0
