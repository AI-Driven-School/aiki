#!/bin/bash
#
# checkpoint.sh - セッション状態の保存スクリプト
#
# 使用方法:
#   ./scripts/checkpoint.sh          # チェックポイント保存
#   ./scripts/checkpoint.sh --analyze # パターン分析
#

set -e

# プロジェクトディレクトリ
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
CHECKPOINT_DIR="$PROJECT_DIR/.claude/checkpoints"

# チェックポイントディレクトリ確認
mkdir -p "$CHECKPOINT_DIR"

# 分析モード
if [ "$1" = "--analyze" ]; then
    echo "## チェックポイント分析"
    echo ""

    # チェックポイント数
    count=$(ls -1 "$CHECKPOINT_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')
    echo "### 統計"
    echo "- 総チェックポイント数: $count"
    echo ""

    if [ "$count" -gt 0 ]; then
        echo "### 最近のチェックポイント"
        ls -1t "$CHECKPOINT_DIR"/*.md 2>/dev/null | head -5 | while read file; do
            basename "$file"
        done
        echo ""

        echo "### よく変更されるファイル"
        grep -h "^- " "$CHECKPOINT_DIR"/*.md 2>/dev/null | \
            grep -v "^- \*\*" | \
            sort | uniq -c | sort -rn | head -10
    fi

    exit 0
fi

# チェックポイント保存モード
TIMESTAMP=$(date +"%Y-%m-%d-%H%M%S")
CHECKPOINT_FILE="$CHECKPOINT_DIR/$TIMESTAMP.md"

echo "# チェックポイント: $TIMESTAMP" > "$CHECKPOINT_FILE"
echo "" >> "$CHECKPOINT_FILE"
echo "## Git状態" >> "$CHECKPOINT_FILE"
echo "" >> "$CHECKPOINT_FILE"

# 現在のブランチ
echo "### ブランチ" >> "$CHECKPOINT_FILE"
echo "\`\`\`" >> "$CHECKPOINT_FILE"
git -C "$PROJECT_DIR" branch --show-current 2>/dev/null >> "$CHECKPOINT_FILE" || echo "(git not available)" >> "$CHECKPOINT_FILE"
echo "\`\`\`" >> "$CHECKPOINT_FILE"
echo "" >> "$CHECKPOINT_FILE"

# 未コミットの変更
echo "### 未コミットの変更" >> "$CHECKPOINT_FILE"
echo "\`\`\`" >> "$CHECKPOINT_FILE"
git -C "$PROJECT_DIR" status --short 2>/dev/null >> "$CHECKPOINT_FILE" || echo "(no changes)" >> "$CHECKPOINT_FILE"
echo "\`\`\`" >> "$CHECKPOINT_FILE"
echo "" >> "$CHECKPOINT_FILE"

# 最近のコミット
echo "### 最近のコミット" >> "$CHECKPOINT_FILE"
echo "\`\`\`" >> "$CHECKPOINT_FILE"
git -C "$PROJECT_DIR" log --oneline -5 2>/dev/null >> "$CHECKPOINT_FILE" || echo "(no commits)" >> "$CHECKPOINT_FILE"
echo "\`\`\`" >> "$CHECKPOINT_FILE"
echo "" >> "$CHECKPOINT_FILE"

# 作業メモセクション
echo "## 作業メモ" >> "$CHECKPOINT_FILE"
echo "" >> "$CHECKPOINT_FILE"
echo "<!-- 作業中のタスクや次のステップをここに記載 -->" >> "$CHECKPOINT_FILE"
echo "" >> "$CHECKPOINT_FILE"
echo "### 進行中のタスク" >> "$CHECKPOINT_FILE"
echo "- " >> "$CHECKPOINT_FILE"
echo "" >> "$CHECKPOINT_FILE"
echo "### 次のステップ" >> "$CHECKPOINT_FILE"
echo "- " >> "$CHECKPOINT_FILE"
echo "" >> "$CHECKPOINT_FILE"
echo "### 決定事項" >> "$CHECKPOINT_FILE"
echo "- " >> "$CHECKPOINT_FILE"

echo "チェックポイントを保存しました: $CHECKPOINT_FILE"
