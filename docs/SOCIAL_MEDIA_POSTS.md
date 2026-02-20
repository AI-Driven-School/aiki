# Social Media Posts (Draft)

Ready-to-use posts for promoting aiki.

---

## X/Twitter Posts

### Post 1: Launch Announcement
```
I built a 4-AI workflow that cuts AI coding costs by 75%.

Claude designs, Codex implements ($0), Gemini researches (free).

Solo devs get full design docs automatically.

13 ready-to-use Agent Skills included.

GitHub: https://github.com/AI-Driven-School/aiki

#ClaudeCode #CodingAgent #OpenSource
```

### Post 2: Cost Focus
```
Stop paying Claude to write boilerplate.

Our 4-AI system:
→ Claude: design & review only ($0.13/feature)
→ Codex: implementation & tests ($0 via ChatGPT Pro)
→ Gemini: research & analysis (free)

75% cost reduction, 2x speed.

https://github.com/AI-Driven-School/aiki
```

### Post 3: Agent Skills Focus
```
13 Agent Skills for Claude Code, Codex CLI, OpenCode, and Cursor:

/project - Full design-to-deploy pipeline
/implement - Auto-generate from specs
/test - E2E tests from requirements
/analyze - 1M token codebase analysis
/mockup - UI mockups via Playwright

All open standard (agentskills.io).

https://github.com/AI-Driven-School/aiki
```

### Post 4: Technical Thread Starter
```
How I made 3 AI coding assistants work together:

1/ Claude Code writes requirements & API specs
2/ Codex CLI implements from those specs (full-auto, $0)
3/ Gemini CLI analyzes the whole codebase (1M tokens, free)
4/ Claude reviews the output

Result: A solo dev workflow with team-grade documentation.

🧵 Thread below...
```

---

## Reddit Posts

### r/ClaudeAI

**Title:** I built an open-source 4-AI workflow: Claude designs, Codex implements, Gemini researches

**Body:**
```
After months of using Claude Code for everything, I realized I was paying Claude to write boilerplate. So I built a system that splits the work:

- **Claude Code**: Design, review, architecture decisions
- **Codex CLI** (ChatGPT Pro): Implementation & tests ($0 extra)
- **Gemini CLI**: Large-scale analysis & research (free)

The result: ~75% cost reduction with better documentation.

**How it works:**
1. Type `/project user authentication`
2. Claude generates requirements, API specs, UI specs
3. Codex auto-implements from those specs
4. Gemini can analyze the full codebase (1M token context)
5. Claude reviews the output

It ships with 13 Agent Skills that work with Claude Code, Codex CLI, OpenCode, and Cursor.

Supports local models via Ollama too, so you can go fully offline.

GitHub: https://github.com/AI-Driven-School/aiki

Happy to answer questions about the architecture or benchmarks.
```

### r/ChatGPT

**Title:** Using Codex CLI + Claude Code + Gemini together: 75% cost reduction for AI-assisted development

**Body:**
```
If you have ChatGPT Pro ($200/mo), you already have unlimited Codex CLI access. Here's how to get more value from it.

I built an open-source workflow template that coordinates 3 AIs:

| AI | Role | Cost |
|---|---|---|
| Claude Code | Design & review | Pay-per-use |
| Codex CLI | Implementation & testing | $0 (included in Pro) |
| Gemini CLI | Research & analysis | Free |

Instead of paying Claude for everything, the expensive work (implementation, test generation) goes to Codex at no extra cost.

**Features:**
- 13 ready-to-use Agent Skills (/project, /implement, /test, etc.)
- Auto-generated design documentation
- One-command setup: `npx aiki init my-app`
- Works with Cursor, OpenCode, and other agents too
- Local model support via Ollama

Benchmarks show Codex is 10-20% faster than Claude for new file creation, while Claude is 40% faster for existing code modifications. By routing each task to the best AI, you get both speed and quality.

GitHub: https://github.com/AI-Driven-School/aiki
```

### r/LocalLLaMA

**Title:** 4-AI collaboration template now supports Ollama for fully offline development

**Body:**
```
aiki is an open-source workflow that coordinates multiple AI coding assistants. We just added Ollama support so you can run the entire pipeline locally.

```bash
# Route implementation tasks to local models
bash scripts/delegate.sh ollama generate "Create a REST API for users"

# Code review with local model
bash scripts/delegate.sh ollama review src/ --model deepseek-coder
```

You can mix and match: use Claude for design decisions, but route implementation to your local codellama/deepseek-coder instance.

The project ships with 13 Agent Skills that work with Claude Code, Codex CLI, OpenCode, and Cursor. All follow the open Agent Skills standard.

GitHub: https://github.com/AI-Driven-School/aiki
```

---

## Awesome Agent Skills Submission

**PR Title:** `Add skill: AI-Driven-School/aiki`

**Entry to add (in Community Skills > Development and Testing):**

```markdown
- **[AI-Driven-School/aiki](https://github.com/AI-Driven-School/aiki)** - 4-AI collaborative development: Claude designs, Codex implements, Gemini researches
```

**Target repository:** [VoltAgent/awesome-agent-skills](https://github.com/VoltAgent/awesome-agent-skills)

**Prerequisites:**
- Must have demonstrated community usage (stars, forks)
- All 13 skills follow the Agent Skills specification
- Description is under 10 words
