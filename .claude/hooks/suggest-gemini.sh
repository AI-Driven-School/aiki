#!/bin/bash
#
# suggest-gemini.sh - Gemini delegation suggestion hook
# Suggests delegating to Gemini before WebSearch/WebFetch tool usage
#

echo "**Web research task detected**
   Large-scale research and comparative analysis is a strength of Gemini (free).

   To delegate to Gemini:
   1. Use the request template in .gemini/GEMINI.md
   2. Ask to save results in .claude/docs/research/

   To continue with Claude: No action needed (Claude will search directly)"

exit 0
