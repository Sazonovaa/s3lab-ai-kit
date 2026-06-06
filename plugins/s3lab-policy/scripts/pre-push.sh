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
