#!/bin/sh
# POSIX-установщик git pre-commit хука (Linux / macOS / Git-Bash).
# Ставит тот же кросс-платформенный хук, что и install-git-hooks.cmd:
# CRLF-валидация + drift-гейт единого описания AI-kit.
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "Run inside a Git repository." >&2; exit 1; }
HOOK="$REPO_ROOT/.git/hooks/pre-commit"
mkdir -p "$REPO_ROOT/.git/hooks"

cat > "$HOOK" <<'HOOK_EOF'
#!/bin/sh
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0

# CRLF-валидация: POSIX-скрипт, иначе .cmd через cmd.exe (Windows без sh-обвязки).
if [ -f "$REPO_ROOT/scripts/validations/validate-crlf.sh" ]; then
  sh "$REPO_ROOT/scripts/validations/validate-crlf.sh" || exit 1
elif command -v cmd.exe >/dev/null 2>&1; then
  cmd.exe /c "\"$REPO_ROOT\\scripts\\validations\\validate-crlf.cmd\"" || exit 1
fi

# Drift-гейт: нативные артефакты должны совпадать с источником .ai/ (node — кросс-платформенно).
BUILDER="$REPO_ROOT/scripts/ai/build-ai-kit.mjs"
if command -v node >/dev/null 2>&1 && [ -f "$BUILDER" ]; then
  node "$BUILDER" --check || exit 1
fi
exit 0
HOOK_EOF

chmod +x "$HOOK" 2>/dev/null || true
echo "Installed Git pre-commit hook: $HOOK"
