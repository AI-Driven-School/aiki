# Codex Delegation Rules

## When to Delegate

Consider delegating the following tasks to Codex:

1. **New file creation**: 3+ new files
2. **Large-scale refactoring**: 10+ file changes
3. **Test creation**: New test files
4. **Boilerplate generation**: Repetitive code generation

## Delegation Process

1. Clearly define the task (requirements, constraints, expected output)
2. Use the template in `.codex/AGENTS.md`
3. Review Codex output with `/review`

## When NOT to Delegate

- Security-related implementations
- Small modifications to existing code (5 lines or fewer)
- Architecture design decisions
- Configuration file edits

## Cost Considerations

- ChatGPT Pro: Unlimited Codex ($0 additional cost)
- Claude: Pay-per-use API billing
- Delegate large implementations to Codex for cost optimization
