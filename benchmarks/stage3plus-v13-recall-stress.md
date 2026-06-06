# Stage 3+: /debate v1.3 の recall 退行ストレステスト

> 実行日: 2026-06-06
> 目的: Stage3 で残した最大の宿題=「**両/全 reviewer が揃って見逃す巧妙な偽**で、v1.3 の『裏取りできない反論を却下』ルールが v1.2 より recall を落とすか」を、敵対的に作った hard-false 18件で突く。
> 副目的: grok を第4ベンダーに入れて独立性回復 → **xAIクレジット枯渇で実行不可**(人間ゲート、後述)。

## TL;DR

**v1.3 の recall 退行は実在する。ただし「誤った理由による偶然の捕捉(lucky catch)」を捨てるときに限られ、正しく論証された捕捉は一度も失わない。** 強い reviewer が1体でもいれば退行は消える。

| パネル | v1.2 recall | v1.3 recall | 退行 |
|---|:-:|:-:|---|
| 弱reviewer単独 (Haiku, web無, n=17 False) | 11/17 = 64.7% | 10/17 = 58.8% | **1件(HF4)** |
| 強reviewer単独 (Codex gpt-5.5, n=17) | 17/17 = 100% | 17/17 = 100% | **0件** |

## 設計

18件の hard-false 主張(HF1-18)を敵対生成。狙いは「2体の独立AI reviewer が誤りやすい罠」: 直感に反する正解 / 版依存(最新仕様変更) / 権威的な誤数値 / ニッチ仕様 / 複合(大半正しく1点だけ偽)。例:
- HF7 Postgres既定=REPEATABLE READ(実はREAD COMMITTED)
- HF8 TIME_WAITは受動クローズ側(実は能動側)
- HF16 cron の日/曜日両指定はAND(実はOR)
- HF12 DNS Flag Day 2020推奨=4096(実は1232)
- HF6 UUIDv4乱数=124bit(実は122bit)

各主張は ground truth + 一次情報出典付き。攻撃側を回し、**同一出力に v1.2/v1.3 両ルール**を適用、採点は ground truth 非開示の独立グレーダー(WebSearch可)。

## 結果1: 強panel(Codex gpt-5.5) — 罠は通用せず

Codex 単独で **17件の偽すべてを捕捉(17/17)**。版依存・誤数値・複合の罠も gpt-5.5 には効かなかった。よって v1.3 の却下ルールは「捨てる対象(誤反論)」が無く recall=100%、v1.2 と同値。**強い fact-checker が panel にいれば退行は発生しない。**

> Gemini は本日分クォータ枯渇で全件無応答 → 2体目の独立攻撃が取れず。退行を測るには「弱い2体目」が必要なので、別途 weak panel を構成(下記)。

## 結果2: 弱panel(Haiku, 検索禁止) — 退行の実証

意図的に弱い reviewer(Claude Haiku, WebSearch禁止, 純パラメトリック知識)を単独 reviewer として18件に当て、v1.2/v1.3 を比較:

- **正しく捕捉 10件** (HF3,5,6,7,8,9,10,11,17,18): 弱reviewerが正しい反論 → v1.2=v1.3=FLAGGED
- **退行 1件 (HF4)**: 主張は偽(418を予約したのはRFC9110でRFC7231でない)。弱reviewerは「部分的に誤り」と FLAG したが、その反論内容が**事実誤認**(「418はRFC7231で未使用記載」と誤って主張の偽前提を肯定)。→ **v1.2はFLAG(偶然の捕捉)、v1.3はグレーダーが誤反論を却下しKEEP=見逃し**。これが狙い通りの退行。
- **両見逃し 6件** (HF1,2,12,14,15,16): 弱reviewerが「妥当」と誤判定 → v1.2=v1.3=KEEP。**v1.3固有でなく panel が弱い(1体・無検索)ことの限界**。
- HF13: 私の生成器の**誤ラベル**(Git 2.51でSHA-256既定化と記載したが、Git 3.0が2026-06時点で未リリース→既定はSHA-1のまま=実はTRUE)。**blind グレーダーが検出・訂正** → 採点者が本当に独立検証している証拠。

## 解釈 — 退行の性質は「防御可能なトレードオフ」

- v1.3 が失う recall は **「誤った理由で偶然当たった FLAG」だけ**。HF4 で v1.2 が捕まえたのは、信用してはいけない誤反論によるもの。v1.3 はそれを却下する設計どおりに動いた。
- v1.3 は**正しく論証された捕捉を一度も失っていない**(10/10 維持)。
- 退行が起きる条件は厳しい: (a)主張が偽 かつ (b)生き残る反論が全て誤論証 のとき**のみ**。reviewer が単に「妥当」と見逃すケース(6件)は v1.2 も同じく見逃すので v1.3 固有の損失ではない。
- **緩和策**: 強い reviewer(gpt-5.5級)を1体入れれば退行は消滅(17/17)。実運用の対処は「v1.3を捨てる」でなく「panel に強fact-checkerを確保」。

## grok 第4ベンダー独立性 — 未達(人間ゲート)

xAI APIキーは存在するが、チームが**クレジット枯渇/上限到達**で全リクエスト不可。実エラー: `has either used all available credits or reached its monthly spending limit`。捏造を避け未実行。**要: xAI クレジット補充(課金判断)**。補充後に grok を第4ベンダーの独立 reviewer/Defender として再走すれば、Anthropic/Google/OpenAI/xAI の4社独立が完成する。

## Honest caveats

1. **退行の定量は弱panel前提**(Haiku単独・検索禁止)。実運用stackはCodex(強)を含むので退行は観測されない。だが「弱い/無検索の reviewer しか居ない構成」では v1.3 は v1.2 を recall で僅かに下回りうる。
2. n=18、著者生成、1件(HF13)に生成器ラベル誤り(グレーダーが訂正)。
3. Gemini クォータ枯渇で本来の2社攻撃が取れず、強panelは Codex 単独評価。
4. grader/weak-reviewer とも Claude family。grok 未投入で真の4社独立は未達。

## 結論

- **言える**: v1.3 の recall 退行は実在するが**「誤論証による偶然の捕捉」を捨てる範囲に限定**され、正しい捕捉は失わない。強fact-checkerを1体入れれば退行ゼロ。設計の安全側の振る舞いとして妥当。
- **まだ言えない**: 真の4社独立(grok)での精度、Gemini込み2社攻撃での挙動。xAIクレジット補充が次の律速。

## 再現
```
stage3-v13/hard/
  hardfalse.json            # 18 hard-false + ground_truth + 出典
  run_attack_hard.sh        # 攻撃(Gemini枯渇/Codex 17/17)
  weak_input.md             # 弱reviewer入力(truth抜き)
  weak_verdicts.json        # Haiku(検索禁止)判定
  grade_weak.md             # 採点入力(truth抜き)
  weak_grade.json           # 独立グレーダー結果→混同行列
```
