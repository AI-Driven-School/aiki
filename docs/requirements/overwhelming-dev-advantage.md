# 要件定義: 圧倒的開発優位性 (ai4dev v5)

**作成日**: 2026-02-20
**ステータス**: Draft

---

## 背景

v4で品質ゲート並列化、アーティファクトキャッシュ、品質ラチェット、適応型auto_fix等を実装済み。
しかし徹底調査の結果、**競合との構造的差別化を決定的にするために以下の弱点が残存**：

1. Codex未インストール時に実装フェーズがスキップされ、パイプラインが空PASSする
2. auto_fixが`claude -p`（単発プロンプト）で、ファイル編集やテスト実行の能力がない
3. フェーズ間が完全直列（投機的実行なし）
4. 機能間の知識共有がない（authの失敗がdashboardに活かされない）
5. カバレッジレポートが存在しない場合、カバレッジゲートがサイレントスキップ
6. deployフェーズがpipeline-engineに統合されていない
7. MAX_RETRIES超過時のエスカレーション先がない

---

## ユーザーストーリー

AS A ai4devを使うソロ開発者
I WANT TO パイプラインを実行するだけで、設計→実装→テスト→レビューが自動完了する
SO THAT 手動介入なしで品質の高いコードが生産され、競合ツールより圧倒的に速く開発できる

AS A Codex未インストールの開発者
I WANT TO Codexがなくても実装・テストフェーズが自動実行される
SO THAT ChatGPT Proサブスクリプションなしでもパイプラインが完結する

AS A 複数機能を開発するチームリーダー
I WANT TO ある機能で学んだ失敗パターンが他の機能のプロンプトにも自動反映される
SO THAT チーム全体の品質が機能を超えて向上する

AS A CI/CDパイプラインの管理者
I WANT TO MAX_RETRIES超過時にGitHub Issueが自動作成される
SO THAT 修正不能なエラーが見逃されない

---

## 受入条件

### 機能要件

- [ ] AC-1: Codex未インストール時、Claude CLIがフォールバック実装者として機能する
- [ ] AC-2: auto_fixが`claude --dangerously-skip-permissions`モードでファイル編集・テスト実行が可能になる（`AUTOFIX_AGENT_MODE`環境変数で有効化）
- [ ] AC-3: テストフェーズのカバレッジ閾値未達時、`--coverage`フラグ付きでテストを再実行する自動フォールバック
- [ ] AC-4: 全機能のmetrics.jsonlから横断的弱点プロファイルを構築し、プロンプトに注入する（`compute_global_weakness_profile()`）
- [ ] AC-5: パイプラインでフェーズがFIXABLEのままMAX_RETRIES超過した場合、`gh issue create`で自動Issue作成（`--escalate-to-github`フラグ）
- [ ] AC-6: deployフェーズをpipeline-engine.shに統合し、`--phases`に`deploy`を指定可能にする
- [ ] AC-7: `_gate_secrets()`がgit diffだけでなく未追跡ファイル（`git ls-files --others`）もスキャン対象とする
- [ ] AC-8: パイプライン実行サマリーに競合比較ラインを表示する（「キャッシュヒット: 3/5フェーズスキップ → 推定3.2倍高速化」）
- [ ] AC-9: `--watch`モードを追加し、ファイル変更を検出して自動的に影響フェーズのみ再実行する

### 非機能要件

- **パフォーマンス**: 2回目以降のキャッシュヒット時、パイプライン全体が90秒以内に完了すること
- **互換性**: 既存の`--dry-run`, `--auto`, `--no-cache`等の全フラグが引き続き動作すること
- **安全性**: `AUTOFIX_AGENT_MODE`はデフォルト無効。明示的にオプトインが必要
- **可観測性**: 全メトリクスがmetrics.jsonlに記録され、`metrics-summary.sh`で閲覧可能
- **後方互換**: v4のテスト（76件）が全てパスし続けること

---

## 制約事項

- **フレームワーク**: Bash（POSIX互換 + bash 3.2+、macOS標準）
- **依存**: Claude CLI、git（必須）。Codex、Gemini、Grok、gh CLI（オプション）
- **テスト**: bats-core（既存テストフレームワーク）
- **コスト**: Claude API従量課金のみ。Codex（$0）、Gemini（$0）

---

## 優先順位（MoSCoW）

### Must Have（今回実装）
1. AC-1: Claude CLIフォールバック実装
2. AC-4: 横断的弱点プロファイル
3. AC-7: 未追跡ファイルのシークレットスキャン
4. AC-6: deployフェーズ統合
5. AC-8: 速度改善サマリー表示

### Should Have（今回実装）
6. AC-3: カバレッジ自動フォールバック
7. AC-5: GitHub Issue自動エスカレーション

### Could Have（次バージョン検討）
8. AC-2: Agent Modeでのauto_fix
9. AC-9: watchモード

---

## 変更対象ファイル（推定）

| ファイル | 変更内容 |
|---------|---------|
| `scripts/pipeline-engine.sh` | deploy統合、速度サマリー、横断弱点、Issueエスカレーション |
| `scripts/project-workflow.sh` | Claude CLIフォールバック実装、横断弱点プロンプト |
| `scripts/lib/quality-gates.sh` | 未追跡ファイルスキャン、カバレッジフォールバック |
| `scripts/lib/knowledge-loop.sh` | 横断的パターン抽出 |
| `tests/pipeline.bats` | 新規テスト追加 |

---

## 備考

- v4の76テストが全てパスし続けることを最優先制約とする
- 各変更は独立してテスト可能な単位で実装する
- Agent Mode（AC-2）は安全性への影響が大きいため、次バージョンに先送り
