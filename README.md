# 一人で作っても、設計書が残る

[![GitHub Sponsors](https://img.shields.io/github/sponsors/yu010101?style=for-the-badge&logo=github&label=Sponsor)](https://github.com/sponsors/yu010101)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](LICENSE)

```bash
/project ユーザー認証
```

1コマンドで要件定義→設計→実装→テスト→デプロイ。
Claude + Codex + Gemini が分担。あなたは承認するだけ。

**コスト95%削減**（トークン消費を3AIで最適分散）

---

## 動作イメージ

```
> /project ユーザー認証

[1/8] 要件定義を生成しました
      → docs/requirements/auth.md
      承認？ [Y/n] Y

[2/8] 画面設計を生成しました
      → docs/specs/login.md
      → mockups/login.png
      承認？ [Y/n] Y

[3/8] API設計を生成しました
      → docs/api/auth.yaml
      承認？ [Y/n] Y

[4/8] DB設計を生成しました
      → migrations/001_users.sql
      承認？ [Y/n] Y

[5/8] 実装中...（自動）
[6/8] テスト生成中...（自動）
[7/8] レビュー中...（自動）

[8/8] デプロイ準備完了
      本番に出しますか？ [Y/n] Y

✅ https://my-app.vercel.app
```

設計4回承認、あとは自動。成果物は全てドキュメント化。

---

## なぜ必要か

| 課題 | このツールで解決 |
|------|-----------------|
| 一人で全部やると設計が雑になる | 要件→API→DBの順で強制的に設計 |
| AIに任せきりで不安 | 承認ポイントで人間がチェック |
| Claude Code課金が高い | Codex/Geminiに分散して95%削減 |
| 後から「なぜこうした」が分からない | docs/に全て残る |

---

## インストール

```bash
curl -fsSL https://raw.githubusercontent.com/yu010101/claude-codex-collab/main/install-fullstack.sh | bash -s -- my-app
cd my-app
claude
```

3つのAI CLIが未インストールなら自動でインストール。

---

## コスト比較

| 作業 | Claude単独 | 3AI分担 | 削減 |
|------|-----------|---------|------|
| 機能追加（設計〜デプロイ） | 80,000トークン | 15,000 | -81% |
| テスト生成 | 30,000 | 3,000 | -90% |
| リファクタリング | 50,000 | 0（Gemini無料枠） | -100% |

---

## 成果物

```
docs/
├── requirements/   # 要件定義（ユーザーストーリー）
├── specs/          # 画面設計（コンポーネント一覧）
├── api/            # API設計（OpenAPI 3.0）
└── reviews/        # レビュー記録
mockups/            # 画面モックアップ（PNG）
migrations/         # DBマイグレーション（SQL）
```

一人で作っても、チーム開発と同じドキュメントが残る。

---

## 動作環境

- macOS / Linux / WSL2
- Node.js 18+

---

<details>
<summary>詳細オプション</summary>

### 個別コマンド

`/project` を使わず、フェーズごとに実行したい場合：

```bash
/requirements ユーザー認証    # 要件定義のみ
/spec ログイン画面           # 画面設計のみ
/api 認証API                # API設計のみ
/schema users               # DB設計のみ
/implement                  # 実装
/test                       # テスト生成
/review                     # レビュー
/deploy                     # デプロイ
```

### 分析・調査

```bash
/analyze              # Geminiで大規模コード解析
/research "質問"      # Geminiで技術リサーチ
/refactor src/        # Geminiでリファクタ提案
```

### 3AI分担

| AI | 担当 |
|----|------|
| Claude Code | 設計・実装・デプロイ |
| Codex | テスト・レビュー |
| Gemini | 解析・リサーチ・リファクタ |

</details>

---

---

## ドキュメント

| ドキュメント | 内容 |
|------------|------|
| [導入ガイド](./docs/GETTING_STARTED.md) | インストール・セットアップ |
| [ハンズオン](./docs/HANDS_ON_TUTORIAL.md) | TODOアプリを作るチュートリアル |
| [コマンド一覧](./docs/COMMANDS.md) | 全コマンドのリファレンス |
| [モックアップ](./docs/MOCKUPS.md) | 画面モックアップの作り方 |

### サンプルモックアップ

- [ログイン画面](./docs/examples/mockup-login.html)
- [TODOアプリ](./docs/examples/mockup-todo.html)
- [ダッシュボード](./docs/examples/mockup-dashboard.html)

---

MIT License | [Issue](https://github.com/yu010101/claude-codex-collab/issues) | [PR](https://github.com/yu010101/claude-codex-collab/pulls)
