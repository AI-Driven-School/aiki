# Contributing to claude-codex-collab

Thank you for your interest in contributing! This guide will help you get started.

## Good First Issues

New to the project? Look for issues labeled [`good first issue`](https://github.com/AI-Driven-School/claude-codex-collab/labels/good%20first%20issue). These are curated tasks that are well-scoped and include clear acceptance criteria.

Popular areas for first contributions:
- **i18n**: Translate skill files or documentation to English
- **Testing**: Add shellcheck compliance or bats tests
- **Enhancement**: Improve error messages or add CLI flags

## How to Contribute

### Reporting Issues

- Use [GitHub Issues](https://github.com/AI-Driven-School/claude-codex-collab/issues)
- Choose the appropriate template (Bug Report or Feature Request)
- Include steps to reproduce for bugs
- Include your environment (OS, Node.js version, Claude Code version)

### Submitting Pull Requests

1. Fork the repository
2. Create a feature branch: `git checkout -b feat/your-feature`
3. Make your changes
4. Test your changes (see Testing below)
5. Commit with a descriptive message following [Conventional Commits](https://www.conventionalcommits.org/)
6. Push and open a PR

### Branch Naming

| Prefix | Purpose |
|--------|---------|
| `feat/` | New feature |
| `fix/` | Bug fix |
| `docs/` | Documentation only |
| `refactor/` | Code refactoring |
| `chore/` | Maintenance tasks |

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add new /deploy skill
fix: correct Codex CLI package reference in install script
docs: update README with skill installation guide
```

## Development Setup

```bash
git clone https://github.com/AI-Driven-School/claude-codex-collab.git
cd claude-codex-collab

# Set up Git LFS (required for binary assets)
git lfs install

# Verify shell scripts pass linting
shellcheck scripts/*.sh

# Open with Claude Code
claude
```

### Git LFS

This project uses [Git LFS](https://git-lfs.github.com/) to track binary assets (images, videos, archives).
If you add or modify binary files, ensure Git LFS is installed:

```bash
# Install Git LFS (one-time setup)
git lfs install

# Verify tracked patterns
cat .gitattributes

# Check which files are tracked by LFS
git lfs ls-files
```

Tracked extensions: `*.mp4`, `*.gif`, `*.mov`, `*.png`, `*.jpg`, `*.jpeg`, `*.webp`, `*.webm`, `*.zip`, `*.tar.gz`

## Testing

### Shell Scripts

```bash
# Lint with ShellCheck
shellcheck scripts/*.sh install*.sh

# Run bats tests (install bats first: brew install bats-core)
bats tests/*.bats

# Dry-run installation
bash install-fullstack.sh --dry-run my-test-app
```

### Skills

```bash
# Validate skill format (requires skills-ref)
for skill in .claude/skills/*/; do
  skills-ref validate "$skill" 2>/dev/null || echo "Check: $skill"
done
```

## Contributing Skills

New skills should follow the [Agent Skills specification](https://agentskills.io/specification):

1. Create `skill-name/SKILL.md` with YAML frontmatter
2. Name: lowercase, hyphens only, max 64 chars
3. Description: include what it does AND when to use it
4. Keep SKILL.md under 500 lines
5. Add to `.claude/skills/` directory (Agent Skills standard format)

## Code Style

### Shell Scripts

- Use `set -euo pipefail` at the top
- Quote all variables: `"$var"` not `$var`
- Use functions for reusable logic
- Add color output via helper functions
- Handle errors gracefully with meaningful messages

### Markdown

- Use ATX-style headers (`#` not underlines)
- One sentence per line for easier diffs
- Use tables for structured data
- Include code examples where helpful

## Questions?

Open a [Discussion](https://github.com/AI-Driven-School/claude-codex-collab/discussions) or [Issue](https://github.com/AI-Driven-School/claude-codex-collab/issues).
