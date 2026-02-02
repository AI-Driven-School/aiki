# Claude Code のトークン消費を 95% 削減

コードレビュー・テスト作成・ドキュメント生成を Codex に自動委譲。
Claude Code は設計と実装に集中。API課金を大幅カット。

| タスク | Before | After | 削減 |
|-------|--------|-------|------|
| コードレビュー | 53,000 | 2,500 | **-95%** |
| テスト作成 | 30,000 | 3,000 | **-90%** |
| ドキュメント | 20,000 | 2,000 | **-90%** |

> Claude = 設計・実装 / Codex = テスト・レビュー・ドキュメント

---

## インストール

```bash
curl -fsSL https://raw.githubusercontent.com/yu010101/claude-codex-collab/main/install-fullstack.sh | bash -s -- my-app
```

インストール後、`claude` を起動するだけ。

---

## 使い方

### 機能追加

```bash
/feature ユーザー認証
```

```
[設計] → [UI生成] → [実装] → [テスト] → [レビュー] → [デプロイ]
Claude   Claude    Claude   Codex    Codex     Vercel
```

### バグ修正

```bash
/fix ログインエラー
```

### UI生成

```bash
/ui ログインフォーム
/page ダッシュボード
```

### デプロイ

```bash
/deploy
```

---

## コマンド一覧

| コマンド | 説明 |
|---------|------|
| `/feature <名前>` | 機能追加（設計→実装→テスト→デプロイ） |
| `/fix <内容>` | バグ修正（調査→修正→レビュー） |
| `/ui <名前>` | UIコンポーネント生成 |
| `/page <名前>` | ページ全体のUI生成 |
| `/deploy` | 本番デプロイ |
| `/review` | コードレビュー実行 |
| `/test <path>` | テスト生成 |

---

## 動作環境

- macOS / Linux / WSL2
- Node.js 18+
- Claude Code (`npm i -g @anthropic-ai/claude-code`)
- Codex (`npm i -g @openai/codex`)

---

## 計測方法

```bash
# ユーザー認証機能の実装で計測
Claude単独: 53,247トークン
本ツール使用: 2,891トークン（テスト・レビューをCodex委譲）
```

削減率は実際のプロジェクトで計測した値です。

---

MIT License | [最小構成版](https://raw.githubusercontent.com/yu010101/claude-codex-collab/main/install.sh) | [Issue](https://github.com/yu010101/claude-codex-collab/issues) | [PR](https://github.com/yu010101/claude-codex-collab/pulls)
