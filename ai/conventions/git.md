# Git workflow

How code flows through git in s3lab projects.

## Branch model

- Trunk-based: `main` is always deployable.
- Feature branches short-lived (hours to days, not weeks).
- Branch names: `feat/<slug>`, `fix/<slug>`, `chore/<slug>`, `docs/<slug>`, `refactor/<slug>`.
- Slug is kebab-case, descriptive: `feat/order-excel-export`, not `feat/branch-1`.

## Commits

- **Conventional Commits**: `type(scope): subject`.
- Types: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `perf`, `style`, `build`, `ci`.
- Scope is the affected service or area: `feat(orders): add excel export endpoint`.
- Subject in imperative present tense, lowercase, no trailing period.
- Body explains *why*, not *what* (the diff shows what). Body separated by blank line.
- Breaking change: `feat(orders)!: rename status column`, plus a `BREAKING CHANGE:` line in body.

## Pull requests

- One PR per logical change. Big features → multiple PRs (stack them or use feature flags).
- PR title follows Conventional Commits — it becomes the squash-merge commit.
- PR description filled from `.github/PULL_REQUEST_TEMPLATE.md`.
- Link the issue: `Closes #123` or `Refs #123`.
- Self-review the diff before requesting review.
- CI must pass. Reviewer agent reports no 🛑.

## Merging

- Squash merge by default. The PR title is the commit message.
- Linear history on `main`. No merge commits.
- Delete branch after merge.

## Rebasing and force-push

- Rebase your branch on `main` before opening a PR if `main` moved significantly.
- Force-push on your own feature branches is fine. Use `--force-with-lease`, not `--force`.
- Never force-push to `main`.

## Tags and releases

- Semver tags: `v1.2.3`.
- Tag from `main` after successful deploy.
- `CHANGELOG.md` updated as part of the tagging PR.

## .gitignore essentials

- `.env`, `*.env.local` (NEVER commit secrets).
- `bin/`, `obj/`, `node_modules/`, `dist/`, `coverage/`, `*.log`.
- IDE files: `.vscode/`, `.idea/` (or commit a curated subset like `.vscode/settings.json` if team-shared).
- OS noise: `.DS_Store`, `Thumbs.db`.

## Submodules

- `.ai-kit` is a submodule pinned to a specific commit. Update with `git submodule update --remote .ai-kit`.
- Submodule bump is its own commit with message: `chore: bump ai-kit to v<version>`.
