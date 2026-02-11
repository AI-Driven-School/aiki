---
name: project
description: Run the full design-to-deploy pipeline using 3 AIs (Claude + Codex + Gemini). Use when starting a new feature, running /project, or needing end-to-end development with requirements, specs, implementation, testing, review, and deployment phases.
metadata:
  author: AI-Driven-School
  version: "1.0"
---

# /project スキル

機能名を指定すると、要件定義から実装・テスト・デプロイまで6フェーズで自動実行します。

## 使用方法

```
/project ユーザー認証
/project 商品検索機能
/project ダッシュボード
```

## 実行フロー

```
[1/6] 要件定義   (Claude)  → docs/requirements/{feature}.md
[2/6] 設計       (Claude)  → docs/specs/{feature}.md, docs/api/{feature}.yaml
[3/6] 実装       (Codex)   → src/**/*
[4/6] テスト     (Codex)   → tests/**/*
[5/6] レビュー   (Claude)  → docs/reviews/{feature}.md
[6/6] デプロイ   (Claude)  → 最終確認
```

## フェーズ詳細

### Phase 1: 要件定義（Claude）

以下のテンプレートで要件定義書を生成:

```markdown
# 要件定義: {機能名}

## ユーザーストーリー

AS A {ユーザー種別}
I WANT TO {やりたいこと}
SO THAT {達成したい目的}

## 受入条件

### 機能要件
- [ ] {条件1}
- [ ] {条件2}
- [ ] {条件3}

### 非機能要件
- パフォーマンス: {要件}
- セキュリティ: {要件}
- アクセシビリティ: {要件}

## 制約事項
- フレームワーク: {使用技術}
- データ永続化: {方式}
```

**出力先**: `docs/requirements/{feature}.md`
**承認**: ユーザーに確認 → `Y` で次へ、`reject {理由}` で再生成

### Phase 2: 設計（Claude）

#### 画面設計
```markdown
# 画面設計: {画面名}

## 概要
{画面の目的と概要}

## コンポーネント構成
| コンポーネント | 種類 | 説明 |
|--------------|------|------|
| {名前} | {種類} | {説明} |

## 状態遷移
| 状態 | トリガー | 遷移先 |
|------|---------|--------|
| {状態} | {操作} | {次の状態} |

## インタラクション
- {操作}: {動作}
```

#### API設計（OpenAPI形式）
```yaml
openapi: 3.0.0
info:
  title: {機能名} API
  version: 1.0.0
paths:
  /{endpoint}:
    post:
      summary: {概要}
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties:
                {field}:
                  type: {type}
      responses:
        '200':
          description: 成功
```

**出力先**: `docs/specs/{feature}.md`, `docs/api/{feature}.yaml`
**承認**: ユーザーに確認

### Phase 3: 実装（Codex）

設計書を基にCodexで実装を委譲:

```bash
# Codexに委譲
codex exec "
以下の設計書を読み込み、実装してください:
- docs/requirements/{feature}.md
- docs/specs/{feature}.md
- docs/api/{feature}.yaml

実装要件:
- Next.js App Router
- TypeScript
- Tailwind CSS
- 既存のコードスタイルに従う
" --full-auto
```

**出力先**: `src/` 配下
**自動実行**: 承認不要（full-auto）

### Phase 4: テスト（Codex）

```bash
# Codexに委譲
codex exec "
実装したコードに対してテストを生成してください:
- E2Eテスト（Playwright）
- 受入条件を全てカバー
" --full-auto
```

**出力先**: `tests/{feature}.spec.ts`
**自動実行**: 承認不要

### Phase 5: レビュー（Claude）

実装コードを設計書と照合し、レビュー:

```markdown
# コードレビュー: {機能名}

## サマリー
- 受入条件: {N}/{M} クリア
- テストカバレッジ: {X}%
- 改善提案: {N}件

## チェック結果

### 受入条件
- [x] {条件1}
- [x] {条件2}
- [ ] {条件3} → {理由}

### セキュリティ
- {チェック項目}: {結果}

### 改善提案
1. {提案1}
2. {提案2}
```

**出力先**: `docs/reviews/{feature}.md`

### Phase 6: デプロイ（Claude）

レビュー結果を確認し、デプロイ判断:

```
レビュー結果:
  ✅ 受入条件クリア
  ✅ テストパス
  ⚠️ 軽微な改善提案あり（デプロイに影響なし）

本番にデプロイしますか？ [Y/n]
```

デプロイ承認後:
```bash
# Vercelデプロイ
vercel --prod
```

## 中断・再開

```
# 進捗確認
/status

# 特定フェーズから再開
/project {機能名} --from=3

# フェーズスキップ
/project {機能名} --skip=1,2
```

## 出力例

```
> /project ユーザー認証

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 プロジェクト開始: ユーザー認証
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[1/6] 要件定義を生成中... (Claude)
      → docs/requirements/auth.md

📄 要件定義:
───────────────────────────────
# 要件定義: ユーザー認証

## ユーザーストーリー
AS A 一般ユーザー
I WANT TO アカウントでログインしたい
SO THAT 個人データにアクセスできる
...
───────────────────────────────

承認しますか？ [Y/n/reject 理由] > Y
✓ 要件定義を承認しました

[2/6] 設計を生成中... (Claude)
      → docs/specs/auth.md
      → docs/api/auth.yaml
...

[3/6] 実装中... (Codex - full-auto) ★
      → src/app/login/page.tsx
      → src/app/api/auth/login/route.ts
      → src/lib/auth.ts

[4/6] テスト生成中... (Codex)
      → tests/auth.spec.ts

[5/6] レビュー中... (Claude)
      ✓ 受入条件: 5/5 クリア
      ✓ テスト: 6 passed
      ⚠️ 改善提案: 2件

[6/6] デプロイ準備完了
      本番にデプロイしますか？ [Y/n] > Y

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ デプロイ完了！
   URL: https://my-app.vercel.app
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
