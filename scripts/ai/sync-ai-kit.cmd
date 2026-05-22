@echo off
setlocal EnableExtensions

set "SUBMODULE_NAME=s3lab-ai-kit"
set "DRY_RUN="

if /i "%~1"=="--dry-run" set "DRY_RUN=1"
if /i "%~1"=="-DryRun" set "DRY_RUN=1"
if /i "%~1"=="dry-run" set "DRY_RUN=1"

for /f "delims=" %%R in ('git rev-parse --show-toplevel 2^>nul') do set "REPO_ROOT=%%R"
if not defined REPO_ROOT (
  echo sync-ai-kit: run this script inside a Git repository. 1>&2
  exit /b 1
)

echo Repo root: %REPO_ROOT%
echo Submodule: %SUBMODULE_NAME%

if defined DRY_RUN (
  echo DRY-RUN: git -C "%REPO_ROOT%" submodule update --init --remote "%SUBMODULE_NAME%"
  echo DRY-RUN: create "%REPO_ROOT%\CURSOR.md"
  echo DRY-RUN: create "%REPO_ROOT%\CLAUDE.md"
  echo DRY-RUN: create "%REPO_ROOT%\CODEX.md"
  echo DRY-RUN: node "%REPO_ROOT%\%SUBMODULE_NAME%\scripts\ai\build-ai-kit.mjs" --out "%REPO_ROOT%"
  exit /b 0
)

git -C "%REPO_ROOT%" submodule update --init --remote "%SUBMODULE_NAME%"
if errorlevel 1 (
  echo sync-ai-kit: failed to update submodule "%SUBMODULE_NAME%". 1>&2
  exit /b 1
)

for /f "delims=" %%H in ('git -C "%REPO_ROOT%\%SUBMODULE_NAME%" rev-parse --short HEAD 2^>nul') do set "SUBMODULE_HEAD=%%H"
if defined SUBMODULE_HEAD echo Updated %SUBMODULE_NAME% to %SUBMODULE_HEAD%.

call :WriteAgentEntry "CURSOR.md" "Cursor"
if errorlevel 1 exit /b 1

call :WriteAgentEntry "CLAUDE.md" "Claude Code"
if errorlevel 1 exit /b 1

call :WriteAgentEntry "CODEX.md" "Codex CLI"
if errorlevel 1 exit /b 1

rem Сгенерировать нативные артефакты вендоров (.claude, .cursor, индекс) в корне проекта.
where node >nul 2>nul
if errorlevel 1 (
  echo sync-ai-kit: Node.js не найден в PATH; пропускаю генерацию нативных артефактов. 1>&2
) else (
  node "%REPO_ROOT%\%SUBMODULE_NAME%\scripts\ai\build-ai-kit.mjs" --out "%REPO_ROOT%"
  if errorlevel 1 (
    echo sync-ai-kit: build-ai-kit завершился с ошибкой. 1>&2
    exit /b 1
  )
)

exit /b 0

:WriteAgentEntry
set "TARGET_FILE=%REPO_ROOT%\%~1"
set "SOURCE_FILE=%~1"
set "TOOL_NAME=%~2"

> "%TARGET_FILE%" echo(# %TOOL_NAME% project entry
>> "%TARGET_FILE%" echo(
>> "%TARGET_FILE%" echo(This project uses `%SUBMODULE_NAME%` as a Git submodule and the single source of truth for AI rules.
>> "%TARGET_FILE%" echo(
>> "%TARGET_FILE%" echo(Before any task, read and follow [`%SUBMODULE_NAME%/%SOURCE_FILE%`]^(%SUBMODULE_NAME%/%SOURCE_FILE%^).
>> "%TARGET_FILE%" echo(Path base: after opening `%SUBMODULE_NAME%/%SOURCE_FILE%`, resolve all relative AI Kit paths from `%SUBMODULE_NAME%/`.
>> "%TARGET_FILE%" echo(Load all AI rules, skills, subagents, hooks, and routing from [`%SUBMODULE_NAME%/`]^(%SUBMODULE_NAME%/^).
>> "%TARGET_FILE%" echo(
>> "%TARGET_FILE%" echo(Do not duplicate rules here. Update the central kit in `%SUBMODULE_NAME%`.

if errorlevel 1 (
  echo sync-ai-kit: failed to write "%TARGET_FILE%". 1>&2
  exit /b 1
)

echo Wrote %~1.
exit /b 0
