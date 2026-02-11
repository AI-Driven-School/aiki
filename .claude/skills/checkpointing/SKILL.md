---
name: checkpointing
description: Save and restore session state for continuity across Claude Code sessions. Captures tasks, changed files, context, and decisions. Use when ending a session, preserving progress, or running /checkpointing.
metadata:
  author: AI-Driven-School
  version: "1.0"
---

# /checkpointing - セッション永続化スキル

> 作業状態を保存し、セッション間で継続性を維持します。

## 使い方

### 基本使用

```
/checkpointing
```

現在の作業状態を `.claude/checkpoints/` に保存します。

### オプション

```
/checkpointing --analyze
```

過去のチェックポイントからパターンを抽出し、ワークフローの改善点を提案します。

## 保存される情報

1. **作業中のタスク**: 現在進行中のタスクリスト
2. **変更ファイル**: 未コミットの変更ファイル一覧
3. **コンテキスト**: セッション中に参照したファイル
4. **決定事項**: セッション中に行った重要な決定

## ファイル形式

```
.claude/checkpoints/
└── YYYY-MM-DD-HHMMSS.md
```

## 実装

このスキルが呼び出されたら、`scripts/checkpoint.sh` を実行してください:

```bash
"$CLAUDE_PROJECT_DIR"/scripts/checkpoint.sh [--analyze]
```

## 次のセッションでの復元

次回セッション開始時に、最新のチェックポイントを読み込むことで
前回の作業状態を復元できます:

```
最新のチェックポイントを読み込んで、前回の続きから作業を開始してください
```
