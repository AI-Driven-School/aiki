# Claude Code + Codex 自動連携テンプレート

Claude Code（Anthropic）とCodex CLI（OpenAI）を自動連携させ、効率的なAI駆動開発を実現するテンプレートです。

## 特徴

- **自動タスク委譲**: 「レビューして」と言うだけでCodexが自動実行
- **トークン節約**: 定型タスクをCodexに委譲し、約95%のトークン削減
- **並列実行**: バックグラウンドでCodexを実行しながら開発継続
- **サブエージェント活用**: 調査・計画を自動的にサブエージェントに委託

## クイックスタート

### ワンラインインストール

```bash
curl -fsSL https://raw.githubusercontent.com/yu010101/claude-codex-collab/main/install.sh | bash
```

### 既存プロジェクトに導入

```bash
cd your-project
curl -fsSL https://raw.githubusercontent.com/yu010101/claude-codex-collab/main/install.sh | bash -s -- .
```

## 必要条件

- [Claude Code](https://claude.ai/claude-code) (`claude` コマンド)
- [Codex CLI](https://github.com/openai/codex) (`codex` コマンド)

```bash
# インストール確認
claude --version
codex --version
```

## 使い方

### 1. Claude Codeを起動

```bash
claude
```

### 2. 自動連携キーワード

以下のキーワードを含む指示で、自動的にCodexに委譲されます：

| キーワード | 動作 |
|-----------|------|
| 「レビュー」「review」 | コードレビュー実行 |
| 「テスト作成」「test」 | ユニットテスト生成 |
| 「ドキュメント」 | ドキュメント生成 |
| 「リファクタ」 | コード整理 |

### 3. 手動でCodexに委譲

```bash
# コードレビュー
./scripts/auto-delegate.sh review

# 特定ブランチとの差分レビュー
./scripts/auto-delegate.sh review main

# テスト作成
./scripts/auto-delegate.sh test src/services/

# ドキュメント生成
./scripts/auto-delegate.sh docs

# カスタムタスク
./scripts/auto-delegate.sh custom "APIのエラーハンドリングを改善して"

# バックグラウンド実行
./scripts/auto-delegate.sh background "全ファイルのリファクタリング"
```

### 4. タスク状態確認

```bash
# 最新タスクの確認
./scripts/check-codex-task.sh

# 特定タスクの確認
./scripts/check-codex-task.sh 20240201-143022
```

## ファイル構成

```
your-project/
├── CLAUDE.md              # Claude Code自動ルール（自動読み込み）
├── AGENTS.md              # エージェント共有情報（Codex自動読み込み）
├── TODO.md                # タスク管理
├── scripts/
│   ├── auto-delegate.sh   # Codex委譲スクリプト
│   └── check-codex-task.sh # タスク確認スクリプト
└── .codex-tasks/          # タスク出力（gitignore済み）
```

## 推奨タスク分担

| タスク | 担当 | 理由 |
|-------|------|------|
| 設計・計画 | Claude Code | コンテキスト理解が重要 |
| 複雑な実装 | Claude Code | 既存コードとの整合性 |
| デバッグ | Claude Code | 対話的な調査が必要 |
| **コードレビュー** | **Codex** | `codex review`で自動化 |
| **テスト作成** | **Codex** | 定型作業 |
| **ドキュメント** | **Codex** | 定型作業 |
| **リファクタリング** | **Codex** | 単純な整理 |

## トークン消費量の比較

| タスク | Claude単独 | 連携時 | 削減率 |
|-------|-----------|-------|--------|
| コードレビュー | ~53,000 | ~2,500 | **95%** |
| テスト作成 | ~30,000 | ~3,000 | **90%** |
| ドキュメント | ~20,000 | ~2,000 | **90%** |

## カスタマイズ

### CLAUDE.md

プロジェクト固有のルールを追加：

```markdown
## プロジェクト概要
<!-- プロジェクトの説明 -->

## コーディング規約
<!-- プロジェクト固有のルール -->
```

### AGENTS.md

エージェント共有情報を追加：

```markdown
## ディレクトリ構造
<!-- プロジェクトの構造 -->

## 重要なファイル
<!-- 主要ファイルの説明 -->
```

## トラブルシューティング

### Codexが実行されない

```bash
# Codexの動作確認
codex --help

# 認証確認
codex login
```

### タスクがバックグラウンドで失敗

```bash
# ログを確認
cat .codex-tasks/output-*.txt
```

## ライセンス

MIT License

## 貢献

Issue・Pull Requestを歓迎します！
