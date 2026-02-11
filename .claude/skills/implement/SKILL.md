---
name: implement
description: Generate implementation code from design documents by delegating to OpenAI Codex. Use when you have specs ready and want to auto-generate source code, or when running /implement.
compatibility: Requires ChatGPT Pro subscription for Codex access
metadata:
  author: AI-Driven-School
  version: "1.0"
---

# /implement スキル

設計書を読み込み、Codexで実装を自動生成します。

## 使用方法

```
/implement
/implement auth
/implement --from=docs/specs/login.md
```

## 実行フロー

```
[1] 設計書の読み込み
    ├─ docs/requirements/*.md
    ├─ docs/specs/*.md
    └─ docs/api/*.yaml

[2] Codexに委譲
    └─ codex exec "..." --full-auto

[3] 実装ファイル生成
    └─ src/**/*
```

## Codex委譲コマンド

```bash
codex exec "
以下の設計書を読み込み、Next.js App Routerで実装してください。

【要件定義】
$(cat docs/requirements/{feature}.md)

【画面設計】
$(cat docs/specs/{feature}.md)

【API設計】
$(cat docs/api/{feature}.yaml)

【実装要件】
- Next.js 14 App Router
- TypeScript strict mode
- Tailwind CSS
- 既存のコードスタイルに従う
- コンポーネントは src/components/ に配置
- APIは src/app/api/ に配置
- 型定義は src/types/ に配置
- ユーティリティは src/lib/ に配置

【品質基準】
- ESLint/Prettierエラーなし
- TypeScriptエラーなし
- 受入条件を全て満たす
" --full-auto
```

## 生成されるファイル構成

```
src/
├── app/
│   ├── {feature}/
│   │   └── page.tsx          # ページコンポーネント
│   └── api/
│       └── {feature}/
│           └── route.ts      # APIエンドポイント
├── components/
│   └── {feature}/
│       ├── {Component}.tsx   # UIコンポーネント
│       └── index.ts          # バレルエクスポート
├── lib/
│   └── {feature}.ts          # ユーティリティ
└── types/
    └── {feature}.ts          # 型定義
```

## 出力例

```
> /implement auth

🔧 実装を開始します... (Codex)

設計書を読み込み中...
  ✓ docs/requirements/auth.md
  ✓ docs/specs/auth.md
  ✓ docs/api/auth.yaml

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 Codex (full-auto) で実装中...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Codex] src/app/login/page.tsx を作成中...
[Codex] src/app/api/auth/login/route.ts を作成中...
[Codex] src/components/auth/LoginForm.tsx を作成中...
[Codex] src/lib/auth.ts を作成中...
[Codex] src/types/auth.ts を作成中...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ 実装完了！

生成ファイル:
  → src/app/login/page.tsx
  → src/app/api/auth/login/route.ts
  → src/components/auth/LoginForm.tsx
  → src/components/auth/index.ts
  → src/lib/auth.ts
  → src/types/auth.ts
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## 注意事項

- Codexの実行には **ChatGPT Pro** サブスクリプションが必要
- `--full-auto` モードで実行するため、承認なしで自動実行
- 生成後は `/review` でコードレビューを推奨
