---
description: Diagnose and fix a bug via the s3lab agent pipeline
argument-hint: <bug description or issue number>
---

# /bugfix

Diagnose, fix, and verify a bug end-to-end.

## Input

Either:
- A free-form bug description, OR
- A GitHub issue number prefixed with `#` — fetch via `gh issue view <number>`.

## Pipeline

### 1. Reproduce
Before fixing anything, understand the bug:
- Read the bug description carefully.
- Use Read/Grep/Glob to locate the relevant code.
- If possible, write a failing test that reproduces the bug.
  - Backend: a xUnit test that fails.
  - Frontend: a Jasmine test or Playwright spec that fails.
- If reproduction isn't possible without more info, STOP and ask the user.

### 2. Decompose
Invoke the `orchestrator` subagent with:
- The bug description
- The failing test (if you wrote one)
- Your initial hypothesis

The plan should answer: which layer is the bug in? Which agent fixes it?

**Show the plan to the user. WAIT for confirmation.**

### 3. Branch
```
git checkout main && git pull
git checkout -b fix/<short-slug>
```

### 4. Fix
Based on the plan:
- Backend bug → `backend-dotnet`
- Frontend bug → `frontend-angular`
- Infra/deploy bug → `devops`
- Contract mismatch → `api-contract`

The implementer fixes the bug and is responsible for ensuring the failing test now passes.

### 5. Regression coverage
Invoke `tester`. Beyond the reproducer:
- Add at least one test covering the boundary the bug crossed.
- If the bug was a regression, link the test name to the bug ID in a comment.

### 6. Review
Invoke `reviewer`. Loop with the implementer until clean.

### 7. Commit and PR
```
git add -A
git commit -m "fix(<scope>): <one-line description>

<body explaining root cause>

Closes #<issue>"
git push -u origin fix/<slug>
gh pr create --title "<same>" --body "<filled from template>"
```

### 8. Final report

```
## Bug fixed

PR: <URL>
Root cause: <one sentence>
Fix: <one sentence>
Regression test: <test name>
```

## Bug description

$ARGUMENTS
