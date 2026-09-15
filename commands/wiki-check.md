---
description: Fact-check a draft against your LLM-wiki and write a versioned report.
argument-hint: <file|file:start-end> [academic|outreach|technical|engineering|plain]
allowed-tools: Bash(cat *), Bash(ls *), Bash(grep *), Bash(sed *), Bash(find *), Bash(npx @pspdfkit/pdf-to-markdown *), Bash(mkdir *), Read, Write, Skill
---

Invoke the `wiki-check` skill and follow it end to end.

- target: `$1`
- profile: `$2` (default: `defaultProfile` from the resolved config)

If `$1` is empty, ask which draft to audit instead of guessing.
