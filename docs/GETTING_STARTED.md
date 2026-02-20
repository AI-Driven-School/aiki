# Getting Started - 導入ガイド

## 概要

4AI適材適所テンプレートは、**Claude × Codex × Gemini** の強みを活かして開発を効率化するCLIツールです。

```
┌─────────────────────────────────────────────────────────────┐
│  /project ユーザー認証                                       │
│                                                             │
│  [1/6] 要件定義      → docs/requirements/auth.md   ✓ 承認   │
│  [2/6] 設計          → docs/api/auth.yaml          ✓ 承認   │
│  [3/6] 実装          → src/                        自動     │
│  [4/6] テスト        → tests/                      自動     │
│  [5/6] レビュー      → docs/reviews/               自動     │
│  [6/6] デプロイ      → https://my-app.vercel.app   ✓ 承認   │
└─────────────────────────────────────────────────────────────┘
```

---

## 4AI適材適所

| AI | 強み | 役割 | 課金 |
|----|------|------|------|
| **Claude** | 推論・設計判断 | 要件定義、アーキテクチャ、レビュー | 従量課金（節約） |
| **Codex** | 実装速度・full-auto | コーディング、テスト生成 | ChatGPT Proに含む |
| **Gemini** | 1Mトークン | 大規模解析、リサーチ | 無料 |

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
curl -fsSL https://raw.githubusercontent.com/AI-Driven-School/aiki/main/install-fullstack.sh | bash -s -- my-project
```

### 方法2: 既存プロジェクトに追加

```bash
cd your-project
curl -fsSL https://raw.githubusercontent.com/AI-Driven-School/aiki/main/install-fullstack.sh | bash
```

### 方法3: 手動インストール

```bash
# リポジトリをクローン
git clone https://github.com/AI-Driven-School/aiki.git
cd aiki

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

# Codex（実装・テスト用）
npm install -g @openai/codex

# Gemini CLI（解析・リサーチ用）
npm install -g @google/gemini-cli
```

### 認証方法（APIキー不要）

各AIツールはアカウントベースの認証を使用します:

```bash
# Claude Code
claude  # 初回起動時にAnthropicアカウントでログイン

# Codex
codex   # ChatGPT Plus/Proアカウントでログイン

# Gemini CLI（Google Cloud認証）
export GOOGLE_GENAI_USE_GCA=true  # ~/.zshrc に追加
gemini  # Googleアカウントで認証
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
│       ├── implement.md    # → Codexに委譲
│       ├── test.md         # → Codexに委譲
│       ├── review.md
│       └── deploy.md
├── scripts/
│   └── delegate.sh       # AI委譲スクリプト
├── docs/
│   ├── requirements/     # 要件定義書（Claude）
│   ├── specs/            # 画面設計書（Claude）
│   ├── api/              # API設計（Claude）
│   └── reviews/          # レビュー記録（Claude）
├── CLAUDE.md             # Claude用プロジェクト設定
├── AGENTS.md             # マルチAI協調ガイド
└── .gitignore
```

---

## クイックスタート

### 1. プロジェクト作成

```bash
curl -fsSL https://raw.githubusercontent.com/AI-Driven-School/aiki/main/install-fullstack.sh | bash -s -- todo-app
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

これで6フェーズの承認ワークフローが始まります。

---

## ワークフロー

```
[1] 要件定義    Claude    ← 推論・判断
      ↓
[2] 設計        Claude    ← アーキテクチャ決定
      ↓
[3] 実装        Codex     ← full-auto で爆速 ★メイン
      ↓
[4] テスト      Codex     ← 実装と一貫性
      ↓
[5] レビュー    Claude    ← 品質チェック
      ↓
[6] デプロイ    Claude    ← 最終判断
```

---

## 次のステップ

- [既存プロジェクトへの導入](./EXISTING_PROJECT_SETUP.md) - 開発中プロジェクトに導入
- [ハンズオンチュートリアル](./HANDS_ON_TUTORIAL.md) - TODOアプリを実際に作る
- [コマンドリファレンス](./COMMANDS.md) - 全コマンドの詳細

---

## トラブルシューティング

### Claude Codeが起動しない

```bash
# 再インストール
npm uninstall -g @anthropic-ai/claude-code
npm install -g @anthropic-ai/claude-code

# 再ログイン
claude
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

### Gemini認証エラー

```bash
# 環境変数を設定
echo 'export GOOGLE_GENAI_USE_GCA=true' >> ~/.zshrc
source ~/.zshrc

# 再認証
gemini
```

### スキルが認識されない

```bash
# .claude/skills/ ディレクトリを確認
ls -la .claude/skills/

# Claudeを再起動
claude
```
