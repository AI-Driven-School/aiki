# Getting Started - 導入ガイド

## 概要

3AI協調開発テンプレートは、Claude Code + Codex + Gemini を連携させて、要件定義からデプロイまでを自動化するCLIツールです。

```
┌─────────────────────────────────────────────────────────────┐
│  /project ユーザー認証                                       │
│                                                             │
│  [1/8] 要件定義      → docs/requirements/auth.md   ✓ 承認   │
│  [2/8] 画面設計      → docs/specs/login.md         ✓ 承認   │
│  [3/8] API設計       → docs/api/auth.yaml          ✓ 承認   │
│  [4/8] DB設計        → migrations/001_users.sql    ✓ 承認   │
│  [5/8] 実装          → src/                        自動     │
│  [6/8] テスト生成    → tests/                      自動     │
│  [7/8] レビュー      → docs/reviews/               自動     │
│  [8/8] デプロイ      → https://my-app.vercel.app   ✓ 承認   │
└─────────────────────────────────────────────────────────────┘
```

---

## 動作要件

| 項目 | 要件 |
|------|-----|
| OS | macOS / Linux / WSL2 |
| Node.js | 18.0 以上 |
| Git | 最新版推奨 |

---

## インストール

### 方法1: ワンライナー（推奨）

```bash
curl -fsSL https://raw.githubusercontent.com/yu010101/claude-codex-collab/main/install-fullstack.sh | bash -s -- my-project
```

### 方法2: 既存プロジェクトに追加

```bash
cd your-project
curl -fsSL https://raw.githubusercontent.com/yu010101/claude-codex-collab/main/install-fullstack.sh | bash
```

### 方法3: 手動インストール

```bash
# リポジトリをクローン
git clone https://github.com/yu010101/claude-codex-collab.git
cd claude-codex-collab

# 既存プロジェクトにコピー
cp -r .claude/ /path/to/your-project/
cp CLAUDE.md AGENTS.md /path/to/your-project/
cp -r scripts/ /path/to/your-project/
```

---

## AI CLIのインストール

インストールスクリプトは自動でAI CLIをインストールしますが、手動の場合:

```bash
# Claude Code（必須）
npm install -g @anthropic-ai/claude-code

# Codex（テスト・レビュー用）
npm install -g @openai/codex

# Gemini CLI（解析・リサーチ用）
npm install -g @google/gemini-cli
```

### APIキーの設定

各AIツールには対応するAPIキーが必要です:

```bash
# Claude
export ANTHROPIC_API_KEY="your-key"

# OpenAI (Codex)
export OPENAI_API_KEY="your-key"

# Google AI (Gemini)
export GOOGLE_AI_API_KEY="your-key"
```

---

## ディレクトリ構造

インストール後のプロジェクト構造:

```
my-project/
├── .claude/
│   └── skills/           # Claudeスキル定義
│       ├── project.md
│       ├── requirements.md
│       ├── spec.md
│       ├── api.md
│       ├── schema.md
│       ├── mockup.md
│       ├── implement.md
│       ├── test.md
│       ├── review.md
│       └── deploy.md
├── scripts/
│   └── delegate.sh       # AI委譲スクリプト
├── docs/
│   ├── requirements/     # 要件定義書
│   ├── specs/            # 画面設計書
│   ├── api/              # API設計（OpenAPI）
│   ├── decisions/        # 設計判断記録
│   └── reviews/          # レビュー記録
├── mockups/              # 画面モックアップ（PNG）
├── migrations/           # DBマイグレーション
├── .tasks/               # AI実行ログ（gitignore）
├── CLAUDE.md             # Claude用プロジェクト設定
├── AGENTS.md             # マルチAI協調ガイド
└── .gitignore
```

---

## クイックスタート

### 1. プロジェクト作成

```bash
curl -fsSL https://raw.githubusercontent.com/yu010101/claude-codex-collab/main/install-fullstack.sh | bash -s -- todo-app
cd todo-app
```

### 2. Claude Code起動

```bash
claude
```

### 3. 開発開始

```
> /project TODOアプリ
```

これで8フェーズの承認ワークフローが始まります。

---

## 次のステップ

- [ハンズオンチュートリアル](./HANDS_ON_TUTORIAL.md) - TODOアプリを実際に作る
- [コマンドリファレンス](./COMMANDS.md) - 全コマンドの詳細
- [モックアップガイド](./MOCKUPS.md) - 画面モックアップの作り方

---

## トラブルシューティング

### Claude Codeが起動しない

```bash
# 再インストール
npm uninstall -g @anthropic-ai/claude-code
npm install -g @anthropic-ai/claude-code

# APIキー確認
echo $ANTHROPIC_API_KEY
```

### Codex/Geminiが動かない

```bash
# パスを確認
which codex
which gemini

# 手動で実行テスト
codex --version
gemini --version
```

### スキルが認識されない

```bash
# .claude/skills/ ディレクトリを確認
ls -la .claude/skills/

# Claudeを再起動
claude
```
