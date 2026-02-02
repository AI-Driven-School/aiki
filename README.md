# 実装2倍速、コスト75%削減

[![GitHub Sponsors](https://img.shields.io/github/sponsors/yu010101?style=for-the-badge&logo=github&label=Sponsor)](https://github.com/sponsors/yu010101)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](LICENSE)
[![Phase](https://img.shields.io/badge/Phase_1-完全無料-22c55e?style=for-the-badge)](https://github.com/yu010101/claude-codex-collab)

<p align="center">
  <img src="./landing/promo.gif" alt="3AI協調開発デモ" width="700">
</p>

<p align="center">
  <strong>Claude</strong> で設計、<strong>Codex</strong> で爆速実装、<strong>Gemini</strong> で大規模解析<br>
  一人開発でも設計書が残る、3AI分業の開発ワークフロー
</p>

---

## 30秒で始める

```bash
# 1. インストール
curl -fsSL https://raw.githubusercontent.com/yu010101/claude-codex-collab/main/install-fullstack.sh | bash -s -- my-app

# 2. 開発開始
cd my-app && claude

# 3. 機能を作る
> /project ユーザー認証
```

**必要なもの:**
| AI | 役割 | コスト |
|----|------|--------|
| Claude Code | 設計・レビュー | 従量課金 |
| Codex (ChatGPT Pro) | 実装・テスト | 月額に含む |
| Gemini CLI | 大規模解析 | 無料 |

---

## なぜ3AI？

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│   単一AI              3AI連携                               │
│   ────────            ────────                              │
│   Claude単体          Claude → 設計・判断のみ               │
│   = 全部課金             ↓                                  │
│   = コスト高い        Codex → 実装・テスト（$0）            │
│                          ↓                                  │
│                       Claude → レビュー                     │
│                                                             │
│   結果: $1.00         結果: $0.25（75%削減）                │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 実測ベンチマーク

| タスク種別 | 勝者 | 理由 |
|-----------|------|------|
| 新規ファイル作成 | **Codex** | 10-20%速い、$0 |
| 既存コード修正 | **Claude** | 40%速い、品質2倍 |
| 大規模解析 | **Gemini** | 1Mトークン、無料 |

> 📊 [詳細なベンチマーク結果](./benchmarks/BENCHMARK_RESULTS.md)

---

## ワークフロー

```
> /project ユーザー認証

[1/6] 要件定義   (Claude)  → docs/requirements/auth.md  ✓
[2/6] API設計    (Claude)  → docs/api/auth.yaml         ✓
[3/6] 実装       (Codex)   → src/**/*.tsx               ★ full-auto
[4/6] テスト     (Codex)   → tests/*.spec.ts            ★ $0
[5/6] レビュー   (Claude)  → 改善提案                    ✓
[6/6] デプロイ             → https://my-app.vercel.app  ✓
```

### 成果物

```
my-app/
├── docs/
│   ├── requirements/   # 要件定義（Claude）
│   ├── specs/          # 画面設計（Claude）
│   └── api/            # API設計（Claude）
├── src/                # 実装コード（Codex）
└── tests/              # テスト（Codex）
```

**一人開発でも、これだけの設計書が残る。**

---

## 実績: StressAIAgent

このテンプレートで実際に作ったSaaS:

### AI駆動型メンタルヘルスSaaS

```
/project 組織分析AI
```

| フェーズ | 担当AI | 成果物 |
|---------|:------:|--------|
| 要件定義 | Claude | `docs/requirements/org-analysis-ai.md` |
| API設計 | Claude | `docs/api/org-analysis.yaml` |
| 画面設計 | Claude | `docs/specs/org-analysis-ai.md` |
| 実装 | **Codex** | バックエンド + フロントエンド |
| テスト | **Codex** | E2Eテスト 10ケース |
| レビュー | Claude | `docs/reviews/org-analysis-ai.md` |

### 生成された機能

- 組織全体のストレス分析ダッシュボード
- 部署別スコアのヒートマップ
- **GPT-4によるAIインサイト自動生成**
- PDFレポート出力
- 管理者権限チェック

> 📁 [ソースコード](./benchmarks/complex-test/)

---

## コマンド

| コマンド | AI | 説明 |
|---------|-----|------|
| `/project <機能>` | All | 設計→実装→デプロイの完全フロー |
| `/requirements <機能>` | Claude | 要件定義生成 |
| `/spec <画面>` | Claude | 画面設計生成 |
| `/api <エンドポイント>` | Claude | API設計生成 |
| `/implement` | Codex | 設計書から実装 |
| `/test` | Codex | テスト生成 |
| `/review` | Claude | コードレビュー |
| `/analyze` | Gemini | 大規模コード解析 |
| `/research <質問>` | Gemini | 技術リサーチ |

---

## 動作環境

- macOS / Linux / WSL2
- Node.js 18+
- ChatGPT Pro（Codex用、$200/月）

---

## ドキュメント

| ドキュメント | 内容 |
|------------|------|
| [導入ガイド](./docs/GETTING_STARTED.md) | インストール・セットアップ |
| [ハンズオン](./docs/HANDS_ON_TUTORIAL.md) | TODOアプリを作るチュートリアル |
| [コマンド一覧](./docs/COMMANDS.md) | 全コマンドのリファレンス |
| [ベンチマーク](./benchmarks/BENCHMARK_RESULTS.md) | 実測データ詳細 |

---

## サポート

Phase 1は完全無料です。開発を支援してくださる方は:

[![GitHub Sponsors](https://img.shields.io/github/sponsors/yu010101?style=for-the-badge&logo=github&label=Sponsor)](https://github.com/sponsors/yu010101)

---

<p align="center">
  MIT License<br>
  <a href="https://github.com/yu010101/claude-codex-collab">GitHub</a> ·
  <a href="https://github.com/yu010101/claude-codex-collab/issues">Issues</a> ·
  <a href="https://github.com/sponsors/yu010101">Sponsor</a>
</p>
