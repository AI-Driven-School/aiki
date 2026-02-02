# コマンドリファレンス

全コマンドの詳細ガイドです。

---

## 目次

1. [プロジェクト管理](#プロジェクト管理)
2. [設計コマンド（Claude）](#設計コマンドclaude)
3. [実装コマンド（Codex）](#実装コマンドcodex)
4. [解析コマンド（Gemini）](#解析コマンドgemini)

---

## プロジェクト管理

### /project

6フェーズの承認ワークフローを実行。

```bash
/project <機能名>
```

#### 例

```bash
/project ユーザー認証
/project 商品検索機能
/project "メール通知システム"
```

#### オプション

| オプション | 説明 |
|-----------|------|
| `--resume` | 中断したプロジェクトを再開 |
| `--list` | 進行中プロジェクト一覧 |
| `--skip-tests` | テスト生成をスキップ |

#### ワークフロー（6フェーズ）

```
Phase 1: 要件定義     → Claude（承認待ち）
Phase 2: 設計         → Claude（承認待ち）
Phase 3: 実装         → Codex（自動）★メイン
Phase 4: テスト       → Codex（自動）
Phase 5: レビュー     → Claude（自動）
Phase 6: デプロイ     → Claude（承認待ち）
```

---

### /status

プロジェクトの進行状況を確認。

```bash
/status
/status <プロジェクト名>
```

#### 出力例

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
プロジェクト: ユーザー認証
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[1/6] 要件定義    ✅ 承認済み
[2/6] 設計        🔄 進行中
[3/6] 実装        ⏳ 待機中（→Codex）
[4/6] テスト      ⏳ 待機中（→Codex）
[5/6] レビュー    ⏳ 待機中
[6/6] デプロイ    ⏳ 待機中
```

---

### /approve

現在のフェーズを承認して次に進む。

```bash
/approve
/approve --all  # 残り全てのフェーズを自動承認
```

---

### /reject

現在のフェーズを却下して再生成。

```bash
/reject <理由>
```

#### 例

```bash
/reject "もっとシンプルな設計に"
/reject "認証方式をJWTに変更"
```

---

## 設計コマンド（Claude）

### /requirements

要件定義書を生成。

```bash
/requirements <機能名>
```

#### 出力

`docs/requirements/<機能名>.md`

#### 出力形式

```markdown
# 要件定義: {機能名}

## ユーザーストーリー
AS A {ユーザー種別}
I WANT TO {やりたいこと}
SO THAT {得られる価値}

## 受入条件
- [ ] 条件1
- [ ] 条件2

## 非機能要件
- パフォーマンス:
- セキュリティ:

## 制約事項
- 技術的制約:
- ビジネス制約:
```

---

### /spec

画面設計書を生成。

```bash
/spec <画面名>
```

#### 出力

- `docs/specs/<画面名>.md`
- `mockups/<画面名>.png`（オプション）

#### 例

```bash
/spec ログイン画面
/spec ダッシュボード
/spec "商品詳細ページ"
```

---

### /api

OpenAPI 3.0形式のAPI設計書を生成。

```bash
/api <API名>
```

#### 出力

`docs/api/<API名>.yaml`

#### 例

```bash
/api 認証API
/api ユーザーAPI
/api 商品API
```

---

### /review

コードレビューを実行。

```bash
/review
/review <ファイルパス>
```

#### 出力

`docs/reviews/<日付>-<機能名>.md`

---

### /deploy

本番環境へデプロイ。

```bash
/deploy
/deploy preview    # プレビュー環境
/deploy production # 本番環境
```

#### 対応プラットフォーム

- Vercel（デフォルト）
- Netlify
- AWS Amplify
- Fly.io

---

## 実装コマンド（Codex）

> これらのコマンドはCodexに委譲され、full-autoモードで実行されます。

### /implement

承認済み設計書から実装コードを生成。

```bash
/implement
/implement <機能名>
```

#### 前提条件

以下が承認済みであること:

1. `docs/requirements/<機能名>.md`
2. `docs/specs/<画面名>.md`
3. `docs/api/<API名>.yaml`

#### 例

```bash
/implement              # 全設計書から実装
/implement auth         # 認証機能のみ
/implement products     # 商品機能のみ
```

#### 実行内容

```bash
./scripts/delegate.sh codex implement
```

---

### /test

テストを生成（Codexに委譲）。

```bash
/test
/test <機能名>
/test <ファイルパス>
```

#### 例

```bash
/test                           # 全テスト
/test auth                      # 認証テスト
/test src/components/Button.tsx # 特定ファイル
```

#### 実行内容

```bash
./scripts/delegate.sh codex test
```

---

## 解析コマンド（Gemini）

> 1Mトークンコンテキストを活かした大規模解析。無料。

### /analyze

Geminiで大規模コード解析。

```bash
/analyze
/analyze <パス>
```

#### 用途

- 大規模リファクタリング前の調査
- 依存関係の把握
- 技術的負債の特定

#### 例

```bash
/analyze                    # プロジェクト全体
/analyze src/               # srcディレクトリ
/analyze src/lib/api/       # 特定ディレクトリ
```

---

### /research

Geminiで技術リサーチ。

```bash
/research "<質問>"
```

#### 例

```bash
/research "Next.js 15 App Router のベストプラクティス"
/research "認証ライブラリ 比較 2025"
/research "React Server Components"
```

---

### /refactor

Geminiでリファクタリング提案。

```bash
/refactor <パス>
```

#### 例

```bash
/refactor src/lib/
/refactor src/components/
```

---

## 承認コマンド一覧

| 入力 | アクション |
|------|----------|
| `Y` / `y` / `yes` / Enter | 承認 |
| `N` / `n` / `no` | 却下（理由を聞かれる） |
| `reject <理由>` | 理由付きで却下 |
| `skip` | フェーズをスキップ |
| `edit` | 手動で編集してから承認 |
| `show` | 生成内容を再表示 |
| `diff` | 前回との差分を表示 |

---

## コマンドエイリアス

| フルコマンド | エイリアス |
|------------|----------|
| `/requirements` | `/req` |
| `/implement` | `/impl` |
| `/deploy` | `/ship` |

---

## 環境変数

| 変数名 | 説明 | デフォルト |
|-------|------|----------|
| `AI_AUTO_APPROVE` | 自動承認モード | `false` |
| `AI_SKIP_TESTS` | テスト生成をスキップ | `false` |
| `AI_DEPLOY_TARGET` | デプロイ先 | `vercel` |
| `GOOGLE_GENAI_USE_GCA` | Gemini認証 | `true` |
