# Extracting text from raw sources

Do **not** open a PDF binary with `cat`, `Read` or `grep`; it wastes context and returns garbage.

Conversions are **cached permanently** under `<knowledgeBase>/<convertedDir>/` (default
`converted`). A paper is converted once, ever. Every later query greps the cached markdown, which
is the point: conversion costs tens of seconds, grep costs nothing.

## Cache layout

The cache mirrors the raw tree, so basename collisions are impossible:

```
<knowledgeBase>/raw/papers/smith2020.pdf   ->  <knowledgeBase>/converted/papers/smith2020.md
<knowledgeBase>/raw/reports/smith2020.pdf  ->  <knowledgeBase>/converted/reports/smith2020.md
```

A source outside `rawDir` but inside `knowledgeBase` mirrors from the knowledge-base root. A source
outside the knowledge base entirely goes to `<convertedDir>/_external/<basename>.md`.

## Protocol

```bash
kb="<knowledgeBase>"; raw="<rawDir>"; conv="<convertedDir>"
pdf="/absolute/path/to/source.pdf"

# Mirror the relative path into the cache
case "$pdf" in
  "$kb/$raw/"*) rel="${pdf#"$kb/$raw/"}" ;;
  "$kb/"*)      rel="${pdf#"$kb/"}" ;;
  *)            rel="_external/$(basename "$pdf")" ;;
esac
out="$kb/$conv/${rel%.*}.md"
```

**1. Check the cache first.** A cached file newer than its source is a hit: use it, convert nothing:

```bash
if [ -f "$out" ] && [ "$out" -nt "$pdf" ]; then
  echo "CACHE HIT: $out"
fi
```

If the cached file is *older* than the source, the PDF was replaced; reconvert.

**2. On a miss, convert atomically.** Write to a `.partial` beside the target and move it into
place only on success, so an interrupted run never leaves a truncated file in the cache:

```bash
mkdir -p "$(dirname "$out")"
tmp="$out.partial"
if npx @pspdfkit/pdf-to-markdown "$pdf" "$tmp" && [ -s "$tmp" ]; then
  mv -f "$tmp" "$out"
  echo "CONVERTED: $out"
else
  echo "CONVERSION FAILED: $pdf"
fi
```

**3. Locate before reading bulk:**

```bash
grep -n -i -C 3 "<key concept>" "$out"
```

**4. Read only the matching region** with `sed -n "<start>,<end>p" "$out"`.

## Rules

- **Never delete anything under `convertedDir`.** Conversions are knowledge-base content, not
  scratch. A failed run leaves its `.partial` behind; that is harmless (it never matches `*.md`,
  so it is never a cache hit) and the next conversion of that source overwrites it.
- Never read a `.partial`; an existing one means a previous run died mid-conversion. Overwrite it.
- Converting the same source twice in one session is a bug. Resolve `$out` once, reuse it.
- If conversion fails, say so and fall back to the wiki layer; never guess the source's content.
- The cache is disposable in the sense that it can always be rebuilt, but rebuilding is expensive.
  Treat `convertedDir` as generated output: worth excluding from the wiki's own indexing, worth
  keeping on disk.

## Searching the whole cache

Because conversions persist, the cache is itself searchable, useful when the citation key is
unknown but the claim is not:

```bash
grep -rn -i "<phrase>" "$kb/$conv/" --include='*.md' | head -20
```

Prefer this over converting another PDF on a hunch.
