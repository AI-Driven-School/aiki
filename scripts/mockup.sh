#!/bin/bash
# モックアップ生成ヘルパースクリプト
#
# 使用方法:
#   ./scripts/mockup.sh "ログイン画面" iphone
#   ./scripts/mockup.sh "ダッシュボード" desktop
#

set -e

NAME="$1"
DEVICE="${2:-iphone}"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if [ -z "$NAME" ]; then
    echo "📱 モックアップ生成"
    echo ""
    echo "使用方法: $0 \"画面名\" [device]"
    echo ""
    echo "デバイス: iphone, iphone-se, ipad, desktop, macbook"
    exit 1
fi

# ファイル名生成（日本語対応）
FILENAME=$(echo "$NAME" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
HTML_FILE="$PROJECT_DIR/mockups/temp-${TIMESTAMP}.html"
PNG_FILE="$PROJECT_DIR/mockups/${FILENAME}-${TIMESTAMP}.png"

mkdir -p "$PROJECT_DIR/mockups"

echo "📱 モックアップ生成: $NAME ($DEVICE)"
echo ""

# Playwrightがインストールされているか確認
if ! npm list playwright --prefix "$PROJECT_DIR" &> /dev/null; then
    echo "📦 Playwrightをインストール中..."
    npm install --prefix "$PROJECT_DIR" playwright
    npx --prefix "$PROJECT_DIR" playwright install chromium
fi

# HTMLファイルが存在するか確認（stdinから読み込む場合）
if [ -t 0 ]; then
    echo "⚠️  HTMLを標準入力から読み込むか、HTMLファイルを指定してください"
    echo ""
    echo "例:"
    echo "  cat mockup.html | $0 \"$NAME\" $DEVICE"
    echo "  $0 \"$NAME\" $DEVICE < mockup.html"
    exit 1
fi

# stdinからHTMLを読み込んで一時ファイルに保存
cat > "$HTML_FILE"

# レンダリング実行
node "$PROJECT_DIR/scripts/render-mockup.js" "$HTML_FILE" "$PNG_FILE" "$DEVICE"

# 一時ファイル削除
rm -f "$HTML_FILE"

echo ""
echo "📎 Markdownで使用:"
echo "![${NAME}](./mockups/$(basename "$PNG_FILE"))"
