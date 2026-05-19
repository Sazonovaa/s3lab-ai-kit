---
description: Sync OpenAPI contract between backend and frontend
argument-hint: (no arguments needed)
---

# /sync-contract

Manually sync the OpenAPI contract and regenerate the frontend TypeScript client.
Useful when you suspect contract drift, or after a manual backend change.

## Steps

### 1. Run api-contract in Mode A
Invoke the `api-contract` subagent in **Mode A** (post-implementation sync):
- Build backend services to refresh OpenAPI.
- Copy the spec to the frontend's source location.
- Regenerate the TypeScript client.
- Verify the frontend builds.

### 2. Show diff
After regeneration, show the diff in `frontend/src/app/api/generated/`:
```
git diff frontend/src/app/api/generated/
```

### 3. Decide next step
- **If the diff is clean** (no changes): contract is already in sync. Report and stop.
- **If the diff shows changes**: report them. The user decides whether this is a clean
  sync or whether frontend code needs adjustment to match new types.
- **If the frontend build fails**: report the build errors. Likely the contract changed
  in a way that breaks existing frontend code — user must decide whether to update the
  frontend or revert the backend change.
