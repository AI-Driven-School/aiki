# Decision: rulesync統合によるAIルール一元管理

**日付**: 2026-03-12
**ステータス**: 採用

## コンテキスト

aikiは4つのAI（Claude, Codex, Gemini, Grok）の設定ファイルを個別管理していた：
- `CLAUDE.md` - Claude Code用
- `.codex/AGENTS.md` - Codex CLI用
- `.gemini/GEMINI.md` - Gemini CLI用
- `.grok/GROK.md` - Grok用

共通情報（プロジェクト概要、ディレクトリ構造、参照先ドキュメント等）が各ファイルに重複していた。

## 決定

[rulesync](https://github.com/dyoshikawa/rulesync)を導入し、`.rulesync/rules/`を単一ソースとして各AIの設定ファイルを自動生成する。

## 構成

```
.rulesync/rules/
├── project-overview.md      # targets: ["*"] - 全AIに配信
├── claude-workflow.md        # targets: ["claudecode"] - CLAUDE.md生成
├── codex-agent.md            # targets: ["codexcli"] - AGENTS.md生成
├── gemini-agent.md           # targets: ["geminicli"] - GEMINI.md生成
├── codex-delegation.md       # targets: ["claudecode"] - .claude/rules/へ
├── gemini-delegation.md      # targets: ["claudecode"] - .claude/rules/へ
└── grok-delegation.md        # targets: ["claudecode"] - .claude/rules/へ
```

## 代替案

1. **手動管理を継続** - 重複管理のコストが増え続ける
2. **カスタムスクリプト** - メンテナンスコストが高い
3. **rulesync** - 25+ツール対応、コミュニティ駆動、MIT

## トレードオフ

- **メリット**: ルール変更が一箇所で完結、新AIツール追加が容易
- **デメリット**: npm依存追加、Grok未対応（手動管理継続）
- **注意**: `rulesync generate`後のCLAUDE.mdは自動生成物となるため、Work History等の動的セクションはソース側(claude-workflow.md)で管理する必要がある
