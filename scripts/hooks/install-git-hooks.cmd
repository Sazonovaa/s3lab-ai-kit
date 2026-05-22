@echo off
setlocal EnableExtensions

for /f "delims=" %%R in ('git rev-parse --show-toplevel 2^>nul') do set "REPO_ROOT=%%R"
if not defined REPO_ROOT (
  echo Run this script inside a Git repository. 1>&2
  exit /b 1
)

set "HOOKS_DIR=%REPO_ROOT%\.git\hooks"
set "HOOK_PATH=%HOOKS_DIR%\pre-commit"

if not exist "%HOOKS_DIR%" mkdir "%HOOKS_DIR%" >nul 2>nul

> "%HOOK_PATH%" echo #!/bin/sh
>> "%HOOK_PATH%" echo REPO_ROOT="$(git rev-parse --show-toplevel 2^>/dev/null)" ^|^| exit 0
>> "%HOOK_PATH%" echo.
>> "%HOOK_PATH%" echo # CRLF-валидация: POSIX-скрипт, иначе .cmd через cmd.exe.
>> "%HOOK_PATH%" echo if [ -f "$REPO_ROOT/scripts/validations/validate-crlf.sh" ]; then
>> "%HOOK_PATH%" echo   sh "$REPO_ROOT/scripts/validations/validate-crlf.sh" ^|^| exit 1
>> "%HOOK_PATH%" echo elif command -v cmd.exe ^>/dev/null 2^>^&1; then
>> "%HOOK_PATH%" echo   cmd.exe /c "\"$REPO_ROOT\scripts\validations\validate-crlf.cmd\"" ^|^| exit 1
>> "%HOOK_PATH%" echo fi
>> "%HOOK_PATH%" echo.
>> "%HOOK_PATH%" echo # Drift-гейт: нативные артефакты должны совпадать с источником .ai/.
>> "%HOOK_PATH%" echo BUILDER="$REPO_ROOT/scripts/ai/build-ai-kit.mjs"
>> "%HOOK_PATH%" echo if command -v node ^>/dev/null 2^>^&1 ^&^& [ -f "$BUILDER" ]; then
>> "%HOOK_PATH%" echo   node "$BUILDER" --check ^|^| exit 1
>> "%HOOK_PATH%" echo fi
>> "%HOOK_PATH%" echo.
>> "%HOOK_PATH%" echo exit 0

echo Installed Git pre-commit hook: %HOOK_PATH%
exit /b 0
