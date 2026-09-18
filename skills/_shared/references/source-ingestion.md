# Reading raw sources

Sources are read as markdown under `<knowledgeBase>/raw/`. These tools never parse a PDF: ingestion
belongs to [llm-wiki](https://github.com/nvk/llm-wiki), whose `/wiki:ingest` extracts the text,
writes the frontmatter and updates the indexes. We read what it produced.

Do **not** open a PDF binary with `cat`, `Read` or `grep`; it wastes context and returns garbage.

## 1. Look in `raw/` first

An ingested source is a markdown file whose frontmatter carries the original path or URL:

```bash
kb="<knowledgeBase>"

# By concept, title or phrase
grep -rn -i "<phrase>" "$kb/raw/" --include='*.md' | head -20

# By the original filename, when the draft cites a file you know
grep -rln "smith2020" "$kb/raw/" --include='*.md'
```

Sources land under `raw/<type>/` (`papers`, `articles`, `repos`, `notes`, `data`) as
`YYYY-MM-DD-slug.md`, so the citation key rarely matches the filename. Search the content and the
`source:`/`title:` frontmatter, not just names.

Once located, `grep -n -i -C 3` to find the region, then `sed -n "<start>,<end>p"` to read only it.

Search once, broadly, rather than resolving one citation at a time: over a multi-claim audit most
sources are already ingested.

## 2. Nothing in `raw/`? Check the inbox

A paper the user just dropped in sits unprocessed under `<knowledgeBase>/inbox/`:

```bash
ls "$kb/inbox/" 2>/dev/null
```

A file there matching the citation is **not yet ingested**. Do not read it, do not convert it, and
do not ingest it on your own initiative: ingesting writes into the user's knowledge base, and
`/wiki:ingest` may route the source into a different topic wiki than the configured
`knowledgeBase`. That is the user's call.

**Ask, following `asking-the-user.md`.** Collect every un-ingested match first, across every claim
or passage, then ask once; never one prompt per file. Name the matched files and the citations that
need them, and offer these options in this order:

1. **Ingest these now** - `/wiki:ingest "<kb>/inbox/<file>" --type papers` for each matched file.
   Recommended when the filenames or titles clearly match the citations.
2. **Ingest the whole inbox** - `/wiki:ingest --inbox`. Offer this only when the inbox holds files
   beyond the ones matched, and say how many extras it would pull in.
3. **Skip, report as unverified** - ingest nothing, carry on, list the files under the run's gaps.

Run `/wiki:ingest` however this agent invokes a command from another toolkit: a skill or command
call if it has one, otherwise print the exact command and let the user run it, then resume when
they say it is done. Either way, search `raw/` again (step 1) afterwards. If the source is still
absent, treat it as step 3 below and say the ingest did not land it where we look.

If the user skips, honour it for the rest of the run: do not re-ask about the same file.

## 3. Still nothing? It is missing

Say so, fall back to the compiled layer (`<knowledgeBase>/wiki/`), and never guess what the source
contains. For `/wiki-check` that is an **Unverifiable** verdict, not a False one.

## Rules

- **Never write into the knowledge base unasked.** Ingestion is llm-wiki's job and starting it is
  the user's decision: ask first, always (`asking-the-user.md`), and run `/wiki:ingest` only on an
  explicit yes. Ask once for the whole run, not once per file.
- No PDF parsing, no conversion, no cache, no generated files of any kind.
- Never fabricate a number, quote or attribution from an unread source.
