#!/usr/bin/env bash
# s3lab-policy v0.1.0
set -euo pipefail

if ! command -v gitleaks >/dev/null 2>&1; then
  echo "s3lab-policy: gitleaks not installed; run: brew install gitleaks" >&2
  exit 1
fi

CFG="$(git rev-parse --show-toplevel)/.s3lab-policy/gitleaks.toml"
exec gitleaks protect --staged --redact --no-banner --config "$CFG"
