---
description: Run the full s3lab feature pipeline end-to-end
argument-hint: <feature description or issue number>
---

# /feature

Implement a new feature end-to-end via the s3lab agent pipeline.

## Input

The user's argument is either:
- A free-form feature description, OR
- A GitHub issue number (prefixed with `#`). If so, fetch the issue first:
  `gh issue view <number>` to get the description.

## Pipeline steps

Execute these in order. After each step, briefly report progress.

### 1. Decompose
Invoke the `orchestrator` subagent with the feature description.
Receive the structured plan.

**Show the plan to the user. WAIT for confirmation or corrections before proceeding.**

### 2. Branch
Create a feature branch from the latest `main`:
```
git checkout main && git pull
git checkout -b feat/<short-slug-derived-from-feature>
```

### 3. Design (if UI involved)
If the plan includes UI changes, invoke the `designer` subagent.
Show its output. **WAIT for user confirmation** before moving on.

### 4. API contract — spec phase
If the plan adds or changes API endpoints, invoke `api-contract` in **Mode B** to spec
endpoints first. This unblocks frontend work in parallel with backend.

### 5. Implementation (parallel where possible)
Based on the plan:
- For backend subtasks, invoke `backend-dotnet`.
- For frontend subtasks, invoke `frontend-angular`.
- If both are needed and there are no blocking dependencies between them after the
  contract is spec'd in step 4, run them as parallel subagent invocations.

### 6. API contract — sync phase
After backend implementation, invoke `api-contract` in **Mode A** to sync the
final OpenAPI and regenerate the frontend client.

If the frontend now uses methods that changed, re-invoke `frontend-angular`
with the diff context.

### 7. DevOps (if needed)
If the plan flagged deployment changes (new service, new env var, new dependency),
invoke `devops`.

### 8. Tests
Invoke `tester`. Run all relevant tests. If tests fail:
- If the test is wrong: tester fixes the test.
- If the code is wrong: loop back to the relevant implementer with the failure context.

### 9. Review
Invoke `reviewer`. If it reports any 🛑 findings:
- Loop back to the relevant implementer with the findings.
- Re-run `tester` after fixes.
- Re-run `reviewer`.
- Repeat until no 🛑 findings.

### 10. Commit and open PR
Once clean:
```
git add -A
git commit -m "<conventional-commit-message-from-orchestrator-plan>"
git push -u origin <branch-name>
gh pr create --title "<same as commit>" --body "$(cat .github/PULL_REQUEST_TEMPLATE.md filled in)"
```

Use `.github/PULL_REQUEST_TEMPLATE.md` as the template, fill in:
- What changed (from agent reports)
- Why
- Test plan (from tester report)
- Linked issue (if applicable)

### 11. Final report

```
## Feature complete

PR: <URL from gh pr create>
Branch: <branch>
Commits: <count>

## Agent invocations
- orchestrator: 1
- designer: <count>
- backend-dotnet: <count>
- frontend-angular: <count>
- api-contract: <count>
- tester: <count>
- reviewer: <count>

## Reviewer findings
- 🛑: 0
- ⚠️: <count>
- Resolved in loop: <count>

## Next step
Human review the PR and merge when ready.
```

Stop. Do not auto-merge.

## Feature description

$ARGUMENTS
