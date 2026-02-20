# OpenCode Compatibility

This project is compatible with [OpenCode](https://github.com/sst/opencode), the open-source coding agent with 75+ model providers.

## How It Works

OpenCode natively supports Claude Code's configuration format:

| Feature | Claude Code Path | OpenCode Support |
|---------|-----------------|:----------------:|
| Project instructions | `CLAUDE.md` | Fallback (prefers `AGENTS.md`) |
| Agent context | `.codex/AGENTS.md` | Native |
| Skills | `.claude/skills/<name>/SKILL.md` | Native |
| Settings | `.claude/settings.json` | Partial (via plugins) |

### Rules File Priority in OpenCode

1. `AGENTS.md` (preferred)
2. `CLAUDE.md` (fallback)

Since this project ships both `CLAUDE.md` and `.codex/AGENTS.md`, OpenCode users get full context automatically.

## Setup

```bash
# Clone and open with OpenCode
git clone https://github.com/AI-Driven-School/aiki.git
cd aiki
opencode
```

All 13 skills in `.claude/skills/` are automatically available in OpenCode.

## Delegation with OpenCode

The delegation system (`scripts/delegate.sh`) works with any terminal, including OpenCode's built-in terminal. You can also use OpenCode's multi-model support to route tasks:

```bash
# Use OpenCode with different providers for different tasks
# Configure in opencode.json:
{
  "provider": {
    "anthropic": { "model": "claude-sonnet-4-5-20250929" },
    "openai": { "model": "gpt-4o" },
    "ollama": { "model": "codellama" }
  }
}
```

## Hooks

Claude Code hooks (`.claude/settings.json`) are not directly supported in OpenCode. The equivalent functionality is available through OpenCode's plugin system. The delegation scripts work independently of the hook system.

## Local Models via OpenCode

OpenCode's built-in Ollama support provides an alternative to our `delegate.sh --provider ollama` approach:

```bash
# opencode.json
{
  "provider": {
    "ollama": {
      "model": "codellama"
    }
  }
}
```

## Further Reading

- [OpenCode Documentation](https://opencode.ai/docs/)
- [OpenCode Skills](https://opencode.ai/docs/skills/)
- [AGENTS.md Standard](https://agents.md/)
- [Agent Skills Specification](https://agentskills.io/specification)
