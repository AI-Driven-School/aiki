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

| AI | 強み | 最適なタスク | コスト |
|----|------|-------------|--------|
| **Claude** | 推論・コード理解 | 複雑な既存コード修正 | 従量課金 |
| **Codex** | 実装速度・full-auto | 単純な新規ファイル作成 | ChatGPT Pro含む |
| **Gemini** | 1Mトークン | 大規模コードベース解析 | 無料 |

**実測に基づく使い分け:**
```
単純タスク（新規作成）  → Codex が 12-16% 速い、コスト $0
複雑タスク（既存修正）  → Claude が 40% 速い、品質も高い
大規模解析              → Gemini（1Mトークン対応）
```

**3AI連携で得られるもの:**
- 単純作業は Codex で $0 実装
- 複雑な設計判断は Claude の推論力
- 大規模解析は Gemini の無料1Mトークン

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

## ベンチマーク（実測値）

### 単純タスク：Codexが速い

```
カウンター      Codex ████████████ 21.8秒
コンポーネント  Claude ██████████████ 24.8秒
                       └─ Codex 12% 速い

認証API         Codex ██████████████████ 46.7秒
                Claude ██████████████████████ 55.7秒
                       └─ Codex 16% 速い
```

| タスク | Codex | Claude | コスト差 |
|--------|-------|--------|---------|
| カウンター | **21.8秒** | 24.8秒 | **$0** vs $0.02 |
| 認証API | **46.7秒** | 55.7秒 | **$0** vs $0.12 |

### 複雑タスク：Claudeが速い・高品質

```
Discord連携     Claude ████████████████ 3分0秒
(15K行に追加)   Codex  ██████████████████████████ 5分3秒
                       └─ Claude 40% 速い、コード量2倍
```

| 項目 | Claude | Codex |
|------|--------|-------|
| 実行時間 | **3分0秒** | 5分3秒 |
| 生成コード | **34KB** | 16KB |
| 機能数 | **多い** | 基本のみ |

### 使い分け早見表

```
┌─────────────────────────────────────────────────────────────┐
│  単純タスク（新規ファイル）     → Codex    速い・$0       │
│  複雑タスク（既存コード修正）   → Claude   速い・高品質   │
│  大規模解析（10万行〜）         → Gemini   1Mトークン     │
└─────────────────────────────────────────────────────────────┘
```

> 📊 [詳細なベンチマーク結果](./benchmarks/BENCHMARK_RESULTS.md)

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
