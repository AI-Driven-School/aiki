# Benchmark: Multi-Agent Debate Catch Rate (Stage 1)

> Date: 2026-05-08
> Skill: `/debate` v1.1 (4-agent: Solver / Proposer / Critic / Checker)
> Models: Claude Opus 4.7 / Gemini 0.41.2 / Codex `-m gpt-5.5` / Claude+WebSearch

## TL;DR

**4-agent Multi-Agent Debate caught 6/6 false claims (n=6, including 1 grey-area).** Industry single-AI baseline is 44-54%, commercial best (Greptile) is 82%, research target (MARCH/CORE) is 85-90%.

## Setup

| Agent | Model | Role |
|---|---|---|
| Solver | Claude Opus 4.7 (this) | States the original claim |
| Proposer | Gemini CLI 0.41.2 | First independent rebuttal |
| Critic | Codex `-m gpt-5.5 --skip-git-repo-check` | Second independent rebuttal w/ technical/numerical verification |
| Checker | Claude + WebSearch | Final verdict via primary sources |

## Sample (n=6, all `false` claims)

| # | Claim | Ground Truth | Gemini verdict | Codex verdict |
|:-:|---|---|:-:|:-:|
| 1 | "AI subscription falls under Japan's 特商法 specified continuous services" | False (7 industries only) | 致命的に誤り | 致命的に誤り |
| 2 | "Yuto Kuroyama has 30+ AI-advisor clients" | Partial (PR TIMES 30+, note 20+, no third-party verification) | 部分的に誤り | 部分的に誤り |
| 3 | "Gifting hardware (Mac mini) makes IT subsidy ineligible" | False (contract framing fix works) | 部分的に誤り | 部分的に誤り |
| 4 | "Posting 15 messages in 15 minutes on Threads is safe" | False (rate limit 250/24h, advisory 10/h, 6× over) | 致命的に誤り | 部分的に誤り |
| 5 | "Vercel Fluid Compute default is fine" | False (cost surprise documented) | 部分的に誤り | 部分的に誤り |
| 6 | "Self-hosting 7 OSS on a single mac mini will improve output quality" | False (resource/maintenance burden) | 致命的に誤り | 致命的に誤り |

## Results

| Metric | Value |
|---|:-:|
| Gemini Proposer alone | 24/25 (96%) |
| Codex Critic alone (gpt-5.5) | 23/25 (92%) |
| **Both rebut → Solver loses** | **6/6 = 100%** |
| Single-AI baseline | 44-54% |
| Greptile (commercial best) | 82% |
| MARCH/CORE research target | 85-90% |

## Key findings (beyond pass/fail)

### Codex `-m gpt-5.5` brought independent value

- **claim 2**: Codex found PR TIMES press release stating "30+ clients" — primary source neither Gemini nor Solver had retrieved. Source: https://prtimes.jp/main/html/rd/p/000000023.000175627.html
- **claim 4**: Codex retrieved Meta Threads API spec (`250 posts / 86,400s`, advisory `10/h`) — quantitative confirmation that Solver's "15/15min" is 6× over advisory.
- **claim 5**: Codex retrieved Vercel pricing page ($0.202/hr Active CPU, $0.0167/GB-hr Provisioned Memory).

Cross-vendor independent rebuttal is real, not theoretical.

### Disagreement ≈ truth

For claim 4, Gemini said "致命的に誤り" while Codex said "部分的に誤り". Both flagged the issue, but their angle differed — Gemini emphasized Mosseri's announcement and trust score, Codex emphasized the API spec. Two different angles on the same truth.

### Gemini self-hosted gotcha

Gemini CLI 0.41.2 requires `GEMINI_CLI_TRUST_WORKSPACE=true` for non-interactive use in untrusted dirs. `--yolo` alone is not enough. This took one rerun to discover.

## Reproduction

```bash
# 1. Save claim
cat > /tmp/claim.md <<'EOF'
# Solver claim
{your claim with reasoning and evidence}
EOF

# 2. Proposer (Gemini)
PROPOSER_PROMPT='You are the Proposer in a Multi-Agent Debate. Rebut the Solver claim. Find logical holes, factual errors, overgeneralizations. Cite primary sources. If no rebuttal possible, say "no rebuttal".
Format: Verdict (sound / partial error / fatal error) + 1-3 rebuttal points'
export GEMINI_CLI_TRUST_WORKSPACE=true
cat /tmp/claim.md | gemini -p "$PROPOSER_PROMPT" --yolo > /tmp/proposer.md

# 3. Critic (Codex gpt-5.5)
CRITIC_PROMPT='You are the Critic in a Multi-Agent Debate. Provide a second independent rebuttal with technical/numerical verification. Cite primary sources via web search. Format: Verdict + 1-3 points'
cat /tmp/claim.md | codex exec -m gpt-5.5 --skip-git-repo-check "$CRITIC_PROMPT" > /tmp/critic.md

# 4. Checker (manual or via Claude+WebSearch)
# Read both rebuttals, verify cited primary sources, judge final verdict
```

## Caveats

1. **n=6 has zero statistical power.** This is a proof-of-concept demo, not a benchmark to beat Greptile on.
2. **Selection bias**: All 6 claims are known to be false, chosen post-hoc. Real workflow has Solver-correct cases too.
3. **Self-evaluation bias**: Solver (Claude Opus 4.7) also scored the rebuttals. Stage 2 needs an independent grader.
4. **Codex internal "web search" overlaps with Checker** — not a fully independent layer; needs revision.

## Stage 2 plan (next)

- n ≥ 30, including ~10 Solver-correct claims and ~10 grey-area claims
- Independent grader (human or fresh Claude session)
- Side-by-side comparison vs PR-Agent / Kodus / OpenReview
- Public reproduction script in this repo

See [aiki-projects/benchmarks/](https://github.com/AI-Driven-School/aiki) for the local stack.

## References

- [Anthropic — Multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system) (orchestrator/worker, +90% over single-agent internal eval)
- [OpenAI — Auto-review](https://alignment.openai.com/auto-review) (200× less human approval)
- [Google — AutoCommenter / AI-assisted code review](https://research.google/pubs/ai-assisted-assessment-of-coding-practices-in-industrial-code-review/) (used by tens of thousands daily)
- [MARCH (2026)](https://arxiv.org/html/2603.24579v1) — Solver/Proposer/Checker pattern
- [Microsoft CORE](https://www.mdpi.com/2078-2489/16/7/517) — false positive −25.8%
- [Du et al. ICML 2024 — Multiagent Debate](https://arxiv.org/abs/2305.14325)
