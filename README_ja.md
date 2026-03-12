# Claudeにボイラープレートを書かせるのをやめよう

[![GitHub Stars](https://img.shields.io/github/stars/AI-Driven-School/aiki?style=for-the-badge&logo=github&label=Stars)](https://github.com/AI-Driven-School/aiki/stargazers)
[![npm](https://img.shields.io/npm/v/aiki?style=for-the-badge&logo=npm)](https://www.npmjs.com/package/aiki)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](LICENSE)
[![GitHub Sponsors](https://img.shields.io/github/sponsors/AI-Driven-School?style=for-the-badge&logo=github&label=Sponsor)](https://github.com/sponsors/AI-Driven-School)

<p align="center">
  <img src="./landing/promo.gif" alt="4AI協調開発デモ" width="700">
</p>

<p align="center">
  Claudeが設計。Codexが<strong>$0</strong>で実装。Geminiが<strong>無料</strong>で調査。<br>
  各タスクを最適なAIにルーティングするCLI — コスト75%削減。
</p>

<p align="center">
  このプロジェクトが役立ったら <a href="https://github.com/AI-Driven-School/aiki/stargazers">Star</a> をお願いします
</p>

---

## 30秒で始める

```bash
# 方法A: npx（推奨）
npx aiki init my-app

# 方法B: curl
curl -fsSL https://raw.githubusercontent.com/AI-Driven-School/aiki/main/install-fullstack.sh | bash -s -- my-app

# 開発開始
cd my-app && claude

# 機能を作る
> /project ユーザー認証
```

**必要なもの:**
| AI | 役割 | コスト |
|----|------|--------|
| Claude Code | 設計・レビュー | 従量課金 |
| Codex (ChatGPT Pro) | 実装・テスト | 月額に含む |
| Gemini CLI | 大規模解析 | 無料 |
| Grok (xAI) | リアルタイムトレンド・X検索 | xAI API |

---

## なぜ4AI？

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│   単一AI              4AI連携                               │
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
| リアルタイムトレンド | **Grok** | ライブX検索、xAI API |

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
├── .rulesync/rules/    # 全AIルールの単一ソース
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
| `/x-trend-research` | Grok | Xトレンド検索 |
| `/x-context-research` | Grok | 記事執筆用Context Pack |

---

## 統一ルール管理（rulesync）

**NEW:** AIルールを一箇所で管理。[rulesync](https://github.com/dyoshikawa/rulesync)が各AIの設定ファイルを自動生成します。

```bash
# ルールを一箇所で編集
vim .rulesync/rules/project-overview.md

# 全AIに一括生成
rulesync generate

# 出力:
#   → CLAUDE.md                  (Claude Code)
#   → AGENTS.md                  (Codex CLI)
#   → GEMINI.md                  (Gemini CLI)
#   → .claude/rules/*.md         (Claude委譲ルール)
#   → .codex/memories/*.md       (Codex共有コンテキスト)
#   → .gemini/memories/*.md      (Gemini共有コンテキスト)
```

| ソース | 生成先 | 説明 |
|--------|--------|------|
| `project-overview.md` | 全3AI | 共通プロジェクトコンテキスト |
| `claude-workflow.md` | Claudeのみ | 強制ルール、コマンド |
| `codex-agent.md` | Codexのみ | 実装ガイドライン |
| `gemini-agent.md` | Geminiのみ | リサーチガイドライン |
| `*-delegation.md` | Claudeのみ | 各AIへの委譲判断ルール |

> Grokは `.grok/GROK.md` で手動管理（rulesyncターゲット未対応）

---

## 自動オーケストレーション（MCPサーバー）

Claudeに自然に話しかけるだけで、タスクが自動的に適切なAIに委譲されます。

```
あなた: 「ユーザー認証を実装して」
→ 自動的にCodexに委譲（実装の専門家）

あなた: 「ReactとVueを比較して」
→ 自動的にGeminiに委譲（調査の専門家）

あなた: 「コードをレビューして」
→ Claudeが処理（設計・レビューの専門家）
```

### セットアップ

```bash
# MCPサーバーをインストール・設定
./scripts/setup-mcp.sh

# Claude Codeを再起動
```

**APIキー不要** - CLI（ChatGPT ProのCodex CLI、無料のGemini CLI）を使用します。

### 利用可能なMCPツール

| ツール | 説明 |
|--------|------|
| `delegate_to_codex` | 実装タスクをCodexに委譲 |
| `delegate_to_gemini` | 調査・分析をGeminiに委譲 |
| `auto_delegate` | 自動的に適切なAIに振り分け |
| `get_orchestration_status` | 各AIサービスの状態を確認 |

> 詳細は [MCPサーバー README](.claude/mcp-servers/ai-orchestrator/README.md) を参照

---

## 互換性

### AI CLI対応

| ツール | 最小バージョン | テスト済み | 必須 |
|--------|:----------:|:--------:|:----:|
| Claude Code | 1.0.0 | 2.1.49 | Yes |
| Codex CLI | 0.1.0 | 0.93.0 | No |
| Gemini CLI | 0.1.0 | 0.26.0 | No |
| Ollama | 0.1.0 | — | No |

### IDE・エージェント対応

| ツール | 対応 | 備考 |
|--------|:----:|------|
| Claude Code | ネイティブ | スキル・Hooks・委譲フル対応 |
| Codex CLI | ネイティブ | AGENTS.mdと委譲スクリプト |
| [OpenCode](https://github.com/sst/opencode) | 互換 | AGENTS.mdと.claude/skills/を自動読み込み |
| Cursor | 互換 | .cursor/rules/テンプレート同梱 |
| VS Code | タスク | templates/vscode-tasks.json同梱 |

> 詳細は [OpenCode互換性ドキュメント](./docs/OPENCODE_COMPATIBILITY.md) を参照

### ローカルモデル対応

[Ollama](https://ollama.ai)でオフライン開発も可能：

```bash
# ローカルモデルでコード生成
bash scripts/delegate.sh ollama generate "REST APIを作成して"

# ローカルモデルでコードレビュー
bash scripts/delegate.sh ollama review src/ --model deepseek-coder
```

---

## 動作環境

- macOS / Linux / WSL2
- Node.js 18+
- ChatGPT Pro（Codex CLI用、$200/月）— `--claude-only`モードなら不要
- Gemini CLI（無料、調査タスク用、任意）

---

## ドキュメント

| ドキュメント | 内容 |
|------------|------|
| [導入ガイド](./docs/GETTING_STARTED.md) | インストール・セットアップ |
| [ハンズオン](./docs/HANDS_ON_TUTORIAL.md) | TODOアプリを作るチュートリアル |
| [コスト比較](./docs/COST_COMPARISON.md) | 4AI vs 単一AIの詳細コスト分析 |
| [OpenCode互換性](./docs/OPENCODE_COMPATIBILITY.md) | OpenCode CLIとの併用 |
| [コマンド一覧](./docs/COMMANDS.md) | 全コマンドのリファレンス |
| [ベンチマーク](./benchmarks/BENCHMARK_RESULTS.md) | 実測データ詳細 |

---

## サポート

Phase 1は完全無料です。このプロジェクトを支援する方法：

1. [GitHub Starをつける](https://github.com/AI-Driven-School/aiki/stargazers) — 他の開発者がこのプロジェクトを見つけやすくなります
2. [X/Twitterでシェア](https://twitter.com/intent/tweet?text=Claude%20%2B%20Codex%20%2B%20Gemini%20%E3%81%AE4AI%E5%8D%94%E8%AA%BF%E9%96%8B%E7%99%BA%E3%80%82%E3%82%B3%E3%82%B9%E3%83%8875%25%E5%89%8A%E6%B8%9B%20%F0%9F%9A%80&url=https%3A%2F%2Fgithub.com%2FAI-Driven-School%2Faiki) — 広めてください
3. [スポンサーになる](https://github.com/sponsors/AI-Driven-School) — 開発を直接支援

[![GitHub Stars](https://img.shields.io/github/stars/AI-Driven-School/aiki?style=for-the-badge&logo=github&label=Star)](https://github.com/AI-Driven-School/aiki/stargazers)
[![GitHub Sponsors](https://img.shields.io/github/sponsors/AI-Driven-School?style=for-the-badge&logo=github&label=Sponsor)](https://github.com/sponsors/AI-Driven-School)

---

<p align="center">
  MIT License<br>
  <a href="https://github.com/AI-Driven-School/aiki">GitHub</a> ·
  <a href="https://github.com/AI-Driven-School/aiki/issues">Issues</a> ·
  <a href="https://github.com/sponsors/AI-Driven-School">Sponsor</a>
</p>
