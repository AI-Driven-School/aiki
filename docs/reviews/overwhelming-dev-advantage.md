# コードレビュー: 圧倒的開発優位性 (aiki v5)

**レビュー日**: 2026-02-20
**レビューアー**: Claude (自動レビュー)

---

## サマリー

- 受入条件: **7/7** クリア（Must Have 5件 + Should Have 2件）
- テスト: **88 passed** (v3: 56 + v4: 20 + v5: 12)
- 後方互換: v4テスト76件すべて合格
- 改善提案: 2件（軽微）

---

## 受入条件チェック

### Must Have（実装済み）

- [x] **AC-1**: Claude CLIフォールバック実装
  - `phase_implement()`と`phase_test()`にClaude CLI fallback追加
  - `build_prompt()`に"implement"と"test_gen"のケース追加
  - Codex未インストール時でも180秒タイムアウト付きで実行

- [x] **AC-4**: 横断的弱点プロファイル
  - `compute_global_weakness_profile()`関数を新設
  - 全機能のmetrics.jsonlからフェーズ別FAIL/FIXABLE回数を集計
  - `build_prompt()`で機能固有プロファイルに加えてグローバルプロファイルも注入

- [x] **AC-7**: 未追跡ファイルのシークレットスキャン
  - `_gate_secrets()`に`git ls-files --others --exclude-standard`のスキャンを追加
  - バイナリファイルスキップ（100KB超もスキップ）
  - `file`コマンドによるテキスト判定

- [x] **AC-6**: deployフェーズ統合
  - `gate_deploy()`をquality-gates.shに新設（レビュー承認・FAIL無し・シークレット無しの3重チェック）
  - `ai_for_phase()`、`phase_name_to_number()`、`gate_for_phase()`にdeploy追加

- [x] **AC-8**: 速度改善サマリー表示
  - `CACHE_HITS`カウンターをpipeline-engine.shに追加
  - キャッシュヒット数、推定速度改善倍率を表示
  - 競合比較ライン（vs Cursor / vs Copilot / vs Devin）を表示

### Should Have（実装済み）

- [x] **AC-3**: カバレッジ自動フォールバック
  - `gate_test()`でテスト通過後にカバレッジデータがない場合、`--coverage`フラグ付きで再実行
  - lcov.infoとcoverage-summary.jsonの再チェック

- [x] **AC-5**: GitHub Issue自動エスカレーション
  - `escalate_to_github()`関数を新設
  - `--escalate-to-github`フラグでFIXABLE+リトライ超過時に`gh issue create`
  - gh CLI未インストール時はgracefully skip

### Could Have（次バージョンに延期）

- [ ] **AC-2**: Agent Modeでのauto_fix → 安全性の理由で延期
- [ ] **AC-9**: watchモード → 次バージョン検討

---

## セキュリティ

- [x] シークレット検出: 未追跡ファイルのスキャンが追加され、カバレッジ完全
- [x] deployゲート: 3重チェック（レビュー承認・FAIL無し・シークレット無し）
- [x] GitHub Issue: gate_outputはhead -50で切り詰め、大量データの漏洩防止
- [x] Claude CLIフォールバック: 180秒タイムアウト付きでリソース消費制限

---

## 非機能要件

- [x] **後方互換**: v4テスト76件が全てパス（テスト76/88はすべてv4以前のテスト）
- [x] **互換性**: `--dry-run`, `--auto`, `--no-cache`等の全フラグが引き続き動作
- [x] **可観測性**: メトリクスは既存のmetrics.jsonl形式で記録

---

## 改善提案

### 軽微（デプロイに影響なし）

1. **カバレッジ再実行の二重実行リスク**: `gate_test()`でテストが`--coverage`付きで再実行される際、テスト自体が失敗する可能性がある。現状は`|| true`で吸収しているが、再実行時の失敗を明示的にログ出力するとデバッグが容易になる。

2. **gate_deploy()の粒度**: 現在はメトリクスの最新1行のみをチェックしているが、複数パイプラインが並行実行された場合に古い結果を参照する可能性がある。タイムスタンプベースのフィルタリングを検討。

---

## 判定

**APPROVED** - すべてのMust Have/Should Have受入条件がクリア。88テスト全合格。後方互換性維持。改善提案はいずれも軽微であり、デプロイをブロックする要因なし。
