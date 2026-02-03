# CLAUDE.md - Project Memory

> このファイルはClaudeが毎回のセッション開始時に読み込み、プロジェクトの文脈を維持するためのものです。

## Project Overview

**claude-codex-collab**: Claude + Codex + Gemini の3AI協調開発ワークフローテンプレート

- Claude: 設計・レビュー担当
- Codex: 実装・テスト担当（ChatGPT Pro、$0）
- Gemini: 大規模分析担当（無料）

## Key Directories

```
.claude/
├── settings.json   # Hooks設定（自動協調提案）
├── hooks/          # AI振り分けスクリプト
├── rules/          # 委譲ルール
├── docs/           # 知識ベース（DESIGN.md, research/）
└── checkpoints/    # セッション状態の保存先

.codex/
└── AGENTS.md       # Codex用コンテキスト

.gemini/
└── GEMINI.md       # Gemini用コンテキスト

docs/
├── requirements/   # 要件定義（Claude作成）
├── specs/          # UI仕様（Claude作成）
├── api/            # API設計（Claude作成）
├── decisions/      # 重要な決定事項の記録
└── reviews/        # コードレビュー結果

skills/             # カスタムスキル
scripts/            # ユーティリティスクリプト
benchmarks/         # ベンチマーク結果・サンプル実装
landing/            # ランディングページ
```

## Working Rules

### 1. 重要な決定は記録する

アーキテクチャ、技術選定、設計方針などの重要な決定は必ず記録：

```bash
docs/decisions/YYYY-MM-DD-title.md
```

### 2. セッション終了時

作業終了前に以下を実行：
- 「今日の作業をCLAUDE.mdに追記して」と依頼
- または自分でWork Historyセクションを更新

### 3. コマンド体系

| コマンド | 担当AI | 用途 |
|---------|--------|------|
| `/project <機能>` | 全員 | 設計→実装→デプロイの完全フロー |
| `/requirements` | Claude | 要件定義 |
| `/spec` | Claude | UI仕様 |
| `/implement` | Codex | 実装 |
| `/review` | Claude | レビュー |
| `/checkpointing` | Claude | セッション状態の保存 |

## Claude Code Orchestra

### 自動協調提案（Hooks）

Claudeは入力内容を自動解析し、適切なAIを提案します：

| キーワード | 提案先AI | 例 |
|-----------|---------|-----|
| 実装, implement, create | Codex | 「認証機能を実装して」 |
| テスト, test | Codex | 「ユニットテストを書いて」 |
| 調査, research, 分析 | Gemini | 「Reactの状態管理を比較して」 |
| 比較, ライブラリ | Gemini | 「認証ライブラリを選定して」 |

### 知識共有

すべてのAIが参照する共有知識ベース：
- `.claude/docs/DESIGN.md` - 設計方針
- `.claude/docs/research/` - Geminiの調査結果

### セッション永続化

```bash
/checkpointing              # 作業状態を保存
/checkpointing --analyze    # パターン分析
```

---

## Important Decisions

最新の重要決定事項（詳細は `docs/decisions/` を参照）：

- **2026-02-03**: Claude Code Orchestra機能を統合（Hooks + Rules + 知識ベース + Checkpointing）

---

## Work History

### 2026-02-03
- Claude Code Orchestra機能を統合
  - .claude/settings.json（Hooks設定）
  - .claude/hooks/（agent-router, suggest-codex, suggest-gemini, post-impl-check）
  - .claude/rules/（codex-delegation.md, gemini-delegation.md）
  - .claude/docs/（DESIGN.md, research/）
  - .codex/AGENTS.md, .gemini/GEMINI.md
  - skills/checkpointing.md, scripts/checkpoint.sh

### 2025-02-03
- CLAUDE.md（このファイル）を作成
- docs/decisions/ ディレクトリを作成
- 記憶永続化の運用ルールを策定

---

## Notes for Claude

- 新機能追加時は必ず `docs/requirements/` に要件を書く
- 実装はCodexに委譲するのが基本方針
- ベンチマーク結果は `benchmarks/` に保存
- ユーザーが「決定事項を記録して」と言ったら `docs/decisions/` に保存
- Hooksによる提案は自動表示される（実行はユーザー判断）
- 設計方針は `.claude/docs/DESIGN.md` に記録する
- Geminiの調査結果は `.claude/docs/research/` に保存される
