---
name: wiki-rewrite
description: Rewrite or expand a targeted section of a draft, producing N distinct propositions grounded in a local LLM-wiki knowledge base. Markup-agnostic (LaTeX, Typst, Markdown, plain text, source comments) and personality-agnostic; voice comes from a shared profile (academic, outreach, technical, engineering, plain). Use when the user asks to rewrite, expand, reword or generate variants of a passage at a given file:line, or invokes /wiki-rewrite.
allowed-tools: Bash(cat *), Bash(ls *), Bash(grep *), Bash(sed *), Bash(find *), Bash(npx @pspdfkit/pdf-to-markdown *), Read
---

# wiki-rewrite

Generate `N` distinct rewrites of one targeted passage, grounded in a local knowledge base.

This skill owns the **pipeline only**. Voice, markup and config live in `../_shared/`. Never inline
any of them here.

## Inputs

| Input | Meaning | Default |
|---|---|---|
| `target` | `<filepath>:<line_number>` | required |
| `n` | number of propositions | `3` |
| `profile` | profile name under `../_shared/profiles/` | config's `defaultProfile` |

If `target` is missing or malformed, ask. Do not guess a line number.

## Step 0 - Config and profile

Follow `../_shared/references/config-resolution.md` to resolve `knowledgeBase`, `wikiDir`, `rawDir`,
`convertedDir` and the shared directory.

Read `../_shared/profiles/<profile>.md`. Use its **Voice**, **Variant axes**, **Constraints** and
**Syntax notes** sections; ignore **Claims** (that belongs to wiki-check). If the named profile has
no file, list the available ones and ask.

## Step 1 - Extract context

Split `target` on the last `:` into `file` and `line`.

```bash
sed -n "$((line-20)),$((line+20))p" "$file"
```

Clamp the start to `1`. Understand what the passage is *doing*; defining, transitioning, claiming,
instructing, concluding. The rewrite must keep that job.

## Step 2 - Detect the markup

Follow `../_shared/references/syntax-detection.md`, Steps 1–3. Extension is the hypothesis; the
context from Step 1 is authoritative. Transclusion (Step 4 there) does not apply: a rewrite targets
one passage in one file.

## Step 3 - Ground the rewrite

**Tier 1 - wiki.** `grep`/`ls` through `<knowledgeBase>/<wikiDir>/` for the passage's key concepts,
entities and citations. Align with definitions already settled there.

**Tier 2 - raw sources.** Only if Tier 1 lacks a specific figure or finding the rewrite needs. Look
under `<knowledgeBase>/<rawDir>/`; for PDFs follow `../_shared/references/pdf-extraction.md`, which
keeps a permanent conversion cache under `<knowledgeBase>/<convertedDir>/`. Check the cache and
`grep` it before converting anything.

If neither tier supports a claim, write the proposition without it and say so. Never fabricate a
citation, number or attribution.

## Step 4 - Generate `n` propositions

Apply the profile's voice and axes, in the syntax detected in Step 2. Each proposition must:

- be a drop-in replacement; same structural job, fits the surrounding text unedited
- differ from the others on a **stated axis**, not just wording
- emit valid markup, carrying through every construct the syntax reference marks load-bearing
- carry only claims grounded in Step 3

If `n` exceeds the profile's axes, extend along the same logic and name each added axis.

## Step 5 - Deliver (console only)

**Write nothing to disk. Modify no files.** Output to chat.

1. One line: detected syntax + profile in use.
2. The original passage, verbatim, in a code block.
3. Per proposition: heading naming its axis, the text in a code block, 1–2 sentences of rationale.
4. Closing line on grounding: which wiki articles or raw sources were used, or that none were needed.

Leave the conversion cache in place; it is knowledge-base content, not scratch. Delete nothing,
not even a failed `.partial`; the next conversion overwrites it.
