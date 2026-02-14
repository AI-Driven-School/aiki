# Grok Delegation Rules

## When to Delegate

Consider delegating the following tasks to Grok:

1. **Real-time trend research**: Current X/social media trends and discussions
2. **Latest tech updates**: Breaking changes, new releases, deprecations
3. **Community sentiment analysis**: Developer opinions and reactions
4. **Content research**: Primary sources and context packs for article writing
5. **Viral content analysis**: What's trending and why

## Delegation Process

1. Clarify the research purpose and expected output
2. Use the template in `.grok/GROK.md`
3. Ask to save results in `.claude/docs/research/`
4. Claude reads results and uses them for decision-making

## When NOT to Delegate

- Large-scale static code analysis (use Gemini)
- Implementation tasks (use Codex)
- Historical/archival research without real-time component
- Security-sensitive information

## Cost Considerations

- Grok: xAI API usage-based billing
- Ideal for real-time and time-sensitive queries
- Complements Gemini (static analysis) with live data
