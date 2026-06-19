# Codex Marketplace Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add repo-scoped Codex marketplace support to the existing s3lab plugin repository.

**Architecture:** Keep Claude Code and Codex manifests side by side in each plugin directory. Codex reads `.agents/plugins/marketplace.json`, then installs plugins from `plugins/<name>` using `.codex-plugin/plugin.json`.

**Tech Stack:** JSON manifests, Markdown documentation, Codex plugin validation scripts.

---

## File Structure

- Create `.agents/plugins/marketplace.json` as the Codex repo marketplace catalog.
- Create `plugins/<name>/.codex-plugin/plugin.json` for each existing plugin.
- Modify `README.md` to document Codex installation and scope.
- Create `docs/superpowers/specs/2026-06-19-codex-marketplace-design.md` for the accepted design.

## Tasks

- [x] Create Codex marketplace manifest with all eight plugins.
- [x] Add Codex plugin manifests to every existing plugin directory.
- [x] Mark only real skill-bearing plugins with `"skills": "./skills/"`.
- [x] Update README with Codex install and usage commands.
- [x] Validate JSON and Codex plugin manifests.
