---
description: Review an existing PR via the reviewer agent
argument-hint: <PR number>
---

# /review-pr

Run a thorough review on an existing PR.

## Steps

### 1. Fetch the PR
```
gh pr view $ARGUMENTS
gh pr diff $ARGUMENTS > /tmp/pr-diff.patch
gh pr checkout $ARGUMENTS
```

### 2. Run reviewer
Invoke the `reviewer` subagent. Pass:
- The PR number
- The diff
- The PR description and linked issue

### 3. Report findings
Post the reviewer's output back to the PR as a comment (if the user confirms):

```
gh pr comment $ARGUMENTS --body "$(cat <review-output>)"
```

Or just show it in the chat for the user to decide whether to comment.

### 4. Verification (optional, ask user)
Offer to run:
- `dotnet build && dotnet test` on the affected services
- `npm run build && npm test -- --watch=false` on the frontend
- `docker compose build` if infra changed

## PR number

$ARGUMENTS
