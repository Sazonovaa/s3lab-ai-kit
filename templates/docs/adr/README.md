# Architecture Decision Records (ADR)

We record significant architectural decisions here. Each ADR is a single short
document with the context, the decision, and its consequences.

## Why

- A new contributor (human or AI) can read the ADR list and understand why the
  system is the way it is.
- Decisions don't get re-litigated every quarter — if you want to change one, you
  supersede it with a new ADR.

## When to write an ADR

Write one when you're about to make a decision that:

- Affects multiple parts of the system
- Is hard or expensive to reverse
- Future contributors might question or undo without context
- Involves a tradeoff worth documenting

Don't write one for trivial choices (variable names, formatting).

## Format

- File name: `NNNN-short-title.md` (e.g., `0007-use-masstransit-for-rabbitmq.md`)
- Numbering: sequential, never reused
- Use `0000-template.md` as the starting point

## Status lifecycle

- **Proposed** — under discussion
- **Accepted** — current decision
- **Superseded by ADR-NNNN** — replaced; keep the old file for history
- **Deprecated** — no longer applies but no replacement yet

## Listing

| # | Title | Status |
|---|-------|--------|
| 0000 | Template | (template only) |
