# Claude Code + Codex フルスタック開発テンプレート

Claude Code + Codex + Supabase + Vercel + frontend-design を統合した、AI駆動フルスタック開発テンプレートです。

## 特徴

- 🤖 **AI連携**: Claude Code + Codex 自動タスク委譲
- 🎨 **デザイン**: frontend-design スキルで高品質UI生成
- 🗄️ **バックエンド**: Supabase (PostgreSQL + Auth + Storage)
- 🚀 **デプロイ**: Vercel ワンクリックデプロイ
- ⚡ **ワークフロー**: 機能追加・バグ修正の自動化

## クイックスタート

### フルスタック版（推奨）

```bash
curl -fsSL https://raw.githubusercontent.com/yu010101/claude-codex-collab/main/install-fullstack.sh | bash -s -- my-app
```

### 基本版（AI連携のみ）

```bash
curl -fsSL https://raw.githubusercontent.com/yu010101/claude-codex-collab/main/install.sh | bash
```

## カスタムスキル

### デザインスキル 🎨

```bash
/design ログインフォーム              # UIコンポーネント生成
/design-page ダッシュボード           # ページ全体のデザイン
/design-system                        # デザインシステム構築
```

### 開発スキル 💻

```bash
/new-feature ユーザー認証             # 機能追加ワークフロー
/fix-bug ログインエラー               # バグ修正ワークフロー
/review                               # Codexコードレビュー
/test src/components/                 # テスト生成
```

### インフラスキル 🏗️

```bash
/deploy                               # Vercel本番デプロイ
/deploy-preview                       # プレビューデプロイ
/db-push                              # Supabaseマイグレーション
/db-gen                               # 型定義生成
/setup-env                            # 環境変数セットアップ
```

## ワークフロー自動化

### /new-feature ワークフロー

```
[依頼] → [設計] → [UI生成] → [実装] → [テスト] → [レビュー] → [デプロイ]
         Plan    design    Claude   Codex    Codex     Vercel
```

### /fix-bug ワークフロー

```
[報告] → [調査] → [修正] → [レビュー] → [デプロイ]
        Explore  Claude    Codex      Vercel
```

## ファイル構成

```
your-project/
├── CLAUDE.md                 # Claude Code設定（自動読み込み）
├── AGENTS.md                 # エージェント共有情報
├── TODO.md                   # タスク管理
├── .claude/
│   └── skills/              # カスタムスキル
│       ├── design.md        # /design
│       ├── deploy.md        # /deploy
│       ├── db.md            # /db-push, /db-gen
│       ├── new-feature.md   # /new-feature
│       └── fix-bug.md       # /fix-bug
├── scripts/
│   ├── auto-delegate.sh     # Codex委譲
│   ├── check-codex-task.sh  # タスク確認
│   └── setup-env.sh         # 環境変数設定
└── .codex-tasks/            # タスク出力
```

## セットアップ後の手順

```bash
# 1. Next.jsプロジェクト作成
npx create-next-app@latest . --typescript --tailwind --app

# 2. Supabase初期化
supabase init
supabase start

# 3. Vercel連携
vercel link

# 4. 環境変数設定
./scripts/setup-env.sh

# 5. Claude Code起動
claude
```

## 使用例

### 新機能追加

```
> /new-feature ユーザープロフィール編集機能

[Plan] 設計中...
- プロフィール編集フォーム
- Supabase users テーブル更新API
- 画像アップロード機能

[Design] UI生成中...
✓ ProfileEditForm.tsx 作成

[実装] ロジック実装中...
✓ app/profile/edit/page.tsx
✓ lib/supabase/profile.ts

[Test] テスト生成中... (Codex)
✓ __tests__/profile.test.tsx

[Review] レビュー中... (Codex)
✓ 問題なし

[Deploy] プレビューデプロイ中...
✓ https://my-app-xxx.vercel.app
```

### バグ修正

```
> /fix-bug ログイン後にリダイレクトされない

[Explore] 調査中...
原因: middleware.ts のリダイレクト条件が不正

[修正]
✓ middleware.ts 修正完了

[Review] レビュー中... (Codex)
✓ 問題なし

[Deploy]
✓ デプロイ完了
```

## タスク分担

| タスク | 担当 | 理由 |
|-------|------|------|
| 設計・計画 | Claude Code | コンテキスト理解 |
| UIデザイン | Claude Code | frontend-design |
| ロジック実装 | Claude Code | 複雑な処理 |
| **コードレビュー** | **Codex** | 自動化・高速 |
| **テスト作成** | **Codex** | 定型作業 |
| **ドキュメント** | **Codex** | 定型作業 |

## トークン削減効果

| タスク | Claude単独 | 連携時 | 削減率 |
|-------|-----------|-------|--------|
| コードレビュー | ~53,000 | ~2,500 | **95%** |
| テスト作成 | ~30,000 | ~3,000 | **90%** |
| ドキュメント | ~20,000 | ~2,000 | **90%** |

## 必要条件

- Node.js 18+
- npm / pnpm
- Git

### 推奨ツール

```bash
# AI開発ツール
npm install -g @anthropic-ai/claude-code
npm install -g @openai/codex

# クラウドツール
npm install -g supabase
npm install -g vercel
```

## ライセンス

MIT License

## 貢献

Issue・Pull Requestを歓迎します！
