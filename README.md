# 3つのAIを、適材適所で

[![GitHub Sponsors](https://img.shields.io/github/sponsors/yu010101?style=for-the-badge&logo=github&label=Sponsor)](https://github.com/sponsors/yu010101)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](LICENSE)

```bash
/project ユーザー認証
```

**Claude** で設計、**Codex** で爆速実装、**Gemini** で大規模解析。
各AIの強みを活かした分業で、品質とスピードを両立。

---

## なぜ3AI？

| AI | 強み | 役割 |
|----|------|------|
| **Claude** | 推論・設計判断 | 要件定義、アーキテクチャ、レビュー |
| **Codex** | 実装速度・full-auto | コーディング、テスト生成 |
| **Gemini** | 1Mトークン・無料 | 大規模解析、リサーチ |

**単一AIの限界:**
- Claude だけ → 実装遅い、課金高い
- Codex だけ → 設計判断が弱い
- Gemini だけ → 実装精度が不安定

**3AI連携の強み:**
- Claude の設計力 × Codex の実装速度 × Gemini の解析力

---

## 動作イメージ

```
> /project ユーザー認証

[Claude] 要件定義を生成...
         → docs/requirements/auth.md
         承認？ [Y/n] Y

[Claude] API設計を生成...
         → docs/api/auth.yaml
         承認？ [Y/n] Y

[Codex]  実装中...（full-auto）
         → src/app/login/page.tsx
         → src/lib/api/auth.ts

[Codex]  テスト生成中...
         → tests/auth.spec.ts

[Claude] レビュー中...
         → 2件の改善提案

[Claude] デプロイ準備完了
         本番に出しますか？ [Y/n] Y

✅ https://my-app.vercel.app
```

---

## コスト構造

| AI | 課金 | 使い方 |
|----|------|--------|
| Claude Code | 従量課金 | **設計・判断のみ**（トークン節約） |
| Codex | ChatGPT Pro に含む | **実装・テスト**（無制限） |
| Gemini | 無料 | **解析・リサーチ** |

> Claude の課金を最小化しつつ、Codex で爆速実装

---

## インストール

```bash
curl -fsSL https://raw.githubusercontent.com/yu010101/claude-codex-collab/main/install-fullstack.sh | bash -s -- my-app
cd my-app
claude
```

### 前提条件

| ツール | 必要なアカウント |
|--------|----------------|
| Claude Code | Anthropic アカウント |
| Codex | ChatGPT Plus/Pro |
| Gemini | Google アカウント |

---

## ワークフロー

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│   [1] 要件定義    Claude    ← 推論・判断                    │
│         ↓                                                   │
│   [2] 設計        Claude    ← アーキテクチャ決定            │
│         ↓                                                   │
│   [3] 実装        Codex     ← full-auto で爆速             │
│         ↓                                                   │
│   [4] テスト      Codex     ← 実装と一貫性                  │
│         ↓                                                   │
│   [5] レビュー    Claude    ← 品質チェック                  │
│         ↓                                                   │
│   [6] デプロイ    Claude    ← 最終判断                      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 成果物

```
docs/
├── requirements/   # 要件定義（Claude）
├── specs/          # 画面設計（Claude）
├── api/            # API設計（Claude）
└── reviews/        # レビュー記録（Claude）
src/                # 実装コード（Codex）
tests/              # テスト（Codex）
```

---

## コマンド一覧

### プロジェクト管理

| コマンド | 説明 |
|---------|------|
| `/project <機能>` | 設計→実装→デプロイの完全フロー |
| `/status` | 進捗確認 |

### 設計（Claude）

| コマンド | 説明 |
|---------|------|
| `/requirements <機能>` | 要件定義 |
| `/spec <画面>` | 画面設計 |
| `/api <エンドポイント>` | API設計 |
| `/review` | コードレビュー |

### 実装（Codex）

| コマンド | 説明 |
|---------|------|
| `/implement` | 設計書から実装 |
| `/test` | テスト生成 |

### 解析（Gemini）

| コマンド | 説明 |
|---------|------|
| `/analyze` | 大規模コード解析 |
| `/research <質問>` | 技術リサーチ |

---

## 動作環境

- macOS / Linux / WSL2
- Node.js 18+
- ChatGPT Plus/Pro（Codex用）

---

## ドキュメント

| ドキュメント | 内容 |
|------------|------|
| [導入ガイド](./docs/GETTING_STARTED.md) | インストール・セットアップ |
| [ハンズオン](./docs/HANDS_ON_TUTORIAL.md) | TODOアプリを作るチュートリアル |
| [コマンド一覧](./docs/COMMANDS.md) | 全コマンドのリファレンス |

---

MIT License | [GitHub](https://github.com/yu010101/claude-codex-collab) | [Issue](https://github.com/yu010101/claude-codex-collab/issues)
