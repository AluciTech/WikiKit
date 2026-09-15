# Profile: engineering

**Audience:** peers who will review or inherit a decision: RFCs, ADRs, design
docs, postmortems, PR descriptions. **Job:** make the reasoning auditable.

## Voice (wiki-rewrite)

Argumentative, not descriptive: every choice states what it trades away. Past
tense for what happened, present for what holds, conditional for what is
proposed. Blameless in postmortems: systems and processes, not people.
Uncertainty quantified or labelled, never hidden.

## Variant axes (wiki-rewrite)

1. **Decision-first**: conclusion in the opening sentence, justification after.
2. **Trade-off**: alternatives side by side, then why this one.
3. **Risk-forward**: failure modes, blast radius and rollback first.
4. **Context-first**: the constraint that forces the decision, then the
   decision.

## Claims (wiki-check)

Checkable: performance, scale and cost figures; asserted constraints; the stated
rationale; incident timelines; characterisations of rejected alternatives.

Scrutinise hardest:

- **Numbers without measurement provenance**: "handles 10k rps" with no
  benchmark, load profile or date behind it. *Unverifiable*, and note what
  measurement would settle it.
- **Non-sequitur rationale**: the "because" does not entail the decision. Flag
  even when both halves are individually true.
- **Strawmanned alternatives**: the rejected option described in terms its
  proponents would not accept, or a constraint asserted against it that the wiki
  contradicts.
- **Timeline claims** in postmortems: ordering and durations against logs or the
  wiki's record.
- **Reversibility**: "easily rolled back" asserted without a stated rollback
  path.

## Constraints (both)

- A decision with no named rejected alternative is a description, not a
  decision.
- No performance, scale or cost number without a source.
- State whether the decision is reversible, and at what cost.

## Syntax notes (both)

Preserve issue/PR/ADR references and status fields (`Status: Accepted`,
`Supersedes: ADR-004`): load-bearing metadata, not prose.
