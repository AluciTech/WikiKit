# Resolving configuration

Shared by every wiki-scitools skill.

Config lives under a `wikiKit` key inside the agent folder's `settings.local.json`, so it
coexists with the agent's own settings instead of fighting them.

## Lookup order

First file that contains a `wikiKit` key wins:

```bash
for d in "${CLAUDE_PROJECT_DIR:-.}/.claude" "${CLAUDE_PROJECT_DIR:-.}/.opencode" \
         "${CLAUDE_PROJECT_DIR:-.}/.agents" "$HOME/.claude" "$HOME/.config/wiki-scitools"; do
  f="$d/settings.local.json"
  [ -f "$f" ] && grep -q '"wikiKit"' "$f" && { echo "CONFIG: $f"; cat "$f"; break; }
done
```

Project scope beats user scope. Read the `wikiKit` object; ignore every sibling key, they
belong to the agent, not to us.

**Legacy fallback.** If nothing is found, check the pre-`settings.local.json` locations and treat
the file as a flat config (no `wikiKit` wrapper):

```bash
for f in "${CLAUDE_PROJECT_DIR:-.}/wiki-scitools.config.json" \
         "$HOME/.claude/wiki-scitools.config.json" \
         "$HOME/.config/wiki-scitools/config.json"; do
  [ -f "$f" ] && { echo "LEGACY CONFIG: $f"; cat "$f"; break; }
done
```

Mention the legacy path once when you use it, and point at
`docs/templates/settings.local.example.json` as the current layout. Do not migrate it silently.

## Keys

| Key | Meaning | Default |
|---|---|---|
| `knowledgeBase` | absolute path to an llm-wiki topic wiki root | **required** |
| `defaultProfile` | profile used when none is passed | `plain` |
| `reportsDir` | where `/wiki-check` writes its report, **relative to the draft** | `reports` |

That is the whole surface. The layout *inside* the knowledge base is llm-wiki's, not ours: a topic
wiki always has `wiki/` (compiled articles), `raw/` (ingested sources) and `inbox/` (drop zone).
Those are fixed names, so there is nothing to configure and nothing to keep in sync. Use them
literally: `<knowledgeBase>/wiki/`, `<knowledgeBase>/raw/`, `<knowledgeBase>/inbox/`.

`knowledgeBase` points at a topic wiki (`HUB/topics/<name>/`), not at the hub: the hub holds no
content.

### Why `reportsDir` is the odd one out

The wiki is the **library**; the report goes on the **desk**, next to the paper it is about. A
report belongs with the draft it audits, travels with that repo, and is versioned alongside it.
Putting it in the wiki would scatter per-draft output into shared reference material.

```
/home/you/wiki/topics/these/       <- knowledgeBase (llm-wiki owns everything below)
├── wiki/                          <- compiled articles   (read)
├── raw/                           <- ingested sources    (read)
└── inbox/                         <- drop zone           (read; /wiki:ingest empties it)

/home/you/projects/paper/          <- wherever the draft lives; NOT configured anywhere
├── main.tex                       <- the file you passed to /wiki-check
└── reports/                       <- reportsDir          (written)
    └── review_v1.md
```

So `reportsDir` is a **folder name**, not a location: setting it to `audits` writes
`/home/you/projects/paper/audits/review_v1.md`. It never moves output into the wiki. To anchor it
elsewhere, give it an absolute path.

## Merge rule

Top-level keys inside `wikiKit` are defaults. `profiles.<name>` overrides any of them for that
profile. A profile with no entry is legal; it inherits every default.

Resolve in this order: `profiles.<name>.<key>` -> `wikiKit.<key>` -> table default.

Stop and tell the user which file to create only if no `knowledgeBase` resolves at all. Never fall
back to a hardcoded path.

## Locating the shared directory

Profiles and references live in `_shared/`, a sibling of each skill's own directory. Resolve it
relative to the skill you are executing (`../_shared/...`). If that path does not exist, locate it:

```bash
for d in "${CLAUDE_PROJECT_DIR:-.}"/.claude/skills/_shared \
         "${CLAUDE_PROJECT_DIR:-.}"/.opencode/skills/_shared \
         "${CLAUDE_PROJECT_DIR:-.}"/.agents/skills/_shared \
         "$HOME"/.claude/skills/_shared; do
  [ -d "$d" ] && { echo "SHARED: $d"; break; }
done
```
