---
name: research
description: Conduct technical research using Gemini CLI, producing comparison reports with recommendations and code examples. Use when evaluating technologies, comparing libraries, or running /research.
compatibility: Requires Gemini CLI (free)
metadata:
  author: AI-Driven-School
  version: "1.0"
---

# /research スキル

技術的な質問をGeminiでリサーチし、レポートを生成します。

## 使用方法

```
/research "Next.js App Routerのベストプラクティス"
/research "JWT vs Session認証の比較"
/research "Tailwind CSS v4の新機能"
```

## 実行フロー

```
[1] 質問の整形
    └─ リサーチ用プロンプト生成

[2] Geminiに委譲
    └─ gemini -p "..." --yolo

[3] レポート生成
    └─ docs/research/{topic}.md
```

## Gemini委譲コマンド

```bash
gemini -p "
以下の技術トピックについて詳細にリサーチし、レポートを作成してください。

【トピック】
{質問}

【リサーチ観点】
1. 概要・背景
2. 主要な選択肢/アプローチ
3. 比較表（該当する場合）
4. ベストプラクティス
5. 実装例（コード）
6. 参考リソース

【出力要件】
- Markdown形式
- コード例は実用的なもの
- 最新の情報を反映（2024年時点）
- 日本語で出力
" --yolo
```

## 出力テンプレート

```markdown
# リサーチ: {トピック}

**調査日**: {YYYY-MM-DD}
**調査者**: Gemini CLI

---

## 1. 概要

{トピックの概要説明}

### 背景

{なぜこのトピックが重要か}

---

## 2. 主要な選択肢

### 選択肢A: {名前}

**概要**: {説明}

**メリット**:
- {メリット1}
- {メリット2}

**デメリット**:
- {デメリット1}
- {デメリット2}

### 選択肢B: {名前}

...

---

## 3. 比較表

| 観点 | 選択肢A | 選択肢B | 選択肢C |
|------|---------|---------|---------|
| {観点1} | {評価} | {評価} | {評価} |
| {観点2} | {評価} | {評価} | {評価} |
| {観点3} | {評価} | {評価} | {評価} |

---

## 4. ベストプラクティス

### 推奨アプローチ

{推奨する選択肢とその理由}

### 避けるべきパターン

- {アンチパターン1}
- {アンチパターン2}

---

## 5. 実装例

### 基本的な実装

```typescript
// {説明}
{コード例}
```

### 応用例

```typescript
// {説明}
{コード例}
```

---

## 6. 参考リソース

- [{タイトル1}]({URL})
- [{タイトル2}]({URL})
- [{タイトル3}]({URL})

---

## 結論

{総括と推奨事項}
```

## 出力例

```
> /research "JWT vs Session認証の比較"

🔬 リサーチ中... (Gemini)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 Gemini でリサーチ中...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Gemini] 情報を収集中...
[Gemini] 比較分析中...
[Gemini] レポートを生成中...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📄 docs/research/jwt-vs-session.md を作成しました
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# リサーチ: JWT vs Session認証の比較

## 比較サマリー

| 観点 | JWT | Session |
|------|-----|---------|
| スケーラビリティ | ✅ 優秀 | ⚠️ 要Redis |
| セキュリティ | ⚠️ 要注意 | ✅ 優秀 |
| 実装複雑度 | 中 | 低 |
| モバイル対応 | ✅ 最適 | ⚠️ Cookie依存 |

## 結論

- **SPA/モバイル**: JWT推奨
- **従来型Web**: Session推奨
- **ハイブリッド**: JWTをRefresh Tokenで管理

詳細は docs/research/jwt-vs-session.md を参照
```

## 活用シーン

- 技術選定時の比較調査
- 新技術のキャッチアップ
- ベストプラクティスの確認
- 実装方法の調査

## 注意事項

- Gemini CLIは **無料** で利用可能
- 最新情報は公式ドキュメントで再確認を推奨
- コード例は動作確認してから使用
