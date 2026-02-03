# AI Orchestrator MCP Server

Claude Code用のMCPサーバー。会話の中で自動的にCodex CLI（$0）とGemini CLI（無料）にタスクを委譲します。

**APIキー不要** - すべてCLIベースで動作します。

## 機能

| ツール | 説明 | コスト |
|--------|------|--------|
| `delegate_to_codex` | 実装タスクをCodex CLIに委譲 | **$0** |
| `delegate_to_gemini` | 調査・分析タスクをGemini CLIに委譲 | **無料** |
| `auto_delegate` | メッセージを解析して自動的に適切なAIに委譲 | - |
| `get_orchestration_status` | 各AI CLIの状態を確認 | - |

## 前提条件

| ツール | 入手方法 |
|--------|----------|
| Codex CLI | ChatGPT Pro契約 ($200/月) → `codex` コマンド |
| Gemini CLI | 無料 → `gemini` コマンド |

## セットアップ

### 1. 依存関係のインストール

```bash
cd .claude/mcp-servers/ai-orchestrator
npm install
```

### 2. ビルド

```bash
npm run build
```

### 3. Claude Codeの設定

`~/.claude/claude_desktop_config.json` を編集:

```json
{
  "mcpServers": {
    "ai-orchestrator": {
      "command": "node",
      "args": ["/path/to/claude-codex-collab/.claude/mcp-servers/ai-orchestrator/dist/index.js"]
    }
  }
}
```

### 4. 簡単セットアップ（推奨）

```bash
./scripts/setup-mcp.sh
```

## 使い方

Claude Codeで以下のように使用できます：

### 自動委譲（話しかけるだけ）
```
「認証機能を実装して」
→ 自動的にCodex CLIに委譲されて実装される（$0）

「ReactとVueを比較して」
→ 自動的にGemini CLIに委譲されて比較分析される（無料）

「この設計について説明して」
→ Claudeが処理（設計・説明はClaudeの得意分野）
```

### 明示的な委譲
```
Codexに委譲: ログイン機能のテストを書いて
Geminiに委譲: Next.js 14のベストプラクティスを調査して
```

## タスク分類ルール

### Codex CLIに委譲されるタスク（$0）
- 実装、create、build、write code
- テスト、unit test
- リファクタ、optimize
- バグ修正、fix
- コードレビュー

### Gemini CLIに委譲されるタスク（無料）
- 調査、research、investigate
- 比較、compare、vs
- 分析、analyze
- アーキテクチャ提案
- ライブラリ選定

### Claudeが処理するタスク
- 要件定義、仕様
- 設計
- 説明、解説
- 質問

## CLIがインストールされていない場合

MCPサーバーはCLIが未インストールでも動作します。
その場合、Webインターフェースで実行するためのプロンプトを生成します：

- Codex未インストール → ChatGPT Pro (https://chatgpt.com) 用プロンプト
- Gemini未インストール → Gemini (https://gemini.google.com) 用プロンプト

## 開発

```bash
# 開発モード
npm run dev

# ビルド
npm run build

# 実行
npm start
```

## ライセンス

MIT
