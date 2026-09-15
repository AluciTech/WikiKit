---
description: Rewrite or expand a draft section, returning N distinct propositions grounded in your LLM-wiki.
argument-hint: <file:line> [n] [academic|outreach|technical|engineering|plain]
allowed-tools: Bash(cat *), Bash(ls *), Bash(grep *), Bash(sed *), Bash(find *), Bash(npx @pspdfkit/pdf-to-markdown *), Read, Skill
---

Invoke the `wiki-rewrite` skill and follow it end to end.

- target: `$1`
- n: `$2` (default 3)
- profile: `$3` (default: `defaultProfile` from the resolved config)

If `$1` is empty, ask for a `<filepath>:<line_number>` target instead of guessing.
