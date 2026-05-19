# Workflow

How work flows from a task to a merged PR in s3lab projects.

## Repository layout assumption

s3lab projects are **monorepos**. Backend services live under `backend/services/<name>/`,
frontend lives under `frontend/`. This is essential for the pipeline: the orchestrator
must see both layers in one context, and `api-contract` agent must commit OpenAPI +
generated TypeScript client atomically.

If you find yourself in a project where backend and frontend are separate repositories,
consolidate them via `git subtree add` before using this kit. See `.ai-kit/docs/multirepo.md`
for guidance.

## High-level flow

```
GitHub Issue
    ↓
orchestrator (decomposes, produces plan)
    ↓
human approval of plan
    ↓
designer (if UI involved)
    ↓
api-contract Mode B (spec endpoints before implementation)
    ↓
[parallel] backend-dotnet  +  frontend-angular
    ↓
api-contract Mode A (sync final contract)
    ↓
devops (if deployment changed)
    ↓
tester (generate + run tests)
    ↓
reviewer (pre-merge check)
    ↓
PR opened via gh CLI
    ↓
human merges
```

## Rules per phase

### Planning
- Non-trivial task → always start with `orchestrator`. Never write code without a plan.
- Plan must include: ordered subtasks, agent assignments, dependencies, risks, open questions.
- Wait for human approval before proceeding.

### Implementation
- One task → one branch → one PR.
- Branch name: `feat/<short-slug>` or `fix/<short-slug>`.
- Backend and frontend can run in parallel after API contract is spec'd.
- Each agent reports what it changed at the end of its turn.

### Contract sync (critical)
- Backend changes API surface → backend regenerates OpenAPI.
- Frontend regenerates TypeScript client from new OpenAPI.
- No hand-written HTTP calls to project endpoints. Ever.
- If frontend needs an endpoint that doesn't exist: STOP, invoke `api-contract` Mode B to spec it.

### Testing
- New public method or component → at least: happy path + one error + one edge case.
- Integration tests for endpoints via Testcontainers.
- Critical user paths covered by Playwright e2e.
- All tests must pass before opening PR.

### Review
- `reviewer` runs before opening PR.
- Outputs: ✅ good, ⚠️ suggestion (non-blocking), 🛑 must fix (blocker).
- 🛑 → loop back to the relevant implementer.
- Clean → open PR with `gh pr create`.

## Definition of done

A task is done when ALL of these are true:

- Plan was approved before implementation
- API contract is in sync (OpenAPI + generated TS client)
- Tests added for new behavior, all green
- Reviewer reports no 🛑
- PR opened with conventional-commit title and filled-in template
- CI passing on the PR

## Anti-patterns

- Running multiple `/feature` pipelines in parallel — you'll lose track of diffs.
- Skipping orchestrator on "obviously simple" tasks — they're rarely simple.
- Trusting `reviewer` blindly — for first weeks, human-review every PR.
- Letting plans exceed 15 subtasks — split into multiple issues instead.
- Editing generated files by hand — regenerate the source instead.
