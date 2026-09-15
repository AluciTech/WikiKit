# Detecting the target's markup language

The rewrite must be a drop-in replacement, so it has to match the document's
markup exactly. Never assume LaTeX, Markdown or anything else; detect it.

## Step 1 - extension gives the hypothesis

| Syntax | Extensions | Emphasis / strong | Headings |
|---|---|---|---|
| LaTeX | `.tex` `.ltx` `.sty` `.cls` | `\emph{}` `\textbf{}` | `\section{}` |
| Typst | `.typ` | `_x_` `*x*` | `= Title` |
| Markdown | `.md` `.markdown` | `*x*` `**x**` | `# Title` |
| Plain text | `.txt` | none | none |

For **source code**, the target line is a comment or docstring. Match the file's
comment style and its existing docstring convention (Google / NumPy / JSDoc /
rustdoc / godoc, read neighbours to tell). Do not rewrite executable lines
unless asked.

## Step 2 - the surrounding context overrules the extension

The 40 lines you already read in Step 1 of the pipeline are authoritative.
Markers:

- **Typst**: `#import`, `#set`, `#let`, `#figure(`, `@label` refs, `$ x $` math
  with spaces
- **LaTeX**: `\begin{}`, `\cite{}`, `\ref{}`, `$x$` / `\(x\)` math
- **Markdown-with-LaTeX-math**: `.md` file containing `$$...$$`; prose is
  Markdown, math is LaTeX

Where extension and content disagree, **content wins**: and say so in one
clause of the rationale. If the file is ambiguous and the surrounding context
has no markers, ask rather than guess.

## Step 3 - carry these through untouched

Per syntax, preserve every construct already present in the passage:

| Syntax | Must survive verbatim |
|---|---|
| LaTeX | `\cite{}` `\ref{}` `\label{}` `\autoref{}`, custom macros, environments |
| Typst | `@refs`, `#cite()`, `<labels>`, `#let` bindings, show/set rules in scope |
| Markdown | reference-style link ids, footnotes `[^x]`, anchors, front-matter |
| Any | placeholder tokens (`{{name}}`, `%s`, `${VAR}`), i18n keys, TODO markers |

Never invent a citation key, label or reference. Reuse only identifiers that
appear in the draft or in the wiki.

## Step 4: Resolve transclusions (multi-file documents)

A draft is often split across files. When the whole document is in scope, follow the includes for
the detected syntax:

| Syntax | Include directives |
|---|---|
| LaTeX | `\input{f}` `\include{f}` `\subfile{f}` `\import{dir}{f}` `\includeonly{}` |
| Typst | `#include "f.typ"` `#import "f.typ": ...` |
| Markdown | none natively; check for a site generator's own syntax before assuming flat |

Rules:

- Resolve each path **relative to the including file's directory**, not the working directory.
- LaTeX omits the `.tex` extension; Typst requires it. Try the bare path, then the
  syntax's default extension.
- Guard against cycles: track visited absolute paths, never re-enter one.
- Cap depth at 5. If deeper, report the unresolved chain rather than following it.
- A missing include file is a finding, not a crash; report the path and continue.
- Skip `\includeonly{}`-excluded files only if that directive is present and non-empty.
