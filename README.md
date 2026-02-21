# 2x Faster Implementation, 75% Cost Reduction

[![GitHub Stars](https://img.shields.io/github/stars/AI-Driven-School/aiki?style=for-the-badge&logo=github&label=Stars)](https://github.com/AI-Driven-School/aiki/stargazers)
[![npm](https://img.shields.io/npm/v/aiki?style=for-the-badge&logo=npm)](https://www.npmjs.com/package/aiki)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](LICENSE)
[![GitHub Sponsors](https://img.shields.io/github/sponsors/AI-Driven-School?style=for-the-badge&logo=github&label=Sponsor)](https://github.com/sponsors/AI-Driven-School)

<p align="center">
  <img src="./landing/promo.gif" alt="4AI Collaborative Development Demo" width="700">
</p>

<p align="center">
  Design with <strong>Claude</strong>, implement at speed with <strong>Codex</strong>, analyze at scale with <strong>Gemini</strong>, track trends with <strong>Grok</strong><br>
  A 4-AI division of labor workflow that leaves design docs even for solo developers
</p>

<p align="center">
  <a href="./README_ja.md">日本語</a> · If this project helps you, please <a href="https://github.com/AI-Driven-School/aiki/stargazers">give it a star</a>
</p>

---

## Get Started in 30 Seconds

```bash
# Option A: npx (recommended)
npx aiki init my-app

# Option B: curl
curl -fsSL https://raw.githubusercontent.com/AI-Driven-School/aiki/main/install-fullstack.sh | bash -s -- my-app

# Then start developing
cd my-app && claude

# Build a feature
> /project user authentication
```

**Requirements:**
| AI | Role | Cost |
|----|------|------|
| Claude Code | Design & Review | Pay-per-use |
| Codex (ChatGPT Pro) | Implementation & Testing | Included in subscription |
| Gemini CLI | Large-scale analysis | Free |
| Grok (xAI) | Real-time trends & X search | xAI API |

---

## Why 4 AIs?

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│   Single AI             4-AI Collaboration                  │
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
| Real-time trends | **Grok** | Live X data, xAI API |

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
| `/x-trend-research` | Grok | X trend search |
| `/x-context-research` | Grok | Context pack for article writing |

---

## Claude Code Skills (13 Skills Included)

This project ships with 13 ready-to-use [Agent Skills](https://agentskills.io) for Claude Code.

### Install Skills

```bash
# Using Vercel skills CLI
npx skills add AI-Driven-School/aiki

# Or clone and use directly
git clone https://github.com/AI-Driven-School/aiki.git
cd aiki && claude
```

### Available Skills

| Skill | AI | Description |
|-------|:--:|-------------|
| `/project` | All | Full design-to-deploy pipeline (6 phases) |
| `/requirements` | Claude | Generate requirements with user stories & acceptance criteria |
| `/spec` | Claude | Generate UI screen design documents |
| `/api` | Claude | Generate OpenAPI 3.0 specifications |
| `/implement` | Codex | Auto-generate code from design docs |
| `/test` | Codex | Generate E2E & unit tests from requirements |
| `/review` | Claude | Code review against design documents |
| `/analyze` | Gemini | Full codebase analysis (1M token context) |
| `/research` | Gemini | Technical research with comparison reports |
| `/frontend-design` | Claude | Production-grade UI without generic AI aesthetics |
| `/mockup` | Claude | Generate UI mockup PNGs via Playwright |
| `/mockup-swift` | Claude | Native iOS/macOS mockups via SwiftUI Preview |
| `/checkpointing` | Claude | Save & restore session state across sessions |

All skills follow the [Agent Skills open standard](https://agentskills.io/specification) and work with Claude Code, Codex CLI, OpenCode, Cursor, and other compatible agents.

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

## Adoption Paths

Start small and add AIs as needed:

| Mode | Command | AIs | Best for |
|------|---------|-----|----------|
| Claude only | `--claude-only` | Claude | Getting started, small projects |
| Claude + Codex | `--claude-codex` | Claude, Codex | Implementation-heavy projects |
| Claude + Gemini | `--claude-gemini` | Claude, Gemini | Research-heavy projects |
| Full (default) | `--full` | All 4 | Maximum productivity |

```bash
# Start with Claude only
bash install-fullstack.sh my-app --claude-only

# Later, upgrade to full 4-AI
bash install-fullstack.sh my-app --full
```

---

## Compatibility

### AI CLI Support

| Tool | Min Version | Max Tested | Required |
|------|:-----------:|:----------:|:--------:|
| Claude Code | 1.0.0 | 2.1.49 | Yes |
| Codex CLI | 0.1.0 | 0.93.0 | No |
| Gemini CLI | 0.1.0 | 0.26.0 | No |
| Ollama | 0.1.0 | — | No |

Version compatibility is automatically checked during installation and delegation. See `.ai-versions.json` for details.

### IDE & Agent Support

| Tool | Support | Notes |
|------|:-------:|-------|
| Claude Code | Native | Full skills, hooks, and delegation |
| Codex CLI | Native | Via AGENTS.md and delegation scripts |
| [OpenCode](https://github.com/sst/opencode) | Compatible | Reads AGENTS.md and .claude/skills/ natively |
| Cursor | Compatible | Via .cursor/rules/ templates |
| VS Code | Tasks | Via templates/vscode-tasks.json |

> See [OpenCode Compatibility](./docs/OPENCODE_COMPATIBILITY.md) for details.

### Local Model Support

Run the entire pipeline offline with [Ollama](https://ollama.ai):

```bash
# Code generation with local model
bash scripts/delegate.sh ollama generate "Create a REST API"

# Code review with local model
bash scripts/delegate.sh ollama review src/ --model deepseek-coder
```

---

## System Requirements

- macOS / Linux / WSL2
- Node.js 18+
- ChatGPT Pro (for Codex CLI, $200/month) - optional with `--claude-only` mode
- Gemini CLI (free, optional for research tasks)

---

## Documentation

| Document | Description |
|----------|-------------|
| [Getting Started](./docs/GETTING_STARTED.md) | Installation & setup |
| [Hands-on Tutorial](./docs/HANDS_ON_TUTORIAL.md) | Build a TODO app step by step |
| [Existing Project Setup](./docs/EXISTING_PROJECT_SETUP.md) | Add to existing projects |
| [Cost Comparison](./docs/COST_COMPARISON.md) | Detailed cost analysis: 4-AI vs single AI |
| [OpenCode Compatibility](./docs/OPENCODE_COMPATIBILITY.md) | Using with OpenCode CLI |
| [Command Reference](./docs/COMMANDS.md) | Complete command reference |
| [Benchmarks](./benchmarks/BENCHMARK_RESULTS.md) | Detailed benchmark data |

---

## Support

Phase 1 is completely free. The easiest way to support this project:

1. [Give it a star on GitHub](https://github.com/AI-Driven-School/aiki/stargazers) - helps others discover this project
2. [Share on X/Twitter](https://twitter.com/intent/tweet?text=4-AI%20collaborative%20development%20with%20Claude%20%2B%20Codex%20%2B%20Gemini.%2075%25%20cost%20reduction%20%F0%9F%9A%80&url=https%3A%2F%2Fgithub.com%2FAI-Driven-School%2Faiki) - spread the word
3. [Sponsor development](https://github.com/sponsors/AI-Driven-School) - support ongoing work

[![GitHub Stars](https://img.shields.io/github/stars/AI-Driven-School/aiki?style=for-the-badge&logo=github&label=Star)](https://github.com/AI-Driven-School/aiki/stargazers)
[![GitHub Sponsors](https://img.shields.io/github/sponsors/AI-Driven-School?style=for-the-badge&logo=github&label=Sponsor)](https://github.com/sponsors/AI-Driven-School)

---

<p align="center">
  MIT License<br>
  <a href="https://github.com/AI-Driven-School/aiki">GitHub</a> ·
  <a href="https://github.com/AI-Driven-School/aiki/issues">Issues</a> ·
  <a href="https://github.com/sponsors/AI-Driven-School">Sponsor</a>
</p>
