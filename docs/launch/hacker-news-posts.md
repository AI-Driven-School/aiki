# Show HN Post Drafts for aiki

## Option 1: Technical/Engineering Angle (Recommended)

**Title:** Show HN: Aiki – CLI that orchestrates 4 AI agents to build features together

**Body:**

I built a CLI tool that coordinates Claude, Codex, Gemini, and Grok to work on the same codebase through a structured pipeline.

The idea: instead of one AI doing everything, assign each agent to what it does best. Claude handles design and code review. Codex handles implementation and tests. Gemini does large-scale analysis (1M token context). Grok pulls real-time data from X for trend research.

Setup:

    npx aiki init my-app

This scaffolds agent config files (.claude/, .codex/, .gemini/, .grok/) with delegation rules, hooks, and a shared knowledge base.

Running `/project user-auth` triggers a 6-phase pipeline: requirements, design, implement, test, review, deploy. Each phase routes to the appropriate agent. A hook system analyzes your input and suggests which AI should handle it -- "implement auth" routes to Codex, "compare state management libraries" routes to Gemini.

The agents share context through a docs directory structure. Claude writes specs to docs/requirements/ and docs/specs/. Codex reads those and implements. Research results from Gemini and Grok land in .claude/docs/research/ where any agent can reference them.

It is not fully autonomous. You approve each delegation step. The agents do not talk to each other directly -- you are the router, the tool just makes routing structured and repeatable.

Limitations: you need accounts/API keys for each AI. The orchestration is convention-based (shared files), not a real multi-agent protocol. It works best for greenfield features where the pipeline maps cleanly. Complex refactoring across existing code still needs human judgment at each step.

252 tests passing. MIT licensed.

GitHub: https://github.com/AI-Driven-School/aiki
Landing: https://ai-driven-school.github.io/aiki/

---

## Option 2: Cost/Efficiency Angle

**Title:** Show HN: Aiki – Build features with 4 AI agents for ~$0.21 each

**Body:**

I was spending too much time copy-pasting context between AI tools, so I built a CLI that structures the handoff between Claude, Codex, Gemini, and Grok.

The cost breakdown per feature is roughly $0.21:

- Claude (design + review): ~$0.15-0.20 in API calls
- Codex (implementation + tests): $0 with ChatGPT Pro
- Gemini (analysis + research): $0 within free tier
- Grok (real-time trends): ~$0.01-0.05 per query

Compare that to Devin at $500/mo or Cursor at $20-40/mo. The tradeoff is that aiki is not autonomous -- you drive each step. But you get transparency into what each agent is doing and why.

    npx aiki init my-app
    # then: /project user-auth

This runs a 6-phase pipeline (requirements, design, implement, test, review, deploy), routing each phase to the best-suited agent. Claude writes specs, Codex implements them, Gemini handles large-scale code analysis, Grok checks what the community thinks about your technical choices.

The agents share state through a conventional directory structure. Specs go in docs/, research in .claude/docs/research/, each agent has its own config directory with delegation rules and prompt templates.

The real value is not any single AI call -- it is having a repeatable process. Every feature follows the same pipeline, produces the same artifacts, and has the same review checkpoints. It turns "vibe coding" into something closer to a structured workflow.

Limitations: requires API keys for Claude and Grok (Codex and Gemini have free tiers). The pipeline assumes greenfield feature work. You are still the decision-maker at every step.

252 tests. MIT license.

GitHub: https://github.com/AI-Driven-School/aiki
Landing: https://ai-driven-school.github.io/aiki/

---

## Option 3: "I Built This" Personal Angle

**Title:** Show HN: Aiki – I made a CLI to stop copy-pasting between AI tools

**Body:**

My workflow had become: write a prompt in Claude, copy the output, paste it into Codex, copy that result, ask Gemini to review it, then manually track what happened. I was spending more time on context transfer than on actual thinking.

So I built aiki, a CLI that gives each AI agent a defined role and passes context between them through the filesystem.

    npx aiki init my-app

This creates config directories for four agents: Claude (design and review), Codex (implementation and testing), Gemini (large-scale analysis), and Grok (real-time trend research). Each gets its own context file, delegation rules, and prompt templates.

When you run `/project user-auth`, it walks through six phases: requirements, design, implement, test, review, deploy. At each step, it suggests which agent should handle it and what context to pass. You approve each handoff.

What I actually use day-to-day:

- Claude writes a spec to docs/specs/
- I hand the spec to Codex, which writes the code and tests
- If I need to evaluate a library choice, Gemini does the comparison
- If I want to know what developers think about a technical decision, Grok searches X

The agents do not communicate directly. The shared filesystem is the protocol. It is simple and it works.

Things I am honest about: this is not Devin. It will not autonomously ship a feature. You are the orchestrator. The tool just makes orchestration less painful and more consistent. It also assumes you have access to these AI tools already -- it does not abstract away the API key situation.

After a few months of use, the biggest win is not speed -- it is that every feature has the same shape: spec, implementation, tests, review. That consistency compounds.

252 tests. MIT licensed.

GitHub: https://github.com/AI-Driven-School/aiki
Landing: https://ai-driven-school.github.io/aiki/
