# s3lab Personal Plugin Marketplace — Design

- Date: 2026-06-06
- Owner: Андрей Сазонов (sien.inbox@gmail.com)
- Status: Approved (brainstorm phase)
- Repo: `s3lab-ai-kit`

## 1. Goal

Build a Claude Code-compatible plugin marketplace inside the `s3lab-ai-kit` repository so personal/team plugins (skills, agents, slash commands, hooks) can be installed via Claude Code's native `/plugin marketplace add` and `/plugin install` commands.

The MVP delivers the marketplace skeleton plus one demo plugin with stub content. Other plugins are scaffolded but empty; real content is added in later iterations.

## 2. Non-goals

- Filling all six domain plugins with real skills/agents — this spec covers structure only.
- Publishing the marketplace to a remote registry or central catalog.
- Supporting non-Claude-Code clients (Cursor, Codex) through this marketplace — those keep their own `.cursor/`, `.codex/` configs out of scope here.
- Migrating prior `.ai/**` content from git history (commit `f567b94` and earlier). Migration may happen later but is not part of this spec.

## 3. Decisions captured in brainstorming

| Question | Decision |
|---|---|
| Platform | Claude Code plugin marketplace format |
| Repo location | Same repo (`s3lab-ai-kit`) |
| Granularity | Domain-split: one plugin per domain |
| Content types per plugin | skills + agents + commands + hooks (all four supported) |
| MVP scope | Skeleton + one demo plugin (`s3lab-engineering`) with stub skill + stub command |
| Layout | Standard Claude Code layout: `.claude-plugin/marketplace.json` at root, `plugins/<name>/` per plugin |

## 4. Repository layout

```
s3lab-ai-kit/
├── .claude-plugin/
│   └── marketplace.json
├── plugins/
│   ├── s3lab-engineering/
│   │   ├── .claude-plugin/plugin.json
│   │   ├── skills/
│   │   │   └── hello-engineering/
│   │   │       └── SKILL.md
│   │   ├── agents/                 (empty, .gitkeep)
│   │   ├── commands/
│   │   │   └── s3lab-hello.md
│   │   └── hooks/                  (empty, .gitkeep)
│   ├── s3lab-dotnet/
│   │   ├── .claude-plugin/plugin.json
│   │   ├── skills/                 (empty, .gitkeep)
│   │   ├── agents/                 (empty, .gitkeep)
│   │   ├── commands/               (empty, .gitkeep)
│   │   └── hooks/                  (empty, .gitkeep)
│   ├── s3lab-product/              (same skeleton)
│   ├── s3lab-testing/              (same skeleton)
│   ├── s3lab-research/             (same skeleton)
│   └── s3lab-writing/              (same skeleton)
├── README.md
└── docs/
    └── superpowers/specs/2026-06-06-marketplace-design.md   (this file)
```

`.gitkeep` files are used to commit empty directories so the plugin skeletons stay intact in git.

## 5. Marketplace manifest

File: `.claude-plugin/marketplace.json`

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

## 6. Plugin manifest template

File: `plugins/<name>/.claude-plugin/plugin.json`

```json
{
  "name": "<plugin-name>",
  "version": "0.1.0",
  "description": "<short description matching marketplace entry>",
  "author": {
    "name": "s3lab",
    "email": "sien.inbox@gmail.com"
  }
}
```

Versioning rule for MVP: every scaffolded plugin starts at `0.1.0`. The demo plugin (`s3lab-engineering`) keeps `0.1.0` after adding stub content. Real content additions in future iterations bump minor; breaking changes bump major.

## 7. Demo plugin: `s3lab-engineering`

### 7.1 Stub skill

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

### 7.2 Stub command

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

### 7.3 Other content types

`agents/` and `hooks/` directories exist with `.gitkeep` only — no stub content. They are reserved for later iterations.

## 8. Install flow

User runs the following in Claude Code:

```text
/plugin marketplace add /Users/saa/Projects/s3lab/s3lab-ai-kit
/plugin install s3lab-engineering@s3lab
```

Expected behavior after install:
- The skill `hello-engineering` is available to invoke.
- The slash command `/s3lab-hello` is available.
- Other plugins (`s3lab-dotnet`, etc.) are visible in `/plugin marketplace` listings but install as no-op skeletons until they get content.

## 9. README update

Add a `## Marketplace (Claude Code)` section to `README.md` with:
- One-paragraph description: marketplace lives at `.claude-plugin/marketplace.json`; plugins live under `plugins/<domain>/`.
- Install commands block (same as section 8).
- List of available plugins with one-line descriptions (mirrors marketplace.json).
- Note that all plugins except `s3lab-engineering` are skeletons in the MVP.

## 10. Testing / acceptance

Manual acceptance checks after implementation:

1. `cat .claude-plugin/marketplace.json | jq .` — valid JSON, all six plugins listed.
2. For each plugin: `cat plugins/<name>/.claude-plugin/plugin.json | jq .` — valid JSON with name, version, description, author.
3. `find plugins -type d` lists all four content subfolders (`skills/`, `agents/`, `commands/`, `hooks/`) under each plugin.
4. In Claude Code: `/plugin marketplace add <abs-path-to-repo>` succeeds, `/plugin marketplace list` shows `s3lab` with six plugins.
5. `/plugin install s3lab-engineering@s3lab` succeeds. After install, the stub command `/s3lab-hello` is callable and the `hello-engineering` skill appears in available skills.

No automated tests are introduced in this spec — marketplace structure is config-only.

## 11. Out of scope / future iterations

- Filling `s3lab-dotnet`, `s3lab-product`, `s3lab-testing`, `s3lab-research`, `s3lab-writing` with real skills/agents/commands/hooks (one spec per domain later).
- Migrating prior `.ai/**` content from git history into the new plugin layout.
- Wiring hooks (e.g., AI usage logging, CRLF guard) into plugin `hooks/` directories.
- Publishing the marketplace through git submodule, remote URL source, or shared registry.
- Cross-vendor coverage (Cursor, Codex) — handled by separate vendor configs, not the marketplace.

## 12. Risks

- **Claude Code marketplace format drift.** The spec relies on the current `.claude-plugin/marketplace.json` schema. If Claude Code changes the schema, manifest fields may need adjustment. Mitigation: keep the demo plugin minimal so re-formatting is cheap.
- **Empty plugins clutter the install UI.** Five skeleton plugins appear in `/plugin marketplace list` with no real content. Mitigation: descriptions explicitly mark them as skeletons until content lands. As an alternative, the empty entries can be removed from `marketplace.json` and re-added once each plugin gets real content.
