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
