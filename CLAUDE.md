# CLAUDE.md - Project Memory

> This file is read by Claude at the start of each session to maintain project context.

## Project Overview

**claude-codex-collab**: 3-AI collaborative development workflow template using Claude + Codex + Gemini

- Claude: Design & review
- Codex: Implementation & testing (ChatGPT Pro, $0)
- Gemini: Large-scale analysis (free)

## Key Directories

```
.claude/
├── settings.json   # Hooks settings (auto-collaboration suggestions)
├── hooks/          # AI routing scripts
├── rules/          # Delegation rules
├── docs/           # Knowledge base (DESIGN.md, research/)
└── checkpoints/    # Session state storage

.codex/
└── AGENTS.md       # Codex context

.gemini/
└── GEMINI.md       # Gemini context

docs/
├── requirements/   # Requirements (created by Claude)
├── specs/          # UI specs (created by Claude)
├── api/            # API design (created by Claude)
├── decisions/      # Important decision records
└── reviews/        # Code review results

skills/             # Custom skills
scripts/            # Utility scripts
benchmarks/         # Benchmark results & sample implementations
landing/            # Landing page
```

## Working Rules

### 1. Record important decisions

Always record architecture, technology choices, and design decisions:

```bash
docs/decisions/YYYY-MM-DD-title.md
```

### 2. End of session

Before ending a session:
- Ask "Update CLAUDE.md with today's work"
- Or manually update the Work History section

### 3. Command system

| Command | AI | Purpose |
|---------|-----|---------|
| `/project <feature>` | All | Complete flow: design -> implementation -> deploy |
| `/requirements` | Claude | Requirements definition |
| `/spec` | Claude | UI specifications |
| `/implement` | Codex | Implementation |
| `/review` | Claude | Review |
| `/checkpointing` | Claude | Save session state |

## Claude Code Orchestra

### Auto-collaboration suggestions (Hooks)

Claude automatically analyzes input and suggests the appropriate AI:

| Keyword | Suggested AI | Example |
|---------|-------------|---------|
| implement, create | Codex | "Implement authentication" |
| test | Codex | "Write unit tests" |
| research, analyze | Gemini | "Compare React state management" |
| compare, library | Gemini | "Evaluate auth libraries" |

### Knowledge sharing

Shared knowledge base referenced by all AIs:
- `.claude/docs/DESIGN.md` - Design principles
- `.claude/docs/research/` - Gemini research results

### Session persistence

```bash
/checkpointing              # Save session state
/checkpointing --analyze    # Pattern analysis
```

---

## Important Decisions

Latest important decisions (see `docs/decisions/` for details):

- **2026-02-03**: Integrated Claude Code Orchestra (Hooks + Rules + Knowledge Base + Checkpointing)

---

## Work History

### 2026-02-03
- Integrated Claude Code Orchestra
  - .claude/settings.json (Hooks settings)
  - .claude/hooks/ (agent-router, suggest-codex, suggest-gemini, post-impl-check)
  - .claude/rules/ (codex-delegation.md, gemini-delegation.md)
  - .claude/docs/ (DESIGN.md, research/)
  - .codex/AGENTS.md, .gemini/GEMINI.md
  - skills/checkpointing.md, scripts/checkpoint.sh

### 2025-02-03
- Created CLAUDE.md (this file)
- Created docs/decisions/ directory
- Established memory persistence rules

---

## Notes for Claude

- Always write requirements in `docs/requirements/` before adding new features
- Default policy: delegate implementation to Codex
- Save benchmark results in `benchmarks/`
- When user says "record this decision", save to `docs/decisions/`
- Hook suggestions are displayed automatically (execution is user's choice)
- Record design principles in `.claude/docs/DESIGN.md`
- Gemini research results are saved to `.claude/docs/research/`
