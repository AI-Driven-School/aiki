# Stage 3 (PoC): /debate v1.3 Precision 改善の実測

> 実行日: 2026-06-05
> Skill: `/debate` v1.3 (Solver / Proposer / Critic / **Defender** / Checker)
> 目的: v1.3 で追加した「Defender + 反論裏取り必須化」が、Stage2 で判明した precision ボトルネック(True-kept 0%)を実際に改善するかを、**同一攻撃出力に2つの集約ルール**を適用して測定する。
> Models: Gemini (Proposer) / Codex gpt-5.5 (Critic) / Claude-fallback (Defender, grok 不在) / 独立 Agent ×2 (Defender + blind grader)

## TL;DR

| 指標 | v1.2 ルール (旧) | **v1.3 ルール (新)** |
|---|:-:|:-:|
| **True-kept** (正しい主張を残す, n=8) | **0/8 = 0%** | **8/8 = 100%** |
| **False-flagged = Recall** (偽を捕捉, n=6) | 6/6 = 100% | 6/6 = 100% |
| **Precision** (捕捉が本当に偽) | 6/14 = 42.9% | 6/6 = **100%** |
| **F1** | 60.0% | **100%** |

**結論(PoC範囲)**: v1.3 は precision を大幅改善(True-kept 0%→100%)しつつ recall 100% を維持した。Stage2 の "True-kept 0/5" を本 PoC でも v1.2 ルールで 0/8 と再現し、v1.3 ルールが 8/8 に反転させた。

## 実験設計(差分の因果分離)

1. **攻撃側(Proposer=Gemini / Critic=Codex)は1回だけ実行**。攻撃プロンプトは v1.1 と同一(「反論せよ。反論なければ妥当と書け」)。
2. その**同一出力に2つの集約ルールを適用**:
   - **v1.2**: いずれかの reviewer が「部分的に誤り/致命的に誤り」を出せば FLAGGED。中身は検証しない。
   - **v1.3**: 各反論を一次情報で照合し「核を偽にする有効な反論」のみ採用(Defender が 誤反論/巻き添え/imprecise を除外)。
3. これにより v1.2→v1.3 の唯一の差は**集約・検証ルール**に限定され、攻撃モデルの差を相殺する。

## サンプル

- **True 主張 8件 (TA-TH)**: bcrypt cost12 OWASP準拠 / CF Workers Free 100k req日 / TS は実行時型検査なし / App Router で gSSP 不可 / npm view version / Bun install 高速 / strict は集合フラグ / Vercel 使用量課金。いずれも公式docsで裏取りした TRUE。
- **False 主張 6件 (FA-FF)**: R2 完全無料 / OAuth2=OIDC / HTTPSでCSRF防げる / TS は実行時型検査する / S3 egress 無料 / MD5 でパスワード安全。いずれも明白な FALSE。

## 観測された現象(precision 問題の実演)

- **Gemini(Proposer)は True 主張 8件すべてに「部分的に誤り」を出した**(=Stage2 の "always rebut" バイアス再現)。例: TA(bcrypt) の3反論は「Argon2idが上」「高セキュリティ用途は13以上」「72バイト制限」で、いずれも *主張を偽にしない隣接論点/難癖*。
- **Codex(Critic)は True 8件すべてに「妥当」**、False 6件すべてに「致命的に誤り」と正しく判定(stage3式プロンプトが効いた)。
- v1.2 ルールでは Gemini の空振り「部分的」が True 主張を全滅させる(0/8)。v1.3 の裏取りでこれらが全件却下され、True 8件が生き残った。
- False 6件では Gemini/Codex 双方が「致命的に誤り」、裏取りも有効 → v1.3 でも全件 FLAGGED(recall 不変)。

## 採点の独立性

- 採点者は **ground truth を渡さない blind な独立 Agent**(本体 Claude とは別コンテキスト)。自前 WebSearch で各主張の真偽を独立判定。
- grader の真偽判定 14/14 が設計上の ground truth と一致 → 採点者較正 OK。
- 別途 **Defender Agent** も独立に 8 True 全件 defensible と判定(grader と独立に同結論=クロスチェック成立)。

## Honest caveats(重要)

1. **n=14 は統計的検出力が低い**。PoC であり、Stage3 本番(n=100)ではない。CI は広い。
2. **選択バイアス**: True は検証容易・False は明白なものを著者が作成。**実運用の grey-zone 分布とは異なる**。特に False が「明白」なため recall 維持は容易な条件。
3. **未検証の主リスク**: *微妙な False 主張*(攻撃側の反論が弱い/裏取り困難な偽)では、v1.3 の「裏取り不能な反論を却下」ルールが**偽を見逃して recall を落とす**可能性。本 PoC の False は明白で、ここを突いていない。Stage3 本番で要検証。
4. **Defender は grok 不在で Claude フォールバック**。ベンダー独立性が落ちる(自己フォールバック規則で Confidence -10%)。grok or 第4ベンダー導入で独立性を回復すべき。
5. grader/Defender とも Claude family。人間採点ではない。

## 次アクション(Stage3 本番への要件)

- n=100(True15/False40/Grey15 + コードPR25 + SWE5)へ拡大。**微妙な False を必ず含め recall 退行を測る**。
- Defender を真の第4ベンダー(grok)で実行し独立性回復。
- v1.2/v1.3 を同一クレームで完全並走し precision/recall 両方の delta を CI 付きで報告。
- 人間スポット採点を一部に入れて grader 較正を裏取り。

## 再現

```
~/aiki-projects/benchmarks/stage3-v13/
  claims/{TA..TH,FA..FF}.md   # 主張 + ground_truth
  run_attack.sh / run_attack_false.sh
  attack/{cid}-{gemini,codex}.md   # 攻撃出力(生)
  bundle_no_truth.md / bundle_false_no_truth.md  # grader 入力(truth 抜き)
```
採点: 独立 Agent に bundle を渡し v1.2/v1.3 verdict を JSON 抽出。
