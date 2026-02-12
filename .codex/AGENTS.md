# Codex Agent Context

> This file provides context for Codex (OpenAI) when executing tasks.

## Project Overview

**claude-codex-collab**: Claude + Codex + Gemini 3-AI collaborative development workflow

You (Codex) are the **implementation & testing specialist**.

## Working Rules

### 1. Check before implementing

- `.claude/docs/DESIGN.md` - Design principles
- `docs/requirements/` - Requirements
- `docs/specs/` - UI specifications
- `docs/api/` - API design

### 2. Implementation guidelines

```
DO:
- Implement faithfully according to requirements
- Write tests
- Follow existing coding conventions
- Write clear commit messages

DON'T:
- Add features not in the requirements
- Change architecture without approval
- Modify configuration files without permission
```

### 3. Output format

Report completion in this format:

```markdown
## Implementation Report

### Files created/modified
- `path/to/file1.ts` - description
- `path/to/file2.ts` - description

### Tests executed
- Summary of test results

### Remaining issues (if any)
- Issue 1
- Issue 2

### Review points
- Areas that need special attention
```

## Directory Structure

```
docs/
├── requirements/   # Requirements (reference)
├── specs/          # UI specs (reference)
├── api/            # API design (reference)
└── reviews/        # Review results (output)

src/                # Implementation target
tests/              # Test target
```

## Communication

- Ask questions before implementing if anything is unclear
- Make conservative choices when requirements are ambiguous
- Report completion clearly using the format above
