---
name: test
description: テストコードを生成（Codexに委譲）
---

# /test スキル

実装コードと要件定義からテストコードを自動生成します。

## 使用方法

```
/test
/test auth
/test --e2e
/test --unit
```

## 実行フロー

```
[1] 要件定義の読み込み
    └─ docs/requirements/*.md（受入条件）

[2] 実装コードの確認
    └─ src/**/*

[3] Codexに委譲
    └─ codex exec "..." --full-auto

[4] テストファイル生成
    └─ tests/**/*.spec.ts
```

## Codex委譲コマンド

```bash
codex exec "
以下の受入条件を全てカバーするE2Eテストを生成してください。

【受入条件】
$(cat docs/requirements/{feature}.md | grep -A 100 '## 受入条件')

【テスト要件】
- Playwright使用
- 各受入条件に対応するテストケース
- Happy path + Edge case
- 適切なセレクタ（data-testid推奨）
- 日本語でテスト名を記述

【テンプレート】
import { test, expect } from '@playwright/test';

test.describe('{機能名}', () => {
  test('{受入条件1}', async ({ page }) => {
    // Arrange
    // Act
    // Assert
  });
});
" --full-auto
```

## 生成されるテスト構成

```
tests/
├── {feature}.spec.ts       # E2Eテスト
├── {feature}.unit.spec.ts  # ユニットテスト（オプション）
└── fixtures/
    └── {feature}.json      # テストデータ
```

## テストテンプレート

```typescript
import { test, expect } from '@playwright/test';

test.describe('ユーザー認証', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/login');
  });

  test('メールとパスワードでログインできる', async ({ page }) => {
    // Arrange
    await page.fill('[data-testid="email-input"]', 'test@example.com');
    await page.fill('[data-testid="password-input"]', 'password123');

    // Act
    await page.click('[data-testid="login-button"]');

    // Assert
    await expect(page).toHaveURL('/dashboard');
    await expect(page.locator('[data-testid="welcome-message"]')).toBeVisible();
  });

  test('無効なパスワードでエラーが表示される', async ({ page }) => {
    // Arrange
    await page.fill('[data-testid="email-input"]', 'test@example.com');
    await page.fill('[data-testid="password-input"]', 'wrong');

    // Act
    await page.click('[data-testid="login-button"]');

    // Assert
    await expect(page.locator('[data-testid="error-message"]')).toHaveText(
      'メールアドレスまたはパスワードが正しくありません'
    );
  });
});
```

## 出力例

```
> /test auth

🧪 テストを生成します... (Codex)

要件定義を読み込み中...
  ✓ docs/requirements/auth.md（受入条件: 5件）

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 Codex (full-auto) でテスト生成中...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Codex] tests/auth.spec.ts を作成中...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ テスト生成完了！

生成ファイル:
  → tests/auth.spec.ts

テストケース: 6件
  ✓ メールとパスワードでログインできる
  ✓ 認証成功時、ダッシュボードにリダイレクトされる
  ✓ 認証失敗時、エラーメッセージが表示される
  ✓ 空のフィールドでバリデーションエラー
  ✓ ログアウトでセッション終了
  ✓ セッション切れでログイン画面にリダイレクト
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

テスト実行: npx playwright test tests/auth.spec.ts
```
