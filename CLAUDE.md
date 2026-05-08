# Claude Workflow Rules

## Rule Enforcement (MANDATORY — DO NOT IGNORE)

### HARD RULES — These are NOT suggestions. Violations will be BLOCKED by hooks.

1. **NEVER implement source code directly** when the task matches Codex delegation criteria:
   - 3+ new source files → MUST delegate to Codex via `/implement`
   - 5+ source file edits → MUST delegate to Codex via `/implement`
   - Test file creation → MUST delegate to Codex
   - Boilerplate/repetitive code → MUST delegate to Codex
   - **Enforced by**: `enforce-delegation.sh` (PreToolUse hook, exit code 2 = BLOCK)

2. **NEVER start implementation without design artifacts**:
   - `docs/requirements/{feature}.md` MUST exist before writing source code
   - `docs/specs/{feature}.md` MUST exist before writing source code
   - Use `/requirements` and `/spec` to create them first
   - **Enforced by**: `agent-router.sh` (design-first warning)

3. **Claude's allowed domains** (NOT blocked):
   - Documentation (`.md` files)
   - Configuration (`.json`, `.yaml`, `.toml`)
   - Design artifacts (`docs/`, `.claude/`, `skills/`, `scripts/`)
   - Requirements, specs, reviews, API design
   - Code review and architecture decisions
   - Hook/script infrastructure

4. **Override**: User can set `export FORCE_CLAUDE=1` to bypass all blocks.

5. **Session counters**: Reset with `rm .claude/.session_edit_count .claude/.session_new_files .claude/.session_edit_log`

## Command System

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

| Keyword | Suggested AI | Example |
|---------|-------------|---------|
| implement, create | Codex | "Implement authentication" |
| test | Codex | "Write unit tests" |
| research, analyze | Gemini | "Compare React state management" |
| compare, library | Gemini | "Evaluate auth libraries" |
| trend, buzz, viral | Grok | "What's trending in React community" |
| X search, realtime | Grok | "Latest developer reactions to Next.js 15" |

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

## Notes for Claude

- Always write requirements in `docs/requirements/` before adding new features
- Default policy: delegate implementation to Codex
- Save benchmark results in `benchmarks/`
- When user says "record this decision", save to `docs/decisions/`
- Record design principles in `.claude/docs/DESIGN.md`
- Gemini research results → `.claude/docs/research/`
- Grok research results → `.claude/docs/research/` (prefixed with `grok-`)

---

## Important Decisions

Latest important decisions (see `docs/decisions/` for details):

- **2026-03-13**: Integrated rulesync for unified AI rule management
- **2026-02-14**: Added Grok (xAI) as 4th AI - real-time trend & X search specialist
- **2026-02-03**: Integrated Claude Code Orchestra (Hooks + Rules + Knowledge Base + Checkpointing)

---

## Work History

### 2026-05-08
- Added Multi-Agent Debate case study (Solver / Proposer / Checker pattern)
  - `docs/examples/multi-agent-debate-case-study.md` — 1ジョブで法律解釈の事実誤認を検出した実例
  - README に動線追加（"Real-world Case" subsection under Case Study）
  - 検証手法: Solver(Claude) → Proposer(Gemini) → Checker(Claude+WebSearch)
  - 参考研究: MARCH (2026), Microsoft CORE — false positive -25.8%
  - 将来の `aiki debate <claim-file>` サブコマンド化候補として記録

### 2026-03-13
- Integrated rulesync for unified AI rules management
  - `.rulesync/rules/` - Single source of truth for all AI rules
  - `rulesync generate` auto-generates CLAUDE.md, AGENTS.md, GEMINI.md
  - `rulesync install` for declarative skill management
  - Added rulesync setup to install-fullstack.sh

### 2026-02-14
- Added Grok (xAI API) integration as 4th AI

### 2026-02-03
- Integrated Claude Code Orchestra

### 2025-02-03
- Created CLAUDE.md, established memory persistence rules
