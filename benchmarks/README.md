# ベンチマーク

Claude Code単体 vs 4AI連携のパフォーマンス比較

## テストタスク

| # | タスク | 複雑度 |
|---|--------|--------|
| 1 | TODOアプリ（CRUD + localStorage） | 低 |
| 2 | 認証API（JWT + リフレッシュトークン） | 中 |
| 3 | ダッシュボード（グラフ + テーブル） | 中 |

## 計測方法

```bash
# Claude Code単体
time claude --print "タスク内容" > output.txt

# Codex単体
time codex --full-auto "タスク内容" > output.txt
```

## 結果

[結果はbenchmarks/results/に保存]
