---
name: analyze
description: Analyze entire codebases using Gemini CLI's 1M token context. Generates architecture reports covering structure, security, performance, and improvement roadmaps. Use when auditing code quality or running /analyze.
compatibility: Requires Gemini CLI (free)
metadata:
  author: AI-Driven-School
  version: "1.0"
---

# /analyze スキル

プロジェクト全体を解析し、アーキテクチャレポートを生成します。
Gemini CLIの1Mトークンコンテキストを活用。

## 使用方法

```
/analyze
/analyze src/
/analyze --security
/analyze --performance
```

## 実行フロー

```
[1] コードベースの収集
    └─ 対象ディレクトリの全ファイル

[2] Geminiに委譲
    └─ gemini -p "..." --yolo

[3] レポート生成
    └─ docs/analysis/{date}-report.md
```

## Gemini委譲コマンド

```bash
# プロジェクト全体をGeminiに渡す
find src -type f \( -name "*.ts" -o -name "*.tsx" \) -exec cat {} \; | \
gemini -p "
以下のコードベースを解析し、レポートを作成してください。

【解析観点】
1. アーキテクチャ概要
   - 全体構造
   - 主要コンポーネント
   - データフロー

2. 技術スタック
   - 使用フレームワーク/ライブラリ
   - 設計パターン

3. コード品質
   - 良い点
   - 改善点

4. セキュリティ懸念
   - 潜在的な脆弱性
   - 推奨対策

5. パフォーマンス
   - ボトルネック候補
   - 最適化提案

6. 改善ロードマップ
   - 優先度高の改善点（3つ）
   - 中長期的な改善点

【出力形式】
Markdown形式で、図や表を活用して分かりやすく。
" --yolo
```

## 出力テンプレート

```markdown
# コードベース解析レポート

**解析日**: {YYYY-MM-DD}
**対象**: {ディレクトリ}
**ファイル数**: {N}ファイル
**総行数**: {N}行

---

## 1. アーキテクチャ概要

### 全体構造

```
src/
├── app/           # Next.js App Router
├── components/    # UIコンポーネント
├── lib/           # ユーティリティ
└── types/         # 型定義
```

### 主要コンポーネント

| コンポーネント | 役割 | 依存関係 |
|--------------|------|---------|
| {名前} | {役割} | {依存} |

### データフロー

```
User → UI → API → Database
         ↓
      State Management
```

---

## 2. 技術スタック

| カテゴリ | 技術 | バージョン |
|---------|------|----------|
| Framework | Next.js | 14.x |
| Language | TypeScript | 5.x |
| Styling | Tailwind CSS | 3.x |
| Database | {DB} | {ver} |

---

## 3. コード品質

### 👍 良い点

1. {良い点1}
2. {良い点2}

### 👎 改善点

1. {改善点1}
2. {改善点2}

---

## 4. セキュリティ懸念

| 懸念事項 | 重要度 | 該当箇所 | 推奨対策 |
|---------|:------:|---------|---------|
| {懸念} | 🔴 High | `{file}` | {対策} |

---

## 5. パフォーマンス

### ボトルネック候補

1. {候補1}: {説明}
2. {候補2}: {説明}

### 最適化提案

- {提案1}
- {提案2}

---

## 6. 改善ロードマップ

### 🔴 優先度高（今すぐ）

1. {改善点}

### 🟡 優先度中（1ヶ月以内）

1. {改善点}

### 🟢 優先度低（長期）

1. {改善点}
```

## 出力例

```
> /analyze

🔍 コードベースを解析中... (Gemini)

ファイルを収集中...
  ✓ 156ファイル, 15,588行を検出

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 Gemini で解析中...（1Mトークン対応）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Gemini] アーキテクチャを解析中...
[Gemini] セキュリティをスキャン中...
[Gemini] パフォーマンスを評価中...
[Gemini] レポートを生成中...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📄 docs/analysis/2024-01-15-report.md を作成しました
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

サマリー:
  📁 ファイル: 156
  📝 総行数: 15,588
  ⚠️ セキュリティ懸念: 3件
  💡 改善提案: 8件
```

## 注意事項

- Gemini CLIは **無料** で利用可能
- 10万行以上のコードベースに最適
- `--yolo` フラグで承認スキップ
