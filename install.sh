#!/bin/bash
# ============================================
# Claude Code + Codex 自動連携インストーラー
# ============================================
# 使用方法:
#   curl -fsSL https://raw.githubusercontent.com/yu010101/claude-codex-collab/main/install.sh | bash
#   curl -fsSL ... | bash -s -- /path/to/project
# ============================================

set -e

VERSION="1.0.0"
REPO_URL="https://raw.githubusercontent.com/yu010101/claude-codex-collab/main"

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_banner() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════╗"
    echo "║                                                   ║"
    echo "║   🤖 Claude Code + Codex 自動連携 v${VERSION}        ║"
    echo "║                                                   ║"
    echo "╚═══════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

check_command() {
    if command -v "$1" &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} $1 $(command -v $1)"
        return 0
    else
        echo -e "  ${RED}✗${NC} $1 - 未インストール"
        return 1
    fi
}

print_banner

# プロジェクトディレクトリ
PROJECT_DIR="${1:-.}"
if [ "$PROJECT_DIR" = "." ]; then
    PROJECT_DIR=$(pwd)
else
    mkdir -p "$PROJECT_DIR"
    cd "$PROJECT_DIR"
    PROJECT_DIR=$(pwd)
fi

echo -e "${YELLOW}📁 インストール先: ${PROJECT_DIR}${NC}"
echo ""

# 必要なコマンドの確認
echo "🔍 必要なコマンドを確認中..."
MISSING=0
check_command "claude" || MISSING=1
check_command "codex" || MISSING=1
echo ""

if [ $MISSING -eq 1 ]; then
    echo -e "${YELLOW}⚠️  一部のコマンドが見つかりません${NC}"
    echo ""
    echo "インストール方法:"
    echo "  Claude Code: npm install -g @anthropic-ai/claude-code"
    echo "  Codex CLI:   npm install -g @openai/codex"
    echo ""
    read -p "続行しますか？ [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# ディレクトリ作成
echo "📁 ディレクトリを作成中..."
mkdir -p scripts
mkdir -p .codex-tasks
echo -e "  ${GREEN}✓${NC} scripts/"
echo -e "  ${GREEN}✓${NC} .codex-tasks/"

# ファイル作成
echo ""
echo "📝 設定ファイルを作成中..."

# CLAUDE.md
cat > CLAUDE.md << 'EOF'
# CLAUDE.md - Claude Code 自動設定

## プロジェクト概要

<!-- プロジェクトの説明を記載してください -->

## 自動タスク委譲ルール

### Codexへの自動委譲

以下のタスクは **自動的にCodexに委譲** してください：

| キーワード | アクション |
|-----------|-----------|
| 「レビュー」「review」「チェックして」 | `./scripts/auto-delegate.sh review` |
| 「テスト作成」「test」「テストを書いて」 | `./scripts/auto-delegate.sh test [path]` |
| 「ドキュメント」「README」 | `./scripts/auto-delegate.sh docs` |
| 「リファクタ」「整理して」 | `./scripts/auto-delegate.sh refactor [path]` |

### サブエージェント活用

| 状況 | 起動するサブエージェント |
|-----|----------------------|
| コードベースの調査が必要 | `Task(subagent_type="Explore")` |
| 実装計画が必要 | `Task(subagent_type="Plan")` |
| 複数ファイルの並列調査 | 複数の `Task` を並列起動 |

### 実装フロー（自動実行）

```
[依頼] → [Explore調査] → [実装] → [Codexレビュー] → [修正] → [完了]
```

## 委譲コマンド

```bash
./scripts/auto-delegate.sh review              # コードレビュー
./scripts/auto-delegate.sh test [path]         # テスト作成
./scripts/auto-delegate.sh docs                # ドキュメント生成
./scripts/auto-delegate.sh refactor [path]     # リファクタリング
./scripts/auto-delegate.sh custom "タスク"     # カスタムタスク
./scripts/auto-delegate.sh background "タスク" # バックグラウンド実行
```

## 注意事項

- 本番環境の認証情報をコードに含めない
- `--force` 付きのgit pushは確認なしで実行しない
EOF
echo -e "  ${GREEN}✓${NC} CLAUDE.md"

# AGENTS.md
cat > AGENTS.md << 'EOF'
# AGENTS.md - AI Agent Collaboration Guide

このファイルはClaude Code / Codex が共同作業するためのガイドです。

## プロジェクト概要

<!-- プロジェクトの説明を記載してください -->

## ディレクトリ構造

```
<!-- ディレクトリ構造を記載してください -->
```

## 開発ルール

### コーディング規約

- コメント: 日本語可
- 変数名・関数名: 英語

### タスク管理

作業前に `TODO.md` を確認・更新してください。

## Claude Code → Codex タスク委譲

### タスクを委譲

```bash
./scripts/auto-delegate.sh review
./scripts/auto-delegate.sh test src/
./scripts/auto-delegate.sh custom "タスク内容"
```

### 状態確認

```bash
./scripts/check-codex-task.sh
```

## 推奨タスク分担

| タスク | 担当 | 理由 |
|-------|------|------|
| 設計・計画 | Claude Code | コンテキスト理解が重要 |
| 複雑な実装 | Claude Code | 既存コードとの整合性 |
| デバッグ | Claude Code | 対話的な調査が必要 |
| コードレビュー | Codex | 自動化・高速 |
| テスト作成 | Codex | 定型作業 |
| ドキュメント | Codex | 定型作業 |

## エージェント識別子

- `@claude-code` - Claude Code
- `@codex` - Codex
- `@human` - 人間
EOF
echo -e "  ${GREEN}✓${NC} AGENTS.md"

# TODO.md
cat > TODO.md << 'EOF'
# TODO - タスク管理

エージェント間で共有するタスクリストです。

## 進行中のタスク

なし

## 未着手タスク

- [ ] セットアップ完了確認 (@human)

## 完了タスク

---

## タスク記載フォーマット

```markdown
- [ ] タスク名 (@担当エージェント)
  - 詳細説明
  - 関連ファイル: `path/to/file`
```

## 担当エージェント識別子

- `@claude-code` - Claude Code
- `@codex` - Codex
- `@human` - 人間
EOF
echo -e "  ${GREEN}✓${NC} TODO.md"

# auto-delegate.sh
cat > scripts/auto-delegate.sh << 'SCRIPT_EOF'
#!/bin/bash
# ============================================
# 自動タスク委譲スクリプト
# Claude CodeからCodexにタスクを委譲
# ============================================

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
        echo "🔍 Codexでコードレビューを実行中..."
        if [ -n "$TASK_ARGS" ]; then
            codex review --base "$TASK_ARGS" 2>&1 | tee "$OUTPUT_FILE"
        else
            codex review --uncommitted 2>&1 | tee "$OUTPUT_FILE"
        fi
        ;;

    "test")
        echo "🧪 Codexでテスト作成を実行中..."
        TARGET="${TASK_ARGS:-.}"
        codex exec --full-auto \
            -C "$PROJECT_DIR" \
            "${TARGET}のユニットテストを作成してください。既存のテストパターンに従ってください。" \
            2>&1 | tee "$OUTPUT_FILE"
        ;;

    "docs")
        echo "📝 Codexでドキュメント生成を実行中..."
        TARGET="${TASK_ARGS:-README.md}"
        codex exec --full-auto \
            -C "$PROJECT_DIR" \
            "プロジェクトのドキュメント（${TARGET}）を生成・更新してください。" \
            2>&1 | tee "$OUTPUT_FILE"
        ;;

    "refactor")
        echo "🔧 Codexでリファクタリングを実行中..."
        TARGET="${TASK_ARGS:-.}"
        codex exec --full-auto \
            -C "$PROJECT_DIR" \
            "${TARGET}のコードを整理・リファクタリングしてください。機能は変更せず、可読性とメンテナンス性を向上させてください。" \
            2>&1 | tee "$OUTPUT_FILE"
        ;;

    "custom")
        echo "⚡ Codexでカスタムタスクを実行中..."
        codex exec --full-auto \
            -C "$PROJECT_DIR" \
            "$TASK_ARGS" \
            2>&1 | tee "$OUTPUT_FILE"
        ;;

    "background")
        echo "🚀 Codexをバックグラウンドで実行中..."
        codex exec --full-auto \
            -C "$PROJECT_DIR" \
            "$TASK_ARGS" \
            > "$OUTPUT_FILE" 2>&1 &
        CODEX_PID=$!
        echo "$CODEX_PID" > "$TASK_DIR/pid-$TASK_ID.txt"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "📋 タスクID: $TASK_ID"
        echo "📄 出力ファイル: $OUTPUT_FILE"
        echo "🔄 PID: $CODEX_PID"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "進捗確認: tail -f $OUTPUT_FILE"
        echo "状態確認: ./scripts/check-codex-task.sh $TASK_ID"
        exit 0
        ;;

    *)
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "🤖 Claude Code + Codex 自動委譲"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "使用方法:"
        echo "  $0 review [base-branch]     コードレビュー"
        echo "  $0 test [target-path]       テスト作成"
        echo "  $0 docs [target-file]       ドキュメント生成"
        echo "  $0 refactor [target-path]   リファクタリング"
        echo "  $0 custom \"タスク内容\"      カスタムタスク"
        echo "  $0 background \"タスク内容\"  バックグラウンド実行"
        echo ""
        exit 1
        ;;
esac

echo ""
echo "✅ 完了 - 出力: $OUTPUT_FILE"
SCRIPT_EOF
chmod +x scripts/auto-delegate.sh
echo -e "  ${GREEN}✓${NC} scripts/auto-delegate.sh"

# check-codex-task.sh
cat > scripts/check-codex-task.sh << 'SCRIPT_EOF'
#!/bin/bash
# ============================================
# Codexタスク状態確認スクリプト
# ============================================

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TASK_DIR="$PROJECT_DIR/.codex-tasks"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

if [ ! -d "$TASK_DIR" ]; then
    echo -e "${RED}タスクディレクトリが存在しません${NC}"
    exit 1
fi

# タスクID取得
if [ -n "$1" ]; then
    TASK_ID="$1"
else
    LATEST=$(ls -t "$TASK_DIR"/output-*.txt 2>/dev/null | head -1)
    if [ -z "$LATEST" ]; then
        echo -e "${YELLOW}タスクが見つかりません${NC}"
        exit 1
    fi
    TASK_ID=$(basename "$LATEST" | sed 's/output-//' | sed 's/.txt//')
fi

OUTPUT_FILE="$TASK_DIR/output-$TASK_ID.txt"
PID_FILE="$TASK_DIR/pid-$TASK_ID.txt"

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}📋 タスク情報: ${TASK_ID}${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# プロセス状態
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if ps -p "$PID" > /dev/null 2>&1; then
        echo -e "状態: ${YELLOW}🔄 実行中${NC} (PID: $PID)"
    else
        echo -e "状態: ${GREEN}✅ 完了${NC}"
    fi
else
    echo -e "状態: ${GREEN}✅ 完了${NC}"
fi

# 出力ファイル
if [ -f "$OUTPUT_FILE" ]; then
    LINES=$(wc -l < "$OUTPUT_FILE" | tr -d ' ')
    SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
    echo "出力: $OUTPUT_FILE ($LINES行, $SIZE)"
    echo ""
    echo -e "${CYAN}📤 出力内容（末尾30行）:${NC}"
    echo "─────────────────────────────────────────"
    tail -30 "$OUTPUT_FILE"
    echo "─────────────────────────────────────────"
else
    echo -e "${YELLOW}出力ファイルがありません${NC}"
fi

echo ""

# タスク一覧
echo -e "${CYAN}📁 最近のタスク:${NC}"
ls -lt "$TASK_DIR"/output-*.txt 2>/dev/null | head -5 | while read line; do
    FILE=$(echo "$line" | awk '{print $NF}')
    ID=$(basename "$FILE" | sed 's/output-//' | sed 's/.txt//')
    if [ "$ID" = "$TASK_ID" ]; then
        echo -e "  ${GREEN}▶ $ID${NC} (現在表示中)"
    else
        echo "    $ID"
    fi
done
echo ""
SCRIPT_EOF
chmod +x scripts/check-codex-task.sh
echo -e "  ${GREEN}✓${NC} scripts/check-codex-task.sh"

# .gitignore 更新
echo ""
echo "📝 .gitignoreを更新中..."
if [ -f .gitignore ]; then
    if ! grep -q ".codex-tasks" .gitignore 2>/dev/null; then
        echo "" >> .gitignore
        echo "# Codex tasks" >> .gitignore
        echo ".codex-tasks/" >> .gitignore
    fi
else
    cat > .gitignore << 'EOF'
# Codex tasks
.codex-tasks/
EOF
fi
echo -e "  ${GREEN}✓${NC} .gitignore"

# 完了メッセージ
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ インストール完了！${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "📖 使い方:"
echo ""
echo "  1. Claude Codeを起動:"
echo -e "     ${BLUE}claude${NC}"
echo ""
echo "  2. 自動連携キーワード:"
echo "     「レビューして」→ Codexが自動実行"
echo "     「テスト作成して」→ Codexが自動実行"
echo ""
echo "  3. 手動でCodexに委譲:"
echo -e "     ${BLUE}./scripts/auto-delegate.sh review${NC}"
echo -e "     ${BLUE}./scripts/auto-delegate.sh test src/${NC}"
echo ""
echo "  4. タスク状態確認:"
echo -e "     ${BLUE}./scripts/check-codex-task.sh${NC}"
echo ""
echo "📚 詳細: https://github.com/yu010101/claude-codex-collab"
echo ""
