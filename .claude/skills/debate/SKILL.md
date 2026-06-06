---
name: debate
description: Multi-Agent Debate (Solver/Proposer/Critic/Defender/Checker 5エージェント反証) で主張・実装・判断を独立検証。学習源の異なるAI (Claude/Gemini/Codex/Grok+WebSearch) を意図的に対立させてハルシネーション・事実誤認を検出。v1.2 で forecast モード追加: 将来予測系の主張には MiroFish 式の agent-based simulation (ステークホルダー・ペルソナ世界を多ラウンド) でシナリオ分布を生成。v1.3 で precision 強化: Defender(擁護者)を追加し攻撃3:擁護0の非対称を解消、かつ「反論=有罪」をやめ Checker が一次情報で裏取りできた反論のみを採用 (false positive 抑制)。`/debate <主張ファイル or テキスト>` で起動。MARCH/Microsoft CORE研究に基づく実装で false positive -25.8% 期待。
metadata:
  version: "1.3"
  references:
    - "MARCH (2026): https://arxiv.org/html/2603.24579v1"
    - "Microsoft CORE: https://www.mdpi.com/2078-2489/16/7/517"
    - "MiroFish (agent-based prediction): https://github.com/666ghj/MiroFish"
    - "/project SKILL.md §9.1"
---

# /debate スキル

Multi-Agent Debate で主張を反証検証する独立スキル。`/project` の §9.1 を任意の主張・実装・判断に横展開する。

## いつ使うか

- 重要な事業判断（参入/撤退/Pivot）の根拠が単独AIで出された
- 法律解釈・市場推定・競合分析など**事実誤認のコストが高い**場合
- 実装コードのレビュー（仕様遵守・ハルシネーション検出）
- ピッチ資料・営業書類の事実確認
- 自分が書いた結論に確信が持てない時

## 使用方法

```bash
# ファイル指定
/debate path/to/claim.md

# 直接テキスト
/debate "中小企業向けAIサブスクは特商法該当でPivotすべき"

# 出力形式指定
/debate path/to/claim.md --format=json    # CI連携用
/debate path/to/claim.md --format=md      # デフォルト
```

## 2つのモード（v1.2: forecast 追加）

`/debate` は主張の性質で2モードに分岐する。`--mode=auto`（デフォルト）で自動判定。

| モード | 対象主張 | 検証手段 | 出力 |
|---|---|---|---|
| **verify**（既存） | **事実主張**（条文/統計/競合事実/コード仕様など、今すでに真偽が決まっているもの） | 学習源の違う3社AIを**敵対的に対立**させCheckerが一次情報で判定 | 真偽 verdict |
| **forecast**（新） | **将来予測主張**（参入したら売れる/この施策でCVが上がる/撤退すべき 等、未来の反応に依存するもの） | MiroFish式の**ステークホルダー・ペルソナ世界**を多ラウンド回し反応をシミュレート | シナリオ分布(bear/base/bull) + GO/NO-GO |

**自動判定ルール**: 主張に「〜すべき」「〜なら売れる/伸びる/儲かる」「参入/撤退/Pivot後どうなるか」など**未来の事象・人間の反応に依存する命題**が含まれれば forecast。純粋な事実照合は verify。両方含む場合は verify で事実部分を固めてから forecast。`--mode=verify` / `--mode=forecast` で明示指定可。

> **なぜ分けるか**: 敵対的debateは「正しいか」の検出に強いが、「将来どう転ぶか」には弱い（誰も未来の一次情報を持たない）。逆にMiroFishのagent-based simulationは予測に強いが反証・ファクトチェックは持たない。両者は補完関係であり、**verify=反証 / forecast=シミュレーション**として使い分ける。

## 5エージェントの役割（v1.1 Codex Critic / v1.3 Defender 追加）

| エージェント | モデル | 役割 |
|---|---|---|
| **Solver** | Claude Opus 4.7 (this, SWE-Bench 87.6%) | 元の主張を整理して保存。攻撃される側 |
| **Proposer** | Gemini CLI 0.41.2 (Gemini 3.x) | 反論者。論理的穴・事実誤認・反例を提示 |
| **Critic** | Codex `-m gpt-5.5` (SWE-Bench 88.7%) | 第二の独立反論者。技術的検証・コード裏付け |
| **Defender** | xAI Grok CLI (学習源4社目, 無ければフォールバック表) | **擁護者(v1.3)**。Proposer/Critic の反論を逆に反証。反論側のハルシネーション・誤読・古い情報・複合主張の巻き添えを突き、Solver主張の steelman(最強の擁護)を構築 |
| **Checker** | Claude with WebSearch | 一次情報で全意見を検証、最終判定。**反論は有罪判定でなく“検証すべき仮説”として扱う(v1.3)** |

**重要**: 学習源の異なる **4社のAIで対立**させる（Anthropic / Google / OpenAI / xAI）。同系統では同じバイアスを共有するため独立検証にならない。Defender も Proposer/Critic と別ベンダーであることが擁護の独立性に効く。

### Defender を追加した理由 (v1.3) — precision のボトルネック対策

[n=30 ベンチ](https://github.com/AI-Driven-School/aiki/blob/main/benchmarks/stage2-debate-n30.md) で **Recall=100% だが Precision=78.3%**。弱点は「正しい主張を誤って“偽”と切り捨てる false positive」約2割。原因はベンチ自身が名指し:

1. **Proposer(Gemini)の "always rebut" バイアス**: TRUE な主張にも 4/5 で「部分的に誤り」を返す
2. **集約が過敏**: 「両者反論→Solver負け」で反論=有罪になり、反論の正しさを検証していない
3. **攻撃3:擁護0の非対称**: 誰も主張を弁護せず、構造的に過剰有罪化

Defender(擁護者)を 4社目の独立ベンダーで置き、**攻撃と擁護を対称化**する。MAD研究(Du et al. ICML2024)の対称debate本筋で、recall を落とさず precision に直接効く。

### Critic を追加した理由 (v1.1)

[2026-05-08 ベンチ結果](https://github.com/AI-Driven-School/aiki/blob/main/benchmarks/stage1-debate-catch-rate.md) で Proposer (Gemini) のみで n=5 中 4件完璧 + 1件部分的（具体数値の精度不足）。第二の反論者として Codex (gpt-5.5) を追加することで:

1. **技術的・数値的検証の強化**: Codex はコード/数値分野で SWE-Bench 88.7% 最強
2. **2社独立反論**: Gemini と Codex は学習源完全別、独立反論度が上がる
3. **三段階フィルタ**: Solver → Proposer → Critic → Checker の4層

## 各社内部実践との関係（設計根拠）

本 skill は以下の各社公開ドキュメントの知見を統合:

| 社 | パターン | 本 skill への反映 |
|---|---|---|
| **Anthropic** ([multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system)) | Orchestrator-Worker (Opus Lead + Sonnet Subagents)、内部評価で **+90%** 単独agent比 | Solver/Proposer/Checker を orchestrator-worker として実装。Solver=Lead, Proposer/Checker=Subagent |
| **OpenAI** ([Auto-review](https://alignment.openai.com/auto-review)) | 別エージェントが boundary-crossing actions を承認、人間承認 **200倍 less** | Checker を「人間承認の代替」として位置づけ。重要案件のみ人間にエスカレ |
| **OpenAI** ([Scaling code verification](https://alignment.openai.com/scaling-code-verification/)) | 100% PR review by Codex、push前 `/review` 標準 | 軽い主張も含め全PR/全主張に適用するデフォルト設計 |
| **Google** ([AutoCommenter研究](https://research.google/pubs/ai-assisted-assessment-of-coding-practices-in-industrial-code-review/)) | 数万人のエンジニアが日常使用、AI-suggested + 人間レビュー必須 | autonomous shipping は禁止、最終判定の confidence < 70% は人間判断必須 |
| **xAI Grok** | Grok Build: 最大 **8並列 agent/session** | 並列度上限を 4→8 に拡張可（debate チェーンを並列で複数主張同時検証） |

## 実行フロー

### Step 1: Solver claim 整形

入力（ファイル or テキスト）から **主張・根拠・出典** を抽出して `/tmp/debate-solver-claim.md` に保存:

```markdown
# Solver 主張

## 結論
{1-2文}

## 根拠
- {根拠1 + 出典URL or {推測値}注記}
- {根拠2 ...}

## 前提
- {前提1}
```

### Step 2: Proposer (Gemini) 起動

```bash
cat /tmp/debate-solver-claim.md | gemini -p "
あなたは Multi-Agent Debate の Proposer (反論者) です。
以下の Solver 主張に対して反論してください。

タスク:
1. Solver主張の論理的な穴・事実誤認・過度の一般化を探す
2. 一次情報・条文・統計を用いて Solver の根拠が正しいか検証
3. 反例・例外規定・反証材料を提示
4. 反論できる箇所が皆無なら「反論なし」と書く

形式:
- 結論 (Solver主張は妥当 / 部分的に誤り / 致命的に誤り)
- 反論ポイント1-3 (具体的に、根拠付きで)
- 提案する修正
" --yolo > /tmp/debate-proposer-rebuttal.md
```

### Step 2.5: Critic (Codex) 起動 — 第二の独立反論

```bash
cat /tmp/debate-solver-claim.md | codex exec --skip-git-repo-check -m gpt-5.5 "
あなたは Multi-Agent Debate の Critic (第二の独立反論者) です。
技術的・数値的検証を主軸に Solver 主張を反証してください。
形式: 結論(妥当/部分的に誤り/致命的に誤り) + 反論ポイント1-3(根拠URL付き)
" > /tmp/debate-critic-rebuttal.md
```

### Step 3: Defender (Grok) 起動 — 擁護者 (v1.3)

Proposer / Critic の反論を**逆に反証**し、Solver主張の steelman を構築する。攻撃3:擁護0の非対称を解消し precision を上げる中核ステップ。**学習源4社目（xAI Grok）**で回すのが理想。利用不可なら「失敗時フォールバック」表に従う。

```bash
cat /tmp/debate-solver-claim.md /tmp/debate-proposer-rebuttal.md /tmp/debate-critic-rebuttal.md | grok -p "
あなたは Multi-Agent Debate の Defender (擁護者) です。
直前の Proposer / Critic の反論に対して、Solver主張を弁護してください。

タスク:
1. 各反論ポイントの妥当性を1つずつ精査し、次のどれかに分類:
   - [誤った反論] 反論側のハルシネーション・誤読・古い情報・出典の読み違い
   - [複合主張の巻き添え] 主張全体でなく一部の枝だけが弱いのに全体を否定している
   - [imprecise≠wrong] 主張は『不正確』なだけで『偽』ではない
   - [有効な反論] 反論が正しく、Solver主張は実際に修正/撤回が必要
2. [有効な反論] 以外には、Solver主張を守る最強の根拠(steelman)を一次情報付きで提示
3. 弁護できない場合は正直に『弁護不能、反論が正しい』と書く(擁護の固執は禁止)

形式:
- 各反論ポイントへの分類 + 根拠
- Solver主張の steelman (生き残る核は何か)
- 結論 (Solver主張は擁護可能 / 一部のみ擁護可能 / 擁護不能)
" > /tmp/debate-defender.md
```

### Step 4: Checker (Claude+WebSearch) 起動 — 反論の裏取り (v1.3)

Proposer / Critic / Defender の全意見を受けて、**WebSearch で一次情報を確認**。v1.3 の核心は集約ルールの変更:

- **反論は有罪判定でなく『検証すべき仮説』として扱う**。Proposer/Critic の各反論ポイントを Checker が一次情報で裏取りできて初めて Solver の負けに寄与する。**裏取れない反論は棄却**（Gemini の "always rebut" 空振りを precision に算入しない）。
- **`部分的に誤り` を `偽` にカウントしない**。"wrong"(主張が間違い) と "imprecise"(不正確だが偽ではない) を分離して出力する。
- Defender が [誤った反論]/[複合主張の巻き添え]/[imprecise≠wrong] に分類した点は、Checker が一次情報で再確認のうえ反論側から減点する。
- 最終 verdict: SOLVER勝ち / PROPOSER勝ち / 両者誤り / 両者部分的に正しい の4択。

### Step 5: 判定出力

`/tmp/debate-verdict.md` に判定結果保存:

```markdown
# Debate Verdict

## Subject
{元の主張の1文要約}

## Verdict
{SOLVER勝ち / PROPOSER勝ち / 両者誤り / 両者部分的}

## Rebuttal Audit (v1.3)
| 反論ポイント | 出所 | 一次情報で裏取り | Defender分類 | 採否 |
|---|---|:-:|---|:-:|
| {反論1} | Proposer/Critic | 確認/不能 | 有効/誤反論/巻き添え/imprecise | 採用/棄却 |
> 採用された反論のみが Verdict に寄与。棄却された反論(裏取り不能・Defender反証成功)は precision を守るため算入しない。

## Wrong vs Imprecise (v1.3)
- **Wrong(偽)**: {主張が事実として誤っている部分。これだけが「偽」判定の根拠}
- **Imprecise(不正確だが偽ではない)**: {数値の粒度・表現の甘さ等。修正対象だが「偽」ではない}

## Reasoning
{なぜその判定か、3-5文}

## Key Evidence
- {一次情報URL 1}: {引用}
- {一次情報URL 2}: {引用}

## Action Required
{Solver主張をどう修正すべきか、または継続採用してよいか}

## Confidence
{0-100%、Checkerが一次情報で確認できた範囲}
```

## Forecast モード実行フロー（v1.2 / MiroFish式）

将来予測主張に対しては、上の verify フロー（Step1-4）ではなく以下を実行する。MiroFish の「種抽出→ペルソナ生成→並列シミュレーション→ReportAgent」を CLI オンリーで軽量再実装したもの。

### F1: Solver — 予測の枠組み抽出

入力から **(a) 予測する結果 / (b) 介入・意思決定 / (c) 時間軸 / (d) 不確実な変数 / (e) 既に手元にある実データ** を抽出して `/tmp/debate-forecast-seed.md` に保存。

> **実データ優先（feedback_data_first_decision）**: (e) に結果を語れる実データ（既存事業の実績・GA4・売上・競合の公開数値など）があれば、**シミュレーションより実データを根拠の主軸にする**。シミュレーションは実データの無い空白を埋める用途に限定する。

### F2: ペルソナ生成（MiroFish: persona generation）

主張に関係する **ステークホルダー・ペルソナを4-6体** 生成（例: 顧客セグメント / 規制当局 / 競合 / 投資家・パートナー / 社内オペ）。各ペルソナに `立場・ゴール・制約・意思決定ルール・情報アクセス・初期スタンス` を持たせ `/tmp/debate-forecast-personas.md` に保存。汎用ではなく**種データに接地**させること（架空の数値・実績を入れない: feedback_no_fabricated_content）。

### F3: 多ラウンド・シミュレーション（MiroFish: 並列 + 動的時系列メモリ）

T0→T1→T2 の3ラウンド（`--rounds=N` で可変）。各ラウンドで前ラウンドの集団状態 `/tmp/debate-forecast-state-T{n}.md` を読み込み更新する＝**動的時系列メモリ**。単一モデルのバイアスが世界を支配しないよう、ペルソナ群を**学習源の違う3社CLIに分担**:

| ペルソナ群 | 駆動CLI |
|---|---|
| 顧客・市場の反応 | `cat seed personas \| gemini --skip-trust -p "..."` |
| 数値・コスト・オペの実行可能性 | `cat seed personas \| codex exec --skip-git-repo-check -m gpt-5.5 "..."` |
| 規制当局・競合の対抗手 | `claude -p`（別 system prompt。orchestrator自身がClaudeなら冗長サブプロセスを避け直接執筆可） |

> **任意ディレクトリで動かすための必須フラグ（2026-05-21 dry-runで判明）**: 信頼登録されていない/git管理外のディレクトリ(例: `/tmp/workdir`)では、`gemini` は信頼チェックで、`codex exec` は git チェックで**即落ちする**。`gemini --skip-trust`（or `GEMINI_CLI_TRUST_WORKSPACE=true`）、`codex exec --skip-git-repo-check` を必ず付ける。`codex` 単体はTUIを開くので非対話では必ず `codex exec`。
> **Gemini クォータ枯渇のフォールバック**: Gemini 3.x は無料枠超過で `exhausted your capacity` のリトライループに入り無応答化する。検知したら background プロセスを止め、当該ペルソナ群を Claude が代替し Confidence を一段下げる（下の失敗時フォールバック表に準拠）。

各ラウンド: 各ペルソナが「この介入に自分はどう反応するか」を前ラウンド状態を踏まえて出力 → 集団状態ファイルに統合 → 次ラウンドへ。

### F4: 定量グラウンディング + 算術チェック（Critic）+ Devil's Advocate（Defender, v1.3）

シミュレーションで出た数値（TAM・転換率・コスト・ランウェイ等）は **Critic の数字を鵜呑みにせず、保守/楽観/固定費整合を自分で再計算**（feedback_debate_arithmetic_check）。実データがある項目は実データで上書き。

**Defender = Devil's Advocate (v1.3)**: シミュレーションが特定シナリオ（多くは base/bull）に収束した場合、Defender が**逆張りで合意を攻撃**する — 「この収束はペルソナ群の同調バイアスではないか？bear を過小評価していないか？」。verify モードの Defender が"擁護"なのに対し forecast では"合意への反証"を担い、いずれも**多数派の暴走を1体で止める**役。これで分布が1シナリオに張り付く false confidence を抑える。

### F5: ReportAgent — シナリオ分布合成（Checker + WebSearch）

WebSearch で外部前提（市場規模・規制・競合動向）を一次情報で接地しつつ、`/tmp/debate-forecast-report.md` に出力:

```markdown
# Forecast Report

## Subject
{予測主張の1文要約}

## Scenario Distribution
| シナリオ | 確率 | 結果 | 主要ドライバー |
|---|:-:|---|---|
| Bear  | {%} | {悪転時} | {何が効いたか} |
| Base  | {%} | {中央値} | {〃} |
| Bull  | {%} | {好転時} | {〃} |

## Leading Indicators（先行指標）
- {30/60/90日で観測すべき・予測が当たり始めるサイン}

## Verdict
{GO / NO-GO / CONDITIONAL（条件付き）}

## Reasoning
{なぜその分布か、シミュ＋実データ＋一次情報の根拠 3-5文}

## Confidence
{0-100%。実データの厚み・一次情報で接地できた割合に比例。シミュ単独依存なら 50% 以下}
```

> **シミュレーションの限界明記**: forecast は「未来の一次情報」を持てない。Confidence はシミュ単独なら必ず 50% 以下とし、重要判断は人間の最終承認を促す（verify と同じ天井ルール）。

## OSS連携（GitHub PR フロー）

ローカル使用ではなく PR レビューで使う場合:

| 用途 | OSS推奨 |
|---|---|
| GitHub PR 自動レビュー | [PR-Agent (qodo-ai)](https://github.com/qodo-ai/pr-agent) v0.32+ |
| 軽量 self-hosted | [Kodus AI](https://github.com/kodustech/kodus-ai) |
| Vercel製シンプル | [OpenReview](https://github.com/vercel-labs/openreview) |

## 制御フラグ

| フラグ | 効果 |
|---|---|
| `--mode=auto` | 主張の性質で verify/forecast を自動判定（デフォルト） |
| `--mode=verify` | 敵対的検証モードを強制（事実主張向け） |
| `--mode=forecast` | シミュレーションモードを強制（将来予測向け） |
| `--rounds=N` | forecast のシミュレーションラウンド数（デフォルト 3） |
| `--format=json` | 判定をJSON出力（CI連携） |
| `--format=md` | Markdown出力（デフォルト） |
| `--proposer=gemini` | Proposer モデル指定（デフォルト gemini） |
| `--defender=grok` | Defender モデル指定（デフォルト grok、v1.3） |
| `--no-defender` | Defender を省き旧 v1.2 挙動に戻す（precision より速度優先時） |
| `--checker=manual` | Checker をユーザー判断にする（一次情報がAIで取れない場合） |
| `--quick` | Step 5 / F5 の詳細reasoning省略、判定のみ |

## 失敗時のフォールバック

各エージェント失敗時の挙動:

| 失敗箇所 | フォールバック |
|---|---|
| Proposer (Gemini) クレジット切れ等 | xAI/Codex で代替試行 → 不可なら Claude(別system prompt)で代替 |
| **Defender (Grok) 未導入/失敗** | ①Codex を擁護ロール(別system prompt)で代替 → ②Gemini を擁護ロールで代替 → ③Claude が別 system prompt で擁護(独立性は落ちるので Confidence -10%明記)。**Defender 役を「省略」せず必ず誰かに担わせる**(擁護の欠落=precision 劣化のため) |
| Checker WebSearch失敗 | Claude単独で論理整合性チェックのみ実行、判定信頼度を50%以下に明記 |
| 一次情報が見つからない | 「Checker判定不能」と明記し、人間判断必須を出力 |
| forecast: Gemini/Codex のいずれか落ち | 残る2社で全ペルソナ群を分担、Confidence を一段下げて明記 |
| forecast: 実データもシミュも薄い | シナリオ分布を出さず「予測不能・前提データ不足」と明記し人間判断へ |

判定末尾に必ず `## Confidence: {N}%` を入れること。

## ベンチマーク（参考）

[研究値 (MARCH/CORE 2026)](https://arxiv.org/html/2603.24579v1):

| アプローチ | bug catch rate | hallucination |
|---|:-:|:-:|
| 単発 AI レビュー | 44-54% | 多 |
| Multi-Agent Debate (本skill) | 85-90% | 少 |
| Debate + 人間重要部のみ | 92-95% | 極少 |

完全AI化の天井は90%。残り5-10%は人間判断必須（重要案件のみ）。

### v1.3 実測（2026-06-05, 独立grader blind）

同一の攻撃出力(Proposer/Critic)に **v1.2ルール(反論あれば即有罪)** と **v1.3ルール(Defender+反論裏取り)** を適用し差分を分離測定。採点は ground truth を渡さない blind な独立 Agent。2回実施: PoC(n=14) → Stage3(n=53)。

**Stage3 (n=53; Unambiguous 41 = True15 + False26):**

| 指標 | v1.2 (旧) | **v1.3 (新)** |
|---|:-:|:-:|
| Precision | 63.4% | **100%** |
| Recall | 100% | **100%（維持）** |
| F1 | 77.6% | **100%** |
| True-kept (正しい主張を残す, n=15) | **0/15 = 0%** | **15/15 = 100%** |
| **微妙False の recall** (SF1-20: 数値僅差/概念すり替え/最新仕様トラップ) | 20/20 | **20/20 = 100%（退行ゼロ）** |

Proposer は True 全15件に「部分的に誤り」を出す("always rebut"バイアス)→ v1.2 は True 全滅(0/15)。v1.3 の裏取りで全件 *難癖/巻き添え/imprecise* として却下し True 15件生存。**最大の懸念だった「微妙Falseで却下ルールが偽を見逃す recall 退行」は発生せず**(巧妙な偽20件でも Critic が有効反論を出し検証通過→20/20 FLAG)。

**Stage3+ (recall 退行ストレステスト, hard-false 18件):**

「両/全reviewerが揃って見逃す巧妙な偽」で v1.3 の却下ルールが recall を落とすかを敵対的に検証(版依存/誤数値/直感に反する罠)。

| パネル | v1.2 recall | v1.3 recall | 退行 |
|---|:-:|:-:|---|
| 強reviewer単独 (Codex gpt-5.5, n=17 False) | 17/17 = 100% | 17/17 = 100% | **0件** |
| 弱reviewer単独 (Haiku, web無, n=17) | 11/17 = 64.7% | 10/17 = 58.8% | **1件(HF4)** |

**結論: v1.3 の recall 退行は実在するが「誤論証による偶然の捕捉(lucky catch)」を捨てる範囲に限定**。退行したHF4は弱reviewerが*事実誤認の反論*でたまたまFLAGしたケースで、v1.3はそれを却下=信用すべきでない捕捉を捨てただけ。**正しく論証された捕捉は一度も失わない(10/10維持)**。強fact-checkerを1体入れれば退行ゼロ。なお blind grader は生成器の誤ラベル(HF13)を自力検出・訂正=独立検証が機能。

> ⚠️ **まだ実運用精度の証明ではない**。(1)**recall 退行は条件付きで実在**: *主張が偽 かつ 生き残る反論が全て誤論証* のとき v1.3<v1.2(弱panel単独で実証)。強reviewer込みなら消える。(2)真の第4ベンダー **grok は xAI クレジット枯渇で未投入**(要課金補充)→4社独立は未達、grader等は Claude family。(3)Gemini クォータ枯渇で2社攻撃が取れず一部 Codex/Claude 単独。(4)Grey 12件は ground truth 係争的で clean metrics から除外。(5)コードPR/SWE・人間採点は未実施。詳細と再現: [n=53](https://github.com/AI-Driven-School/aiki/blob/main/benchmarks/stage3-v13-debate-n53.md) / [PoC](https://github.com/AI-Driven-School/aiki/blob/main/benchmarks/stage3-v13-precision-poc.md) / [recall退行](https://github.com/AI-Driven-School/aiki/blob/main/benchmarks/stage3plus-v13-recall-stress.md)。

## 実例

claude-codex-collab repo の case study参照:
[Real-world Case: 1ジョブで法律解釈の事実誤認を検出](https://github.com/AI-Driven-School/aiki/blob/main/docs/examples/multi-agent-debate-case-study.md)

## /project との関係

- `/project` skill §9.1 と機能重複あり、本 skill は**独立利用版**
- `/project` 内では §9.1 として組込発動
- 単独主張・実装・判断のレビューは本 skill を直接呼ぶ方が軽量
