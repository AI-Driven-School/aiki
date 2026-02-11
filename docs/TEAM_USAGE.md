# Team Usage Guide

This guide covers how to use claude-codex-collab effectively in a team environment.

## Branch Naming Convention

When multiple team members use the `/project` workflow, use consistent branch naming:

```
<prefix>/<feature>-<author>
```

| Prefix | Purpose | Example |
|--------|---------|---------|
| `feat/` | New features | `feat/auth-alice` |
| `fix/` | Bug fixes | `fix/login-error-bob` |
| `refactor/` | Refactoring | `refactor/api-layer-carol` |
| `ai/` | AI-generated code | `ai/implement-auth-codex` |

## Shared Configuration

### `.claude/team-config.yaml`

Team settings are defined in `.claude/team-config.yaml`. This file configures:

- Branch prefixes per workflow phase
- Auto-approval settings
- Lock timeouts for concurrent workflows

```yaml
# Example: Customize branch prefix
branch_prefix: "feat"

# Example: Auto-approve requirements phase
auto_approve_phases:
  - requirements
```

## Concurrent Workflow Patterns

### Pattern 1: Sequential (recommended for small teams)

```
Alice: /project user-auth
  [completes all 6 phases]
Bob:   /project search
  [starts after Alice finishes]
```

### Pattern 2: Parallel with locks

```
Alice: /project user-auth     # acquires lock on user-auth
Bob:   /project search         # acquires lock on search (no conflict)
Carol: /project user-auth      # BLOCKED - lock held by Alice
```

The `project-workflow.sh` script automatically manages locks to prevent conflicts on the same feature.

### Pattern 3: Phase-based parallelism

```
Alice: /project user-auth --from=1 --skip=3,4  # Design only
Bob:   /project user-auth --from=3              # Implementation only
```

Split phases across team members for faster delivery.

## Merge Strategy

### AI-Generated Code

1. AI generates code on a feature branch
2. Human reviews the PR (use `/review` for AI-assisted review)
3. Squash-merge to main for clean history

### Resolving Conflicts

When multiple AI sessions modify the same files:

1. Use `git merge --no-commit` to see conflicts
2. Run `/review` on the merged result
3. Have a human make final decisions on conflicts

## Tips for Teams

- **Lock awareness**: Check `.project-state-*.lock` files before starting a workflow
- **Force unlock**: Use `--force-unlock` if a lock is stale (e.g., crashed session)
- **Shared docs**: All design docs in `docs/` are committed to git for visibility
- **Review rotation**: Alternate who runs `/review` to spread knowledge
