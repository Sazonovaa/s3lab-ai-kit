#!/usr/bin/env bash
set -euo pipefail

SUBMODULE_NAME="s3lab-ai-kit"
DRY_RUN=""

case "${1:-}" in
  --dry-run|-DryRun|dry-run) DRY_RUN=1 ;;
esac

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$REPO_ROOT" ]; then
  echo "sync-ai-kit: run this script inside a Git repository." >&2
  exit 1
fi

echo "Repo root: $REPO_ROOT"
echo "Submodule: $SUBMODULE_NAME"

write_agent_entry() {
  source_file="$1"
  tool_name="$2"
  target_file="$REPO_ROOT/$source_file"

  cat > "$target_file" <<EOF
# $tool_name project entry

This project uses \`$SUBMODULE_NAME\` as a Git submodule and the single source of truth for AI rules.

Before any task, read and follow [\`$SUBMODULE_NAME/$source_file\`]($SUBMODULE_NAME/$source_file).
Path base: after opening \`$SUBMODULE_NAME/$source_file\`, resolve all relative AI Kit paths from \`$SUBMODULE_NAME/\`.
Load all AI rules, skills, subagents, hooks, and routing from [\`$SUBMODULE_NAME/\`]($SUBMODULE_NAME/).

Do not duplicate rules here. Update the central kit in \`$SUBMODULE_NAME\`.
EOF

  echo "Wrote $source_file."
}

if [ -n "$DRY_RUN" ]; then
  echo "DRY-RUN: git -C \"$REPO_ROOT\" submodule update --init --remote \"$SUBMODULE_NAME\""
  echo "DRY-RUN: create \"$REPO_ROOT/CURSOR.md\""
  echo "DRY-RUN: create \"$REPO_ROOT/CLAUDE.md\""
  echo "DRY-RUN: create \"$REPO_ROOT/CODEX.md\""
  echo "DRY-RUN: node \"$REPO_ROOT/$SUBMODULE_NAME/scripts/ai/build-ai-kit.mjs\" --out \"$REPO_ROOT\""
  exit 0
fi

if ! git -C "$REPO_ROOT" submodule update --init --remote "$SUBMODULE_NAME"; then
  echo "sync-ai-kit: failed to update submodule \"$SUBMODULE_NAME\"." >&2
  exit 1
fi

SUBMODULE_HEAD="$(git -C "$REPO_ROOT/$SUBMODULE_NAME" rev-parse --short HEAD 2>/dev/null || true)"
if [ -n "$SUBMODULE_HEAD" ]; then
  echo "Updated $SUBMODULE_NAME to $SUBMODULE_HEAD."
fi

write_agent_entry "CURSOR.md" "Cursor"
write_agent_entry "CLAUDE.md" "Claude Code"
write_agent_entry "CODEX.md" "Codex CLI"

# Сгенерировать нативные артефакты вендоров (.claude, .cursor, индекс) в корне проекта.
if ! command -v node >/dev/null 2>&1; then
  echo "sync-ai-kit: Node.js не найден в PATH; пропускаю генерацию нативных артефактов." >&2
else
  if ! node "$REPO_ROOT/$SUBMODULE_NAME/scripts/ai/build-ai-kit.mjs" --out "$REPO_ROOT"; then
    echo "sync-ai-kit: build-ai-kit завершился с ошибкой." >&2
    exit 1
  fi
fi

exit 0
