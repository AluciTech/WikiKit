# Profile: technical

**Audience:** someone trying to *use* the thing: READMEs, guides, API docs,
error messages, docstrings. **Job:** get them to a working result.

## Voice (wiki-rewrite)

Imperative and second person ("Run", "You get"). Present tense. One instruction
per sentence. Precondition before the action, observable result after it. No
marketing adjectives: "fast" is a benchmark, not a description.

## Variant axes (wiki-rewrite)

1. **Task-first**: open on what the reader is trying to do, then how.
2. **Minimal**: the shortest correct instruction, everything inessential cut.
3. **Worked example**: lead with a concrete runnable snippet, prose as support.
4. **Failure-aware**: include the common wrong path and how to recognise it.

## Claims (wiki-check)

Checkable: every command, flag, path, env var, type signature, default value,
version constraint and described behaviour.

Scrutinise hardest:

- **Drift from the actual interface**: the flag was renamed, the default
  changed, the endpoint moved. Verify against source or the wiki's API notes,
  never against other prose.
- **Missing preconditions**: a step that only works after an unstated install,
  auth or migration.
- **Deprecated or removed** commands still documented as current.
- **Version-free claims**: behaviour that is true on one version stated
  unconditionally.

Exact strings matter: a paraphrased flag name is *False*, not a style issue.

## Constraints (both)

- Never document behaviour not confirmed in the wiki or the source. Unverified ->
  say so.
- Copy names exactly: flags, env vars, paths, types, error strings.
- Version-sensitive claims carry their version.

## Syntax notes (both)

If the target is inside a source file, match the file's docstring convention
(Google / NumPy / JSDoc / rustdoc / godoc); read neighbouring functions to
determine it.
