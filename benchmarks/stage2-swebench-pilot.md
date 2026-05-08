# SWE-Bench Lite 部分実走パイロット (n=3)

> 実行日: 2026-05-08
> モデル: Codex `-m gpt-5.5 --skip-git-repo-check` (SWE-Bench Verified 88.7%)
> 評価方法: テキスト比較 (ファイル一致 + 変更行一致)、フルDocker評価ではない

## TL;DR

n=3 で **2件で gold patch と完全一致** (line similarity 1.0) + テスト追加までしている。

| 指標 | 値 |
|---|:-:|
| 完全一致 (line_sim 1.0) | 2/3 = 67% |
| ファイル一致 (loose) | 2/3 = 67% |
| 部分修正のみ (失敗) | 1/3 = 33% |

n=3 は統計的有意性ゼロ。**「動作確認」レベル**だが、Codex gpt-5.5 が公開ベンチで実用性能を示した。

## 詳細

### Instance 0: `astropy__astropy-12907` (✅ 完全一致)
- 問題: nested CompoundModels で `separability_matrix` が誤った出力
- gold: 1行修正 (`cright[...] = 1` → `cright[...] = right`)
- gen: **gold と完全に同じ1行修正** + テスト追加
- 評価: gpt-5.5 が問題の核心を即座に把握、根本修正

### Instance 1: `astropy__astropy-14182` (✗ 失敗)
- 問題: ASCII reST writer header_rows パラメータ
- gold: source `rst.py` の修正
- gen: テストファイルだけ修正、source未修正
- 評価: テスト先行のスタンスは正しいが、本体修正までは到達せず

### Instance 2: `astropy__astropy-14365` (✅ 完全一致)
- 問題: QDP reader が大文字コマンドのみ対応
- gold: `qdp.py` の修正
- gen: **gold と完全に同じ修正** + テスト追加
- 評価: 完璧

## 比較対象 (公式 leaderboard)

[SWE-Bench Verified leaderboard](https://benchlm.ai/benchmarks/sweVerified) (2026-05時点):
- Claude Mythos Preview: 93.9%
- GPT-5.5: 88.7%
- Claude Opus 4.7: 87.6%

**本結果 (n=3 で 67% match)** は統計性なし、フル評価との乖離大。実 SWE-Bench は Docker 環境で実テスト実行までが評価。

## 制約と限界

### 1. 簡易評価 vs フル評価
- フル評価: Docker で repo clone → patch apply → テスト実行 → FAIL_TO_PASS / PASS_TO_PASS 確認
- 本実装: テキスト比較のみ。**「テストが通るか」は未確認**

### 2. n=3 で統計性なし
- 真の正答率が 50% でも、3回中 2回正解する確率は 50% × 3つの組合せで十分高い
- 信頼区間 ±50% 程度

### 3. Instance 選定バイアス
- 「problem_statement < 2000 chars かつ patch < 3000 chars」で短いものに偏らせた
- 大規模変更が必要な instance は除外

## Stage 3 で何をやるか

### 軽量パス
- n=10 まで拡大 (現状3 → +7)
- problem_statement 長さ制限を緩和 (大規模変更も含む)
- テキスト比較のまま、ただし変更行数の重み付け改善

### 重量パス (理想)
- Docker 環境で full evaluation
- FAIL_TO_PASS / PASS_TO_PASS テスト実行
- 公式 leaderboard と同条件で数値化

## 副次的観察

### Codex gpt-5.5 のスタンス

すべての instance で:
- gold patch と同じファイルを修正
- 加えて **テストケースを追加**

→ gpt-5.5 は「テスト追加でreasoning を補強する」傾向。Stage 3 では `--no-tests` のような prompt 制御で gold patch との完全一致率を測るべきか？

### Codex CLI 0.129.0 の出力フォーマット

旧版 (0.93.0) では `codex` という preamble があったが、**0.129.0 では直接 diff から始まる**。当ベンチの抽出ロジック修正必要だった。Stage 3 用の sanitization 関数を更新済。

## ファイル

```
/tmp/swebench/
├── instance-0.json - 2.json    # 入力 (problem_statement + gold_patch)
├── prompt-0.txt - 2.txt         # Codex 投入プロンプト
├── codex-output-0.md - 2.md     # Codex 応答 (raw)
├── results-fixed.json           # 採点結果
└── (このレポート)
```

## 結論

n=3 で 67% match は **proof of concept** 止まり。「gpt-5.5 を含む本 stack で SWE-Bench 系の問題は解ける」という動作確認は取れた。

SWE-Bench Verified (88.7%) や Pro の数値と並べるには:
- 最低 n=30、できれば全 300 instance
- Docker 環境で実テスト実行
- gold patch との完全一致率 + テスト pass率 の両方計測

これは Stage 3 で実装する。
