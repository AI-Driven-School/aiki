#!/bin/bash
# ============================================
# AI Usage Report - トークン消費量・コスト計測
# ============================================
# 使用方法:
#   ./scripts/usage-report.sh          # 今日の使用量
#   ./scripts/usage-report.sh --week   # 過去7日間
#   ./scripts/usage-report.sh --month  # 過去30日間
#   ./scripts/usage-report.sh --reset  # データリセット
# ============================================

set -e

# カラー定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
GRAY='\033[0;90m'
NC='\033[0m'
BOLD='\033[1m'

# 設定
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
USAGE_DIR="$PROJECT_DIR/.usage"
USAGE_FILE="$USAGE_DIR/usage.log"
# shellcheck disable=SC2034
SUMMARY_FILE="$USAGE_DIR/summary.json"

# 料金設定（1Kトークンあたり）
CLAUDE_INPUT_COST=0.003    # $3/1M input
CLAUDE_OUTPUT_COST=0.015   # $15/1M output
# shellcheck disable=SC2034
CODEX_COST=0               # ChatGPT Pro に含む
# shellcheck disable=SC2034
GEMINI_COST=0              # 無料枠

# ディレクトリ初期化
mkdir -p "$USAGE_DIR"
touch "$USAGE_FILE"

# ============================================
# 関数定義
# ============================================

show_header() {
    echo -e "${CYAN}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  AI Usage Report - claude-codex-collab"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${NC}"
}

# 使用量を記録
log_usage() {
    local ai="$1"
    local input_tokens="$2"
    local output_tokens="$3"
    local task="$4"
    local timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    echo "$timestamp|$ai|$input_tokens|$output_tokens|$task" >> "$USAGE_FILE"
}

# 今日の使用量を取得
get_today_usage() {
    local today
    today=$(date +"%Y-%m-%d")
    grep "^$today" "$USAGE_FILE" 2>/dev/null || echo ""
}

# 期間の使用量を取得
get_period_usage() {
    local days="$1"
    local start_date
    start_date=$(date -v-${days}d +"%Y-%m-%d" 2>/dev/null || date -d "-${days} days" +"%Y-%m-%d")

    while IFS= read -r line; do
        local log_date
        log_date=$(echo "$line" | cut -d'|' -f1 | cut -d' ' -f1)
        if [[ "$log_date" > "$start_date" ]] || [[ "$log_date" == "$start_date" ]]; then
            echo "$line"
        fi
    done < "$USAGE_FILE"
}

# 使用量を集計
calculate_usage() {
    local data="$1"

    local claude_input=0
    local claude_output=0
    local codex_input=0
    local codex_output=0
    local gemini_input=0
    local gemini_output=0

    while IFS='|' read -r timestamp ai input output task; do
        case "$ai" in
            "claude")
                claude_input=$((claude_input + input))
                claude_output=$((claude_output + output))
                ;;
            "codex")
                codex_input=$((codex_input + input))
                codex_output=$((codex_output + output))
                ;;
            "gemini")
                gemini_input=$((gemini_input + input))
                gemini_output=$((gemini_output + output))
                ;;
        esac
    done <<< "$data"

    echo "$claude_input|$claude_output|$codex_input|$codex_output|$gemini_input|$gemini_output"
}

# コスト計算
calculate_cost() {
    local claude_input="$1"
    local claude_output="$2"

    # Claude のコスト計算（$3/1M input, $15/1M output）
    local input_cost
    input_cost=$(echo "scale=4; $claude_input * $CLAUDE_INPUT_COST / 1000" | bc)
    local output_cost
    output_cost=$(echo "scale=4; $claude_output * $CLAUDE_OUTPUT_COST / 1000" | bc)
    local total
    total=$(echo "scale=2; $input_cost + $output_cost" | bc)

    echo "$total"
}

# プログレスバー描画
draw_bar() {
    local value="$1"
    local max="$2"
    local width=20
    local color="$3"

    if [ "$max" -eq 0 ]; then
        max=1
    fi

    local filled=$((value * width / max))
    if [ "$filled" -gt "$width" ]; then
        filled=$width
    fi

    local empty=$((width - filled))

    printf "${color}"
    printf '█%.0s' $(seq 1 $filled 2>/dev/null) || true
    printf "${GRAY}"
    printf '░%.0s' $(seq 1 $empty 2>/dev/null) || true
    printf "${NC}"
}

# メインレポート表示
show_report() {
    # shellcheck disable=SC2034
    local period="$1"
    local period_label="$2"
    local data="$3"

    if [ -z "$data" ]; then
        echo -e "${YELLOW}データがありません${NC}"
        echo ""
        echo "使用量を記録するには:"
        echo -e "  ${BLUE}./scripts/usage-report.sh --log claude 1000 500 \"設計タスク\"${NC}"
        echo ""
        return
    fi

    local usage
    usage=$(calculate_usage "$data")
    IFS='|' read -r claude_in claude_out codex_in codex_out gemini_in gemini_out <<< "$usage"

    local claude_total=$((claude_in + claude_out))
    local codex_total=$((codex_in + codex_out))
    local gemini_total=$((gemini_in + gemini_out))
    local all_total=$((claude_total + codex_total + gemini_total))

    local claude_cost
    claude_cost=$(calculate_cost "$claude_in" "$claude_out")

    echo -e "${BOLD}$period_label${NC}"
    echo ""

    # Claude
    printf "  ${BLUE}Claude${NC}   "
    draw_bar "$claude_total" "$all_total" "$BLUE"
    printf "  %'d tokens" "$claude_total"
    echo -e "  ${YELLOW}\$${claude_cost}${NC}"

    # Codex
    printf "  ${GREEN}Codex${NC}    "
    draw_bar "$codex_total" "$all_total" "$GREEN"
    printf "  %'d tokens" "$codex_total"
    echo -e "  ${GREEN}\$0.00${NC} ${GRAY}(Pro含む)${NC}"

    # Gemini
    printf "  ${CYAN}Gemini${NC}   "
    draw_bar "$gemini_total" "$all_total" "$CYAN"
    printf "  %'d tokens" "$gemini_total"
    echo -e "  ${GREEN}\$0.00${NC} ${GRAY}(無料)${NC}"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # 合計とコスト削減
    local claude_only_cost
    claude_only_cost=$(echo "scale=2; ($claude_in + $codex_in + $gemini_in) * $CLAUDE_INPUT_COST / 1000 + ($claude_out + $codex_out + $gemini_out) * $CLAUDE_OUTPUT_COST / 1000" | bc)
    local savings
    savings=$(echo "scale=0; (1 - $claude_cost / $claude_only_cost) * 100" | bc 2>/dev/null || echo "0")

    printf "  ${BOLD}合計:${NC} %'d tokens\n" "$all_total"
    echo ""
    echo -e "  ${BOLD}コスト:${NC} ${YELLOW}\$${claude_cost}${NC}"
    echo -e "  ${GRAY}(Claude単体なら \$${claude_only_cost})${NC}"

    if [ "$savings" != "0" ] && [ -n "$savings" ]; then
        echo ""
        echo -e "  ${GREEN}★ ${savings}% 削減達成！${NC}"
    fi

    echo ""
}

# 削減効果シミュレーション
show_simulation() {
    echo -e "${BOLD}コスト削減シミュレーション${NC}"
    echo ""
    echo "  月間コード行数を入力してください（例: 5000）"
    read -p "  > " lines

    if ! [[ "$lines" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}数値を入力してください${NC}"
        return
    fi

    # 概算: 1行 ≈ 20トークン、実装50%、設計30%、テスト20%
    local total_tokens=$((lines * 20))
    local design_tokens=$((total_tokens * 30 / 100))
    # shellcheck disable=SC2034
    local impl_tokens=$((total_tokens * 50 / 100))
    # shellcheck disable=SC2034
    local test_tokens=$((total_tokens * 20 / 100))

    local claude_only
    claude_only=$(echo "scale=2; $total_tokens * ($CLAUDE_INPUT_COST + $CLAUDE_OUTPUT_COST) / 2 / 1000" | bc)
    local with_collab
    with_collab=$(echo "scale=2; $design_tokens * ($CLAUDE_INPUT_COST + $CLAUDE_OUTPUT_COST) / 2 / 1000" | bc)
    local savings
    savings=$(echo "scale=2; $claude_only - $with_collab" | bc)
    local percent
    percent=$(echo "scale=0; (1 - $with_collab / $claude_only) * 100" | bc)

    echo ""
    echo "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "  ${GRAY}Claude単体:${NC}        \$${claude_only}/月"
    echo ""
    echo -e "  ${BOLD}claude-codex-collab:${NC}"
    echo -e "    Claude (設計):   \$${with_collab}"
    echo -e "    Codex (実装):    ${GREEN}\$0.00${NC}"
    echo -e "    Gemini (解析):   ${GREEN}\$0.00${NC}"
    echo -e "    ────────────────────"
    echo -e "    ${BOLD}合計:${NC}            ${YELLOW}\$${with_collab}/月${NC}"
    echo ""
    echo -e "  ${GREEN}★ 節約額: \$${savings}/月 (${percent}%削減)${NC}"
    echo ""
}

# データリセット
reset_data() {
    echo -e "${YELLOW}使用量データをリセットしますか？ [y/N]${NC}"
    read -p "> " confirm

    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        rm -f "$USAGE_FILE"
        touch "$USAGE_FILE"
        echo -e "${GREEN}リセット完了${NC}"
    else
        echo "キャンセルしました"
    fi
}

# 使用量をログに記録
manual_log() {
    local ai="$2"
    local input="$3"
    local output="$4"
    local task="${5:-manual entry}"

    if [ -z "$ai" ] || [ -z "$input" ] || [ -z "$output" ]; then
        echo "使用方法: ./scripts/usage-report.sh --log <ai> <input_tokens> <output_tokens> [task]"
        echo "例: ./scripts/usage-report.sh --log claude 1000 500 \"設計タスク\""
        exit 1
    fi

    log_usage "$ai" "$input" "$output" "$task"
    echo -e "${GREEN}記録しました: $ai - input:$input, output:$output${NC}"
}

# ヘルプ表示
show_help() {
    echo "AI Usage Report - claude-codex-collab"
    echo ""
    echo "使用方法:"
    echo "  ./scripts/usage-report.sh              今日の使用量を表示"
    echo "  ./scripts/usage-report.sh --week       過去7日間の使用量"
    echo "  ./scripts/usage-report.sh --month      過去30日間の使用量"
    echo "  ./scripts/usage-report.sh --simulate   コスト削減シミュレーション"
    echo "  ./scripts/usage-report.sh --log <ai> <in> <out> [task]  使用量を記録"
    echo "  ./scripts/usage-report.sh --reset      データをリセット"
    echo "  ./scripts/usage-report.sh --help       このヘルプを表示"
    echo ""
    echo "例:"
    echo "  ./scripts/usage-report.sh --log claude 1500 800 \"API設計\""
    echo "  ./scripts/usage-report.sh --log codex 5000 3000 \"実装\""
    echo "  ./scripts/usage-report.sh --log gemini 10000 2000 \"コード解析\""
}

# ============================================
# メイン処理
# ============================================

case "${1:-}" in
    "--week")
        show_header
        data=$(get_period_usage 7)
        show_report 7 "過去7日間の使用量" "$data"
        ;;
    "--month")
        show_header
        data=$(get_period_usage 30)
        show_report 30 "過去30日間の使用量" "$data"
        ;;
    "--simulate")
        show_header
        show_simulation
        ;;
    "--log")
        manual_log "$@"
        ;;
    "--reset")
        reset_data
        ;;
    "--help"|"-h")
        show_help
        ;;
    *)
        show_header
        data=$(get_today_usage)
        show_report 1 "今日の使用量 ($(date +%Y-%m-%d))" "$data"
        ;;
esac
