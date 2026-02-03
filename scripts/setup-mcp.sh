#!/bin/bash

# setup-mcp.sh - MCPサーバーのセットアップスクリプト
# AI Orchestratorを設定し、Claude Codeと連携させます

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MCP_DIR="$PROJECT_ROOT/.claude/mcp-servers/ai-orchestrator"

# カラー出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_step() {
    echo -e "${BLUE}▶${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# ヘッダー
print_header "AI Orchestrator MCP セットアップ"

echo "このスクリプトは以下を設定します："
echo "  1. MCPサーバーの依存関係をインストール"
echo "  2. TypeScriptをビルド"
echo "  3. Claude Code設定ファイルを生成"
echo ""

# Node.jsの確認
print_step "Node.jsのバージョンを確認中..."
if ! command -v node &> /dev/null; then
    print_error "Node.jsがインストールされていません"
    echo "  brew install node@20"
    exit 1
fi

NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    print_error "Node.js 18以上が必要です（現在: v$NODE_VERSION）"
    exit 1
fi
print_success "Node.js $(node --version)"

# 依存関係のインストール
print_step "MCPサーバーの依存関係をインストール中..."
cd "$MCP_DIR"
npm install --silent
print_success "依存関係をインストールしました"

# ビルド
print_step "TypeScriptをビルド中..."
npm run build --silent
print_success "ビルド完了"

# Claude Code設定ディレクトリ
CLAUDE_CONFIG_DIR="$HOME/.claude"
CLAUDE_CONFIG_FILE="$CLAUDE_CONFIG_DIR/claude_desktop_config.json"

print_step "Claude Code設定を確認中..."

# 設定ディレクトリを作成
mkdir -p "$CLAUDE_CONFIG_DIR"

# 環境変数の確認
MISSING_KEYS=""
if [ -z "$OPENAI_API_KEY" ]; then
    MISSING_KEYS="$MISSING_KEYS OPENAI_API_KEY"
fi
if [ -z "$GEMINI_API_KEY" ]; then
    MISSING_KEYS="$MISSING_KEYS GEMINI_API_KEY"
fi

if [ -n "$MISSING_KEYS" ]; then
    print_warning "以下の環境変数が設定されていません:$MISSING_KEYS"
    echo ""
    echo "  ~/.zshrc または ~/.bashrc に以下を追加してください:"
    echo ""
    if [ -z "$OPENAI_API_KEY" ]; then
        echo "    export OPENAI_API_KEY=\"your-openai-api-key\""
    fi
    if [ -z "$GEMINI_API_KEY" ]; then
        echo "    export GEMINI_API_KEY=\"your-gemini-api-key\""
    fi
    echo ""
fi

# 設定ファイルを生成
MCP_ENTRY="{
  \"command\": \"node\",
  \"args\": [\"$MCP_DIR/dist/index.js\"]
}"

if [ -f "$CLAUDE_CONFIG_FILE" ]; then
    print_warning "既存の設定ファイルが見つかりました: $CLAUDE_CONFIG_FILE"
    echo ""
    echo "  以下の設定を手動で追加してください:"
    echo ""
    echo "  \"mcpServers\": {"
    echo "    \"ai-orchestrator\": $MCP_ENTRY"
    echo "  }"
else
    # 新規作成
    cat > "$CLAUDE_CONFIG_FILE" << EOF
{
  "mcpServers": {
    "ai-orchestrator": {
      "command": "node",
      "args": ["$MCP_DIR/dist/index.js"]
    }
  }
}
EOF
    print_success "設定ファイルを作成しました: $CLAUDE_CONFIG_FILE"
fi

# 完了メッセージ
print_header "セットアップ完了"

echo "次のステップ:"
echo ""
echo "  1. 環境変数を設定（まだの場合）:"
echo "     export OPENAI_API_KEY=\"your-key\""
echo "     export GEMINI_API_KEY=\"your-key\""
echo ""
echo "  2. Claude Codeを再起動"
echo ""
echo "  3. 動作確認:"
echo "     Claude Codeで「認証機能を実装して」と入力すると"
echo "     自動的にCodexに委譲されます"
echo ""

# 使用可能なツールを表示
echo -e "${CYAN}利用可能なMCPツール:${NC}"
echo ""
echo "  • delegate_to_codex  - 実装タスクをCodexに委譲"
echo "  • delegate_to_gemini - 調査・分析をGeminiに委譲"
echo "  • auto_delegate      - 自動的に適切なAIに委譲"
echo "  • get_orchestration_status - 各AIの状態を確認"
echo ""
