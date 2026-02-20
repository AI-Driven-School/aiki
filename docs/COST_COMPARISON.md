# Cost Comparison: 4-AI Collaboration vs Single AI

## TL;DR

| Approach | Monthly Cost | Speed | Documentation |
|----------|:-----------:|:-----:|:------------:|
| Claude only | ~$100-200 | 1x | Manual |
| **4-AI Collab** | **~$25-50** | **2x** | **Auto-generated** |

---

## How It Works

```
Single AI (Claude only)          4-AI Collaboration
─────────────────────            ─────────────────────
Design    → Claude ($)           Design    → Claude ($)
Implement → Claude ($$)          Implement → Codex ($0) ★
Test      → Claude ($$)          Test      → Codex ($0) ★
Review    → Claude ($)           Review    → Claude ($)
Research  → Claude ($)           Research  → Gemini ($0) ★

Total: $$$$$                     Total: $$
```

**Key insight:** Implementation and testing account for 60-70% of AI token usage. By delegating these to Codex (included in ChatGPT Pro subscription), you eliminate the majority of per-token costs.

---

## Cost Per AI

| AI | Pricing Model | Cost for This Workflow | Required |
|----|--------------|----------------------|:--------:|
| Claude Code | Pay-per-token (API) | ~$0.01-0.05 per task | Yes |
| Codex CLI | ChatGPT Pro ($200/mo) | $0 incremental | No* |
| Gemini CLI | Free tier | $0 | No* |

*\*Optional. The project works with Claude only (`--claude-only` mode).*

---

## Real-World Cost Breakdown

### Example: User Authentication Feature

| Phase | Single AI (Claude) | 4-AI Collaboration |
|-------|:-----------------:|:------------------:|
| Requirements | ~$0.03 | ~$0.03 (Claude) |
| API Design | ~$0.05 | ~$0.05 (Claude) |
| Implementation (5 files) | ~$0.40 | $0 (Codex) |
| Test Generation (3 files) | ~$0.25 | $0 (Codex) |
| Code Review | ~$0.05 | ~$0.05 (Claude) |
| Research (auth libraries) | ~$0.10 | $0 (Gemini) |
| **Total** | **~$0.88** | **~$0.13** |
| **Savings** | — | **85%** |

### Example: Dashboard with Charts

| Phase | Single AI (Claude) | 4-AI Collaboration |
|-------|:-----------------:|:------------------:|
| Requirements | ~$0.04 | ~$0.04 (Claude) |
| UI Spec | ~$0.06 | ~$0.06 (Claude) |
| Implementation (8 files) | ~$0.65 | $0 (Codex) |
| Test Generation (5 files) | ~$0.40 | $0 (Codex) |
| Code Review | ~$0.08 | ~$0.08 (Claude) |
| **Total** | **~$1.23** | **~$0.18** |
| **Savings** | — | **85%** |

### Example: Full-Stack CRUD API

| Phase | Single AI (Claude) | 4-AI Collaboration |
|-------|:-----------------:|:------------------:|
| Requirements | ~$0.05 | ~$0.05 (Claude) |
| API Design | ~$0.08 | ~$0.08 (Claude) |
| Implementation (12 files) | ~$1.20 | $0 (Codex) |
| Test Generation (8 files) | ~$0.80 | $0 (Codex) |
| Code Review | ~$0.10 | ~$0.10 (Claude) |
| **Total** | **~$2.23** | **~$0.23** |
| **Savings** | — | **90%** |

---

## Monthly Estimates

### Solo Developer (20 features/month)

| Metric | Claude Only | 4-AI Collab |
|--------|:----------:|:----------:|
| Claude API cost | ~$20-40 | ~$4-8 |
| ChatGPT Pro | $0 | $200 (shared) |
| Gemini | $0 | $0 |
| **Effective AI cost** | **$20-40** | **$4-8** |

> **Note:** ChatGPT Pro ($200/mo) is likely already part of your existing subscription. The incremental cost of using Codex CLI for this workflow is $0.

### Team of 5 (100 features/month)

| Metric | Claude Only | 4-AI Collab |
|--------|:----------:|:----------:|
| Claude API cost | ~$100-200 | ~$20-40 |
| ChatGPT Pro | $0 | $200 (shared) |
| Gemini | $0 | $0 |
| **Effective AI cost** | **$100-200** | **$20-40** |

---

## Speed Comparison

Based on our [benchmarks](../benchmarks/BENCHMARK_RESULTS.md):

| Task Type | Claude | Codex | Gemini | Winner |
|-----------|:------:|:-----:|:------:|:------:|
| New file creation | 24.8s | **21.8s** | — | Codex (12% faster) |
| Existing code edit | **15.2s** | 25.1s | — | Claude (40% faster) |
| Large codebase analysis | — | — | **45s** | Gemini (1M tokens) |
| Test generation | 30.1s | **22.4s** | — | Codex (25% faster) |

**Combined throughput:** By running Codex implementation in parallel with Claude review, overall feature delivery is ~2x faster.

---

## Adoption Paths

Start small and scale up:

| Mode | Cost | Best For |
|------|------|----------|
| `--claude-only` | Claude API only | Getting started, small projects |
| `--claude-codex` | Claude + ChatGPT Pro | Implementation-heavy projects |
| `--claude-gemini` | Claude + Free Gemini | Research-heavy projects |
| `--full` (default) | All 3 AIs | Maximum savings & speed |

```bash
# Start with Claude only (zero additional cost)
bash install-fullstack.sh my-app --claude-only

# Upgrade to full 4-AI when ready
bash install-fullstack.sh my-app --full
```

---

## FAQ

**Q: Do I need ChatGPT Pro ($200/month) just for this?**
A: No. If you already have ChatGPT Pro, Codex CLI is included at no extra cost. If not, start with `--claude-only` mode.

**Q: What if I don't have Gemini CLI?**
A: Gemini is optional. Research tasks will fall back to Claude. Install Gemini CLI anytime for free.

**Q: How accurate are these cost estimates?**
A: Estimates are based on Claude API pricing as of 2025. Actual costs vary by model version and task complexity. See our [benchmark data](../benchmarks/BENCHMARK_RESULTS.md) for measured results.

**Q: Can I use local models instead of cloud APIs?**
A: Yes! Use `--provider ollama` with delegate.sh to route tasks to local models via Ollama. See [Getting Started](./GETTING_STARTED.md) for setup.
