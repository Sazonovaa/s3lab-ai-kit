# s3lab Codex Marketplace Support - Design

- Date: 2026-06-19
- Owner: s3lab
- Status: Approved
- Repo: `s3lab-ai-kit`

## Goal

Add Codex plugin marketplace support alongside the existing Claude Code marketplace so the same repository can expose team plugins to Codex.

## Scope

The Codex support uses the documented repo marketplace layout:

- `.agents/plugins/marketplace.json` at the repository root.
- `plugins/<name>/.codex-plugin/plugin.json` for each existing plugin.
- `skills` are the only content type activated for Codex in this iteration.

Claude-only `commands/`, `agents/`, and `hooks/` remain in the repository for Claude Code. They are not converted to Codex commands, subagents, or hooks in this change.

## Decisions

1. Keep the existing `plugins/<name>/` directories as the shared plugin source.
2. Add Codex manifests next to Claude manifests instead of replacing `.claude-plugin/plugin.json`.
3. List all existing plugins in the Codex marketplace so the marketplace shape matches Claude.
4. Include `"skills": "./skills/"` only for plugins that currently contain real `SKILL.md` files.
5. Document Codex install flow with `codex plugin marketplace add <repo-root>` and `/plugins`.

## Acceptance

1. `.agents/plugins/marketplace.json` is valid JSON and lists all eight plugins.
2. Every `plugins/<name>/.codex-plugin/plugin.json` is valid JSON.
3. The Codex plugin validator passes for every plugin.
4. README documents both Claude Code and Codex installation paths.
