# 既存プロジェクトへの導入ハンズオン

既にコードがあるプロジェクトに aiki を導入する手順です。

---

## 目次

1. [前提条件](#1-前提条件)
2. [Step 1: 現状確認](#step-1-現状確認)
3. [Step 2: インストール](#step-2-インストール)
4. [Step 3: プロジェクト固有設定](#step-3-プロジェクト固有設定)
5. [Step 4: 動作確認](#step-4-動作確認)
6. [Tips: 手動で最小構成を導入](#tips-手動で最小構成を導入)

---

## 1. 前提条件

### 必要なもの

| 項目 | 要件 |
|------|-----|
| OS | macOS / Linux / WSL2 |
| Node.js | 18.0 以上 |
| Claude Code | インストール済み |

### 対象プロジェクト例

```
my-existing-app/
├── src/
│   ├── app/
│   ├── components/
│   └── lib/
├── tests/
├── package.json
└── README.md
```

---

## Step 1: 現状確認

### 1-1. プロジェクトディレクトリに移動

```bash
cd /path/to/your-project
```

### 1-2. 既存ファイルの確認

```bash
# CLAUDE.md があるか確認
ls -la CLAUDE.md AGENTS.md 2>/dev/null || echo "設定ファイルなし（新規導入OK）"

# .claude ディレクトリがあるか確認
ls -la .claude/ 2>/dev/null || echo ".claudeディレクトリなし（新規導入OK）"
```

**出力例（新規導入の場合）:**
```
設定ファイルなし（新規導入OK）
.claudeディレクトリなし（新規導入OK）
```

### 1-3. 既存設定がある場合

既に `CLAUDE.md` がある場合はバックアップ:

```bash
# バックアップ作成
cp CLAUDE.md CLAUDE.md.backup
cp AGENTS.md AGENTS.md.backup 2>/dev/null || true
```

---

## Step 2: インストール

### 2-1. インストールスクリプト実行

**フルスタック版（推奨）:**

```bash
curl -fsSL https://raw.githubusercontent.com/AI-Driven-School/aiki/main/install-fullstack.sh | bash
```

**最小構成版（軽量）:**

```bash
curl -fsSL https://raw.githubusercontent.com/AI-Driven-School/aiki/main/install.sh | bash
```

### 2-2. インストール完了メッセージ

```
┌───────────────────────────────────────────┐
│  4AI適材適所テンプレート セットアップ完了   │
│  Claude × Codex × Gemini                  │
└───────────────────────────────────────────┘

✓ CLAUDE.md
✓ AGENTS.md
✓ scripts/delegate.sh
✓ .claude/skills/
```

### 2-3. 追加されるファイル確認

```bash
ls -la CLAUDE.md AGENTS.md scripts/ .claude/
```

**出力:**
```
-rw-r--r--  CLAUDE.md
-rw-r--r--  AGENTS.md

scripts/:
delegate.sh

.claude/:
skills/
```

---

## Step 3: プロジェクト固有設定

### 3-1. CLAUDE.md にプロジェクト情報を追加

`CLAUDE.md` の末尾に追加:

```bash
cat >> CLAUDE.md << 'EOF'

## プロジェクト固有

### 概要
- プロジェクト名: [あなたのプロジェクト名]
- 技術スタック: [例: Next.js, TypeScript, Prisma]

### ディレクトリ構造
```
src/
├── app/        # Next.js App Router
├── components/ # UIコンポーネント
└── lib/        # ユーティリティ
```

### 開発ルール
- コンポーネントは `components/` 配下に作成
- API は `app/api/` 配下に作成
- テストは `tests/` に配置

### よく使うコマンド
```bash
npm run dev      # 開発サーバー
npm run build    # ビルド
npm run test     # テスト実行
```
EOF
```

### 3-2. 設定を確認

```bash
# 追加した内容を確認
tail -30 CLAUDE.md
```

### 3-3. バージョン管理に追加

```bash
# .gitignore に不要なファイルを追加（必要に応じて）
echo ".codex-tasks/" >> .gitignore
echo ".claude-backup-*/" >> .gitignore

# コミット
git add CLAUDE.md AGENTS.md scripts/ .claude/ .gitignore
git commit -m "feat: aiki を導入"
```

---

## Step 4: 動作確認

### 4-1. Claude Code 起動

```bash
claude
```

### 4-2. 設定の読み込み確認

```
> このプロジェクトの概要を教えて
```

CLAUDE.md の内容を認識していれば成功。

### 4-3. サブエージェントの動作確認

```
> src/ 配下の構造を調べて
```

Claude が `Task(Explore)` でコード探索を開始すれば成功。

### 4-4. スキルの確認（フルスタック版のみ）

```
> /requirements ユーザー認証機能
```

要件定義が生成されれば成功。

---

## Tips: 手動で最小構成を導入

スクリプトを使わず、必要なファイルだけ手動で追加する方法。

### CLAUDE.md のみ追加

```bash
curl -fsSL https://raw.githubusercontent.com/AI-Driven-School/aiki/main/templates/default/CLAUDE.md > CLAUDE.md
```

### 特定のスキルだけ追加

```bash
mkdir -p .claude/skills

# 実装スキルのみ
curl -fsSL https://raw.githubusercontent.com/AI-Driven-School/aiki/main/.claude/skills/implement.md > .claude/skills/implement.md

# レビュースキルのみ
curl -fsSL https://raw.githubusercontent.com/AI-Driven-School/aiki/main/.claude/skills/review.md > .claude/skills/review.md
```

### サブエージェントルールだけ追加

既存の CLAUDE.md に以下を追記:

```markdown
## サブエージェント活用ルール

### 必須: Taskツールでサブエージェントを起動

1. **コード探索 (Explore)**
   - トリガー: 「〜はどこ？」「〜を探して」
   - 起動: `Task(subagent_type="Explore", prompt="...")`

2. **計画立案 (Plan)**
   - トリガー: 「〜を実装したい」「設計して」
   - 起動: `Task(subagent_type="Plan", prompt="...")`

3. **並列調査**
   - 複数ファイル/機能の調査 → 複数Taskを同時起動
```

---

## アップデート方法

既に導入済みのプロジェクトを最新版に更新:

```bash
curl -fsSL https://raw.githubusercontent.com/AI-Driven-School/aiki/main/update.sh | bash
```

**注意:** `## プロジェクト固有` セクションは自動的に保持されます。

---

## トラブルシューティング

### CLAUDE.md が上書きされた

```bash
# バックアップから復元
cp CLAUDE.md.backup CLAUDE.md

# または git から復元
git checkout HEAD -- CLAUDE.md
```

### スキルが認識されない

```bash
# ディレクトリ構造を確認
ls -la .claude/skills/

# Claude を再起動
claude
```

### 既存の CLAUDE.md とマージしたい

```bash
# テンプレートをダウンロード（別名で保存）
curl -fsSL https://raw.githubusercontent.com/AI-Driven-School/aiki/main/templates/default/CLAUDE.md > CLAUDE.template.md

# 手動でマージ
# 1. CLAUDE.template.md から必要な部分をコピー
# 2. 既存の CLAUDE.md に追記
```

---

## 次のステップ

- [ハンズオンチュートリアル](./HANDS_ON_TUTORIAL.md) - 新機能を追加してみる
- [コマンドリファレンス](./COMMANDS.md) - 全コマンドの詳細
