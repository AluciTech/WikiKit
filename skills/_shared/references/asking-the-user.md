# Asking the user

Shared by every WikiKit skill. Some decisions are the user's, not ours: writing into their
knowledge base, picking between readings the evidence does not settle, or acting on an ambiguity
that a guess would quietly bury. Ask, then proceed.

This reference is **agent-agnostic on purpose**. Do not name a specific tool in a skill; name this
file and let the agent pick the mechanism it actually has.

## Protocol

When a choice is genuinely ambiguous, ask the user before proceeding.

If you have a built-in structured question tool available (a tool for presenting multiple-choice
options to the user), use it, batching related questions together where it supports that. If no
such tool is available to you, present the same options as a plain numbered list in your response
and wait for the user's reply before continuing.

Either way the content is the same: the same question, the same options, in the same order. Only
the presentation differs. Never skip the question because the structured tool is missing, and never
fabricate an answer to keep the run moving.

## Shape of a question

- **One question per decision**, and one round per run. Collect every ambiguity you have found,
  then ask once. A long audit must not become a prompt storm.
- **Two to four options**, mutually exclusive, ordered best-first. Mark the one you would pick
  `(Recommended)` and say why in a few words.
- **Always include an opt-out** ("skip", "leave it", "report it as unverified") so the user can
  decline without arguing.
- **Name the concrete thing**: the file, the citation, the `path:line`. "A source is missing" is
  not a question; "`smith2020.pdf` is in `inbox/`, cited at `intro.tex:42`" is.
- The user may answer something you did not list. Take it.

Plain-list fallback, when no structured tool exists:

```
smith2020.pdf sits un-ingested in inbox/, cited at intro.tex:42.

1) Ingest it now (recommended - the filename matches the citation key)
2) Ingest the whole inbox (3 other files would come in too)
3) Skip it; I will report the claim as unverified

Reply with a number, or tell me what you would rather do.
```

Then **stop and wait**. Do not answer on the user's behalf, and do not carry on with the option you
would have picked.

## When not to ask

Asking has a cost; spend it where the answer changes what you do.

- **Do not ask** what the config already answers, what the profile already rules on, or what a
  sensible default settles. Pick it, say which you picked in one line, move on.
- **Do ask** before anything that writes outside this run's own output, before an action that is
  awkward to undo, and whenever two readings of the draft are both defensible and lead to different
  verdicts or different rewrites.

## Honour the answer

A decision holds for the rest of the run. If the user skips a source, do not re-ask about it later
under a different claim. Record what they chose where the run reports its gaps, so the skipped
decision is visible in the output rather than lost in the conversation.
