# s3lab Marketplace Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Scaffold a Claude Code plugin marketplace inside the `s3lab-ai-kit` repo with one demo plugin (`s3lab-engineering`) containing a stub skill and stub slash command, plus five empty skeleton plugins for the other domains.

**Architecture:** Standard Claude Code marketplace layout — `.claude-plugin/marketplace.json` at the repository root lists all six plugins. Each plugin lives under `plugins/<name>/` with its own `.claude-plugin/plugin.json` manifest and four content directories (`skills/`, `agents/`, `commands/`, `hooks/`). Empty directories are preserved in git via `.gitkeep` files.

**Tech Stack:** JSON manifests (Claude Code plugin spec), Markdown with YAML frontmatter for skills/commands, `jq` for JSON validation, `git` for commits.

**Spec:** `docs/superpowers/specs/2026-06-06-marketplace-design.md`

**Working directory for all commands below:** `/Users/saa/Projects/s3lab/s3lab-ai-kit`

---

## File Structure

Files this plan creates:

```
.claude-plugin/
└── marketplace.json

plugins/s3lab-engineering/
├── .claude-plugin/plugin.json
├── skills/hello-engineering/SKILL.md
├── agents/.gitkeep
├── commands/s3lab-hello.md
└── hooks/.gitkeep

plugins/s3lab-dotnet/
├── .claude-plugin/plugin.json
├── skills/.gitkeep
├── agents/.gitkeep
├── commands/.gitkeep
└── hooks/.gitkeep

plugins/s3lab-product/      (same skeleton as s3lab-dotnet)
plugins/s3lab-testing/      (same skeleton)
plugins/s3lab-research/     (same skeleton)
plugins/s3lab-writing/      (same skeleton)
```

Files this plan modifies:
- `README.md` — add `## Marketplace (Claude Code)` section near the top, after the existing intro.

Single-responsibility rationale: the marketplace manifest aggregates plugin metadata only; per-plugin manifests own version/description; skill and command files own behavior. No file mixes concerns.

---

## Task 1: Create the marketplace manifest

**Files:**
- Create: `.claude-plugin/marketplace.json`

- [ ] **Step 1: Create the directory**

```bash
mkdir -p .claude-plugin
```

- [ ] **Step 2: Write `marketplace.json`**

Write the file with this exact content:

```json
{
  "name": "s3lab",
  "owner": {
    "name": "s3lab",
    "email": "sien.inbox@gmail.com"
  },
  "plugins": [
    {
      "name": "s3lab-engineering",
      "source": "./plugins/s3lab-engineering",
      "description": "Engineering skills, agents, commands and hooks for s3lab team workflows."
    },
    {
      "name": "s3lab-dotnet",
      "source": "./plugins/s3lab-dotnet",
      "description": ".NET 10 backend skills and agents (Clean Architecture, CQRS, infrastructure)."
    },
    {
      "name": "s3lab-product",
      "source": "./plugins/s3lab-product",
      "description": "Product skills: PRD/MVP preparation, sprint acceptance criteria."
    },
    {
      "name": "s3lab-testing",
      "source": "./plugins/s3lab-testing",
      "description": "Testing skills and agents for web/e2e/UI and unit-test guidance."
    },
    {
      "name": "s3lab-research",
      "source": "./plugins/s3lab-research",
      "description": "Research skills: competitors, technologies, market analysis."
    },
    {
      "name": "s3lab-writing",
      "source": "./plugins/s3lab-writing",
      "description": "Writing skills: structure and tone for technical articles (Habr/VC)."
    }
  ]
}
```

- [ ] **Step 3: Validate JSON**

Run:
```bash
jq . .claude-plugin/marketplace.json
```
Expected: the file prints back as pretty JSON with no parse error. Exit code 0.

- [ ] **Step 4: Verify all six plugin entries are present**

Run:
```bash
jq -r '.plugins[].name' .claude-plugin/marketplace.json
```
Expected output (exactly six lines, in this order):
```
s3lab-engineering
s3lab-dotnet
s3lab-product
s3lab-testing
s3lab-research
s3lab-writing
```

- [ ] **Step 5: Commit**

```bash
git add .claude-plugin/marketplace.json
git commit -m "feat(marketplace): add s3lab marketplace manifest"
```

---

## Task 2: Scaffold the `s3lab-engineering` demo plugin

**Files:**
- Create: `plugins/s3lab-engineering/.claude-plugin/plugin.json`
- Create: `plugins/s3lab-engineering/skills/hello-engineering/SKILL.md`
- Create: `plugins/s3lab-engineering/commands/s3lab-hello.md`
- Create: `plugins/s3lab-engineering/agents/.gitkeep`
- Create: `plugins/s3lab-engineering/hooks/.gitkeep`

- [ ] **Step 1: Create directories**

```bash
mkdir -p plugins/s3lab-engineering/.claude-plugin
mkdir -p plugins/s3lab-engineering/skills/hello-engineering
mkdir -p plugins/s3lab-engineering/agents
mkdir -p plugins/s3lab-engineering/commands
mkdir -p plugins/s3lab-engineering/hooks
```

- [ ] **Step 2: Write `plugin.json`**

File: `plugins/s3lab-engineering/.claude-plugin/plugin.json`

```json
{
  "name": "s3lab-engineering",
  "version": "0.1.0",
  "description": "Engineering skills, agents, commands and hooks for s3lab team workflows.",
  "author": {
    "name": "s3lab",
    "email": "sien.inbox@gmail.com"
  }
}
```

- [ ] **Step 3: Write the stub skill**

File: `plugins/s3lab-engineering/skills/hello-engineering/SKILL.md`

```markdown
---
name: hello-engineering
description: Stub skill demonstrating s3lab-engineering plugin installation. Replace with real engineering skills (onboarding, dev workflow, code review) in a later iteration.
---

# hello-engineering

This is a placeholder skill that confirms the `s3lab-engineering` plugin loaded
correctly after `/plugin install s3lab-engineering@s3lab`.

When invoked, respond with a short confirmation message and remind the user that
real engineering skills (onboarding, dev workflow, code review) are not yet
implemented in this plugin.
```

- [ ] **Step 4: Write the stub command**

File: `plugins/s3lab-engineering/commands/s3lab-hello.md`

```markdown
---
description: Stub slash command for s3lab-engineering plugin. Confirms plugin installation.
---

Respond with the following message:

"s3lab-engineering plugin is installed and active. Real engineering commands
are not yet implemented — see plugins/s3lab-engineering/ in the s3lab-ai-kit
repository to add them."
```

- [ ] **Step 5: Add `.gitkeep` to the empty `agents/` and `hooks/` directories**

Create empty files:
- `plugins/s3lab-engineering/agents/.gitkeep`
- `plugins/s3lab-engineering/hooks/.gitkeep`

Both files should be empty (zero bytes).

- [ ] **Step 6: Validate `plugin.json`**

Run:
```bash
jq . plugins/s3lab-engineering/.claude-plugin/plugin.json
```
Expected: pretty-printed JSON, exit code 0.

- [ ] **Step 7: Verify directory structure**

Run:
```bash
find plugins/s3lab-engineering -type f | sort
```
Expected output (exactly five files):
```
plugins/s3lab-engineering/.claude-plugin/plugin.json
plugins/s3lab-engineering/agents/.gitkeep
plugins/s3lab-engineering/commands/s3lab-hello.md
plugins/s3lab-engineering/hooks/.gitkeep
plugins/s3lab-engineering/skills/hello-engineering/SKILL.md
```

- [ ] **Step 8: Commit**

```bash
git add plugins/s3lab-engineering
git commit -m "feat(marketplace): scaffold s3lab-engineering demo plugin with stub skill and command"
```

---

## Task 3: Scaffold the five skeleton plugins

The five plugins (`s3lab-dotnet`, `s3lab-product`, `s3lab-testing`, `s3lab-research`, `s3lab-writing`) have identical structure: a `plugin.json` and four empty content directories with `.gitkeep`. The only differences are `name` and `description` in each `plugin.json`.

**Files (per plugin `<name>`):**
- Create: `plugins/<name>/.claude-plugin/plugin.json`
- Create: `plugins/<name>/skills/.gitkeep`
- Create: `plugins/<name>/agents/.gitkeep`
- Create: `plugins/<name>/commands/.gitkeep`
- Create: `plugins/<name>/hooks/.gitkeep`

- [ ] **Step 1: Create directories for all five plugins**

```bash
for name in s3lab-dotnet s3lab-product s3lab-testing s3lab-research s3lab-writing; do
  mkdir -p "plugins/$name/.claude-plugin"
  mkdir -p "plugins/$name/skills"
  mkdir -p "plugins/$name/agents"
  mkdir -p "plugins/$name/commands"
  mkdir -p "plugins/$name/hooks"
done
```

- [ ] **Step 2: Write `plugins/s3lab-dotnet/.claude-plugin/plugin.json`**

```json
{
  "name": "s3lab-dotnet",
  "version": "0.1.0",
  "description": ".NET 10 backend skills and agents (Clean Architecture, CQRS, infrastructure).",
  "author": {
    "name": "s3lab",
    "email": "sien.inbox@gmail.com"
  }
}
```

- [ ] **Step 3: Write `plugins/s3lab-product/.claude-plugin/plugin.json`**

```json
{
  "name": "s3lab-product",
  "version": "0.1.0",
  "description": "Product skills: PRD/MVP preparation, sprint acceptance criteria.",
  "author": {
    "name": "s3lab",
    "email": "sien.inbox@gmail.com"
  }
}
```

- [ ] **Step 4: Write `plugins/s3lab-testing/.claude-plugin/plugin.json`**

```json
{
  "name": "s3lab-testing",
  "version": "0.1.0",
  "description": "Testing skills and agents for web/e2e/UI and unit-test guidance.",
  "author": {
    "name": "s3lab",
    "email": "sien.inbox@gmail.com"
  }
}
```

- [ ] **Step 5: Write `plugins/s3lab-research/.claude-plugin/plugin.json`**

```json
{
  "name": "s3lab-research",
  "version": "0.1.0",
  "description": "Research skills: competitors, technologies, market analysis.",
  "author": {
    "name": "s3lab",
    "email": "sien.inbox@gmail.com"
  }
}
```

- [ ] **Step 6: Write `plugins/s3lab-writing/.claude-plugin/plugin.json`**

```json
{
  "name": "s3lab-writing",
  "version": "0.1.0",
  "description": "Writing skills: structure and tone for technical articles (Habr/VC).",
  "author": {
    "name": "s3lab",
    "email": "sien.inbox@gmail.com"
  }
}
```

- [ ] **Step 7: Add `.gitkeep` to every content directory**

Create empty files (zero bytes) at:
```
plugins/s3lab-dotnet/skills/.gitkeep
plugins/s3lab-dotnet/agents/.gitkeep
plugins/s3lab-dotnet/commands/.gitkeep
plugins/s3lab-dotnet/hooks/.gitkeep
plugins/s3lab-product/skills/.gitkeep
plugins/s3lab-product/agents/.gitkeep
plugins/s3lab-product/commands/.gitkeep
plugins/s3lab-product/hooks/.gitkeep
plugins/s3lab-testing/skills/.gitkeep
plugins/s3lab-testing/agents/.gitkeep
plugins/s3lab-testing/commands/.gitkeep
plugins/s3lab-testing/hooks/.gitkeep
plugins/s3lab-research/skills/.gitkeep
plugins/s3lab-research/agents/.gitkeep
plugins/s3lab-research/commands/.gitkeep
plugins/s3lab-research/hooks/.gitkeep
plugins/s3lab-writing/skills/.gitkeep
plugins/s3lab-writing/agents/.gitkeep
plugins/s3lab-writing/commands/.gitkeep
plugins/s3lab-writing/hooks/.gitkeep
```

Bulk shell helper:
```bash
for name in s3lab-dotnet s3lab-product s3lab-testing s3lab-research s3lab-writing; do
  for sub in skills agents commands hooks; do
    : > "plugins/$name/$sub/.gitkeep"
  done
done
```

- [ ] **Step 8: Validate every `plugin.json`**

Run:
```bash
for name in s3lab-dotnet s3lab-product s3lab-testing s3lab-research s3lab-writing; do
  echo "--- $name ---"
  jq . "plugins/$name/.claude-plugin/plugin.json" || exit 1
done
```
Expected: each manifest prints back as pretty JSON, exit code 0, no parse errors.

- [ ] **Step 9: Verify every plugin name matches its directory**

Run:
```bash
for name in s3lab-dotnet s3lab-product s3lab-testing s3lab-research s3lab-writing; do
  actual=$(jq -r .name "plugins/$name/.claude-plugin/plugin.json")
  [ "$actual" = "$name" ] && echo "OK  $name" || echo "MISMATCH expected=$name got=$actual"
done
```
Expected: five lines, all starting with `OK `.

- [ ] **Step 10: Commit**

```bash
git add plugins/s3lab-dotnet plugins/s3lab-product plugins/s3lab-testing plugins/s3lab-research plugins/s3lab-writing
git commit -m "feat(marketplace): scaffold five skeleton plugins (dotnet, product, testing, research, writing)"
```

---

## Task 4: Update `README.md` with a Marketplace section

**Files:**
- Modify: `README.md` (insert a new `## Marketplace (Claude Code)` section)

- [ ] **Step 1: Read the current `README.md` to find the insertion point**

The new section goes immediately after the existing intro paragraph (the one starting with "`s3lab-ai-kit` — стандартный набор AI-инструкций...") and before the existing `## Для чего введён AI Kit` heading.

- [ ] **Step 2: Insert the Marketplace section**

Use an Edit operation that places this block between the intro paragraph and the `## Для чего введён AI Kit` heading. The exact new content to insert (everything between the four-backtick fences, four-backtick fences themselves NOT included in the file):

````markdown
## Marketplace (Claude Code)

Репозиторий содержит Claude Code plugin marketplace в `.claude-plugin/marketplace.json`. Плагины разложены по доменам в `plugins/<имя>/`. На текущий момент полностью оформлен только демо-плагин `s3lab-engineering` (заглушка skill + slash-команда), остальные плагины — пустые скелеты.

Установка локально:

```text
/plugin marketplace add /Users/saa/Projects/s3lab/s3lab-ai-kit
/plugin install s3lab-engineering@s3lab
```

Доступные плагины:

- `s3lab-engineering` — Engineering skills, agents, commands and hooks for s3lab team workflows.
- `s3lab-dotnet` — .NET 10 backend skills and agents (Clean Architecture, CQRS, infrastructure). *skeleton*
- `s3lab-product` — Product skills: PRD/MVP preparation, sprint acceptance criteria. *skeleton*
- `s3lab-testing` — Testing skills and agents for web/e2e/UI and unit-test guidance. *skeleton*
- `s3lab-research` — Research skills: competitors, technologies, market analysis. *skeleton*
- `s3lab-writing` — Writing skills: structure and tone for technical articles (Habr/VC). *skeleton*
````

- [ ] **Step 3: Verify the section appears exactly once and in the right place**

Run:
```bash
grep -n "^## Marketplace (Claude Code)$" README.md
```
Expected: exactly one match.

Run:
```bash
awk '/^## /{print NR": "$0}' README.md | head -5
```
Expected: `## Marketplace (Claude Code)` appears in the heading list, and it precedes `## Для чего введён AI Kit`.

- [ ] **Step 4: Commit**

```bash
git add README.md
git commit -m "docs(readme): document the Claude Code marketplace and install flow"
```

---

## Task 5: Final repository-level validation

This task runs the acceptance checks from spec section 10 against the assembled marketplace. No code changes — only verification and a final empty-state confirmation.

- [ ] **Step 1: Re-validate the marketplace manifest**

Run:
```bash
jq . .claude-plugin/marketplace.json > /dev/null && echo "marketplace.json OK"
```
Expected: `marketplace.json OK`, exit code 0.

- [ ] **Step 2: Re-validate every plugin manifest**

Run:
```bash
for f in plugins/*/.claude-plugin/plugin.json; do
  jq . "$f" > /dev/null && echo "OK  $f" || { echo "FAIL $f"; exit 1; }
done
```
Expected: six `OK` lines, one per plugin manifest.

- [ ] **Step 3: Verify every plugin has all four content directories**

Run:
```bash
for d in plugins/*/; do
  for sub in skills agents commands hooks; do
    [ -d "$d$sub" ] && echo "OK  $d$sub" || { echo "MISSING $d$sub"; exit 1; }
  done
done
```
Expected: 24 `OK` lines (6 plugins × 4 directories), exit code 0.

- [ ] **Step 4: Cross-check `marketplace.json` plugin names against actual directories**

Run:
```bash
jq -r '.plugins[].name' .claude-plugin/marketplace.json | sort > /tmp/s3lab-listed.txt
ls -1 plugins | sort > /tmp/s3lab-actual.txt
diff /tmp/s3lab-listed.txt /tmp/s3lab-actual.txt && echo "marketplace and plugins/ in sync"
```
Expected: `marketplace and plugins/ in sync`, no diff output, exit code 0.

- [ ] **Step 5: Confirm clean tree (no uncommitted artifacts)**

Run:
```bash
git status --porcelain
```
Expected: empty output (no untracked or modified files).

- [ ] **Step 6: Manually test install in Claude Code (out-of-band)**

This step is manual and is not automated by the plan. The implementer should run, in a Claude Code session:

```text
/plugin marketplace add /Users/saa/Projects/s3lab/s3lab-ai-kit
/plugin marketplace list
/plugin install s3lab-engineering@s3lab
/s3lab-hello
```

Expected outcome:
- `marketplace list` shows `s3lab` with six plugins.
- `install s3lab-engineering@s3lab` reports success.
- `/s3lab-hello` returns the stub confirmation message.

Record any issues here as follow-up tasks for the next iteration. No commit on this step.
