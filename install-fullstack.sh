#!/bin/bash
# ============================================
# 3AI協調開発テンプレート v6.0
# Claude設計 × Codex実装 × Gemini解析
# ============================================

set -e

VERSION="6.0.0"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
echo "┌─────────────────────────────────────────────────────────┐"
echo "│                                                         │"
echo "│   3AI協調開発テンプレート v6.0                          │"
echo "│                                                         │"
echo "│   Claude → 設計・判断                                   │"
echo "│   Codex  → 実装・テスト（メイン）                       │"
echo "│   Gemini → 解析・リサーチ                               │"
echo "│                                                         │"
echo "└─────────────────────────────────────────────────────────┘"
echo -e "${NC}"

PROJECT_NAME="${1:-}"
if [ -n "$PROJECT_NAME" ]; then
    mkdir -p "$PROJECT_NAME"
    cd "$PROJECT_NAME"
fi
PROJECT_DIR=$(pwd)

echo "ツールを確認中..."
echo ""

for cmd in node npm git; do
    if command -v "$cmd" &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} $cmd"
    else
        echo -e "  ${YELLOW}✗${NC} $cmd (必須)"
        exit 1
    fi
done

echo ""

MISSING_AI=0
for cmd in claude codex gemini; do
    if command -v "$cmd" &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} $cmd"
    else
        echo -e "  ${YELLOW}○${NC} $cmd"
        MISSING_AI=1
    fi
done

echo ""

if [ $MISSING_AI -eq 1 ]; then
    read -p "AIツールをインストール？ [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        command -v claude &> /dev/null || npm install -g @anthropic-ai/claude-code
        command -v codex &> /dev/null || npm install -g @openai/codex
        command -v gemini &> /dev/null || npm install -g @google/gemini-cli
        echo -e "${GREEN}✓ インストール完了${NC}"
    fi
fi

echo ""
echo "セットアップ中..."

# ディレクトリ構造
mkdir -p scripts
mkdir -p .claude/skills
mkdir -p .tasks/{codex,gemini}
mkdir -p docs/{requirements,specs,api,reviews}

# ===== CLAUDE.md =====
cat > CLAUDE.md << 'EOF'
# CLAUDE.md - 3AI協調開発 v6.0

## コンセプト

```
Claude  → 設計・判断（頭脳）
Codex   → 実装・テスト（手足）
Gemini  → 解析・リサーチ（目）
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
| 設計、レビュー | Claude | 判断力 |

## コスト最適化

```
Claude  → 設計・判断のみ（トークン節約）
Codex   → 実装・テスト（ChatGPT Proに含む）
Gemini  → 解析・リサーチ（無料）
```
EOF

# ===== AGENTS.md =====
cat > AGENTS.md << 'EOF'
# AGENTS.md - 3AI協調ガイド v6.0

## 役割分担

| AI | 役割 | 強み | 課金 |
|----|------|------|------|
| **Claude** | 設計・判断・レビュー | 推論力、品質 | 従量課金 |
| **Codex** | 実装・テスト | 速度、full-auto | Pro含む |
| **Gemini** | 解析・リサーチ | 1Mコンテキスト | 無料 |

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

# ===== スキル: project =====
cat > .claude/skills/project.md << 'EOF'
---
name: project
description: 3AI協調の完全ワークフロー
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

# ===== スキル: implement =====
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

# ===== スキル: test =====
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

# ===== スキル: analyze =====
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

# ===== スキル: research =====
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

    *)
        echo "3AI協調開発 - 委譲スクリプト"
        echo ""
        echo "使用方法:"
        echo "  $0 codex implement [prompt]    # Codexで実装"
        echo "  $0 codex test [path]           # Codexでテスト生成"
        echo "  $0 codex review                # Codexでレビュー"
        echo "  $0 gemini analyze [path]       # Geminiで解析"
        echo "  $0 gemini research \"質問\"      # Geminiでリサーチ"
        exit 1
        ;;
esac
SCRIPT_EOF
chmod +x scripts/delegate.sh

# ===== .gitignore =====
cat > .gitignore << 'EOF'
node_modules/
.next/
.env
.env.local
.tasks/
.DS_Store
EOF

# ===== 完了メッセージ =====
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}セットアップ完了 v6.0${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${CYAN}3AI役割分担:${NC}"
echo -e "  ${BLUE}Claude${NC}  → 設計・判断・レビュー"
echo -e "  ${BLUE}Codex${NC}   → 実装・テスト（メイン）"
echo -e "  ${BLUE}Gemini${NC}  → 解析・リサーチ"
echo ""
echo -e "${CYAN}開始:${NC}"
echo -e "  ${BLUE}claude${NC}"
echo -e "  ${BLUE}/project ユーザー認証${NC}"
echo ""
echo -e "${CYAN}個別コマンド:${NC}"
echo -e "  ${BLUE}/requirements${NC}  要件定義（Claude）"
echo -e "  ${BLUE}/spec${NC}          画面設計（Claude）"
echo -e "  ${BLUE}/api${NC}           API設計（Claude）"
echo -e "  ${BLUE}/implement${NC}     実装（Codex）"
echo -e "  ${BLUE}/test${NC}          テスト（Codex）"
echo -e "  ${BLUE}/review${NC}        レビュー（Claude）"
echo -e "  ${BLUE}/analyze${NC}       解析（Gemini）"
echo -e "  ${BLUE}/research${NC}      リサーチ（Gemini）"
echo ""
