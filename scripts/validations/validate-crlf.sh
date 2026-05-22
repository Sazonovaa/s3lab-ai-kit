#!/bin/sh
# POSIX-вариант validate-crlf.cmd (Linux / macOS / Git-Bash).
# Политика .gitattributes: текстовые файлы — CRLF в worktree, КРОМЕ файлов с
# явным атрибутом eol=lf (например *.sh). Проверяет staged-файлы перед коммитом.
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
cd "$REPO_ROOT" || exit 0

# Базовая проверка whitespace и маркеров конфликтов.
git diff --cached --check || exit 1

viol="$(mktemp)"
git diff --cached --name-only --diff-filter=ACMR | while IFS= read -r f; do
  line="$(git ls-files --eol -- "$f" 2>/dev/null)"
  [ -z "$line" ] && continue
  case "$line" in
    *"eol=lf"*) continue ;;   # явный lf-файл (.sh и т.п.) — ок
    *"w/crlf"*) continue ;;   # CRLF — ок
    *"w/-text"*) continue ;;  # бинарный — ок
    *"w/none"*) continue ;;   # без содержимого — ок
    *) printf '%s\n' "$f" >> "$viol" ;;
  esac
done

if [ -s "$viol" ]; then
  echo "CRLF validation failed. Staged text files without CRLF line endings:" >&2
  sed 's/^/  /' "$viol" >&2
  echo "Convert these files to CRLF before commit (или задайте eol=lf в .gitattributes)." >&2
  rm -f "$viol"
  exit 1
fi
rm -f "$viol"
exit 0
