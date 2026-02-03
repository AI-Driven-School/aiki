# 2x Faster Implementation, 75% Cost Reduction

[![GitHub Sponsors](https://img.shields.io/github/sponsors/AI-Driven-School?style=for-the-badge&logo=github&label=Sponsor)](https://github.com/sponsors/AI-Driven-School)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](LICENSE)
[![Phase](https://img.shields.io/badge/Phase_1-Free-22c55e?style=for-the-badge)](https://github.com/AI-Driven-School/claude-codex-collab)

<p align="center">
  <img src="./landing/promo.gif" alt="3AI Collaborative Development Demo" width="700">
</p>

<p align="center">
  Design with <strong>Claude</strong>, implement at speed with <strong>Codex</strong>, analyze at scale with <strong>Gemini</strong><br>
  A 3-AI division of labor workflow that leaves design docs even for solo developers
</p>

<p align="center">
  <a href="./README_ja.md">日本語</a>
</p>

---

## Get Started in 30 Seconds

```bash
# 1. Install
curl -fsSL https://raw.githubusercontent.com/AI-Driven-School/claude-codex-collab/main/install-fullstack.sh | bash -s -- my-app

# 2. Start developing
cd my-app && claude

# 3. Build a feature
> /project user authentication
```

**Requirements:**
| AI | Role | Cost |
|----|------|------|
| Claude Code | Design & Review | Pay-per-use |
| Codex (ChatGPT Pro) | Implementation & Testing | Included in subscription |
| Gemini CLI | Large-scale analysis | Free |

---

## Why 3 AIs?

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│   Single AI             3-AI Collaboration                  │
│   ─────────             ──────────────────                  │
│   Claude only           Claude → Design & decisions only    │
│   = Everything billed      ↓                                │
│   = High cost           Codex → Implementation & tests ($0) │
│                            ↓                                │
│                         Claude → Review                     │
│                                                             │
│   Result: $1.00         Result: $0.25 (75% reduction)       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Benchmark Results

| Task Type | Winner | Reason |
|-----------|--------|--------|
| New file creation | **Codex** | 10-20% faster, $0 |
| Existing code modification | **Claude** | 40% faster, 2x quality |
| Large-scale analysis | **Gemini** | 1M tokens, free |

> [Detailed benchmark results](./benchmarks/BENCHMARK_RESULTS.md)

---

## Workflow

```
> /project user authentication

[1/6] Requirements  (Claude)  → docs/requirements/auth.md  ✓
[2/6] API Design    (Claude)  → docs/api/auth.yaml         ✓
[3/6] Implementation(Codex)   → src/**/*.tsx               ★ full-auto
[4/6] Testing       (Codex)   → tests/*.spec.ts            ★ $0
[5/6] Review        (Claude)  → Improvement suggestions    ✓
[6/6] Deploy                  → https://my-app.vercel.app  ✓
```

### Output

```
my-app/
├── docs/
│   ├── requirements/   # Requirements (Claude)
│   ├── specs/          # UI specs (Claude)
│   └── api/            # API design (Claude)
├── src/                # Implementation (Codex)
└── tests/              # Tests (Codex)
```

**Even solo developers get comprehensive design documentation.**

---

## Case Study: StressAIAgent

A real SaaS built with this template:

### AI-Powered Mental Health SaaS

```
/project organization analysis AI
```

| Phase | AI | Output |
|-------|:--:|--------|
| Requirements | Claude | `docs/requirements/org-analysis-ai.md` |
| API Design | Claude | `docs/api/org-analysis.yaml` |
| UI Specs | Claude | `docs/specs/org-analysis-ai.md` |
| Implementation | **Codex** | Backend + Frontend |
| Testing | **Codex** | 10 E2E test cases |
| Review | Claude | `docs/reviews/org-analysis-ai.md` |

### Generated Features

- Organization-wide stress analysis dashboard
- Department score heatmap
- **GPT-4 powered AI insights generation**
- PDF report export
- Admin permission checks

> [Source code](./benchmarks/complex-test/)

---

## Commands

| Command | AI | Description |
|---------|-----|-------------|
| `/project <feature>` | All | Complete flow: design → implementation → deploy |
| `/requirements <feature>` | Claude | Generate requirements |
| `/spec <screen>` | Claude | Generate UI specifications |
| `/api <endpoint>` | Claude | Generate API design |
| `/implement` | Codex | Implement from design docs |
| `/test` | Codex | Generate tests |
| `/review` | Claude | Code review |
| `/analyze` | Gemini | Large-scale code analysis |
| `/research <query>` | Gemini | Technical research |

---

## Auto-Orchestration (MCP Server)

**NEW:** Talk naturally to Claude, and tasks are automatically delegated to the right AI.

```
You: "Implement user authentication"
→ Automatically delegated to Codex (implementation specialist)

You: "Compare React vs Vue"
→ Automatically delegated to Gemini (research specialist)

You: "Review my code"
→ Handled by Claude (design & review specialist)
```

### Setup

```bash
# Install and configure MCP server
./scripts/setup-mcp.sh

# Restart Claude Code
```

**No API keys needed** - Uses CLI tools (Codex CLI from ChatGPT Pro, Gemini CLI free).

### Available MCP Tools

| Tool | Description |
|------|-------------|
| `delegate_to_codex` | Send implementation tasks to Codex |
| `delegate_to_gemini` | Send research/analysis to Gemini |
| `auto_delegate` | Automatically route to the right AI |
| `get_orchestration_status` | Check AI service status |

> See [MCP Server README](.claude/mcp-servers/ai-orchestrator/README.md) for details

---

## System Requirements

- macOS / Linux / WSL2
- Node.js 18+
- ChatGPT Pro (for Codex CLI, $200/month)
- Gemini CLI (free, optional for research tasks)

---

## Documentation

| Document | Description |
|----------|-------------|
| [Getting Started](./docs/GETTING_STARTED.md) | Installation & setup |
| [Hands-on Tutorial](./docs/HANDS_ON_TUTORIAL.md) | Build a TODO app step by step |
| [Existing Project Setup](./docs/EXISTING_PROJECT_SETUP.md) | Add to existing projects |
| [Command Reference](./docs/COMMANDS.md) | Complete command reference |
| [Benchmarks](./benchmarks/BENCHMARK_RESULTS.md) | Detailed benchmark data |

---

## Support

Phase 1 is completely free. If you'd like to support development:

[![GitHub Sponsors](https://img.shields.io/github/sponsors/AI-Driven-School?style=for-the-badge&logo=github&label=Sponsor)](https://github.com/sponsors/AI-Driven-School)

---

<p align="center">
  MIT License<br>
  <a href="https://github.com/AI-Driven-School/claude-codex-collab">GitHub</a> ·
  <a href="https://github.com/AI-Driven-School/claude-codex-collab/issues">Issues</a> ·
  <a href="https://github.com/sponsors/AI-Driven-School">Sponsor</a>
</p>
