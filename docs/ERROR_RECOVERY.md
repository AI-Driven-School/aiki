# エラーリカバリガイド

AI実行時のエラー対処方法とリカバリ機構の使い方を説明します。

---

## クイックスタート

```bash
# 通常実行（リトライ3回、タイムアウト300秒）
./scripts/ai-runner.sh claude "この関数を説明して"

# フォールバック有効（Claude失敗→Codex→Gemini）
./scripts/ai-runner.sh claude "テストを作成" --fallback

# タイムアウト延長
./scripts/ai-runner.sh codex "大規模リファクタリング" --timeout 600
```

---

## エラーリカバリ機構

### 自動リトライ

| エラー種別 | 動作 | リトライ間隔 |
|-----------|------|-------------|
| タイムアウト | 3回リトライ | 5秒 |
| ネットワークエラー | 3回リトライ | 5秒 |
| レート制限 | 60秒待機後リトライ | 60秒 |
| 認証エラー | 即座に停止 | - |

### フォールバック順序

```
Claude 失敗
    ↓
Codex で再試行（実装タスク向け）
    ↓
Gemini で再試行（解析タスク向け）

Codex 失敗
    ↓
Claude で再試行

Gemini 失敗
    ↓
Claude で再試行（要約モード）
```

---

## オプション一覧

| オプション | デフォルト | 説明 |
|-----------|-----------|------|
| `--timeout <秒>` | 300 | タイムアウト秒数 |
| `--retry <回数>` | 3 | 最大リトライ回数 |
| `--fallback` | false | 失敗時に別AIにフォールバック |
| `--quiet` | false | 進捗表示を抑制 |

---

## エラー別対処法

### 1. タイムアウト

**症状:** `タイムアウト (300秒)` と表示される

**対処:**
```bash
# タイムアウトを延長
./scripts/ai-runner.sh codex "大規模タスク" --timeout 600

# または、タスクを分割
./scripts/ai-runner.sh codex "フロントエンドを実装"
./scripts/ai-runner.sh codex "バックエンドを実装"
```

### 2. レート制限

**症状:** `レート制限に達しました` と表示される

**対処:**
```bash
# 自動で60秒待機後リトライ
# 手動で待ちたい場合は Ctrl+C で中断して数分後に再実行
```

### 3. 認証エラー

**症状:** `認証エラー: 再ログインが必要です` と表示される

**対処:**
```bash
# Claude
claude  # インタラクティブモードで再ログイン

# Codex
codex   # ChatGPT アカウントで再認証

# Gemini
export GOOGLE_GENAI_USE_GCA=true
gemini  # Googleアカウントで再認証
```

### 4. AIがインストールされていない

**症状:** `<ai> がインストールされていません` と表示される

**対処:**
```bash
# Claude
npm install -g @anthropic-ai/claude-code

# Codex
npm install -g @openai/codex

# Gemini
npm install -g @google/gemini-cli
```

### 5. ネットワークエラー

**症状:** `ネットワークエラー` と表示される

**対処:**
- インターネット接続を確認
- VPN/プロキシ設定を確認
- ファイアウォール設定を確認

---

## delegate.sh との連携

`scripts/delegate.sh` でエラーリカバリを有効にする:

```bash
# delegate.sh の内部で ai-runner.sh を使用
./scripts/delegate.sh codex implement "設計書パス" --fallback
```

---

## CLAUDE.md での設定

プロジェクトの `CLAUDE.md` に以下を追記すると、AIが自動でリカバリ機構を使用:

```markdown
## エラーハンドリング

AI実行時は以下のルールに従う:

1. **タイムアウト**: 300秒でタイムアウト、3回リトライ
2. **レート制限**: 60秒待機後リトライ
3. **フォールバック**:
   - 実装タスク: Claude → Codex
   - 解析タスク: Gemini → Claude
```

---

## トラブルシューティング

### Q: リトライしても失敗する

```bash
# 詳細ログを確認
./scripts/ai-runner.sh claude "タスク" 2>&1 | tee debug.log

# 別のAIで試す
./scripts/ai-runner.sh codex "同じタスク" --fallback
```

### Q: フォールバックが機能しない

```bash
# 各AIが利用可能か確認
which claude && claude --version
which codex && codex --version
which gemini && gemini --version
```

### Q: 特定のAIだけ使いたい

```bash
# フォールバックを無効化（デフォルト）
./scripts/ai-runner.sh claude "タスク"

# --fallback をつけなければフォールバックしない
```

---

## 関連ドキュメント

- [使用量レポート](./USAGE_REPORT.md) - トークン消費量の確認
- [コマンドリファレンス](./COMMANDS.md) - 全コマンド一覧
