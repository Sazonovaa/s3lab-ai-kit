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
