---
title: "Claude + Codex + Gemini の3AI連携で開発コストを75%削減した話"
emoji: "🤖"
type: "tech"
topics: ["claude", "chatgpt", "gemini", "ai", "開発効率化"]
published: false
---

## はじめに

個人開発やスタートアップで、AIを使った開発効率化に興味はありませんか？

今回、**Claude、Codex、Gemini**の3つのAIを連携させて、開発コストを**75%削減**する仕組みを作りました。

実際にメンタルヘルスSaaS「StressAIAgent」の機能をこの方法で実装したので、その過程を共有します。

## なぜ3AI連携？

### 単一AIの問題

Claude単体で開発すると、全ての処理に課金が発生します。

```
要件定義 → Claude（課金）
設計 → Claude（課金）
実装 → Claude（課金）← ここが一番コード量多い
テスト → Claude（課金）
レビュー → Claude（課金）
```

### 3AI連携の解決策

各AIの得意分野で分業させます：

| AI | 役割 | コスト |
|----|------|--------|
| **Claude** | 設計・判断・レビュー | 従量課金 |
| **Codex** | 実装・テスト | $0（ChatGPT Pro含む） |
| **Gemini** | 大規模解析・リサーチ | 無料 |

実装とテストはコード量が多いため、ここをCodex（ChatGPT Proに含まれる）に任せるだけで大幅なコスト削減になります。

## /project コマンド

このワークフローを自動化する `/project` コマンドを作りました。

```bash
> /project 組織分析AI

[1/6] 要件定義   (Claude)  → docs/requirements/org-analysis-ai.md  ✓
[2/6] 設計       (Claude)  → docs/specs/, docs/api/                ✓
[3/6] 実装       (Codex)   → backend/, frontend/                   ★ $0
[4/6] テスト     (Codex)   → tests/e2e/                            ★ $0
[5/6] レビュー   (Claude)  → docs/reviews/                         ✓
[6/6] デプロイ   → 承認後実行
```

各フェーズで承認/却下ができるため、AIの出力を確認しながら進められます。

## 実際に作った機能

### 組織分析AIダッシュボード

メンタルヘルスSaaSに「組織全体のストレス傾向をAIが分析する機能」を追加しました。

**生成されたファイル:**

```
docs/
├── requirements/org-analysis-ai.md  # 要件定義
├── specs/org-analysis-ai.md         # 画面設計
├── api/org-analysis.yaml            # OpenAPI仕様
└── reviews/org-analysis-ai.md       # レビュー結果

backend/
├── app/routers/org_analysis.py      # APIエンドポイント
└── app/services/org_analysis_service.py  # ビジネスロジック

frontend/
└── app/admin/org-analysis/page.tsx  # ダッシュボード画面

tests/
└── e2e/org-analysis.spec.ts         # E2Eテスト（10ケース）
```

### 実装された機能

- 組織全体のストレススコア表示
- 部署別スコアのヒートマップ
- 過去6ヶ月のトレンドグラフ
- **GPT-4によるAIインサイト生成**
- PDFレポート出力

## AI分担の詳細

### Phase 1-2: 設計（Claude）

要件定義と設計はClaudeが担当。ユーザーストーリー、受入条件、API仕様を自動生成。

```markdown
# 要件定義: 組織分析AI

## ユーザーストーリー

AS A 人事担当者・経営層
I WANT TO 組織全体のストレス傾向をAIが分析したレポートを見たい
SO THAT データに基づいた意思決定と早期介入ができる

## 受入条件

- [x] 部署別ストレススコアの集計・可視化
- [x] AIによる傾向分析コメント生成
- [x] 前月比・前年比の変化表示
...
```

### Phase 3-4: 実装・テスト（Codex）

設計書をCodexに渡して実装を委譲。

```bash
codex exec --full-auto "
以下の設計書を読み込み、実装してください。

【要件定義】
$(cat docs/requirements/org-analysis-ai.md)

【API設計】
$(cat docs/api/org-analysis.yaml)

【画面設計】
$(cat docs/specs/org-analysis-ai.md)
"
```

Codexは `--full-auto` モードで承認なしに実装を進めます。

### Phase 5: レビュー（Claude）

実装されたコードをClaudeがレビュー。

```markdown
# コードレビュー: 組織分析AI

## サマリー

| 項目 | 結果 |
|------|------|
| 受入条件 | 6/6 クリア ✅ |
| テストカバレッジ | 10ケース |
| 改善提案 | 3件 |
| ブロッカー | 0件 |

## 判定: ✅ PASS
```

## コスト比較

### Before: Claude単体

```
要件定義: $0.05
設計: $0.10
実装: $0.60  ← 一番重い
テスト: $0.20
レビュー: $0.05
-----------------
合計: $1.00
```

### After: 3AI連携

```
要件定義: $0.05 (Claude)
設計: $0.10 (Claude)
実装: $0.00 (Codex) ★
テスト: $0.00 (Codex) ★
レビュー: $0.05 (Claude)
解析: $0.00 (Gemini) ★
-----------------
合計: $0.20 → 80%削減
```

## 導入方法

### 必要なもの

- Claude Code CLI
- ChatGPT Pro（$200/月）→ Codex含む
- Gemini CLI（無料）

### インストール

```bash
curl -fsSL https://raw.githubusercontent.com/yu010101/claude-codex-collab/main/install-fullstack.sh | bash -s -- my-app
cd my-app && claude
```

### 使い方

```bash
> /project ユーザー認証
```

これだけで6フェーズが順次実行されます。

## まとめ

3AI連携のメリット：

1. **コスト削減**: 実装・テストを$0で実行
2. **設計書が残る**: 一人開発でもドキュメント化
3. **品質担保**: 各フェーズで承認/却下
4. **AI分業**: 各AIの得意分野を活用

OSSで公開しているので、ぜひ試してみてください。

https://github.com/yu010101/claude-codex-collab

質問やフィードバックはGitHub IssueまたはTwitter DMでお待ちしています。
