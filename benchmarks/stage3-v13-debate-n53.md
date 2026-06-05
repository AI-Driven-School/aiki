# Stage 3: /debate v1.3 ベンチ (n=53, 独立グレーダー)

> 実行日: 2026-06-05
> Skill: `/debate` v1.3 (Solver / Proposer / Critic / Defender / Checker)
> 目的: PoC(n=14)で見えた precision 改善を拡大検証し、**最大リスク=「微妙な False で v1.3 の反論却下ルールが recall を落とす」を測る**。
> Models: Proposer=Gemini(36件)/Claude-fallback(17件, Geminiクォータ枯渇) / Critic=Codex gpt-5.5(53件) / 独立グレーダー=Claude Agent ×3(blind, ground truth 非開示)

## TL;DR

| 指標 (Unambiguous n=41: True15+False26) | v1.2 (旧) | **v1.3 (新)** |
|---|:-:|:-:|
| **Precision** | 63.4% | **100%** |
| **Recall** | 100% | **100%（維持）** |
| F1 | 77.6% | **100%** |
| Accuracy | 63.4% | **100%** |
| **True-kept** (正しい主張を残す, n=15) | **0/15 = 0%** | **15/15 = 100%** |
| **微妙False の recall** (SF1-20) | 20/20 | **20/20 = 100%（退行ゼロ）** |

**結論**: v1.3 は precision を 63→100%(本n)に改善し、かつ **20件の巧妙な False(数値僅差・概念すり替え・最新仕様トラップ)でも recall 100% を維持**。最大の懸念だった「却下ルールが偽を見逃す」退行は本ベンチでは発生しなかった。

## サンプル構成 (n=53)

| カテゴリ | 件数 | 用途 |
|---|:-:|---|
| True (NL) | 15 (NT1-7 + 既存TA-TH) | precision/True-kept |
| 明白 False (NL) | 6 (FA-FF) | recall sanity |
| **微妙 False (NL)** | **20 (SF1-20)** | **recall 退行の本丸** |
| Grey (規範主張) | 12 (G1-12) | disagreement |

微妙False の設計(怠惰なレビュアーが見逃す罠): 数値僅差(SF2 10万→100万req, SF7 40万→100万GB秒, SF14 AES 14→20ラウンド, SF19 UUIDv4 122→128bit), 概念すり替え(SF1 301がPOST保持=実は308, SF5 Postgres既定REPEATABLE READ=実はREAD COMMITTED, SF9 git revert=reset --hardの説明, SF4 JWS暗号化), 最新仕様トラップ(SF8 Python3.13 GIL既定無効, SF6 0-RTT非冪等安全, SF18 SNI既定暗号化)。

## 実験設計(差分の因果分離)

攻撃側(Proposer+Critic)を1回実行し、**同一出力に2つの集約ルール**を適用:
- **v1.2**: いずれかの reviewer が「部分的に誤り/致命的に誤り」を出せば FLAGGED。中身未検証。
- **v1.3**: 各反論を grader が一次情報照合。**核を実際に偽にする有効反論のみ採用**(難癖/巻き添え/imprecise/裏取り不能は却下)。
唯一の差は集約・検証ルール。

## 主要結果

### 1. Precision 改善 (True-kept 0/15 → 15/15)

Proposer は True 15件すべてに「部分的に誤り」を出した(="always rebut"バイアスを n=15 でも再現)。v1.2 はこれで True を全滅(0/15)。v1.3 は grader が各反論を一次照合し、全件 *難癖/巻き添え/imprecise* と判定して却下 → True 15件が生存(15/15)。

### 2. Recall 維持 — 微妙 False でも退行なし (20/20)

本ベンチの核心。20件の巧妙な偽主張すべてで、Critic(Codex) が「核を偽にする有効反論」を生成し、v1.3 の検証を通過 → 20/20 FLAGGED。**v1.3 の却下ルールは valid な反論を捨てない**ことを示す。明白False 6件も 6/6 FLAGGED。

### 3. Grey の扱い(正直な論点)

12件の規範主張(「XはYより常に優れる/全プロジェクトで採用すべき」)は、設計上 GREY ラベル。だが独立グレーダーは 11/12 を **「常に/全て/すべき」の絶対的全称が客観的に偽の overclaim」** として FALSE 判定し FLAGGED。1件(G10 FP vs OOP)のみ純主観として KEPT。
→ これは v1.3 の precision エラーではなく、過度一般化を正しく捕捉した可能性が高い。ただし「主観の単純表明」を偽と切るリスクとの境界は曖昧で、Grey は ground truth 自体が係争的。**clean metrics からは Grey を除外**して報告。

## 採点の独立性・較正

- グレーダー3体は ground truth 非開示で各主張の真偽を独立判定。**Unambiguous 41件で grader の真偽判定が intended label と全件一致**(15 TRUE / 26 FALSE)→ 較正良好。
- v1.3 verdict は grader の独立真偽判定と Unambiguous 41/41 で一致。

## Honest caveats(重要)

1. **recall 退行を完全には潰せていない**: 本ベンチの微妙False は「検証すれば明確に偽」で、Critic が全件有効反論を出した。真の退行リスクは *両 reviewer が揃って実証できない偽*(誰も裏取りできない巧妙な嘘)。そのケースは本セットに含まれず未検証。recall 100% は「v1.3 が valid 反論を捨てない」ことの証拠だが「あらゆる微妙Falseを捕捉する」証明ではない。
2. **ベンダー独立性の劣化**: Gemini クォータ枯渇で 17件(SF12,SF17-20,G1-12)の Proposer を Claude フォールバックに置換。これら + grader も Claude family。OpenAI(Codex) 以外の独立性が一部低下。
3. **n=53、選択バイアス**: 著者がクレーム作成。True は検証容易、False は(巧妙だが)検証で確定するもの。実運用分布とは異なる。
4. **コードPR/SWE-Bench 比較は未実施**(stage3-design の CF/CT/SB 部分)。本ベンチは NL 論述のみ。
5. **人間採点なし**。grader は Claude。

## 結論として言えること / 言えないこと

- **言える**: v1.3 の「Defender+反論裏取り」は、同一攻撃出力に対し v1.2 比で precision を 63→100%(n=41)に上げ、20件の巧妙な False を含めても recall 100% を維持した。"always rebut" バイアスによる false positive を構造的に除去できている。
- **まだ言えない**: 「実運用で精度向上」。両reviewerが揃って見逃す微妙Falseでの recall、真の第4ベンダー(grok)独立性、grey境界、人間較正、コード/SWE領域は未確定。

## 再現

```
~/aiki-projects/benchmarks/stage3-v13/
  stage3_claims.json            # 39新規クレーム+ground_truth+出典
  claims/*.md (53)              # TA-TH/FA-FF(PoC)+NT/SF/G
  run_attack_stage3.sh          # Proposer+Critic 実走
  attack/{cid}-{gemini,codex}.md
  grade_{A,B,C}.md              # blind grader 入力(ground truth 抜き、python生成)
```
採点: 独立 Agent3体に grade_*.md を渡し v1.2/v1.3 verdict を JSON 抽出 → python で混同行列。
