#!/bin/bash
# ============================================
# Claude Code + Codex フルスタック開発テンプレート
# ============================================
# 使用方法:
#   curl -fsSL https://raw.githubusercontent.com/yu010101/claude-codex-collab/main/install-fullstack.sh | bash
#   curl -fsSL ... | bash -s -- my-project-name
# ============================================

set -e

VERSION="2.0.0"
REPO_RAW="https://raw.githubusercontent.com/yu010101/claude-codex-collab/main"

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

print_banner() {
    echo -e "${MAGENTA}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║                                                           ║"
    echo "║   🚀 フルスタック開発テンプレート v${VERSION}                 ║"
    echo "║                                                           ║"
    echo "║   Claude Code + Codex + Supabase + Vercel + Design       ║"
    echo "║                                                           ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

check_command() {
    if command -v "$1" &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} $1"
        return 0
    else
        echo -e "  ${YELLOW}○${NC} $1 (未インストール)"
        return 1
    fi
}

install_if_missing() {
    local cmd=$1
    local install_cmd=$2
    local name=$3

    if ! command -v "$cmd" &> /dev/null; then
        echo -e "${YELLOW}📦 ${name}をインストール中...${NC}"
        eval "$install_cmd"
        echo -e "${GREEN}✓ ${name}インストール完了${NC}"
    fi
}

print_banner

# プロジェクト名とディレクトリ
PROJECT_NAME="${1:-}"
if [ -n "$PROJECT_NAME" ]; then
    mkdir -p "$PROJECT_NAME"
    cd "$PROJECT_NAME"
fi
PROJECT_DIR=$(pwd)
PROJECT_NAME=${PROJECT_NAME:-$(basename "$PROJECT_DIR")}

echo -e "${CYAN}📁 プロジェクト: ${PROJECT_NAME}${NC}"
echo -e "${CYAN}📂 ディレクトリ: ${PROJECT_DIR}${NC}"
echo ""

# ===== 必要なコマンド確認 =====
echo "🔍 開発ツールを確認中..."
echo ""

MISSING_REQUIRED=0
MISSING_OPTIONAL=0

echo -e "${CYAN}[必須ツール]${NC}"
check_command "node" || MISSING_REQUIRED=1
check_command "npm" || MISSING_REQUIRED=1
check_command "git" || MISSING_REQUIRED=1

echo ""
echo -e "${CYAN}[AI開発ツール]${NC}"
check_command "claude" || MISSING_OPTIONAL=1
check_command "codex" || MISSING_OPTIONAL=1

echo ""
echo -e "${CYAN}[クラウドツール]${NC}"
check_command "supabase" || MISSING_OPTIONAL=1
check_command "vercel" || MISSING_OPTIONAL=1

echo ""

if [ $MISSING_REQUIRED -eq 1 ]; then
    echo -e "${RED}❌ 必須ツールがインストールされていません${NC}"
    echo "Node.js: https://nodejs.org/"
    exit 1
fi

# オプションツールのインストール提案
if [ $MISSING_OPTIONAL -eq 1 ]; then
    echo -e "${YELLOW}⚠️  一部のツールが見つかりません${NC}"
    echo ""
    echo "インストールコマンド:"
    command -v claude &> /dev/null || echo "  npm install -g @anthropic-ai/claude-code"
    command -v codex &> /dev/null || echo "  npm install -g @openai/codex"
    command -v supabase &> /dev/null || echo "  npm install -g supabase"
    command -v vercel &> /dev/null || echo "  npm install -g vercel"
    echo ""
    read -p "自動インストールしますか？ [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        command -v claude &> /dev/null || npm install -g @anthropic-ai/claude-code
        command -v codex &> /dev/null || npm install -g @openai/codex
        command -v supabase &> /dev/null || npm install -g supabase
        command -v vercel &> /dev/null || npm install -g vercel
        echo -e "${GREEN}✓ ツールインストール完了${NC}"
    fi
fi

# ===== ディレクトリ構造作成 =====
echo ""
echo "📁 ディレクトリ構造を作成中..."
mkdir -p scripts
mkdir -p .codex-tasks
mkdir -p .claude/skills
echo -e "  ${GREEN}✓${NC} scripts/"
echo -e "  ${GREEN}✓${NC} .codex-tasks/"
echo -e "  ${GREEN}✓${NC} .claude/skills/"

# ===== CLAUDE.md 作成 =====
echo ""
echo "📝 設定ファイルを作成中..."

cat > CLAUDE.md << 'EOF'
# CLAUDE.md - フルスタック開発設定

## プロジェクト概要

<!-- プロジェクトの説明を記載 -->

## 技術スタック

- **フロントエンド**: Next.js 14 (App Router)
- **バックエンド**: Supabase (PostgreSQL + Auth + Storage)
- **デプロイ**: Vercel
- **AI開発**: Claude Code + Codex

## 自動タスク委譲ルール

### Codexへの自動委譲

| キーワード | アクション |
|-----------|-----------|
| 「レビュー」「review」 | `./scripts/auto-delegate.sh review` |
| 「テスト作成」「test」 | `./scripts/auto-delegate.sh test` |
| 「ドキュメント」 | `./scripts/auto-delegate.sh docs` |
| 「リファクタ」 | `./scripts/auto-delegate.sh refactor` |

### サブエージェント活用

| 状況 | 起動 |
|-----|------|
| コード探索 | `Task(subagent_type="Explore")` |
| 計画立案 | `Task(subagent_type="Plan")` |
| 並列調査 | 複数Task並列 |

## カスタムスキル

### デザインスキル

- `/design [説明]` - UIコンポーネント生成
- `/design-page [ページ名]` - ページ全体のデザイン
- `/design-system` - デザインシステム構築

### 開発スキル

- `/new-feature [機能名]` - 機能追加ワークフロー
- `/fix-bug [問題]` - バグ修正ワークフロー
- `/review` - Codexコードレビュー
- `/test [対象]` - テスト生成

### インフラスキル

- `/deploy` - Vercelデプロイ
- `/deploy-preview` - プレビューデプロイ
- `/db-push` - Supabaseマイグレーション
- `/db-gen` - 型定義生成
- `/setup-env` - 環境変数セットアップ

## ワークフロー

### 新機能追加フロー（自動）

```
[/new-feature 依頼]
    ↓
[1] Plan → 設計
    ↓
[2] /design → UI生成
    ↓
[3] 実装
    ↓
[4] Codex → テスト
    ↓
[5] Codex → レビュー
    ↓
[6] /deploy-preview
```

### バグ修正フロー（自動）

```
[/fix-bug 報告]
    ↓
[1] Explore → 原因調査
    ↓
[2] 修正実装
    ↓
[3] Codex → レビュー
    ↓
[4] /deploy
```

## コマンドリファレンス

```bash
# 開発サーバー
npm run dev

# Supabase
supabase start          # ローカル起動
supabase db push        # マイグレーション
supabase gen types      # 型生成

# Vercel
vercel                  # デプロイ
vercel --prod           # 本番デプロイ

# Codex委譲
./scripts/auto-delegate.sh review
./scripts/auto-delegate.sh test
```

## ディレクトリ構造

```
/
├── app/                    # Next.js App Router
│   ├── (auth)/            # 認証ページ
│   ├── (dashboard)/       # ダッシュボード
│   └── api/               # API Routes
├── components/            # UIコンポーネント
│   ├── ui/               # 基本UI
│   └── features/         # 機能別
├── lib/                   # ユーティリティ
│   ├── supabase/         # Supabaseクライアント
│   └── utils/            # ヘルパー
├── supabase/             # Supabase設定
│   ├── migrations/       # マイグレーション
│   └── functions/        # Edge Functions
└── scripts/              # 開発スクリプト
```
EOF
echo -e "  ${GREEN}✓${NC} CLAUDE.md"

# ===== AGENTS.md =====
cat > AGENTS.md << 'EOF'
# AGENTS.md - AI Agent Collaboration Guide

## プロジェクト概要

フルスタックWebアプリケーション
- Next.js + Supabase + Vercel

## 推奨タスク分担

| タスク | 担当 |
|-------|------|
| 設計・計画 | Claude Code |
| UIデザイン | Claude Code (frontend-design) |
| ロジック実装 | Claude Code |
| コードレビュー | Codex |
| テスト作成 | Codex |
| ドキュメント | Codex |

## エージェント識別子

- `@claude-code`
- `@codex`
- `@human`
EOF
echo -e "  ${GREEN}✓${NC} AGENTS.md"

# ===== TODO.md =====
cat > TODO.md << 'EOF'
# TODO - タスク管理

## 進行中

なし

## 未着手

- [ ] プロジェクト初期設定 (@human)
- [ ] Supabase接続設定 (@human)
- [ ] Vercel連携 (@human)

## 完了

---
EOF
echo -e "  ${GREEN}✓${NC} TODO.md"

# ===== カスタムスキル: design =====
cat > .claude/skills/design.md << 'EOF'
---
name: design
description: UIコンポーネントを生成
---

# /design スキル

高品質なUIコンポーネントを生成します。

## 実行内容

1. frontend-design スキルを呼び出し
2. コンポーネントを生成
3. 適切なディレクトリに配置

## 使用方法

```
/design ログインフォーム
/design ユーザープロフィールカード
/design データテーブル（ソート・フィルター付き）
```
EOF
echo -e "  ${GREEN}✓${NC} .claude/skills/design.md"

# ===== カスタムスキル: deploy =====
cat > .claude/skills/deploy.md << 'EOF'
---
name: deploy
description: Vercelにデプロイ
---

# /deploy スキル

Vercelにデプロイします。

## 実行コマンド

```bash
# 型チェック
npm run type-check || true

# ビルド確認
npm run build

# デプロイ
vercel --prod
```

## プレビューデプロイ

`/deploy-preview` でプレビュー環境にデプロイ:

```bash
vercel
```
EOF
echo -e "  ${GREEN}✓${NC} .claude/skills/deploy.md"

# ===== カスタムスキル: db =====
cat > .claude/skills/db.md << 'EOF'
---
name: db-push
description: Supabaseマイグレーション実行
---

# /db-push スキル

Supabaseにマイグレーションを適用します。

## 実行コマンド

```bash
supabase db push
```

---

# /db-gen スキル

Supabaseから型定義を生成します。

## 実行コマンド

```bash
supabase gen types typescript --local > lib/supabase/database.types.ts
```
EOF
echo -e "  ${GREEN}✓${NC} .claude/skills/db.md"

# ===== カスタムスキル: new-feature =====
cat > .claude/skills/new-feature.md << 'EOF'
---
name: new-feature
description: 新機能追加ワークフロー
---

# /new-feature スキル

新機能を追加する際のフルワークフローを実行します。

## ワークフロー

1. **計画フェーズ**
   - Task(subagent_type="Plan") で設計
   - 必要なファイル・変更点を特定

2. **デザインフェーズ**
   - frontend-design スキルでUI生成
   - コンポーネントを作成

3. **実装フェーズ**
   - ロジックを実装
   - APIエンドポイント作成（必要に応じて）
   - Supabase連携（必要に応じて）

4. **テストフェーズ**
   - Codexでテスト生成
   - `./scripts/auto-delegate.sh test`

5. **レビューフェーズ**
   - Codexでコードレビュー
   - `./scripts/auto-delegate.sh review`

6. **デプロイフェーズ**
   - プレビューデプロイ
   - `vercel`

## 使用方法

```
/new-feature ユーザー認証機能
/new-feature ダッシュボード画面
/new-feature 通知システム
```
EOF
echo -e "  ${GREEN}✓${NC} .claude/skills/new-feature.md"

# ===== カスタムスキル: fix-bug =====
cat > .claude/skills/fix-bug.md << 'EOF'
---
name: fix-bug
description: バグ修正ワークフロー
---

# /fix-bug スキル

バグを修正するワークフローを実行します。

## ワークフロー

1. **調査フェーズ**
   - Task(subagent_type="Explore") で原因調査
   - 関連ファイルを特定

2. **修正フェーズ**
   - バグを修正
   - 影響範囲を確認

3. **レビューフェーズ**
   - Codexでレビュー
   - `./scripts/auto-delegate.sh review`

4. **テストフェーズ**
   - 修正の検証
   - リグレッションテスト

## 使用方法

```
/fix-bug ログイン時にエラーが発生する
/fix-bug データが保存されない
```
EOF
echo -e "  ${GREEN}✓${NC} .claude/skills/fix-bug.md"

# ===== auto-delegate.sh =====
cat > scripts/auto-delegate.sh << 'SCRIPT_EOF'
#!/bin/bash
set -e

TASK_TYPE="$1"
TASK_ARGS="$2"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TASK_DIR="$PROJECT_DIR/.codex-tasks"
mkdir -p "$TASK_DIR"

TASK_ID=$(date +%Y%m%d-%H%M%S)
OUTPUT_FILE="$TASK_DIR/output-$TASK_ID.txt"

cd "$PROJECT_DIR"

case "$TASK_TYPE" in
    "review")
        echo "🔍 Codexでコードレビュー..."
        if [ -n "$TASK_ARGS" ]; then
            codex review --base "$TASK_ARGS" 2>&1 | tee "$OUTPUT_FILE"
        else
            codex review --uncommitted 2>&1 | tee "$OUTPUT_FILE"
        fi
        ;;
    "test")
        echo "🧪 Codexでテスト作成..."
        TARGET="${TASK_ARGS:-.}"
        codex exec --full-auto -C "$PROJECT_DIR" \
            "${TARGET}のユニットテストを作成。Jest/Vitestを使用。" \
            2>&1 | tee "$OUTPUT_FILE"
        ;;
    "docs")
        echo "📝 Codexでドキュメント生成..."
        codex exec --full-auto -C "$PROJECT_DIR" \
            "プロジェクトのドキュメントを生成・更新。" \
            2>&1 | tee "$OUTPUT_FILE"
        ;;
    "refactor")
        echo "🔧 Codexでリファクタリング..."
        TARGET="${TASK_ARGS:-.}"
        codex exec --full-auto -C "$PROJECT_DIR" \
            "${TARGET}をリファクタリング。可読性向上。" \
            2>&1 | tee "$OUTPUT_FILE"
        ;;
    "custom")
        echo "⚡ Codexでカスタムタスク..."
        codex exec --full-auto -C "$PROJECT_DIR" "$TASK_ARGS" \
            2>&1 | tee "$OUTPUT_FILE"
        ;;
    "background")
        echo "🚀 バックグラウンド実行..."
        codex exec --full-auto -C "$PROJECT_DIR" "$TASK_ARGS" \
            > "$OUTPUT_FILE" 2>&1 &
        echo "タスクID: $TASK_ID | PID: $!"
        echo "$!" > "$TASK_DIR/pid-$TASK_ID.txt"
        exit 0
        ;;
    *)
        echo "使用方法:"
        echo "  $0 review [base]"
        echo "  $0 test [path]"
        echo "  $0 docs"
        echo "  $0 refactor [path]"
        echo "  $0 custom \"タスク\""
        echo "  $0 background \"タスク\""
        exit 1
        ;;
esac
echo "✅ 完了: $OUTPUT_FILE"
SCRIPT_EOF
chmod +x scripts/auto-delegate.sh
echo -e "  ${GREEN}✓${NC} scripts/auto-delegate.sh"

# ===== check-codex-task.sh =====
cat > scripts/check-codex-task.sh << 'SCRIPT_EOF'
#!/bin/bash
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TASK_DIR="$PROJECT_DIR/.codex-tasks"

if [ -n "$1" ]; then
    TASK_ID="$1"
else
    LATEST=$(ls -t "$TASK_DIR"/output-*.txt 2>/dev/null | head -1)
    [ -z "$LATEST" ] && echo "タスクなし" && exit 1
    TASK_ID=$(basename "$LATEST" | sed 's/output-//' | sed 's/.txt//')
fi

echo "📋 タスク: $TASK_ID"
PID_FILE="$TASK_DIR/pid-$TASK_ID.txt"
[ -f "$PID_FILE" ] && ps -p $(cat "$PID_FILE") > /dev/null 2>&1 && echo "🔄 実行中" || echo "✅ 完了"
echo "---"
tail -30 "$TASK_DIR/output-$TASK_ID.txt" 2>/dev/null
SCRIPT_EOF
chmod +x scripts/check-codex-task.sh
echo -e "  ${GREEN}✓${NC} scripts/check-codex-task.sh"

# ===== setup-env.sh =====
cat > scripts/setup-env.sh << 'SCRIPT_EOF'
#!/bin/bash
echo "🔧 環境変数セットアップ"

if [ -f .env.local ]; then
    echo "⚠️  .env.local が既に存在します"
    read -p "上書きしますか？ [y/N] " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 0
fi

cat > .env.local << 'ENV_EOF'
# Supabase
NEXT_PUBLIC_SUPABASE_URL=your-supabase-url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# App
NEXT_PUBLIC_APP_URL=http://localhost:3000
ENV_EOF

echo "✅ .env.local を作成しました"
echo "📝 Supabaseの値を設定してください"
SCRIPT_EOF
chmod +x scripts/setup-env.sh
echo -e "  ${GREEN}✓${NC} scripts/setup-env.sh"

# ===== .gitignore =====
cat > .gitignore << 'EOF'
# Dependencies
node_modules/
.pnpm-store/

# Build
.next/
out/
dist/

# Environment
.env
.env.local
.env.*.local

# Codex
.codex-tasks/

# Supabase
supabase/.temp/

# IDE
.idea/
.vscode/
*.swp

# OS
.DS_Store
Thumbs.db

# Debug
npm-debug.log*
yarn-debug.log*
yarn-error.log*
EOF
echo -e "  ${GREEN}✓${NC} .gitignore"

# ===== 完了メッセージ =====
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ フルスタック開発テンプレート セットアップ完了！${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${CYAN}📖 クイックスタート:${NC}"
echo ""
echo "  1. Claude Codeを起動:"
echo -e "     ${BLUE}claude${NC}"
echo ""
echo "  2. カスタムスキル:"
echo -e "     ${BLUE}/design ログインフォーム${NC}      UIコンポーネント生成"
echo -e "     ${BLUE}/new-feature ユーザー認証${NC}    機能追加ワークフロー"
echo -e "     ${BLUE}/deploy${NC}                     Vercelデプロイ"
echo -e "     ${BLUE}/db-push${NC}                    Supabaseマイグレーション"
echo ""
echo "  3. Codex委譲:"
echo -e "     ${BLUE}./scripts/auto-delegate.sh review${NC}"
echo -e "     ${BLUE}./scripts/auto-delegate.sh test${NC}"
echo ""
echo -e "${CYAN}📦 次のステップ:${NC}"
echo ""
echo "  # Next.jsプロジェクト作成（まだの場合）"
echo -e "  ${BLUE}npx create-next-app@latest . --typescript --tailwind --app${NC}"
echo ""
echo "  # Supabase初期化"
echo -e "  ${BLUE}supabase init${NC}"
echo -e "  ${BLUE}supabase start${NC}"
echo ""
echo "  # Vercel連携"
echo -e "  ${BLUE}vercel link${NC}"
echo ""
echo "  # 環境変数設定"
echo -e "  ${BLUE}./scripts/setup-env.sh${NC}"
echo ""
echo -e "${CYAN}📚 ドキュメント:${NC}"
echo "  https://github.com/yu010101/claude-codex-collab"
echo ""
