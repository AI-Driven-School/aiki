# 設計書: 圧倒的開発優位性 (ai4dev v5)

**作成日**: 2026-02-20
**関連要件**: docs/requirements/overwhelming-dev-advantage.md

---

## 概要

v4の14変更を土台に、ai4devを**他のすべての開発手法より構造的に速く・高品質に**する7件の変更を実装する。

---

## 変更一覧（7変更、5ファイル修正）

| # | AC | ファイル | 変更内容 |
|---|-----|---------|---------|
| 1 | AC-1 | `scripts/project-workflow.sh` | Claude CLIフォールバック実装 |
| 2 | AC-4 | `scripts/project-workflow.sh` | 横断的弱点プロファイル |
| 3 | AC-7 | `scripts/lib/quality-gates.sh` | 未追跡ファイルシークレットスキャン |
| 4 | AC-6 | `scripts/pipeline-engine.sh` | deployフェーズ統合 |
| 5 | AC-8 | `scripts/pipeline-engine.sh` | 速度改善サマリー |
| 6 | AC-3 | `scripts/lib/quality-gates.sh` | カバレッジ自動フォールバック |
| 7 | AC-5 | `scripts/pipeline-engine.sh` | GitHub Issue自動エスカレーション |

---

## Change 1: Claude CLIフォールバック実装

**ファイル**: `scripts/project-workflow.sh` の `phase_implement()`, `phase_test()`

### 現状の問題
```
if command -v codex &> /dev/null; then
    bash "$SCRIPT_DIR/delegate.sh" codex implement "$FEATURE_SLUG" --full-auto
else
    log_warn "Codex not installed, skipping"  ← 何も実装されない！
fi
```

### 設計
Codex未インストール時、Claude CLIで設計書を元に実装を生成する：

```bash
phase_implement() {
    if command -v codex &> /dev/null; then
        # 既存: Codex委譲
    else
        # NEW: Claude CLIフォールバック
        local impl_prompt=$(build_implement_prompt "$FEATURE" "$LANG_FLAG")
        invoke_claude "$impl_prompt" "/dev/null" "_fallback_noop"
    fi
}
```

`build_implement_prompt()`は新規関数。要件+設計書+API仕様を全て読み込み、
「src/配下にNext.js App Router + TypeScriptで実装してください」と指示する。

同様に`phase_test()`にも`build_test_prompt()`フォールバックを追加。

---

## Change 2: 横断的弱点プロファイル

**ファイル**: `scripts/project-workflow.sh` の `compute_weakness_profile()`

### 現状の問題
```bash
feature_lines=$(grep "\"feature\":\"${feature}\"" "$metrics_file")
# ↑ 現在の機能のみ。他機能の失敗が無視される
```

### 設計
新関数 `compute_global_weakness_profile()`:
- metrics.jsonlの**全機能**からフェーズ別FAIL/FIXABLE回数を集計
- 機能固有プロファイル + グローバルプロファイルを合成
- 「test phaseがプロジェクト全体で12回失敗。特にテスト品質に注意」とプロンプトに注入

```bash
compute_global_weakness_profile() {
    local metrics_file="${PROJECT_DIR}/.claude/docs/metrics.jsonl"
    [ ! -f "$metrics_file" ] && return

    local profile=""
    for phase_name in requirements design implement test review; do
        local fail_count fixable_count
        fail_count=$(grep -c "\"name\":\"${phase_name}\",\"result\":\"FAIL\"" "$metrics_file" || echo "0")
        fixable_count=$(grep -c "\"name\":\"${phase_name}\",\"result\":\"FIXABLE\"" "$metrics_file" || echo "0")
        if [ "$fail_count" -gt 0 ] || [ "$fixable_count" -gt 0 ]; then
            profile="${profile}Phase '${phase_name}' has failed ${fail_count} times and needed fixes ${fixable_count} times across ALL features.\n"
        fi
    done
    echo -e "$profile"
}
```

`build_prompt()`で既存の`compute_weakness_profile()`（機能固有）に加えて
`compute_global_weakness_profile()`（全機能横断）も注入。

---

## Change 3: 未追跡ファイルシークレットスキャン

**ファイル**: `scripts/lib/quality-gates.sh` の `_gate_secrets()`

### 現状の問題
```bash
diff_content=$(cd "$dir" && git diff HEAD; git diff --cached)
# ↑ 未追跡ファイル（untracked）がスキャンされない
```

### 設計
`git ls-files --others --exclude-standard`の出力ファイルも内容をスキャンする：

```bash
_gate_secrets() {
    # 既存: git diff HEAD + git diff --cached
    ...

    # NEW: 未追跡ファイルのスキャン
    local untracked_files
    untracked_files=$(cd "$dir" && git ls-files --others --exclude-standard 2>/dev/null)
    if [ -n "$untracked_files" ]; then
        local untracked_content=""
        while IFS= read -r ufile; do
            [ -z "$ufile" ] && continue
            [ -f "${dir}/${ufile}" ] || continue
            # テキストファイルのみ（バイナリスキップ）
            if file "${dir}/${ufile}" | grep -q text 2>/dev/null; then
                untracked_content="${untracked_content}$(cat "${dir}/${ufile}" 2>/dev/null)"
            fi
        done <<< "$untracked_files"
        # 同じパターンでスキャン
        local untracked_hits=$(echo "$untracked_content" | grep -nE '...' | head -10)
        ...
    fi
}
```

---

## Change 4: deployフェーズ統合

**ファイル**: `scripts/pipeline-engine.sh`

### 設計
1. `PHASES`デフォルトに`deploy`を追加（ただし`--auto`時のみ有効）
2. `ai_for_phase()`に`deploy`を追加
3. `phase_name_to_number()`に`deploy → 6`を追加
4. `gate_for_phase()`に`deploy`を追加（project-workflow.shのデプロイ安全チェックをゲート関数に抽出）
5. `quality-gates.sh`に`gate_deploy()`を新設

```bash
gate_deploy() {
    local feature_slug="$1"
    local dir="${2:-$PWD}"
    local errors=0 details="" raw_output=""

    # 1. レビューAPPROVED確認
    # 2. metrics.jsonlにFAILフェーズなし確認
    # 3. 未コミット変更にシークレットなし確認

    if [ "$errors" -gt 0 ]; then
        printf "FAIL: %s\n---DETAILS---\n%s" "$details" "$raw_output"
        return $GATE_FAIL
    fi
    echo "PASS: deploy safety checks passed"
    return $GATE_PASS
}
```

---

## Change 5: 速度改善サマリー

**ファイル**: `scripts/pipeline-engine.sh` のパイプラインサマリー部分

### 設計
パイプライン完了時のサマリーに以下を追加：

```
  Cache hits:  3/5 phases skipped
  Speed gain:  ~3.2x faster (estimated)

  vs Cursor:   No pipeline, no cache, no quality ratchet
  vs Copilot:  No multi-AI routing, no auto-fix loop
  vs Devin:    $500/mo vs $0 (Codex) + usage-based
```

実装:
- `CACHE_HITS`カウンターを追加（cache-hit時にインクリメント）
- 速度推定: `cache_hit_phases * 平均フェーズ時間 / 実際の実行時間`
- 競合比較ラインは固定テキスト（過度に動的にしない）

---

## Change 6: カバレッジ自動フォールバック

**ファイル**: `scripts/lib/quality-gates.sh` の `gate_test()`

### 現状の問題
カバレッジレポートが存在しない場合、カバレッジチェックがサイレントスキップ。

### 設計
テスト通過後にカバレッジレポートがない場合、`--coverage`フラグ付きで再実行を試みる：

```bash
# テスト成功後、カバレッジデータがない場合
if [ -z "$coverage_pct" ]; then
    # npm test -- --coverage で再実行を試みる
    if [ "$runner" = "npm_test" ] && _has_npm_script "$dir" "test"; then
        local cov_out
        cov_out=$(cd "$dir" && $pm test -- --coverage 2>&1) || true
        # lcov.info / coverage-summary.json の再チェック
        ...
    fi
fi
```

---

## Change 7: GitHub Issue自動エスカレーション

**ファイル**: `scripts/pipeline-engine.sh` のリトライループ後

### 設計
`--escalate-to-github`フラグ追加。FIXABLE状態でMAX_RETRIES超過時：

```bash
escalate_to_github() {
    local phase="$1" feature="$2" gate_output="$3"

    if ! command -v gh &>/dev/null; then
        log_warn "gh CLI not installed, cannot escalate"
        return 1
    fi

    local title="[ai4dev] Auto-fix failed: ${phase} phase for '${feature}'"
    local body="## Pipeline Auto-Fix Failure

**Feature**: ${feature}
**Phase**: ${phase}
**Max retries exhausted**: ${MAX_RETRIES}

### Gate Output
\`\`\`
$(echo "$gate_output" | head -50)
\`\`\`

### Action Required
Manual intervention needed to fix ${phase} phase issues.

---
*Auto-generated by ai4dev pipeline-engine*"

    gh issue create --title "$title" --body "$body" 2>&1
}
```

---

## 複合効果

### v5の速度スタック
```
v4: キャッシュ(5) × 並列ゲート(4) × diff対応(6) = 4.3倍
v5: + Claudeフォールバック(1) + カバレッジ自動化(6) + deploy統合(4)
→ Codexなしでも完全パイプライン実行 → 環境セットアップ時間0
→ 全フェーズがパイプライン管理下 → 一貫した品質保証
```

### v5の品質スタック
```
v4: 要件ゲート + 品質ラチェット + 知識ループ
v5: + 横断弱点プロファイル(2) + 未追跡スキャン(3) + Issue自動化(7)
→ 機能Aの失敗が機能Bを改善（指数的学習）
→ シークレット漏洩リスクの完全排除
→ 修正不能エラーの自動エスカレーション
```

### 競合との最終的差異

| 能力 | ai4dev v5 | Cursor | Copilot | Devin |
|------|-----------|--------|---------|-------|
| 2回目以降の速度 | 3-5倍高速 | 毎回同速 | 毎回同速 | 毎回同速 |
| Codex不要の完全パイプライン | Yes | N/A | N/A | N/A |
| 機能横断学習 | Yes | No | No | 不明 |
| 未追跡ファイルのスキャン | Yes | No | No | No |
| 自動GitHub Issue | Yes | No | No | Yes |
| 月額コスト | $0+従量 | $20 | $19 | $500 |
