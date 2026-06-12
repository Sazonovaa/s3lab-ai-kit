# s3lab-loop Orchestrator Plugin — Design

- Date: 2026-06-12
- Owner: Андрей Сазонов (sien.inbox@gmail.com)
- Status: Approved (brainstorm phase)
- Repo: `s3lab-ai-kit`

## 1. Goal

Ship a Claude Code plugin `s3lab-loop` that turns a single user-provided goal into a finished draft through a fixed orchestrated pipeline (`decompose → research → draft → critique → refine`). The plugin owns the goal end-to-end, runs each stage as an isolated specialist subagent, and returns only the final draft plus a one-line verdict to the main thread.

The primary design driver is token economy: the main conversation must not accumulate planning chatter, intermediate drafts, or specialist transcripts. The orchestrator itself runs as a subagent so its own context is also invisible to the main thread.

## 2. Non-goals

- Persisting loop state to disk or resuming across sessions (single-shot only).
- Concurrent loops (one `/s3lab-loop` invocation at a time, no locking).
- Configurable iteration budget, model selection, or specialist swapping in v1.
- Domain-specific specialists (code reviewer, security auditor, etc.). v1 is domain-agnostic.
- Cross-vendor support (Cursor, Codex). Claude Code only.
- Loop telemetry, usage logging, or analytics.

## 3. Decisions captured in brainstorming

| Question | Decision |
|---|---|
| Domain scope | Universal — works for any goal type the specialists can handle (text, research, spec, code-adjacent). |
| Entry surface | Slash command `/s3lab-loop "goal text"`. |
| Pipeline shape | Fixed: `decompose → research → draft → (critique → refine)*N → return`. No dynamic re-planning. |
| Specialists | Five preconfigured subagents in `agents/`. One subagent per stage. |
| Orchestrator placement | Top-level subagent (`loop-orchestrator`) spawned by the slash command. Main thread does not orchestrate. |
| Stop conditions | Base only: `critic.verdict = done`, iteration counter reaches 3, or user Ctrl+C. |
| Critic evaluation input | Goal text + current draft. No acceptance-criteria checklist, no rubric. |
| Iteration budget | `MAX_REFINE_ROUNDS = 3` hardcoded. No plateau detection, no token cap. |
| State | In-memory only inside the orchestrator subagent. No files, no index, no resume. |
| Plugin name | `s3lab-loop`. Slash command `/s3lab-loop` (no conflict with the superpowers `/loop` skill). |

## 4. Architecture

```
main thread
    │
    │ /s3lab-loop "goal"
    ▼
loop-orchestrator (subagent)         ← owns goal, holds state, counts iterations
    │
    ├─► loop-decomposer (subagent)   ← goal → ordered plan + AC checklist
    ├─► loop-researcher (subagent)   ← plan → research bundle (facts + sources)
    ├─► loop-drafter   (subagent)    ← plan + research → first draft
    │
    │ ┌──────────────── refine loop, ≤ 3 rounds ────────────────┐
    ├─► loop-critic    (subagent)    ← goal + draft → verdict (done|revise + weak_points)
    └─► loop-refiner   (subagent)    ← goal + draft + weak_points → revised draft
      └──────────────────────────────────────────────────────────┘
            │
            ▼
        returns to main: final draft + 1-line verdict block
```

Three conceptual levels:

- **L1 Orchestrator.** `loop-orchestrator` subagent. Owns the goal, holds the pipeline state, decides which specialist runs next, enforces the iteration budget.
- **L2 Specialists.** Five stage-specialist subagents. Each runs in a cold context, receives only the minimal slice it needs, returns a structured result.
- **L3 Narrow workers.** Out of scope in v1. Specialists may spawn sub-subagents in future iterations (e.g., researcher fanning out parallel `WebFetch` calls). The plugin layout does not preclude this.

Token economy contract:

- Main thread sees only the orchestrator's final return. No planning, no intermediate drafts, no critic transcripts.
- Orchestrator sees only specialist results, not their internal transcripts.
- Each specialist call gets a minimal input slice (see §6); orchestrator does not forward unrelated state.

## 5. Components and files

```
plugins/s3lab-loop/
├── .claude-plugin/
│   └── plugin.json
├── commands/
│   └── s3lab-loop.md
├── agents/
│   ├── loop-orchestrator.md
│   ├── loop-decomposer.md
│   ├── loop-researcher.md
│   ├── loop-drafter.md
│   ├── loop-critic.md
│   └── loop-refiner.md
├── hooks/
│   └── .gitkeep
└── skills/
    └── .gitkeep
```

**`commands/s3lab-loop.md`** is a thin proxy. Its body instructs the model: spawn `loop-orchestrator` with the user-supplied goal as prompt, return its result verbatim, do nothing else. No orchestration logic lives in the slash command.

**Agent tool grants:**

| Agent | Tools | Model |
|---|---|---|
| `loop-orchestrator` | `Agent` (to spawn specialists), `TaskCreate` / `TaskUpdate` / `TaskList` (internal iteration tracking) | sonnet |
| `loop-decomposer` | `Read`, `Grep` | sonnet |
| `loop-researcher` | `Read`, `Grep`, `Glob`, `WebFetch`, `WebSearch` | sonnet |
| `loop-drafter` | `Read` | sonnet |
| `loop-critic` | `Read` | sonnet |
| `loop-refiner` | `Read` | sonnet |

Specialists do not have `Write`; they return their output as the subagent result. The orchestrator does not have `Write` either — the final draft is returned to the main thread as text and the user decides where to save it.

**Marketplace registration.** Add an entry to `.claude-plugin/marketplace.json`:

```json
{
  "name": "s3lab-loop",
  "source": "./plugins/s3lab-loop",
  "description": "Goal-driven research-draft-critique-refine loop orchestrator."
}
```

## 6. Data flow and specialist contracts

Pseudocode the orchestrator follows:

```
goal     = main thread input
plan     = call decomposer(goal)
research = call researcher(goal, plan)
draft    = call drafter(goal, plan, research)

for i in 1..3:
    verdict = call critic(goal, draft)
    if verdict.status == "done":
        break
    draft = call refiner(goal, draft, verdict.weak_points)

return {
    final_draft: draft,
    iterations: i,
    verdict: "done" | "max_rounds_reached" | "refine_failed",
    notes: [...]
}
```

Subagent input/output contracts:

| Agent | Prompt input (orchestrator → specialist) | Return output (specialist → orchestrator) |
|---|---|---|
| `loop-decomposer` | `GOAL: <text>` | A single block containing `PLAN:` (ordered Markdown list, 3–7 steps) followed by `AC:` (bullet checklist of acceptance criteria). Orchestrator forwards this block intact wherever `<plan>` is referenced below. |
| `loop-researcher` | `GOAL: <text>\nPLAN: <plan>` | `RESEARCH:` — bullet facts with inline sources (`[url]` for web, `[file:line]` for repo). Soft cap ≤ 500 words. |
| `loop-drafter` | `GOAL: <text>\nPLAN: <plan>\nRESEARCH: <bundle>` | Full draft in Markdown. Draft only, no preamble or commentary. The drafter is the one consumer of the AC checklist — it uses AC to self-check coverage before returning. |
| `loop-critic` | `GOAL: <text>\nDRAFT:\n<draft>` | YAML block: `verdict: done` or `verdict: revise` plus `weak_points: [...]` (each with `severity`, `location`, `issue`). |
| `loop-refiner` | `GOAL: <text>\nDRAFT:\n<draft>\nWEAK_POINTS: <list>` | Revised draft in Markdown. Draft only, no preamble. |

Token-economy details:

- Critic input excludes plan, research, and previous critiques. Each critic call sees only goal + current draft.
- Refiner input excludes previous drafts and previous critiques. It sees only goal + current draft + the latest `weak_points` list.
- Research is computed once before the refine loop. The orchestrator keeps the bundle in its own context; specialists do not re-fetch.
- Critic returns YAML, not free text, so the orchestrator parses the verdict deterministically without spending model tokens on interpretation.

Final return to main thread, exact format:

```
LOOP COMPLETE
Iterations: <n> / 3
Verdict: <done|max_rounds_reached|refine_failed|error>
Notes: <comma-separated notes, or "none">

--- DRAFT ---
<full final draft text, or "(none)" if error>
```

## 7. Stops, errors, fallbacks

Stop conditions (only these three):

| Trigger | Orchestrator action |
|---|---|
| `critic.verdict == "done"` | Break loop. Return current draft, `verdict: done`. |
| Iteration counter reaches 3 | Break loop. Return current draft, `verdict: max_rounds_reached`. |
| User Ctrl+C | Subagent chain is killed. Main thread receives cancellation. In-memory state is lost — accepted trade-off per §3 (no persistence). |

Specialist failure handling:

| Failure | Recovery |
|---|---|
| `decomposer` returns empty or unparseable plan | Abort. Orchestrator returns to main: `error: decomposer produced no plan; refine goal text`. No retry — empty plans usually mean weak goal text. |
| `researcher` fails (network error, tool error, timeout) | Degrade: continue with `RESEARCH: <empty>`. Add `research: skipped due to error` to `notes`. Pipeline proceeds. |
| `drafter` returns empty | One retry with hint `"previous attempt returned empty"`. Second empty → abort, error to main. |
| `critic` returns unparseable YAML | One retry with hint `"your previous response was not valid YAML; respond only with valid YAML matching the schema"`. Second unparseable → treat as `verdict: revise`, `weak_points: ["critic output unparseable"]`, proceed to refine. |
| `refiner` returns empty or strictly shorter / worse | Treat as plateau. Break loop. Return **previous draft** (last good), `verdict: refine_failed`, note `refiner regressed at iteration <i>`. |

Explicit non-handling:

- **Malformed goal.** No validation. Orchestrator tries honestly; if decomposer fails, the error surfaces.
- **Critic plateau.** Not detected. Three rounds always run when critic keeps saying revise — per §3 (Q7=A).
- **Concurrent loops.** Not prevented. User running two `/s3lab-loop` invocations gets two independent subagent chains. v1 does not lock.

## 8. Acceptance scenarios

Manual verification, executed against an install of `s3lab-loop` in a test repo.

1. **Happy path / done early.**
   Goal: `"Напиши 3-абзацное summary архитектуры s3lab-policy плагина."`
   Expected: 1/3 iterations, `verdict: done`. Final draft is a coherent 3-paragraph summary.

2. **Refinement loop fires.**
   Goal with intentionally vague or conflicting requirements.
   Expected: critic returns `revise` at least once, refiner produces a changed draft, loop terminates either by `done` on iteration 2 or 3, or by `max_rounds_reached` at 3/3. Verdict reflects what happened.

3. **Max rounds reached.**
   Goal: deliberately impossible (`"Докажи P=NP в 200 слов."`).
   Expected: 3/3 iterations, `verdict: max_rounds_reached`, no infinite loop, no crash.

4. **Researcher graceful degrade.**
   Goal that needs web search, executed in an environment where `WebFetch` is unavailable.
   Expected: researcher fails, orchestrator continues with empty research, draft still produced, `notes` includes `research skipped due to error`.

5. **Decomposer abort.**
   Goal: `"."` (garbage).
   Expected: decomposer returns empty plan, orchestrator aborts cleanly with `error: decomposer produced no plan`. No stack trace, no partial output.

6. **Critic malformed YAML retry.**
   Not deterministically reproducible. Spot check: if a critic call ever returns invalid YAML during scenarios 2 or 3, the retry path must be visible in token counts or visible orchestrator messaging.

7. **Token economy spot check.**
   After scenario 2 completes, the main thread context must contain only the user's `/s3lab-loop` invocation and the orchestrator's final block (`LOOP COMPLETE ...`). No specialist prompts, no intermediate drafts, no critic YAML. Verify via `/context` or transcript inspection.

Verification gates before merge:

- Scenario 1 passes manually.
- Scenario 3 passes manually.
- Scenario 7 passes by visual inspection.

## 9. Out of scope / future iterations

- Persisting state to `.s3lab-loop/<id>/` to support `/s3lab-loop resume`, `/s3lab-loop list`, `/s3lab-loop show`.
- Configurable `MAX_REFINE_ROUNDS`, model selection, or specialist toggles via plugin config.
- Domain-specific specialist packs (engineering, research, writing) loaded behind a flag.
- Plateau detection and early stop heuristics.
- Token-budget cap independent of iteration count.
- Hook integration (e.g., `SessionStart` ensuring agents are registered).
- Cross-vendor support (Cursor, Codex).
- Loop telemetry to a usage log.

## 10. Risks

- **Subagent nesting limits.** The orchestrator is itself a subagent spawning further subagents. If Claude Code restricts nested subagent calls, the design collapses to flat (main thread orchestrates). Mitigation: validate nested-subagent behavior in scenario 1 before building the full specialist set.
- **YAML parser fragility.** Critic output is contractually YAML; LLMs drift toward freeform. The single-retry rule mitigates but does not eliminate this. Mitigation: keep the schema tiny and explicit in the critic agent's instructions.
- **Specialist drift.** Each specialist is a markdown file; over time their instructions may diverge from the orchestrator's contract. Mitigation: include the input/output contracts from §6 verbatim in each agent file, so the contract lives next to the agent that satisfies it.
- **Cold-start cost.** Each specialist invocation pays subagent startup cost. For very small goals, this may exceed the token savings from isolation. Mitigation: accepted in v1; future iteration may collapse stages for tiny goals.
- **User Ctrl+C loses work.** No persistence means an interrupted long run produces nothing. Accepted per §3 (Q8=A); a future iteration can add file-backed state.
