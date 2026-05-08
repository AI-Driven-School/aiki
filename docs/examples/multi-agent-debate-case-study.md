# Case Study: Multi-Agent Debate が1ジョブで重大な事実誤認を検出した話

**日付**: 2026-05-08
**手法**: aikiの Solver / Proposer / Checker 3エージェント反証
**結果**: Solver単独では気づけなかった**法律解釈の致命的誤り**を Proposer が反論で発見、Checker が WebSearch で確定。

## 背景

中小企業向けAIサブスク事業の参入判断中、契約構造（24ヶ月ロック+機器贈与モデル）の法規制リスク評価で:

- **Solver (Claude)** が「特商法『特定継続的役務提供』に該当 → 24ヶ月ロックは無効化される」と判定
- 8観点スコアカード合計 26/40 で **Pivot 推奨** と結論

これだけ見ると「丁寧な調査」に見えるが、Solver単独だと事実誤認に気づけない。

## デバート実行

### Step 1: Solver 主張の保存

```bash
cat > /tmp/solver-claim.md <<EOF
## 主張
月額¥98k〜¥498kで24ヶ月ロックの軍師Boxは、特商法「特定継続的役務」に該当し、
中途解約権が法律上強制される。よって24ヶ月縛りは無効化される。

## 根拠
- 月額5万円超 + 解約禁止1〜2ヶ月超 → 特商法対象
- 軍師Lite ¥98k > 5万円閾値 ✅
- 24ヶ月 >> 1〜2ヶ月閾値 ✅
EOF
```

### Step 2: Proposer (Gemini) で反論

```bash
cat /tmp/solver-claim.md | gemini -p "
あなたは Multi-Agent Debate の Proposer (反論者) です。
日本の弁護士的な視点で、Solver 主張に対して反論してください。
- 論理的な穴・事実誤認・過度の一般化を探す
- 特商法の実際の条文を確認し、Solverの解釈が正しいか検証
- 反論できなければ「反論なし」と書く
" --yolo > /tmp/proposer-rebuttal.md
```

**Proposer (Gemini) の反論**:

> ## 結論: Solver主張は「致命的に誤り」
>
> ### 反論ポイント1: 「特定継続的役務提供」の対象外（事実誤認）
>
> 特商法における特定継続的役務提供は、法で指定された **「7業種」に限定列挙** されている:
> ①エステ ②美容医療 ③語学 ④家庭教師 ⑤学習塾 ⑥パソコン教室 ⑦結婚相手紹介
>
> SaaS/経営コンサルは政令未指定 = 規制対象外。
> Solver が引用した「金額5万円超・期間1〜2ヶ月超」の閾値は、上記7業種に該当した上で適用される条件。

### Step 3: Checker (WebSearch) で事実確認

[消費者庁 特定商取引法ガイド](https://www.no-trouble.caa.go.jp/what/continuousservices/) で確定:

> 特定継続的役務は政令で **7業種限定列挙**。
> SaaS/経営コンサルは政令未指定 = 規制対象外と考えられる。

**判定: PROPOSER 勝ち。Solver主張は事実誤認**

## 学び

### 1. 単独AIは「もっともらしい嘘」を流暢に書く

Solver(Claude)の出した主張は、構造化されていて出典URL付きで一見説得力があった。
しかし条文の限定列挙という決定的事実を見落としていた。

### 2. 学習源が異なるAIで反証する効果

同系統のAI（Claudeのみ、GPTのみ）では同じバイアスを持つため独立検証にならない。
**Anthropic / Google / OpenAI** という異なる系統で対立させて初めて意味がある。

[2026年の研究 (MARCH, Microsoft CORE)](https://arxiv.org/html/2603.24579v1) でも、
Multi-Agent Debate は false positive を **25.8%削減**することが示されている。

### 3. Checker は WebSearch を持つ層が担う必要がある

Codex/Geminiは条文DBにアクセスできない。最終確定には:
- WebSearch を持つAI (Claude with WebSearch)
- 公式情報源（消費者庁、政府公表データ）

への接続が必須。

## ROI

このデバート1ジョブの実働時間: **約2分**（Gemini呼出+WebSearch1回）
- もし Solver単独で進めていたら → クライアント提示資料に誤った法律解釈を記載
- クライアントが顧問弁護士に確認 → 「特商法に該当しません」の指摘
- 信用失墜・案件失注のリスク

**コスト**: Gemini無料枠 + WebSearch ≈ ¥0
**回避できた損失**: 案件1件分の信用 = 数百万円規模

## aikiにおける実装

aiki は CLI で異種AIをタスクごとにルーティングする設計のため、
このデバートを `aiki debate <claim-file>` のように1コマンド化する余地がある。

将来追加候補:
- `aiki debate` サブコマンド
- Solver/Proposer/Checker の役割を `--role` で明示
- 出力を JSON で返し、CI に組み込み可能化

## 参考文献

- [MARCH: Multi-Agent Reinforced Self-Check (2026)](https://arxiv.org/html/2603.24579v1)
- [Microsoft CORE: 多エージェント検証フレームワーク](https://www.mdpi.com/2078-2489/16/7/517)
- [消費者庁 特定商取引法ガイド](https://www.no-trouble.caa.go.jp/what/continuousservices/)
- [PR-Agent (Qodo)](https://github.com/qodo-ai/pr-agent) — Multi-AI レビューOSS
