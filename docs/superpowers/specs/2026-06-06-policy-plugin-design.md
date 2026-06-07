# s3lab-policy Plugin — Design

- Date: 2026-06-06
- Owner: Андрей Сазонов (sien.inbox@gmail.com)
- Status: Approved (brainstorm phase)
- Repo: `s3lab-ai-kit`
- Spec depends on: `2026-06-06-marketplace-design.md` (the marketplace this plugin ships in)

## 1. Goal

Create a mandatory, install-once Claude Code plugin (`s3lab-policy`) that, after `/plugin install s3lab-policy@s3lab`, automatically installs git `pre-commit` and `pre-push` hooks into any repository where Claude Code starts. These hooks use `gitleaks` to block commits or pushes that contain secrets (passwords, tokens, API keys, private keys, connection strings with credentials, and similar confidential material).

`s3lab-policy` is positioned as the baseline policy plugin for every s3lab project. Secrets-guard is the MVP; broader common rules (commit message conventions, branch naming, lint baselines, etc.) are explicitly out of scope for this spec and will land in follow-up specs.

## 2. Non-goals

- Enforce secrets-guard server-side (GitLab/GitHub CI, push proxy). Out of scope.
- Mutate non-Claude-Code git environments (Cursor, Codex, plain shell users without Claude Code installed). The git hooks themselves are tool-agnostic and protect any caller, but distribution is via Claude Code only.
- Build common project conventions content (commit message rules, branch naming, lint baselines). The plugin will host those later — they are separate specs.
- Add custom s3lab-specific gitleaks rules. The MVP uses gitleaks defaults (~150 built-in patterns) plus a per-repo allowlist. Custom rules are a follow-up.
- Prevent the user from running `git commit --no-verify` or `git push --no-verify`. Git built-in bypass is not blocked — `/policy-status` surfaces when bypass was used so reviewers can see it.
- Cover hooks beyond pre-commit and pre-push (e.g., commit-msg, prepare-commit-msg). Not needed for secrets detection.

## 3. Decisions captured in brainstorming

| Question | Decision |
|---|---|
| Distribution scope | Plugin in the s3lab marketplace |
| Plugin name | `s3lab-policy` (mandatory baseline; secrets-guard is MVP, common rules later) |
| Install trigger | `SessionStart` hook auto-installs into the cwd repository |
| Scanner engine | `gitleaks` |
| Git events covered | `pre-commit` + `pre-push` |
| Behavior if gitleaks missing | Auto-install via `brew install gitleaks` (macOS-first); if brew unavailable, print install instruction and continue (do not block install) |
| User-managed pre-commit/pre-push without sentinel | Do NOT overwrite; print a notice and offer `/policy-status` |
| Bypass | `--no-verify` left intact (git built-in); `/policy-status` exposes bypass usage for review visibility |

## 4. Plugin layout

```
plugins/s3lab-policy/
├── .claude-plugin/
│   └── plugin.json
├── hooks/
│   └── hooks.json                       # SessionStart → install-policy.mjs
├── scripts/
│   ├── install-policy.mjs               # idempotent installer (called by SessionStart hook)
│   ├── ensure-gitleaks.mjs              # which gitleaks || brew install gitleaks
│   ├── pre-commit.sh                    # template copied into <repo>/.git/hooks/pre-commit
│   ├── pre-push.sh                      # template copied into <repo>/.git/hooks/pre-push
│   └── gitleaks.toml                    # template copied into <repo>/.s3lab-policy/gitleaks.toml
├── commands/
│   └── policy-status.md                 # /policy-status slash command
├── skills/
│   └── secrets-incident-response/
│       └── SKILL.md                     # recovery procedure when a secret already landed in history
└── agents/                              # reserved (empty)
```

`plugin.json` (version `0.1.0` for the MVP). The `SCHEMA_VERSION` constant used in installed hook sentinels equals the plugin version.

## 5. Marketplace integration

Add `s3lab-policy` to `.claude-plugin/marketplace.json` as the first entry, in front of `s3lab-engineering`, so the install order makes the mandatory baseline obvious:

```json
{
  "name": "s3lab-policy",
  "source": "./plugins/s3lab-policy",
  "description": "Обязательный baseline: secrets-guard на git pre-commit/pre-push, общие правила для всех s3lab-проектов."
}
```

Update `README.md`'s `## Marketplace (Claude Code)` section:
- Note that `s3lab-policy` is required and should be installed first.
- Show the install command immediately after the marketplace-add command.

## 6. SessionStart hook contract

`hooks/hooks.json`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "node \"${CLAUDE_PLUGIN_ROOT}/scripts/install-policy.mjs\"",
            "timeout": 30,
            "statusMessage": "s3lab-policy: checking guard hooks…"
          }
        ]
      }
    ]
  }
}
```

`install-policy.mjs` runs once per Claude Code session start.

Pseudocode:

```
1. cwd = process.cwd()
2. Run `git rev-parse --git-dir` → if fails, emit {"systemMessage": "s3lab-policy: not a git repo, skipping"} and exit 0.
3. gitDir = stdout of step 2 (absolute path).
4. Run ensure-gitleaks.mjs:
   - which gitleaks → if found, return ok.
   - which brew → if found, attempt `brew install gitleaks`. On non-zero exit, return missing.
   - Otherwise return missing.
5. For each (name, source) in [(pre-commit, scripts/pre-commit.sh), (pre-push, scripts/pre-push.sh)]:
   - target = path.join(gitDir, "hooks", name)
   - read target if exists; detect sentinel "# s3lab-policy v<version>" on first 10 lines.
   - if file missing → write template, chmod 0755.
   - if sentinel present and version == current → no-op.
   - if sentinel present and version older → copy existing to target.bak; write template; chmod 0755.
   - if file present without sentinel → leave intact; collect into userManagedHooks[].
6. Ensure gitleaks config:
   - repoRoot = `git rev-parse --show-toplevel`
   - configPath = path.join(repoRoot, ".s3lab-policy", "gitleaks.toml")
   - same sentinel logic (sentinel here is a TOML comment "# s3lab-policy v<version>" on the first line).
7. Compose a systemMessage summary:
   - actions taken: ["installed pre-commit", "updated pre-push", …]
   - userManagedHooks warning, if any
   - gitleaks status: installed | auto-installed | missing-please-run
   - hint: "run /policy-status for details"
8. Exit 0.
```

Errors during step 4/5 should never block the Claude Code session: emit a systemMessage with the failure and exit 0. The hook itself becomes the next safety net.

## 7. Installed git hook scripts

### 7.1 `pre-commit.sh`

```sh
#!/usr/bin/env bash
# s3lab-policy v0.1.0
set -euo pipefail
if ! command -v gitleaks >/dev/null 2>&1; then
  echo "s3lab-policy: gitleaks not installed; run: brew install gitleaks" >&2
  exit 1
fi
CFG="$(git rev-parse --show-toplevel)/.s3lab-policy/gitleaks.toml"
exec gitleaks protect --staged --redact --no-banner --config "$CFG"
```

`gitleaks protect --staged` runs over the staged diff, redacts findings so they are not echoed back in plaintext, and returns a non-zero exit code on any hit. The non-zero exit aborts the commit.

### 7.2 `pre-push.sh`

```sh
#!/usr/bin/env bash
# s3lab-policy v0.1.0
set -euo pipefail
if ! command -v gitleaks >/dev/null 2>&1; then
  echo "s3lab-policy: gitleaks not installed; run: brew install gitleaks" >&2
  exit 1
fi
CFG="$(git rev-parse --show-toplevel)/.s3lab-policy/gitleaks.toml"
# Determine the commit range being pushed.
if range_start=$(git rev-parse '@{push}' 2>/dev/null); then
  :
elif range_start=$(git rev-parse origin/HEAD 2>/dev/null); then
  :
else
  # First push or no upstream — scan from the branch's root commit forward.
  range_start=$(git rev-list --max-parents=0 HEAD | tail -n 1)
fi
exec gitleaks detect --log-opts="${range_start}..HEAD" --redact --no-banner --config "$CFG"
```

`gitleaks detect` walks the commit range and exits non-zero on any hit, aborting the push.

### 7.3 `gitleaks.toml`

```toml
# s3lab-policy v0.1.0
[extend]
useDefault = true

[allowlist]
description = "Per-repo overrides — add paths or regexes here to silence false positives. Commit this file so the team agrees on what is allowlisted."
paths = []
regexes = []
```

This file lives at `<repo>/.s3lab-policy/gitleaks.toml` and is intended to be committed. The hook templates point at this path explicitly so allowlist edits travel with the repo and are visible in code review.

## 8. `/policy-status` slash command

`commands/policy-status.md` instructs Claude to gather and print, in this exact order, inside a single fenced code block:

1. Plugin version, read from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json` (Claude Code injects `CLAUDE_PLUGIN_ROOT` as the plugin's installed directory). If the path does not resolve, print `unknown`.
2. Installed `pre-commit` version (parsed from sentinel on the first 10 lines of `.git/hooks/pre-commit`), or `user-managed` if the hook exists without a sentinel, or `missing` if absent.
3. Installed `pre-push` version, same rules against `.git/hooks/pre-push`.
4. gitleaks config version (parsed from `# s3lab-policy v<version>` on line 1 of `.s3lab-policy/gitleaks.toml`), or `user-managed` / `missing` per the hook rules.
5. `gitleaks version` output (`gitleaks` subcommand, no dashes), or `not installed`.
6. The 20 most recent commits from `git log --pretty=format:'%h %s' -n 20`, each annotated `[unknown]`. The command does NOT attempt to distinguish verified from bypassed commits — bypass detection from local state is unreliable (git does not record `--no-verify` in the reflog message or anywhere readable post-hoc), so honest annotation is `[unknown]`.
7. A one-line summary: `OK` if hook and config sentinel versions all equal the plugin version and `gitleaks` is installed; otherwise `ATTENTION`.

The command body is purely a read operation — no writes, no installs, no auto-fix. If the summary is `ATTENTION`, the command lists each specific reason after the code block in plain text. It mentions `/plugin install s3lab-policy@s3lab` only if step 1's plugin manifest could not be read.

## 9. `secrets-incident-response` skill

`skills/secrets-incident-response/SKILL.md` is a short, ordered runbook that activates when the user asks about a leaked or about-to-be-leaked secret. It walks the user through:

1. **Revoke first.** Identify which provider (AWS, GitHub, Slack, Postgres, etc.) issued the secret. Revoke or rotate via the provider's UI/CLI before any git surgery — once a secret is out, treat it as compromised.
2. **Confirm exposure.** `git log -p -S '<token-fragment>' --all` to find every commit and branch carrying it. Check whether the commit was already pushed to `origin`.
3. **Rewrite history if local only.** `git filter-repo --replace-text` or `git rebase -i` to drop or scrub the commit.
4. **Rewrite history if already pushed.** Coordinate with collaborators, then `git filter-repo` followed by `git push --force-with-lease` to every branch and tag that contained the secret. Explicitly note that force-push is destructive and requires team coordination.
5. **Invalidate caches.** CI artifact stores, deployment slots, container layers, log aggregators — every place that may have cached the secret needs the new value.
6. **Postmortem.** Record what leaked, when, who rotated it, and what control failed (was the hook bypassed? was the file outside the staged scan?). This feeds future allowlist tightening or rule additions.

The skill does NOT auto-run filter-repo — it walks the user through each step and waits for confirmation between destructive actions.

## 10. README update

Update `README.md`'s `## Marketplace (Claude Code)` section:

- Insert `s3lab-policy` as the first plugin in the list, with a `mandatory baseline` badge in prose ("установите первым — обязательный baseline для всех s3lab-проектов").
- Add a "Что включает baseline" sub-paragraph: `pre-commit` + `pre-push` блокируют secrets через `gitleaks`; per-repo allowlist в `.s3lab-policy/gitleaks.toml`; recovery skill `secrets-incident-response`.
- Show the install command sequence:

```text
/plugin marketplace add /Users/saa/Projects/s3lab/s3lab-ai-kit
/plugin install s3lab-policy@s3lab
/plugin install s3lab-engineering@s3lab    # остальные — по необходимости
```

## 11. Acceptance tests

Manual acceptance after implementation:

1. **Fresh install.** In a clean git repo without prior hooks, install `s3lab-policy`, restart Claude Code. After SessionStart: `.git/hooks/pre-commit` and `.git/hooks/pre-push` exist with sentinel `# s3lab-policy v0.1.0`, both executable; `.s3lab-policy/gitleaks.toml` exists with sentinel.
2. **Idempotency.** Restart the session in the same repo. `install-policy.mjs` emits a `up-to-date` systemMessage and does not modify any file (verified via `mtime` snapshot before/after).
3. **User-managed hooks.** Add a pre-commit hook without sentinel, restart. `install-policy.mjs` does NOT overwrite it; systemMessage names the file as user-managed and points to `/policy-status`.
4. **Block secret commit.** `echo 'AWS_SECRET_ACCESS_KEY=AKIA1234567890ABCDEF' > leak.txt && git add leak.txt && git commit -m test` exits non-zero with a gitleaks finding (redacted). Without `--no-verify`, the commit does not land.
5. **Block secret push.** Bypass commit with `--no-verify`, then `git push` against a remote: pre-push hook scans the commit range, blocks the push with a gitleaks finding.
6. **gitleaks bootstrap.** On a machine with brew but without gitleaks, SessionStart triggers `brew install gitleaks`; subsequent commits enforce the rule.
7. **gitleaks missing + no brew.** SessionStart emits a `please install gitleaks` systemMessage and does not abort; the hooks themselves print the install instruction and exit 1 when invoked, blocking commits until gitleaks lands.
8. **/policy-status.** Run in the repo from acceptance 1; output lists plugin version (from `${CLAUDE_PLUGIN_ROOT}`), hook versions, gitleaks config version, gitleaks binary version, and at least the last 20 commits each annotated `[unknown]`. The summary line is `OK` when sentinel versions all match the plugin version and `gitleaks` is installed.
9. **Per-repo allowlist.** Add a regex to `.s3lab-policy/gitleaks.toml` `[allowlist]` block, commit; previously-blocked content (matching the regex) now passes pre-commit.

No automated test harness is introduced — the plugin is integration-heavy and is best validated by these manual scenarios.

## 12. Risks

- **SessionStart mutates a third-party repo without prior consent.** The first install writes files into `.git/hooks/` and creates `.s3lab-policy/`. Mitigation: explicit `systemMessage` on first install, sentinel-based idempotency, refusal to overwrite user-managed hooks, and `/policy-status` for transparent state.
- **`brew install gitleaks` requires network and may prompt for sudo on some configurations.** Mitigation: errors during install are logged but do not block the Claude Code session; the hook itself shows a clear install instruction the next time it runs.
- **`--no-verify` bypass.** Git itself allows commits and pushes to skip hooks. Mitigation: this spec accepts the bypass exists; `/policy-status` exposes recent bypass usage so review can challenge it. A future iteration may add a server-side guard.
- **False positives blocking real work.** Default gitleaks rules occasionally match high-entropy strings that are not secrets. Mitigation: per-repo `[allowlist]` block in `.s3lab-policy/gitleaks.toml`. Reviewers see allowlist edits in PRs.
- **Sentinel drift between plugin version and installed hook version.** A plugin upgrade may silently overwrite a customized hook. Mitigation: `install-policy.mjs` creates `*.bak` before overwriting any sentinel-marked file; user can diff and merge customizations forward.
- **Worktrees and submodules.** `git rev-parse --git-dir` returns the worktree git dir, which may not be the main `.git/hooks/` directory. Mitigation: install-policy resolves and writes to whichever path `git rev-parse --git-dir` reports, which is correct for git's own resolution; if the path is not writable, the script logs and exits 0.

## 13. Out of scope / follow-ups

- Common project rules content (commit message format, branch naming, lint baselines) — separate specs landing in `s3lab-policy/skills/` and `s3lab-policy/agents/`.
- Custom s3lab gitleaks rules beyond the default ruleset — separate spec once domain-specific patterns are catalogued.
- Server-side enforcement on GitLab/GitHub.
- Cross-vendor coverage (Cursor, Codex installer parity).
- CI integration that scans PRs server-side.
- A `policy-update` slash command that bumps installed hooks without waiting for SessionStart.
- Reliable bypass detection. Git does not record `--no-verify` in any reflog-readable form, so `/policy-status` annotates every recent commit as `[unknown]`. A future iteration could write a per-commit sidecar marker file from the installed hooks (e.g., `.s3lab-policy/verified/<sha>`) and have `/policy-status` check membership.
