# Stage 3 ベンチマーク設計 (n=100)

> 設計日: 2026-05-08
> 目的: 統計的有意性確保 + 商用ツール直接比較 + 公開ベンチ部分実走
> 想定期間: 2-3日（実走部分のみ、設計は本書）

## Stage 2 から見えた課題と対応

| 課題 | 対応 (Stage 3 で実装) |
|---|---|
| n=30 で信頼区間 ±5-10pp 広い | **n=100 まで拡大** (+70件追加) |
| Self-evaluation bias (κ=0.534 moderate) | 採点者を **Agent (general-purpose) 専従**に固定、Self比較を独立報告 |
| reviewer の「常に何か反論する」傾向 (True 0%通過) | プロンプト改訂: **「反論なき場合はverbatimで '反論なし' と書け」を強調**、複数回 emphasize |
| 商用ツール (Greptile/PR-Agent) と土俵違い | **コード変更系主張 30件**を追加、PR diff 形式と並行評価 |
| Codex 内蔵 web_search が Checker と重複 | **Codex に `--no-web-search`相当の prompt 制約**を入れる |
| SWE-Bench フル評価していない | **n=10 まで拡大**、Docker 評価可能なら実テスト pass 率も |

## サンプル構成 (n=100)

| カテゴリ | 件数 | 用途 |
|---|:-:|---|
| **False (自然言語論述)** | 40件 | Recall 計測 (Stage 2 の F1-F18 を含む拡張) |
| **True (自然言語論述)** | 15件 | Precision 計測 (Stage 2 の T1-T5 を含む拡張) |
| **Grey (自然言語論述)** | 15件 | Reviewer 一致度・debate 機能性計測 |
| **コード変更系 False** | 20件 | PR-Agent 直接比較対象 |
| **コード変更系 True** | 5件 | PR-Agent precision 比較対象 |
| **SWE-Bench Lite 抽出** | 5件 | 公開ベンチ実走、leaderboard 数値と相対比較 |
| **合計** | **100件** | - |

## 新規追加すべき主張 (70件)

### False 自然言語 (+22件、F19-F40)

| # | テーマ |
|---|---|
| F19 | Cloudflare R2 は完全無料 (実は10GB/月超で課金) |
| F20 | Bun と Node.js のパフォーマンス差は無視できる |
| F21 | Rust より Go の方が常にメモリ効率良い |
| F22 | Postgres と MySQL は性能差ほぼなし |
| F23 | Vercel の Edge Functions は無制限 region |
| F24 | npm install -g は sudo 不要 |
| F25 | Docker on Mac は Linux と性能同等 |
| F26 | Claude Sonnet で SWE-Bench 90%超 |
| F27 | OAuth 2.0 と OpenID Connect は同じもの |
| F28 | HTTPS だけで CSRF 攻撃を防げる |
| F29 | bcrypt より argon2 は古い |
| F30 | Redis は memcached より遅い |
| F31 | Tailwind v4 は v3 と互換性100% |
| F32 | Next.js App Router で getServerSideProps が使える |
| F33 | TypeScript は実行時型チェックを行う |
| F34 | Cloudflare Workers は Node.js API 全対応 |
| F35 | GitHub Free private repo は無制限ストレージ |
| F36 | yarn と npm の lock ファイルは互換 |
| F37 | Stripe Connect は手数料0% |
| F38 | Sentry の error tracking は無料無制限 |
| F39 | AWS S3 は egress 完全無料 |
| F40 | Anthropic API は GPT-5.5 互換 |

### True 自然言語 (+10件、T6-T15)

| # | テーマ (公式ドキュメント裏取り済) |
|---|---|
| T6 | OpenAI Codex CLI 0.129.0 で gpt-5.5 動作確認 (本日確認済) |
| T7 | Anthropic Mythos Preview は Project Glasswing 招待制 (公式声明) |
| T8 | METR HCAST は 2026-01 に 170→228 タスク拡張 |
| T9 | Cloudflare Workers Free は 100k req/day, 10ms CPU |
| T10 | bcrypt の cost factor 12 は 2025年推奨 (OWASP) |
| T11 | TypeScript strict は noImplicitAny + strictNullChecks 等の集合 |
| T12 | Next.js 16 は React 19 を要求 |
| T13 | npm view で package 最新バージョン確認可能 |
| T14 | Bun の package install は npm より高速 (公式ベンチ) |
| T15 | Vercel pricing は Active CPU + Provisioned Memory + Invocations |

### Grey 自然言語 (+8件、G8-G15)

| # | テーマ |
|---|---|
| G8 | TypeScript より Rust が常に良い |
| G9 | モノレポ vs マルチレポ、規模問わずモノレポが良い |
| G10 | Server Components は Client Components より常に高速 |
| G11 | tRPC は GraphQL より優れている |
| G12 | Prisma は Drizzle ORM より優れている |
| G13 | テストカバレッジ 80% を超えるべきだ |
| G14 | デザインシステムは 2人チームでも構築すべき |
| G15 | Bun は本番環境で使うべきではない |

### コード変更系 False (+20件、CF1-CF20)

各 PR diff 形式 (実 GitHub PR or fake PR で作成):

| # | テーマ |
|---|---|
| CF1 | `eval(userInput)` を使った PR を「安全」と主張 |
| CF2 | `<div dangerouslySetInnerHTML={{ __html: userContent }} />` を「XSS耐性あり」 |
| CF3 | SQL: `db.query("SELECT * FROM users WHERE id=" + req.body.id)` を「安全」 |
| CF4 | `password === md5(input)` で「セキュア」 |
| CF5 | Migration: `ALTER TABLE users DROP COLUMN email` をrevertableと主張 |
| CF6 | `git push --force origin main` を CI で実行 |
| CF7 | `process.env.SECRET` を console.log |
| CF8 | `for (var i...)` のクロージャバグを「正常動作」と主張 |
| CF9 | React `useEffect` 依存配列空で外部state参照を「正常」 |
| CF10 | `setTimeout(() => state++, 0)` を React で正しいstate更新 |
| CF11 | `JSON.parse(localStorage.getItem('x'))` を try-catch なしで OK |
| CF12 | `await Promise.all(users.map(u => slowFetch(u)))` を「N+1問題なし」 |
| CF13 | `app.use(cors())` 全 origin 許可を「セキュア」 |
| CF14 | Cookie httpOnly 無しで JWT 保存「OK」 |
| CF15 | Express raw body parser で巨大 payload 制限なし「OK」 |
| CF16 | Docker `USER root` のまま production 「問題なし」 |
| CF17 | `package.json` で latest tag 全 deps「再現性あり」 |
| CF18 | `.env` を `.gitignore` に入れない |
| CF19 | `npm audit` 警告無視「リスクなし」 |
| CF20 | TypeScript `as any` キャストを「型安全」 |

### コード変更系 True (+5件、CT1-CT5)

| # | テーマ (実装が正しい主張) |
|---|---|
| CT1 | `const x = useMemo(() => expensive(), [dep])` で正しく memoize |
| CT2 | `try { await fetch(...) } catch (e) { logger.error(e); throw e; }` でエラー透過 |
| CT3 | `db.query('SELECT * FROM users WHERE id = $1', [req.body.id])` parameterized で安全 |
| CT4 | `bcrypt.hash(password, 12)` で 2025推奨設定 |
| CT5 | `Object.freeze(config)` で immutable |

### SWE-Bench Lite 抽出 (+5件、SB1-SB5)

| # | instance_id (Stage 2 で実行済の3件 + 新規2件) |
|---|---|
| SB1 | astropy__astropy-12907 ✅ 完全一致済 |
| SB2 | astropy__astropy-14182 ✗ 失敗済 |
| SB3 | astropy__astropy-14365 ✅ 完全一致済 |
| SB4 | (新規抽出予定) |
| SB5 | (新規抽出予定) |

## 実走プロトコル

### Step 1: 主張ファイル作成 (70件 + 既存30件)
- `~/aiki-projects/benchmarks/stage3/claims/` 配下に各 .md
- ground truth と sources をメタデータに記録

### Step 2: Reviewer プロンプト改訂

```
あなたは Multi-Agent Debate の {Proposer|Critic} です。
Solver 主張に対して反論してください。

**重要**: Solver が完全に正しい場合は、verbatim で次の通り出力:
「結論: Solver主張は妥当。反論なし。」
これ以外は反論ポイント1-3を出力。

タスク:
1) 論理的な穴・事実誤認・過度の一般化を探す
2) 一次情報・統計を用いて反証材料を提示
3) 上記2つで何も見つからなければ「反論なし」と明記

形式: 結論 (Solver主張は妥当 / 部分的に誤り / 致命的に誤り) + 反論ポイント1-3 (反論ない場合は省略可)
```

### Step 3: 並列実走

```bash
for cid in F1..F40 T1..T15 G1..G15 CF1..CF20 CT1..CT5 SB1..SB5; do
  cat claims/$cid.md | gemini -p "$PROPOSER_PROMPT" --yolo > rebuttals/$cid-gemini.md &
  cat claims/$cid.md | codex exec -m gpt-5.5 --skip-git-repo-check "$CRITIC_PROMPT" > rebuttals/$cid-codex.md &
  # 並列度上限 4 (yu01環境)
done
```

時間見積:
- 70件 × (Gemini 60秒 + Codex 180秒) = 70 × 240秒 = 280分 = **4-5時間**
- 4並列なら 70 × 240 / 4 = 70分 = **1.2時間**

### Step 4: コード変更系の PR-Agent 評価

```bash
# 25件 (CF20 + CT5) を fake PR として GitHub に作成
# PR-Agent self-hosted で review
# 結果を抽出
```

### Step 5: SWE-Bench Lite 5件で Codex 評価
Stage 2 で 3件実走済、+2件追加で n=5 確保。

### Step 6: 採点 (独立 Agent)
全100件の rebuttal を 1 Agent (general-purpose) に投げて verdict 抽出。

### Step 7: 集計と業界比較

| Metric | 自然言語 (n=70) | コードPR (n=25) | SWE-Bench (n=5) |
|---|:-:|:-:|:-:|
| Recall | ? | ? | ? |
| Precision | ? | ? | ? |
| F1 | ? | ? | ? |
| vs PR-Agent (同主張) | — | **直接比較** | — |
| vs SWE-Bench Verified leaderboard | — | — | **公開数値と並べる** |

## 統計的有意性

n=100 (False 60 + True 20 + Grey 15 + SWE 5) なら:
- Recall 推定の標準誤差 ≈ ±5pp (95% CI)
- Precision 推定の標準誤差 ≈ ±10pp
- 「Greptile 82% を有意に上回る」を主張するには Recall ≥ 90% が必要 (n=60で SE ±5pp)

## 公開計画

Stage 3 完走時:
1. claude-codex-collab repo に `benchmarks/stage3-debate-n100.md` 追加
2. Hacker News / Reddit r/MachineLearning で結果共有
3. X 長文記事「Multi-Agent Debate の n=100 ベンチで分かったこと」
4. 軽量公開ベンチ実装を Pip/npm で配布検討

## 撤退基準

- Recall < 85% (Stage 2 の100% から大幅低下) → 設計見直し
- κ < 0.4 (採点者間一致 fair未満) → 採点プロトコル全面再設計
- コード変更系で PR-Agent と差がない → 「自然言語論述」領域に絞る判断

## 副次目標

- aiki repo の README / 公式 docs に Stage 3 結果を反映
- Anthropic Project Glasswing 招待を狙う材料 (公開実績)
- AI駆動開発エンジニア案件への営業材料
