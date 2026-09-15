---
name: wiki-check
description: Fact-check a draft against a local LLM-wiki knowledge base. Resolves multi-file documents, extracts every claim, verifies it against wiki articles then raw sources, categorises each as accurate/false/needs-nuance/unverifiable, and writes a versioned report. Markup-agnostic (LaTeX, Typst, Markdown, plain text) and genre-aware via a shared profile. Use when the user asks to audit, fact-check, verify claims in, or peer-review a draft, or invokes /wiki-check.
allowed-tools: Bash(cat *), Bash(ls *), Bash(grep *), Bash(sed *), Bash(find *), Bash(npx @pspdfkit/pdf-to-markdown *), Bash(mkdir *), Read, Write
---

# wiki-check

Audit a draft's factual claims against a local knowledge base and write a versioned report.

This skill owns the **pipeline only**. Genre, markup and config live in `../_shared/`.

## Inputs

| Input | Meaning | Default |
|---|---|---|
| `target` | draft file, or `<file>:<start>-<end>` to scope to a range | required |
| `profile` | profile name under `../_shared/profiles/` | config's `defaultProfile` |

## Step 0 - Config and profile

Follow `../_shared/references/config-resolution.md` to resolve `knowledgeBase`, `wikiDir`, `rawDir`,
`convertedDir`, `reportsDir` and the shared directory.

Read `../_shared/profiles/<profile>.md`. Use its **Claims**, **Constraints** and **Syntax notes**
sections; ignore **Voice** and **Variant axes** (those belong to wiki-rewrite). The Claims section
decides what counts as checkable and where to be strict; it is not advisory.

## Step 1 - Resolve the document

Detect the markup via `../_shared/references/syntax-detection.md`, then follow its **Step 4** to
resolve transclusions. Compile the full text, recording for every line which file it came from:
findings must cite the real source file, not the assembled text.

If `target` carries a line range, restrict to it and skip transclusion.

Report the assembled scope before proceeding: file count, total lines, any include that failed to
resolve.

## Step 2 - Extract claims

Break the text into individually checkable assertions. Use the profile's **Claims** section to
decide what qualifies; genres differ sharply here, and applying the wrong one produces noise.

For each, record: the verbatim quote, its source file and line, and the citation key or source it
leans on (if any).

Skip: pure signposting ("this section argues"), definitions the wiki itself supplies, and anything
the profile's Claims section rules out of scope.

If the draft is large, say how many claims you extracted before verifying; do not silently sample.
If you must sample, state the criterion.

## Step 3 - Verify, two tiers

**Tier 1 - wiki.** Search `<knowledgeBase>/<wikiDir>/` for the concept, entity or cited work. The
wiki is the first authority: it holds settled definitions and paper summaries.

**Tier 2 - raw sources.** Only when a specific number, metric or finding is missing or
unverifiable in the wiki. Resolve the draft's citation key to a file under
`<knowledgeBase>/<rawDir>/`; for PDFs follow `../_shared/references/pdf-extraction.md`.

Conversions are cached permanently under `<knowledgeBase>/<convertedDir>/`. Before converting
anything, check the cache, and grep the whole cache for the claim - across a multi-claim audit most
sources are already there from earlier runs. Convert each source at most once per session, and
**never delete anything in the cache**, not even a failed `.partial`; the next conversion
overwrites it.

## Step 4 - Categorise

| Verdict | Meaning |
|---|---|
| **Accurate** | Confirmed by wiki or raw source. |
| **False** | Directly contradicted by wiki or raw source. |
| **Needs nuance** | Misreads, over-rounds, drops a scope condition, or overstates the source. |
| **Unverifiable** | Cited source absent from `rawDir`, or the assertion is not in it. |

"I could not find it" is **Unverifiable**, never False. Contradiction requires a located source
that says otherwise: quote it.

Where the profile's Claims section escalates a category (outreach treats a dropped hedge as False,
academic treats hedge drift as Needs nuance), the profile wins.

## Step 5 - Report

Write to `<reportsDir>/review_v<N>.md`.

`reportsDir` is anchored to the **draft's directory**, not the knowledge base - the report lands
next to the paper it audits, not inside the wiki. Auditing `~/projects/paper/main.tex` with the
default writes `~/projects/paper/reports/review_v1.md`.

If `reportsDir` is an absolute path, use it as-is. If the draft spans several files, anchor to the
directory of the file the user passed as `target`.

```bash
mkdir -p "$reports"
n=$(ls "$reports" 2>/dev/null | sed -n 's/^review_v\([0-9]\+\)\.md$/\1/p' | sort -n | tail -1)
echo "$reports/review_v$(( ${n:-0} + 1 )).md"
```

Never overwrite an existing report; always take the next free number.

Structure:

1. **Header**: draft, profile, detected syntax, files assembled, claim count, date.
2. **Summary table**: counts per verdict, and the highest-severity findings first.
3. **Findings**, ordered False -> Needs nuance -> Unverifiable. Each one:
   - the claim quoted verbatim, with `path:line` of the **original** file
   - the evidence quoted verbatim, with its wiki article or raw source path
   - for False and Needs nuance, a corrected rewrite in the draft's detected syntax
4. **Accurate claims**: a compact list, no prose. They matter for coverage, not for reading.
5. **Gaps**: citations that resolved to nothing, includes that failed, and sources whose
   conversion failed.

Then print to chat: the report path, the verdict counts, and the three findings most worth acting
on. Do not paste the whole report into the conversation.

## Constraints

- Modify the draft **never**. This skill writes exactly one file, the report.
- Quote evidence; never summarise a source into a verdict.
- Do not flag style, wording or structure. That is wiki-rewrite's job; say so and move on.
