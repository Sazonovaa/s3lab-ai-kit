---
description: Print the status of s3lab-policy guard hooks in the current repository, gitleaks availability, and recent commits.
---

You are running the `/policy-status` command for the `s3lab-policy` plugin. Do NOT make any changes to the filesystem, hooks, or configuration. This is a read-only diagnostic.

Gather and print the following information, in this exact order, in a single fenced code block so it is easy to copy. If a value is unknown or unavailable, print `unknown` — do not guess.

1. **Plugin version.** Read `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json` (Claude Code injects `CLAUDE_PLUGIN_ROOT` as the plugin's installed directory). Print the `version` field. If you cannot resolve the path, print `unknown`.
2. **Installed pre-commit hook.** Read the first 10 lines of `.git/hooks/pre-commit` in the cwd repository. If it exists and contains a line matching `# s3lab-policy v<version>`, print the version. If it exists without the sentinel, print `user-managed`. If it does not exist, print `missing`.
3. **Installed pre-push hook.** Same logic against `.git/hooks/pre-push`.
4. **gitleaks config.** Read the first line of `.s3lab-policy/gitleaks.toml`. If it matches `# s3lab-policy v<version>`, print the version. If the file exists without that sentinel on the first line, print `user-managed`. If the file does not exist, print `missing`.
5. **gitleaks binary.** Run `gitleaks version` (subcommand is `version`, no dashes). If it succeeds, print the version string. If it fails or the binary is not on PATH, print `not installed`.
6. **Recent commits.** Run `git log --pretty=format:'%h %s' -n 20`. Append ` [unknown]` to every line. Bypass detection from local state is not reliable — git does not record `--no-verify` usage in any way the command can read. Do not attempt to mark commits as verified or bypassed.
7. **Summary.** Last line of the block: `OK` if the installed pre-commit, pre-push, and gitleaks config sentinel versions all equal the plugin version, AND `gitleaks` is installed. Otherwise `ATTENTION`.

After the code block, if the summary is `ATTENTION`, list each specific reason in plain text (one per line). Do NOT propose fixes — that is the user's call. Mention `/plugin install s3lab-policy@s3lab` only if the plugin manifest itself could not be read.
