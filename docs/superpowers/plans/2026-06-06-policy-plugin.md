# s3lab-policy Plugin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship `s3lab-policy` as the first plugin in the s3lab marketplace, with a `SessionStart` hook that auto-installs `gitleaks`-backed `pre-commit` and `pre-push` hooks plus a per-repo `gitleaks.toml` allowlist into any git repository where Claude Code starts.

**Architecture:** Plugin lives at `plugins/s3lab-policy/`. A `SessionStart` hook in the plugin runs `scripts/install-policy.mjs` (Node 18+), which resolves the cwd's git dir, ensures `gitleaks` is on PATH (auto-installs via `brew` if missing), and copies sentinel-marked templates (`pre-commit.sh`, `pre-push.sh`, `gitleaks.toml`) into `.git/hooks/` and `<repo>/.s3lab-policy/`. Sentinel `# s3lab-policy v<version>` makes installs idempotent and prevents overwriting user-managed hooks.

**Tech Stack:** Node.js 18+ ESM, POSIX `bash`, `gitleaks`, JSON manifests, Markdown for slash commands and skills.

**Spec:** `docs/superpowers/specs/2026-06-06-policy-plugin-design.md`

**Working directory for all commands below:** `/Users/saa/Projects/s3lab/s3lab-ai-kit`

---

## File Structure

Files this plan creates:

```
plugins/s3lab-policy/
├── .claude-plugin/plugin.json
├── hooks/hooks.json
├── scripts/
│   ├── install-policy.mjs
│   ├── ensure-gitleaks.mjs
│   ├── pre-commit.sh
│   ├── pre-push.sh
│   └── gitleaks.toml
├── commands/policy-status.md
├── skills/secrets-incident-response/SKILL.md
└── agents/.gitkeep
```

Files this plan modifies:
- `.claude-plugin/marketplace.json` — prepend `s3lab-policy` as the first plugin entry.
- `README.md` — promote `s3lab-policy` as mandatory in the existing `## Marketplace (Claude Code)` section.

Single-responsibility rationale: `install-policy.mjs` owns the install orchestration; `ensure-gitleaks.mjs` owns the binary-presence check; each `pre-commit.sh`/`pre-push.sh` owns one git-event guard; `gitleaks.toml` owns scan configuration. Skills and commands are independent docs.

---

## Task 1: Scaffold the `s3lab-policy` plugin skeleton

**Files:**
- Create: `plugins/s3lab-policy/.claude-plugin/plugin.json`
- Create: `plugins/s3lab-policy/agents/.gitkeep`

- [ ] **Step 1: Create directories**

```bash
mkdir -p plugins/s3lab-policy/.claude-plugin
mkdir -p plugins/s3lab-policy/hooks
mkdir -p plugins/s3lab-policy/scripts
mkdir -p plugins/s3lab-policy/commands
mkdir -p plugins/s3lab-policy/skills/secrets-incident-response
mkdir -p plugins/s3lab-policy/agents
```

- [ ] **Step 2: Write `plugin.json`**

File: `plugins/s3lab-policy/.claude-plugin/plugin.json`

```json
{
  "name": "s3lab-policy",
  "version": "0.1.0",
  "description": "Обязательный baseline: secrets-guard на git pre-commit/pre-push, общие правила для всех s3lab-проектов.",
  "author": {
    "name": "s3lab",
    "email": "sien.inbox@gmail.com"
  }
}
```

- [ ] **Step 3: Add `.gitkeep` to empty `agents/`**

```bash
: > plugins/s3lab-policy/agents/.gitkeep
```

- [ ] **Step 4: Validate manifest**

Run:
```bash
jq . plugins/s3lab-policy/.claude-plugin/plugin.json > /dev/null && echo "plugin.json OK"
```
Expected: `plugin.json OK`, exit code 0.

- [ ] **Step 5: Commit**

```bash
git add plugins/s3lab-policy/.claude-plugin plugins/s3lab-policy/agents
git commit -m "feat(policy): scaffold s3lab-policy plugin skeleton"
```

---

## Task 2: Write hook script templates and gitleaks config template

These three files are templates copied verbatim into target repositories by `install-policy.mjs`. They contain the `# s3lab-policy v0.1.0` sentinel on the first content line so the installer can detect version drift.

**Files:**
- Create: `plugins/s3lab-policy/scripts/pre-commit.sh`
- Create: `plugins/s3lab-policy/scripts/pre-push.sh`
- Create: `plugins/s3lab-policy/scripts/gitleaks.toml`

- [ ] **Step 1: Write `pre-commit.sh`**

File: `plugins/s3lab-policy/scripts/pre-commit.sh`

```bash
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

- [ ] **Step 2: Write `pre-push.sh`**

File: `plugins/s3lab-policy/scripts/pre-push.sh`

```bash
#!/usr/bin/env bash
# s3lab-policy v0.1.0
set -euo pipefail

if ! command -v gitleaks >/dev/null 2>&1; then
  echo "s3lab-policy: gitleaks not installed; run: brew install gitleaks" >&2
  exit 1
fi

CFG="$(git rev-parse --show-toplevel)/.s3lab-policy/gitleaks.toml"

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

- [ ] **Step 3: Write `gitleaks.toml`**

File: `plugins/s3lab-policy/scripts/gitleaks.toml`

```toml
# s3lab-policy v0.1.0
[extend]
useDefault = true

[allowlist]
description = "Per-repo overrides — add paths or regexes here to silence false positives. Commit this file so the team agrees on what is allowlisted."
paths = []
regexes = []
```

- [ ] **Step 4: Mark shell scripts executable in source tree**

Even though they will be re-`chmod`'d at install time, set the executable bit in the repo so the file mode is part of git history.

```bash
chmod +x plugins/s3lab-policy/scripts/pre-commit.sh plugins/s3lab-policy/scripts/pre-push.sh
```

- [ ] **Step 5: Syntax-check the shell scripts**

Run:
```bash
bash -n plugins/s3lab-policy/scripts/pre-commit.sh && echo "pre-commit.sh OK"
bash -n plugins/s3lab-policy/scripts/pre-push.sh && echo "pre-push.sh OK"
```
Expected: both lines print `OK`, exit code 0 each.

- [ ] **Step 6: Verify sentinel is on the expected line**

Run:
```bash
head -2 plugins/s3lab-policy/scripts/pre-commit.sh | tail -1
head -2 plugins/s3lab-policy/scripts/pre-push.sh | tail -1
head -1 plugins/s3lab-policy/scripts/gitleaks.toml
```
Expected: all three commands print a line containing `# s3lab-policy v0.1.0`.

- [ ] **Step 7: Commit**

```bash
git add plugins/s3lab-policy/scripts/pre-commit.sh plugins/s3lab-policy/scripts/pre-push.sh plugins/s3lab-policy/scripts/gitleaks.toml
git commit -m "feat(policy): add pre-commit, pre-push, and gitleaks.toml templates"
```

---

## Task 3: Implement `ensure-gitleaks.mjs`

This module exposes `ensureGitleaks()` (used by the installer) and also works as a standalone CLI for ad-hoc checks. It never throws — it returns a status object the caller decides what to do with.

**Files:**
- Create: `plugins/s3lab-policy/scripts/ensure-gitleaks.mjs`

- [ ] **Step 1: Write the module**

File: `plugins/s3lab-policy/scripts/ensure-gitleaks.mjs`

```js
#!/usr/bin/env node
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

export function ensureGitleaks() {
  const which = spawnSync('which', ['gitleaks'], { encoding: 'utf8' });
  if (which.status === 0) {
    return { status: 'present', path: (which.stdout || '').trim() };
  }
  const brew = spawnSync('which', ['brew'], { encoding: 'utf8' });
  if (brew.status !== 0) {
    return { status: 'missing-no-brew' };
  }
  const install = spawnSync('brew', ['install', 'gitleaks'], { encoding: 'utf8' });
  if (install.status === 0) {
    return { status: 'installed' };
  }
  const errorText = (install.stderr || install.stdout || '').toString().slice(0, 500);
  return { status: 'install-failed', error: errorText };
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const result = ensureGitleaks();
  process.stdout.write(JSON.stringify(result) + '\n');
}
```

- [ ] **Step 2: Syntax-check**

Run:
```bash
node --check plugins/s3lab-policy/scripts/ensure-gitleaks.mjs && echo "ensure-gitleaks.mjs OK"
```
Expected: `ensure-gitleaks.mjs OK`, exit code 0.

- [ ] **Step 3: Smoke-run the standalone CLI**

Run:
```bash
node plugins/s3lab-policy/scripts/ensure-gitleaks.mjs
```
Expected: a single JSON line. On a machine with `gitleaks` already installed: `{"status":"present","path":"/some/path/gitleaks"}`. On a machine without it but with brew, the command may install gitleaks — that is acceptable (brew is the intended bootstrap path). On a machine without brew: `{"status":"missing-no-brew"}`.

If the smoke-run installed gitleaks via brew, this is the correct behavior — the spec accepts that the installer may bootstrap the binary. Re-run the command to confirm it now returns `{"status":"present",…}`.

- [ ] **Step 4: Commit**

```bash
git add plugins/s3lab-policy/scripts/ensure-gitleaks.mjs
git commit -m "feat(policy): add ensure-gitleaks helper module"
```

---

## Task 4: Implement `install-policy.mjs`

This is the SessionStart hook entrypoint. It resolves the cwd's git dir, ensures gitleaks, then copies the three templates (pre-commit, pre-push, gitleaks.toml) into the right paths with sentinel-based idempotency. Output is a single JSON line on stdout that Claude Code consumes as `systemMessage`.

**Files:**
- Create: `plugins/s3lab-policy/scripts/install-policy.mjs`

- [ ] **Step 1: Write the module**

File: `plugins/s3lab-policy/scripts/install-policy.mjs`

```js
#!/usr/bin/env node
import { spawnSync } from 'node:child_process';
import { mkdirSync, readFileSync, writeFileSync, existsSync, copyFileSync, chmodSync } from 'node:fs';
import { join, dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { ensureGitleaks } from './ensure-gitleaks.mjs';

const PLUGIN_VERSION = '0.1.0';
const SENTINEL_RE = /# s3lab-policy v([0-9]+\.[0-9]+\.[0-9]+)/;

const SELF_DIR = dirname(fileURLToPath(import.meta.url));

const HOOK_TEMPLATES = [
  { name: 'pre-commit', template: join(SELF_DIR, 'pre-commit.sh'), mode: 0o755 },
  { name: 'pre-push', template: join(SELF_DIR, 'pre-push.sh'), mode: 0o755 },
];
const CONFIG_TEMPLATE = { template: join(SELF_DIR, 'gitleaks.toml'), mode: 0o644 };

function emit(message) {
  process.stdout.write(JSON.stringify({ systemMessage: `s3lab-policy: ${message}` }) + '\n');
}

function runGit(args) {
  const r = spawnSync('git', args, { encoding: 'utf8' });
  return { ok: r.status === 0, stdout: (r.stdout || '').trim(), stderr: (r.stderr || '').trim() };
}

function sentinelVersionOf(filePath) {
  if (!existsSync(filePath)) return null;
  const head = readFileSync(filePath, 'utf8').split('\n').slice(0, 10).join('\n');
  const m = head.match(SENTINEL_RE);
  return m ? m[1] : null;
}

function installFile({ targetPath, templatePath, mode }) {
  const action = { target: targetPath };
  if (existsSync(targetPath)) {
    const ver = sentinelVersionOf(targetPath);
    if (ver === PLUGIN_VERSION) {
      action.status = 'up-to-date';
      return action;
    }
    if (ver) {
      copyFileSync(targetPath, `${targetPath}.bak`);
      copyFileSync(templatePath, targetPath);
      chmodSync(targetPath, mode);
      action.status = 'updated';
      action.previousVersion = ver;
      return action;
    }
    action.status = 'user-managed-skipped';
    return action;
  }
  mkdirSync(dirname(targetPath), { recursive: true });
  copyFileSync(templatePath, targetPath);
  chmodSync(targetPath, mode);
  action.status = 'installed';
  return action;
}

function main() {
  const gitDir = runGit(['rev-parse', '--git-dir']);
  if (!gitDir.ok) {
    emit('not a git repo, skipping guard install.');
    return;
  }
  const gitDirAbs = resolve(gitDir.stdout);

  const repoRoot = runGit(['rev-parse', '--show-toplevel']);
  if (!repoRoot.ok) {
    emit('git dir resolved but repo root missing, skipping.');
    return;
  }

  const gitleaks = ensureGitleaks();

  const actions = [];
  for (const t of HOOK_TEMPLATES) {
    actions.push({
      kind: 'hook',
      name: t.name,
      ...installFile({
        targetPath: join(gitDirAbs, 'hooks', t.name),
        templatePath: t.template,
        mode: t.mode,
      }),
    });
  }

  actions.push({
    kind: 'config',
    name: 'gitleaks.toml',
    ...installFile({
      targetPath: join(repoRoot.stdout, '.s3lab-policy', 'gitleaks.toml'),
      templatePath: CONFIG_TEMPLATE.template,
      mode: CONFIG_TEMPLATE.mode,
    }),
  });

  const installed = actions.filter(a => a.status === 'installed').map(a => a.name);
  const updated = actions.filter(a => a.status === 'updated').map(a => a.name);
  const userManaged = actions.filter(a => a.status === 'user-managed-skipped').map(a => a.name);

  const parts = [];
  if (installed.length) parts.push(`installed: ${installed.join(', ')}`);
  if (updated.length) parts.push(`updated: ${updated.join(', ')}`);
  if (userManaged.length) parts.push(`user-managed (skipped): ${userManaged.join(', ')} — run /policy-status`);
  if (!parts.length) parts.push('hooks up-to-date');
  parts.push(`gitleaks: ${gitleaks.status}`);

  emit(parts.join('; '));
}

main();
```

- [ ] **Step 2: Syntax-check**

Run:
```bash
node --check plugins/s3lab-policy/scripts/install-policy.mjs && echo "install-policy.mjs OK"
```
Expected: `install-policy.mjs OK`, exit code 0.

- [ ] **Step 3: Smoke-run inside this repo**

The current working directory is itself a git repo, so the script will attempt a real install here. Run:

```bash
node plugins/s3lab-policy/scripts/install-policy.mjs
```

Expected behavior:
- A single JSON line on stdout, shape: `{"systemMessage":"s3lab-policy: installed: pre-commit, pre-push, gitleaks.toml; gitleaks: present"}` (or `installed` if brew just installed it).
- `.git/hooks/pre-commit`, `.git/hooks/pre-push`, and `.s3lab-policy/gitleaks.toml` now exist with the sentinel on the first content line.

Verify:
```bash
head -2 .git/hooks/pre-commit | tail -1
head -2 .git/hooks/pre-push | tail -1
head -1 .s3lab-policy/gitleaks.toml
ls -l .git/hooks/pre-commit .git/hooks/pre-push
```
Expected: each `head` prints `# s3lab-policy v0.1.0`; both hook files are executable (mode `-rwxr-xr-x`).

- [ ] **Step 4: Smoke-run idempotency**

Run the installer a second time:
```bash
node plugins/s3lab-policy/scripts/install-policy.mjs
```
Expected: single JSON line of shape `{"systemMessage":"s3lab-policy: hooks up-to-date; gitleaks: present"}`. No `.bak` files appear.

```bash
ls .git/hooks/*.bak 2>/dev/null && echo "FAIL: stray .bak" || echo "OK: no .bak"
```
Expected: `OK: no .bak`.

- [ ] **Step 5: Add the install artifacts to `.gitignore`**

The installer wrote real hooks into the local `.git/hooks/` (which git doesn't track anyway) and `.s3lab-policy/gitleaks.toml` (which IS tracked by design and should land in repos that use the plugin). For this development repository, we still want the `.s3lab-policy/` directory committed — it serves as a live example. Confirm `.s3lab-policy/gitleaks.toml` is untracked and stage it explicitly in Step 6.

Run:
```bash
git status --porcelain .s3lab-policy/gitleaks.toml
```
Expected: a line like `?? .s3lab-policy/gitleaks.toml`.

- [ ] **Step 6: Commit installer + the live config artifact**

```bash
git add plugins/s3lab-policy/scripts/install-policy.mjs .s3lab-policy/gitleaks.toml
git commit -m "feat(policy): add install-policy SessionStart entrypoint"
```

---

## Task 5: Wire the SessionStart hook

`hooks.json` registers `install-policy.mjs` to fire on Claude Code session start. The `${CLAUDE_PLUGIN_ROOT}` placeholder is substituted by Claude Code with the plugin's directory at runtime, so the path resolves correctly even when the plugin is installed from a cache.

**Files:**
- Create: `plugins/s3lab-policy/hooks/hooks.json`

- [ ] **Step 1: Write `hooks.json`**

File: `plugins/s3lab-policy/hooks/hooks.json`

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

- [ ] **Step 2: Validate JSON and schema-relevant keys**

Run:
```bash
jq -e '.hooks.SessionStart[0].hooks[0] | select(.type=="command") | .command' plugins/s3lab-policy/hooks/hooks.json
```
Expected: exit 0, prints the `command` string (with placeholder unchanged).

- [ ] **Step 3: Commit**

```bash
git add plugins/s3lab-policy/hooks/hooks.json
git commit -m "feat(policy): wire SessionStart hook to install-policy"
```

---

## Task 6: Promote `s3lab-policy` in the marketplace manifest

Prepend `s3lab-policy` as the first entry in the `plugins` array so install ordering signals mandatoriness.

**Files:**
- Modify: `.claude-plugin/marketplace.json`

- [ ] **Step 1: Edit the file**

Open `.claude-plugin/marketplace.json`. The current `plugins` array starts with `s3lab-engineering`. Insert a new object BEFORE it so the array becomes:

```json
"plugins": [
  {
    "name": "s3lab-policy",
    "source": "./plugins/s3lab-policy",
    "description": "Обязательный baseline: secrets-guard на git pre-commit/pre-push, общие правила для всех s3lab-проектов."
  },
  {
    "name": "s3lab-engineering",
    "source": "./plugins/s3lab-engineering",
    "description": "Engineering skills, agents, commands and hooks for s3lab team workflows."
  },
  // …existing entries unchanged…
]
```

Use the Edit tool with `old_string` containing the opening of the array plus the first existing entry, and `new_string` inserting the new entry above it. The remaining five entries (`s3lab-dotnet`, `s3lab-product`, `s3lab-testing`, `s3lab-research`, `s3lab-writing`) stay in place and in order.

- [ ] **Step 2: Validate JSON**

Run:
```bash
jq . .claude-plugin/marketplace.json > /dev/null && echo "marketplace.json OK"
```
Expected: `marketplace.json OK`.

- [ ] **Step 3: Verify the plugin list is in expected order**

Run:
```bash
jq -r '.plugins[].name' .claude-plugin/marketplace.json
```
Expected output (exactly seven lines in this exact order):
```
s3lab-policy
s3lab-engineering
s3lab-dotnet
s3lab-product
s3lab-testing
s3lab-research
s3lab-writing
```

- [ ] **Step 4: Cross-check marketplace names against plugin directories**

Run:
```bash
jq -r '.plugins[].name' .claude-plugin/marketplace.json | sort > /tmp/s3lab-listed.txt
ls -1 plugins | sort > /tmp/s3lab-actual.txt
diff /tmp/s3lab-listed.txt /tmp/s3lab-actual.txt && echo "marketplace and plugins/ in sync"
```
Expected: `marketplace and plugins/ in sync`, no diff output.

- [ ] **Step 5: Commit**

```bash
git add .claude-plugin/marketplace.json
git commit -m "feat(marketplace): list s3lab-policy as the mandatory first plugin"
```

---

## Task 7: Implement the `/policy-status` slash command

The command body is interpreted by Claude on invocation. It reads state — never writes — and prints a compact status block.

**Files:**
- Create: `plugins/s3lab-policy/commands/policy-status.md`

- [ ] **Step 1: Write the command file**

File: `plugins/s3lab-policy/commands/policy-status.md`

```markdown
---
description: Print the status of s3lab-policy guard hooks in the current repository, gitleaks availability, and recent commit verification state.
---

You are running the `/policy-status` command for the `s3lab-policy` plugin. Do NOT make any changes to the filesystem, hooks, or configuration. This is a read-only diagnostic.

Gather and print the following information, in this exact order, in a single fenced code block so it is easy to copy. If a value is unknown or unavailable, print `unknown` — do not guess.

1. **Plugin version.** Read `plugins/s3lab-policy/.claude-plugin/plugin.json` from the marketplace source. If you can't find it, print `unknown`.
2. **Installed pre-commit hook.** Read the first 10 lines of `.git/hooks/pre-commit` in the cwd repository. If it exists and contains a line matching `# s3lab-policy v<version>`, print the version. If it exists without the sentinel, print `user-managed`. If it does not exist, print `missing`.
3. **Installed pre-push hook.** Same logic against `.git/hooks/pre-push`.
4. **gitleaks config.** Read the first line of `.s3lab-policy/gitleaks.toml`. If it exists and contains the sentinel, print the version. If it exists without the sentinel, print `user-managed`. If it does not exist, print `missing`.
5. **gitleaks binary.** Run `gitleaks version` (note: subcommand is `version`, no `--`). If it succeeds, print the version string. If it fails or the binary is not on PATH, print `not installed`.
6. **Recent commits.** Run `git log --pretty=format:'%h %s' -n 20`. For each commit, append ` [verified]` unless the reflog entry for that commit shows the literal `--no-verify`, in which case append ` [bypassed]`. If the reflog has rotated and you cannot determine, append ` [unknown]`. Detection: `git reflog show --grep-reflog='--no-verify' --format='%h'` returns SHAs that were committed with `--no-verify`; intersect with the 20 commits above.
7. **Summary.** Last line of the block: `OK` if the installed pre-commit and pre-push versions both match the plugin version, the gitleaks config matches the plugin version, AND `gitleaks` is installed. Otherwise `ATTENTION`.

After the code block, if the summary is `ATTENTION`, list each specific reason in plain text (one per line). Do NOT propose fixes — that is the user's call. Mention `/plugin install s3lab-policy@s3lab` only if the plugin manifest itself appears missing.
```

- [ ] **Step 2: Verify frontmatter parses**

Run:
```bash
head -3 plugins/s3lab-policy/commands/policy-status.md
```
Expected: first line `---`, second line starting with `description:`, third line `---`.

- [ ] **Step 3: Commit**

```bash
git add plugins/s3lab-policy/commands/policy-status.md
git commit -m "feat(policy): add /policy-status slash command"
```

---

## Task 8: Write the `secrets-incident-response` skill

A short, ordered runbook for handling a leaked secret. Activates when the user describes a leak or asks for recovery steps. The skill walks each step interactively — it does not autorun destructive commands.

**Files:**
- Create: `plugins/s3lab-policy/skills/secrets-incident-response/SKILL.md`

- [ ] **Step 1: Write the skill**

File: `plugins/s3lab-policy/skills/secrets-incident-response/SKILL.md`

```markdown
---
name: secrets-incident-response
description: Recovery runbook for when a secret (token, password, API key, private key, connection string with credentials) has been committed or pushed. Use when the user reports a leaked secret, suspects one, or is asked by a teammate to clean up history.
---

# secrets-incident-response

When a secret reaches git, treat it as compromised. Walk the user through the
steps below in order. Confirm each destructive action with the user before
running it — do not chain force-pushes or filter-repo invocations
automatically.

## 1. Revoke first

Identify the provider of the leaked secret (AWS, GCP, GitHub, GitLab, Slack,
Stripe, Postgres user, Mailgun, etc.). Direct the user to revoke or rotate via
the provider's console or CLI **before** touching git. Once a secret has been
pushed, scrubbing git history does not retroactively make it secret — only
revocation does.

If revocation is blocked (off-hours, missing access), ask the user to escalate
to whoever owns the credential before proceeding.

## 2. Confirm the exposure

Run, in order:

- `git log -p -S '<secret-fragment>' --all` — every commit on every ref that
  introduces or removes the secret.
- `git branch --contains <commit-sha>` for each hit — which branches still
  carry the commit.
- `git tag --contains <commit-sha>` — same for tags.
- `git ls-remote origin` — confirm whether the affected commits are present on
  the remote.

If the secret is only in local commits and has not been pushed, jump to
section 3 (local rewrite). If it is already on the remote, go to section 4
(coordinated rewrite).

## 3. Local-only rewrite

If the secret-bearing commit is the most recent on the current branch:

```sh
git reset --soft HEAD~1
# Remove or scrub the secret from the working tree, then re-stage and commit.
git commit -m "<original message, without the secret>"
```

If the commit is deeper in history, prefer `git filter-repo`:

```sh
# install once: brew install git-filter-repo
git filter-repo --replace-text <(echo '<secret-string>==><REDACTED>')
```

`filter-repo` rewrites every ref. Confirm with `git log -p -S '<secret-fragment>' --all` afterwards.

## 4. Coordinated rewrite (already pushed)

State the cost up front: every collaborator must re-clone or rebase their work
afterward, and CI may need cache invalidation. Get explicit user
acknowledgement before continuing.

Steps:

```sh
git filter-repo --replace-text <(echo '<secret-string>==><REDACTED>')
git push --force-with-lease origin <branch> <other-branches> --tags
```

Notify collaborators (Slack, email, or however the team coordinates) before
force-pushing. After the push, anyone with an existing clone must re-clone or
run `git fetch && git reset --hard origin/<branch>`.

## 5. Invalidate caches and artifacts

Walk every place that may have cached the secret with the old value:

- CI artifact stores (GitLab CI artifacts, GitHub Actions cache, build cache
  on agents).
- Container registries — any image built from the affected commit should be
  rebuilt and re-pushed.
- Deployment slots / environment variables on production hosts.
- Log aggregators (the secret may appear in stdout captures).
- Local developer machines — ask the team to drop stale clones if practical.

## 6. Postmortem

Record, briefly:

- What leaked (provider, scope).
- When it was committed and when it was discovered.
- Who rotated, who force-pushed, when.
- Which control failed: was `pre-commit` bypassed with `--no-verify`? Was the
  secret in an unstaged file that was later staged in bulk? Was the file
  outside the gitleaks scan path?

Feed the failure mode back into `.s3lab-policy/gitleaks.toml` (add a stricter
rule or remove an over-broad allowlist entry). If the bypass was the failure
mode, raise it with the team — that is a process gap, not a tooling gap.
```

- [ ] **Step 2: Verify frontmatter parses**

Run:
```bash
head -4 plugins/s3lab-policy/skills/secrets-incident-response/SKILL.md
```
Expected: first line `---`, then `name:`, then `description:`, then `---`.

- [ ] **Step 3: Commit**

```bash
git add plugins/s3lab-policy/skills/secrets-incident-response/SKILL.md
git commit -m "feat(policy): add secrets-incident-response skill"
```

---

## Task 9: Update the README

Promote `s3lab-policy` as the mandatory baseline plugin in the existing `## Marketplace (Claude Code)` section.

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Read the relevant section to locate the edit**

The current marketplace section starts at line 7 with `## Marketplace (Claude Code)` and lists six plugins. Replace the section body — but keep the heading — with the version below.

- [ ] **Step 2: Replace the section body**

Use Edit on `README.md` to replace the existing marketplace section's body. The exact replacement (the content of the four-backtick fence below, fences themselves NOT included in the file):

````markdown
## Marketplace (Claude Code)

Репозиторий содержит Claude Code plugin marketplace в `.claude-plugin/marketplace.json`. Плагины разложены по доменам в `plugins/<имя>/`. Плагин `s3lab-policy` обязателен — устанавливайте его первым в каждом проекте: его `SessionStart` hook автоматически ставит `pre-commit` и `pre-push` с `gitleaks`-сканером в репозитории, где открыта сессия Claude Code. Остальные плагины опциональны и устанавливаются по нужде; полностью оформлен только демо-плагин `s3lab-engineering` (заглушка skill + slash-команда), `s3lab-dotnet`/`s3lab-product`/`s3lab-testing`/`s3lab-research`/`s3lab-writing` — пустые скелеты.

Установка локально:

```text
/plugin marketplace add /Users/saa/Projects/s3lab/s3lab-ai-kit
/plugin install s3lab-policy@s3lab
/plugin install s3lab-engineering@s3lab
```

Что включает baseline (`s3lab-policy`):

- `pre-commit` и `pre-push` блокируют коммит/push с найденным secret через `gitleaks` (~150 встроенных правил).
- Per-repo allowlist в `.s3lab-policy/gitleaks.toml` — коммитится в репо, фиксирует команд-договорённости по false positives.
- Slash-команда `/policy-status` показывает текущее состояние защиты.
- Skill `secrets-incident-response` — runbook на случай, когда secret уже попал в историю.
- `gitleaks` ставится автоматически через `brew install gitleaks`, если его нет.

Доступные плагины:

- `s3lab-policy` — Обязательный baseline: secrets-guard на git pre-commit/pre-push, общие правила для всех s3lab-проектов.
- `s3lab-engineering` — Engineering skills, agents, commands and hooks for s3lab team workflows.
- `s3lab-dotnet` — .NET 10 backend skills and agents (Clean Architecture, CQRS, infrastructure). *skeleton*
- `s3lab-product` — Product skills: PRD/MVP preparation, sprint acceptance criteria. *skeleton*
- `s3lab-testing` — Testing skills and agents for web/e2e/UI and unit-test guidance. *skeleton*
- `s3lab-research` — Research skills: competitors, technologies, market analysis. *skeleton*
- `s3lab-writing` — Writing skills: structure and tone for technical articles (Habr/VC). *skeleton*
````

- [ ] **Step 3: Verify the heading is unique and in place**

Run:
```bash
grep -n "^## Marketplace (Claude Code)$" README.md
```
Expected: exactly one match.

Run:
```bash
awk '/^## /{print NR": "$0}' README.md | head -5
```
Expected: `## Marketplace (Claude Code)` precedes `## Для чего введён AI Kit`, both still present.

- [ ] **Step 4: Commit**

```bash
git add README.md
git commit -m "docs(readme): promote s3lab-policy as mandatory baseline plugin"
```

---

## Task 10: Acceptance validation

This task runs the manual acceptance scenarios from spec §11 against the assembled plugin. Several scenarios require a Claude Code session restart and are out-of-band for the plan; they are listed for completeness with explicit "manual" markers.

- [ ] **Step 1: Re-validate every JSON manifest in the plugin**

Run:
```bash
jq . plugins/s3lab-policy/.claude-plugin/plugin.json > /dev/null && echo "plugin.json OK"
jq . plugins/s3lab-policy/hooks/hooks.json > /dev/null && echo "hooks.json OK"
jq . .claude-plugin/marketplace.json > /dev/null && echo "marketplace.json OK"
```
Expected: three `OK` lines.

- [ ] **Step 2: Syntax-check every script**

Run:
```bash
node --check plugins/s3lab-policy/scripts/install-policy.mjs && echo "install-policy.mjs OK"
node --check plugins/s3lab-policy/scripts/ensure-gitleaks.mjs && echo "ensure-gitleaks.mjs OK"
bash -n plugins/s3lab-policy/scripts/pre-commit.sh && echo "pre-commit.sh OK"
bash -n plugins/s3lab-policy/scripts/pre-push.sh && echo "pre-push.sh OK"
```
Expected: four `OK` lines.

- [ ] **Step 3: Verify the marketplace and the plugins/ directory still agree**

Run:
```bash
jq -r '.plugins[].name' .claude-plugin/marketplace.json | sort > /tmp/s3lab-listed.txt
ls -1 plugins | sort > /tmp/s3lab-actual.txt
diff /tmp/s3lab-listed.txt /tmp/s3lab-actual.txt && echo "marketplace and plugins/ in sync"
```
Expected: `marketplace and plugins/ in sync`.

- [ ] **Step 4: Confirm clean working tree**

Run:
```bash
git status --porcelain
```
Expected: no output unless `.s3lab-policy/gitleaks.toml` is still unstaged — in which case the smoke-run from Task 4 Step 6 should have already committed it. If the tree is dirty for an unexpected reason, stop and investigate before proceeding.

- [ ] **Step 5 (manual): block a real secret commit in this repo**

This step is manual because it requires running git commit interactively and inspecting the abort.

```bash
echo 'AWS_SECRET_ACCESS_KEY=AKIA1234567890ABCDEF' > /tmp/leak.txt
cp /tmp/leak.txt leak.txt
git add leak.txt
git commit -m "should-be-blocked"
```

Expected: `git commit` exits non-zero. `gitleaks` prints a redacted finding and the commit does not land. Verify with `git log -1` showing the previous commit (the README docs commit), not `should-be-blocked`.

Cleanup:
```bash
git restore --staged leak.txt
rm leak.txt /tmp/leak.txt
```

- [ ] **Step 6 (manual): test in a fresh git repo**

In a separate terminal:

```bash
mkdir /tmp/policy-smoke && cd /tmp/policy-smoke
git init
node /Users/saa/Projects/s3lab/s3lab-ai-kit/plugins/s3lab-policy/scripts/install-policy.mjs
ls -l .git/hooks/pre-commit .git/hooks/pre-push
head -2 .git/hooks/pre-commit | tail -1
head -1 .s3lab-policy/gitleaks.toml
```
Expected: both hooks executable; both sentinel lines print `# s3lab-policy v0.1.0`.

Cleanup:
```bash
rm -rf /tmp/policy-smoke
```

- [ ] **Step 7 (manual): test in Claude Code with a session restart**

This step is fully manual. In a Claude Code session:

```text
/plugin marketplace update s3lab
/plugin install s3lab-policy@s3lab
```

Then close the session and reopen it inside a fresh git repository (a throwaway directory under `~/tmp/` works). Expected behavior on session start:
- A `systemMessage` line `s3lab-policy: installed: pre-commit, pre-push, gitleaks.toml; gitleaks: present` (or `installed` if brew bootstrapped it) appears.
- `/policy-status` returns a summary ending in `OK`.

If the session does not show the message, the SessionStart hook did not fire — check `/hooks` from Claude Code and verify the plugin's `hooks.json` was loaded.

No commit on this step.
