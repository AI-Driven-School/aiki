#!/bin/bash
# ============================================
# 4-AI Collaborative Development Template v6.3
# Claude Design x Codex Implementation x Gemini Analysis x Grok Trends
# ============================================

set -e

# shellcheck disable=SC2034
VERSION="6.3.0"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

# ===== Adoption mode parsing =====
ADOPTION_MODE="full"
PROJECT_NAME=""

for arg in "$@"; do
    case "$arg" in
        --claude-only)
            ADOPTION_MODE="claude-only"
            ;;
        --claude-codex)
            ADOPTION_MODE="claude-codex"
            ;;
        --claude-gemini)
            ADOPTION_MODE="claude-gemini"
            ;;
        --full)
            ADOPTION_MODE="full"
            ;;
        --help|-h)
            echo "Usage: $0 [project-name] [--claude-only|--claude-codex|--claude-gemini|--full]"
            echo ""
            echo "Adoption modes:"
            echo "  --claude-only    Claude Code only (no external AI delegation)"
            echo "  --claude-codex   Claude + Codex (implementation delegation)"
            echo "  --claude-gemini  Claude + Gemini (research delegation)"
            echo "  --full           All 4 AIs (default)"
            echo ""
            echo "Examples:"
            echo "  $0 my-app --claude-only    # Start with Claude only"
            echo "  $0 my-app --full           # Full 4-AI setup"
            exit 0
            ;;
        -*)
            echo "Unknown option: $arg"
            exit 1
            ;;
        *)
            PROJECT_NAME="$arg"
            ;;
    esac
done

echo -e "${CYAN}"
echo "┌─────────────────────────────────────────────────────────┐"
echo "│                                                         │"
echo "│   4-AI Collaborative Template v6.3                      │"
echo "│                                                         │"
case "$ADOPTION_MODE" in
    claude-only)
echo "│   Mode: Claude only                                     │"
echo "│   Claude -> Design, decisions, implementation           │"
        ;;
    claude-codex)
echo "│   Mode: Claude + Codex                                  │"
echo "│   Claude -> Design, decisions                           │"
echo "│   Codex  -> Implementation, testing                     │"
        ;;
    claude-gemini)
echo "│   Mode: Claude + Gemini                                 │"
echo "│   Claude -> Design, decisions, implementation           │"
echo "│   Gemini -> Analysis, research                          │"
        ;;
    full)
echo "│   Mode: Full 4-AI collaboration                         │"
echo "│   Claude -> Design, decisions                           │"
echo "│   Codex  -> Implementation, testing (primary)           │"
echo "│   Gemini -> Analysis, research                          │"
echo "│   Grok   -> Real-time trends, X search                  │"
        ;;
esac
echo "│                                                         │"
echo "└─────────────────────────────────────────────────────────┘"
echo -e "${NC}"

if [ -n "$PROJECT_NAME" ]; then
    mkdir -p "$PROJECT_NAME"
    cd "$PROJECT_NAME"
fi
# shellcheck disable=SC2034
PROJECT_DIR=$(pwd)

# Initialize git repo if not already one (required for quality gates)
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    git init -q
    echo -e "  ${GREEN}✓${NC} git init"
fi

# Idempotency: detect existing installation
EXISTING_INSTALL=false
if [ -f "CLAUDE.md" ] && [ -d ".claude/skills" ]; then
    EXISTING_INSTALL=true
    echo -e "${YELLOW}Existing installation detected.${NC}"
    echo -e "Files will be updated only if they don't exist (safe upgrade)."
    echo ""
fi

# Helper: write file only if it doesn't exist (idempotent)
safe_write() {
    local target="$1"
    if [ "$EXISTING_INSTALL" = true ] && [ -f "$target" ]; then
        echo -e "  ${YELLOW}skip${NC} $target (already exists)"
        return 1
    fi
    return 0
}

echo "Checking tools..."
echo ""

for cmd in node npm git; do
    if command -v "$cmd" &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} $cmd"
    else
        echo -e "  ${YELLOW}✗${NC} $cmd (required)"
        exit 1
    fi
done

echo ""

# Determine required and optional AIs based on adoption mode
REQUIRED_AIS=("claude")
OPTIONAL_AIS=()
case "$ADOPTION_MODE" in
    claude-only)
        OPTIONAL_AIS=()
        ;;
    claude-codex)
        REQUIRED_AIS+=("codex")
        ;;
    claude-gemini)
        REQUIRED_AIS+=("gemini")
        ;;
    full)
        REQUIRED_AIS+=("codex" "gemini")
        OPTIONAL_AIS+=("grok")
        ;;
esac

MISSING_AI=0
for cmd in "${REQUIRED_AIS[@]}"; do
    if command -v "$cmd" &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} $cmd (required)"
    else
        echo -e "  ${RED}✗${NC} $cmd (required)"
        MISSING_AI=1
    fi
done

for cmd in "${OPTIONAL_AIS[@]}"; do
    if command -v "$cmd" &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} $cmd (optional)"
    else
        echo -e "  ${YELLOW}○${NC} $cmd (optional)"
    fi
done

echo ""

if [ $MISSING_AI -eq 1 ]; then
    read -p "Install required AI tools? [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        for cmd in "${REQUIRED_AIS[@]}"; do
            if ! command -v "$cmd" &> /dev/null; then
                case "$cmd" in
                    claude) npm install -g @anthropic-ai/claude-code ;;
                    codex)  npm install -g @openai/codex ;;
                    gemini) npm install -g @google/gemini-cli ;;
                esac
            fi
        done
        echo -e "${GREEN}✓ Installation complete${NC}"
    else
        echo -e "${RED}Required AI tools are missing. Setup cannot continue.${NC}"
        echo -e "Re-run with ${CYAN}--claude-only${NC} to use Claude only mode."
        exit 1
    fi
fi

echo ""
echo "Setting up..."

# Directory structure
mkdir -p scripts
mkdir -p .claude/skills
mkdir -p .tasks/{codex,gemini,grok}
mkdir -p .grok
mkdir -p docs/{requirements,specs,api,reviews}

# ===== CLAUDE.md =====
if safe_write "CLAUDE.md"; then
cat > CLAUDE.md << 'EOF'
# CLAUDE.md - 4AI協調開発 v6.3

## コンセプト

```
Claude  → 設計・判断（頭脳）
Codex   → 実装・テスト（手足）
Gemini  → 解析・リサーチ（目）
Grok    → リアルタイム情報・トレンド（耳）
```

## ワークフロー

```
/project <機能名>
    ↓
[1] 要件定義   → Claude（推論・判断）
[2] 設計       → Claude（アーキテクチャ）
[3] 実装       → Codex（full-auto）★メイン
[4] テスト     → Codex（実装と一貫性）
[5] レビュー   → Claude（品質チェック）
[6] デプロイ   → Claude（最終判断）
```

## コマンド一覧

### 設計（Claude担当）
| コマンド | 説明 | 出力 |
|---------|------|------|
| `/requirements <機能>` | 要件定義 | docs/requirements/*.md |
| `/spec <画面>` | 画面設計 | docs/specs/*.md |
| `/api <エンドポイント>` | API設計 | docs/api/*.yaml |
| `/review` | コードレビュー | docs/reviews/*.md |

### 実装（Codex担当）
| コマンド | 説明 | 出力 |
|---------|------|------|
| `/implement` | 設計書から実装 | src/ |
| `/test` | テスト生成 | tests/ |

### 解析（Gemini担当）
| コマンド | 説明 |
|---------|------|
| `/analyze` | 大規模コード解析 |
| `/research <質問>` | 技術リサーチ |

## 自動委譲ルール

| キーワード | 委譲先 | 理由 |
|-----------|--------|------|
| 実装、コーディング | Codex | 速度重視 |
| テスト作成 | Codex | 実装と一貫性 |
| 解析、調査 | Gemini | 1Mコンテキスト |
| リサーチ | Gemini | 無料 |
| トレンド、バズ | Grok | リアルタイム |
| X検索、最新情報 | Grok | xAI API |
| 設計、レビュー | Claude | 判断力 |

## コスト最適化

```
Claude  → 設計・判断のみ（トークン節約）
Codex   → 実装・テスト（ChatGPT Proに含む）
Gemini  → 解析・リサーチ（無料）
Grok    → リアルタイム情報（xAI API）
```

## サブエージェント活用ルール（重要）

### 必須: 以下の場合はTaskツールでサブエージェントを起動

1. **コード探索 (Explore)**
   - トリガー: 「〜はどこ？」「〜を探して」「構造を教えて」「〜を調査」
   - 起動: \`Task(subagent_type="Explore", prompt="...")\`

2. **計画立案 (Plan)**
   - トリガー: 「〜を実装したい」「設計して」「計画を立てて」
   - 起動: \`Task(subagent_type="Plan", prompt="...")\`

3. **並列調査**
   - 複数ファイル/機能の調査が必要な場合
   - **複数のTaskを同時に起動**して並列処理

### サブエージェント起動例

\`\`\`
# 単発調査
Task(subagent_type="Explore", prompt="認証機能の実装箇所を調査")

# 計画立案
Task(subagent_type="Plan", prompt="ユーザー認証の実装計画を立案")

# 並列調査（同時に複数起動）
Task(subagent_type="Explore", prompt="フロントエンドの認証フローを調査")
Task(subagent_type="Explore", prompt="バックエンドのAPIエンドポイントを調査")
Task(subagent_type="Explore", prompt="DBスキーマを調査")
\`\`\`

### 判断基準

| 状況 | アクション |
|------|-----------|
| 「〜はどこ？」 | \`Task(Explore)\` |
| 「〜の仕組みを教えて」 | \`Task(Explore)\` |
| 「〜を実装したい」 | \`Task(Plan)\` → 計画後に実装 |
| 複数箇所を同時調査 | 複数の \`Task(Explore)\` を並列 |
| 単純なファイル読み込み | Read ツールで直接 |

### 並列処理の原則

- **独立したタスクは常に並列化**
- 1つのメッセージで複数のTaskを同時起動
- 結果を待ってから次のアクションへ
EOF
fi

# ===== AGENTS.md =====
if safe_write "AGENTS.md"; then
cat > AGENTS.md << 'EOF'
# AGENTS.md - 4AI協調ガイド v6.3

## 役割分担

| AI | 役割 | 強み | 課金 |
|----|------|------|------|
| **Claude** | 設計・判断・レビュー | 推論力、品質 | 従量課金 |
| **Codex** | 実装・テスト | 速度、full-auto | Pro含む |
| **Gemini** | 解析・リサーチ | 1Mコンテキスト | 無料 |
| **Grok** | トレンド・最新情報 | リアルタイムX検索 | xAI API |

## なぜこの分担？

### Claude（頭脳）
- 要件の妥当性を判断
- アーキテクチャを決定
- コード品質をレビュー
- デプロイの最終判断

### Codex（手足）
- 設計書に基づいて爆速実装
- full-autoモードで自律的に作業
- テストも実装と一貫して生成

### Gemini（目）
- 大規模コードベースを俯瞰
- 技術調査・リサーチ
- 無料なので気軽に使える

### Grok（耳）
- X/SNSのリアルタイムトレンド
- 最新技術ニュース・breaking changes
- コミュニティの反応・感情分析

## 委譲方法

```bash
# Codexに実装を委譲
./scripts/delegate.sh codex implement "ログイン機能を実装"

# Codexにテストを委譲
./scripts/delegate.sh codex test "auth"

# Geminiに解析を委譲
./scripts/delegate.sh gemini analyze "src/"

# Geminiにリサーチを委譲
./scripts/delegate.sh gemini research "Next.js 15 App Router"
```
EOF
fi

# ===== スキル: project =====
cat > .claude/skills/project.md << 'EOF'
---
name: project
description: 4AI協調の完全ワークフロー
---

# /project スキル

Claude設計 → Codex実装 → Claudeレビューの完全フロー。

## 使用方法

```
/project ユーザー認証
/project 商品検索機能
```

## ワークフロー

### Phase 1: 要件定義（Claude）
```
入力: 機能名
出力: docs/requirements/{機能名}.md
担当: Claude（推論・判断）
→ 承認待ち
```

### Phase 2: 設計（Claude）
```
入力: 要件定義
出力: docs/specs/*.md, docs/api/*.yaml
担当: Claude（アーキテクチャ）
→ 承認待ち
```

### Phase 3: 実装（Codex）
```
入力: 設計書
出力: src/
担当: Codex（full-auto）
→ 自動実行
```

### Phase 4: テスト（Codex）
```
入力: 実装コード
出力: tests/
担当: Codex
→ 自動実行
```

### Phase 5: レビュー（Claude）
```
入力: 実装 + テスト
出力: docs/reviews/*.md
担当: Claude（品質チェック）
→ 自動実行
```

### Phase 6: デプロイ（Claude）
```
入力: レビュー結果
出力: 本番URL
担当: Claude（最終判断）
→ 承認待ち
```

## 承認コマンド

```
/approve    # 承認して次へ
/reject     # 却下して再生成
/status     # 進捗確認
```
EOF

# ===== スキル: implement (Codex modes only) =====
if [ "$ADOPTION_MODE" = "claude-codex" ] || [ "$ADOPTION_MODE" = "full" ]; then
cat > .claude/skills/implement.md << 'EOF'
---
name: implement
description: Codexで実装（高速）
---

# /implement スキル

設計書に基づいてCodexで実装。full-autoモードで高速。

## 使用方法

```
/implement
/implement auth
```

## 実行内容

```bash
./scripts/delegate.sh codex implement
```

## 前提条件

以下が承認済みであること:
- docs/requirements/*.md
- docs/api/*.yaml

## 出力

```
src/
├── app/
├── components/
├── lib/
└── types/
```
EOF

# ===== スキル: test (Codex modes only) =====
cat > .claude/skills/test.md << 'EOF'
---
name: test
description: Codexでテスト生成
---

# /test スキル

Codexでテストを生成。実装と同じAIなので一貫性あり。

## 使用方法

```
/test
/test auth
```

## 実行内容

```bash
./scripts/delegate.sh codex test
```
EOF
fi  # end Codex modes

# ===== スキル: review =====
cat > .claude/skills/review.md << 'EOF'
---
name: review
description: Claudeでコードレビュー（品質重視）
---

# /review スキル

Claudeでコードレビュー。設計意図との整合性をチェック。

## 使用方法

```
/review
```

## 出力

`docs/reviews/{日付}.md`

## レビュー観点

- 設計書との整合性
- セキュリティ
- パフォーマンス
- 可読性
EOF

# ===== スキル: analyze (Gemini modes only) =====
if [ "$ADOPTION_MODE" = "claude-gemini" ] || [ "$ADOPTION_MODE" = "full" ]; then
cat > .claude/skills/analyze.md << 'EOF'
---
name: analyze
description: Geminiで大規模解析
---

# /analyze スキル

Geminiの1Mトークンコンテキストで大規模コード解析。

## 使用方法

```
/analyze
/analyze src/
```

## 実行内容

```bash
./scripts/delegate.sh gemini analyze
```
EOF

# ===== スキル: research (Gemini modes only) =====
cat > .claude/skills/research.md << 'EOF'
---
name: research
description: Geminiで技術リサーチ（無料）
---

# /research スキル

Geminiで技術リサーチ。無料なので気軽に。

## 使用方法

```
/research "Next.js 15 App Router"
/research "認証ライブラリ比較"
```

## 実行内容

```bash
./scripts/delegate.sh gemini research "質問"
```
EOF
fi  # end Gemini modes

# ===== スキル: requirements =====
cat > .claude/skills/requirements.md << 'EOF'
---
name: requirements
description: Claudeで要件定義
---

# /requirements スキル

Claudeで要件定義書を生成。推論力を活かした判断。

## 使用方法

```
/requirements ユーザー認証
```

## 出力

`docs/requirements/{機能名}.md`
EOF

# ===== スキル: spec =====
cat > .claude/skills/spec.md << 'EOF'
---
name: spec
description: Claudeで画面設計
---

# /spec スキル

Claudeで画面設計書を生成。

## 使用方法

```
/spec ログイン画面
```

## 出力

`docs/specs/{画面名}.md`
EOF

# ===== スキル: api =====
cat > .claude/skills/api.md << 'EOF'
---
name: api
description: ClaudeでAPI設計
---

# /api スキル

ClaudeでOpenAPI 3.0形式のAPI設計書を生成。

## 使用方法

```
/api 認証API
```

## 出力

`docs/api/{API名}.yaml`
EOF

# ===== delegate.sh =====
cat > scripts/delegate.sh << 'SCRIPT_EOF'
#!/bin/bash
set -e

AI="$1"
TASK="$2"
ARGS="$3"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TASK_ID=$(date +%Y%m%d-%H%M%S)

cd "$PROJECT_DIR"

case "$AI" in
    "codex")
        TASK_DIR="$PROJECT_DIR/.tasks/codex"
        mkdir -p "$TASK_DIR"
        OUTPUT_FILE="$TASK_DIR/output-$TASK_ID.txt"

        case "$TASK" in
            "implement")
                echo "🚀 Codex: 実装中...（full-auto）"
                PROMPT="${ARGS:-docs/配下の設計書に基づいて実装してください}"
                codex exec --full-auto -C "$PROJECT_DIR" "$PROMPT" 2>&1 | tee "$OUTPUT_FILE"
                ;;
            "test")
                echo "🧪 Codex: テスト生成中..."
                TARGET="${ARGS:-.}"
                codex exec --full-auto -C "$PROJECT_DIR" \
                    "${TARGET}のテストを作成。受入条件に基づく。" \
                    2>&1 | tee "$OUTPUT_FILE"
                ;;
            "review")
                echo "📝 Codex: レビュー中..."
                codex review --uncommitted 2>&1 | tee "$OUTPUT_FILE"
                ;;
            *)
                echo "Codexタスク: implement, test, review"
                exit 1
                ;;
        esac
        echo "→ $OUTPUT_FILE"
        ;;

    "gemini")
        TASK_DIR="$PROJECT_DIR/.tasks/gemini"
        mkdir -p "$TASK_DIR"
        OUTPUT_FILE="$TASK_DIR/output-$TASK_ID.txt"

        # Gemini用の環境変数
        export GOOGLE_GENAI_USE_GCA=true

        case "$TASK" in
            "analyze")
                echo "🔍 Gemini: コード解析中..."
                TARGET="${ARGS:-.}"
                gemini -p "このコードベースを解析してください: $TARGET" 2>&1 | tee "$OUTPUT_FILE"
                ;;
            "research")
                echo "📚 Gemini: リサーチ中..."
                gemini -p "$ARGS" 2>&1 | tee "$OUTPUT_FILE"
                ;;
            *)
                echo "Geminiタスク: analyze, research"
                exit 1
                ;;
        esac
        echo "→ $OUTPUT_FILE"
        ;;

    "grok")
        TASK_DIR="$PROJECT_DIR/.tasks/grok"
        mkdir -p "$TASK_DIR"
        OUTPUT_FILE="$TASK_DIR/output-$TASK_ID.txt"

        case "$TASK" in
            "trend")
                echo "📡 Grok: トレンド検索中..."
                # xAI API経由でトレンド検索
                echo "Grok trend search: $ARGS" | tee "$OUTPUT_FILE"
                echo "→ Use x-trend-research skill or xAI API directly"
                ;;
            "search")
                echo "🔍 Grok: X検索中..."
                echo "Grok X search: $ARGS" | tee "$OUTPUT_FILE"
                echo "→ Use x-context-research skill or xAI API directly"
                ;;
            *)
                echo "Grokタスク: trend, search"
                exit 1
                ;;
        esac
        echo "→ $OUTPUT_FILE"
        ;;

    *)
        echo "4AI協調開発 - 委譲スクリプト"
        echo ""
        echo "使用方法:"
        echo "  $0 codex implement [prompt]    # Codexで実装"
        echo "  $0 codex test [path]           # Codexでテスト生成"
        echo "  $0 codex review                # Codexでレビュー"
        echo "  $0 gemini analyze [path]       # Geminiで解析"
        echo "  $0 gemini research \"質問\"      # Geminiでリサーチ"
        echo "  $0 grok trend \"トピック\"       # Grokでトレンド検索"
        echo "  $0 grok search \"キーワード\"    # GrokでX検索"
        exit 1
        ;;
esac
SCRIPT_EOF
chmod +x scripts/delegate.sh

# ===== .gitignore =====
if safe_write ".gitignore"; then
cat > .gitignore << 'EOF'
node_modules/
.next/
.env
.env.local
.tasks/
.DS_Store
EOF
fi

# ===== Complete =====
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Setup complete v6.3 (mode: ${ADOPTION_MODE})${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${CYAN}Roles (${ADOPTION_MODE}):${NC}"
echo -e "  ${BLUE}Claude${NC}  -> Design, decisions, review"
if [ "$ADOPTION_MODE" = "claude-codex" ] || [ "$ADOPTION_MODE" = "full" ]; then
echo -e "  ${BLUE}Codex${NC}   -> Implementation, testing"
fi
if [ "$ADOPTION_MODE" = "claude-gemini" ] || [ "$ADOPTION_MODE" = "full" ]; then
echo -e "  ${BLUE}Gemini${NC}  -> Analysis, research"
fi
if [ "$ADOPTION_MODE" = "full" ]; then
echo -e "  ${BLUE}Grok${NC}    -> Real-time trends, X search (optional)"
fi
echo ""
echo -e "${CYAN}Get started:${NC}"
echo -e "  ${BLUE}claude${NC}"
echo -e "  ${BLUE}/project user-auth${NC}"
echo ""
echo -e "${CYAN}Commands:${NC}"
echo -e "  ${BLUE}/requirements${NC}  Requirements (Claude)"
echo -e "  ${BLUE}/spec${NC}          UI specs (Claude)"
echo -e "  ${BLUE}/api${NC}           API design (Claude)"
if [ "$ADOPTION_MODE" = "claude-codex" ] || [ "$ADOPTION_MODE" = "full" ]; then
echo -e "  ${BLUE}/implement${NC}     Implement (Codex)"
echo -e "  ${BLUE}/test${NC}          Test (Codex)"
fi
echo -e "  ${BLUE}/review${NC}        Review (Claude)"
if [ "$ADOPTION_MODE" = "claude-gemini" ] || [ "$ADOPTION_MODE" = "full" ]; then
echo -e "  ${BLUE}/analyze${NC}       Analyze (Gemini)"
echo -e "  ${BLUE}/research${NC}      Research (Gemini)"
fi
echo ""

# ===== AI Version Compatibility Check =====
SCRIPT_SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_SOURCE_DIR/scripts/lib/version-check.sh" ]; then
    source "$SCRIPT_SOURCE_DIR/scripts/lib/version-check.sh"
    if [ -f "$SCRIPT_SOURCE_DIR/.ai-versions.json" ]; then
        check_all_versions "$SCRIPT_SOURCE_DIR/.ai-versions.json"
        echo ""
    fi
fi
