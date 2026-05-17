@echo off
setlocal EnableExtensions EnableDelayedExpansion

for %%I in ("%~dp0..\..") do set "SCRIPT_REPO_ROOT=%%~fI"
set "REPO_ROOT_FILE=%TEMP%\sync-submodule-root-%RANDOM%-%RANDOM%.txt"
git rev-parse --show-toplevel > "%REPO_ROOT_FILE%" 2>nul
if not errorlevel 1 set /p "REPO_ROOT="<"%REPO_ROOT_FILE%"
del /q "%REPO_ROOT_FILE%" >nul 2>nul

if not defined REPO_ROOT set "REPO_ROOT=%SCRIPT_REPO_ROOT%"
if not exist "%REPO_ROOT%\tiss.ai.kit.standart\" set "REPO_ROOT=%SCRIPT_REPO_ROOT%"

set "SUBMODULE_PATH=%REPO_ROOT%\tiss.ai.kit.standart"
set "SYNC_SCRIPT_PATH=%REPO_ROOT%\scripts\ai\sync-ai-kit.cmd"
if not exist "%SYNC_SCRIPT_PATH%" set "SYNC_SCRIPT_PATH=%SUBMODULE_PATH%\scripts\ai\sync-ai-kit.cmd"

if not exist "%SUBMODULE_PATH%\" (
  call :log "submodule directory not found: %SUBMODULE_PATH%"
  call :finish
  exit /b 0
)

git -C "%SUBMODULE_PATH%" rev-parse --is-inside-work-tree >nul 2>nul
if errorlevel 1 (
  call :log "submodule directory is not a git repository: %SUBMODULE_PATH%"
  call :finish
  exit /b 0
)

git -C "%SUBMODULE_PATH%" fetch --quiet
if errorlevel 1 (
  call :log "failed to fetch remote changes"
  call :finish
  exit /b 0
)

set "UPSTREAM="
for /f "usebackq delims=" %%A in (`git -C "%SUBMODULE_PATH%" rev-parse --abbrev-ref --symbolic-full-name "@{u}" 2^>nul`) do set "UPSTREAM=%%A"
if not defined UPSTREAM (
  call :log "current submodule branch has no upstream"
  call :finish
  exit /b 0
)

for /f "usebackq delims=" %%A in (`git -C "%SUBMODULE_PATH%" rev-parse HEAD`) do set "LOCAL_HEAD=%%A"
for /f "usebackq delims=" %%A in (`git -C "%SUBMODULE_PATH%" rev-parse "%UPSTREAM%"`) do set "REMOTE_HEAD=%%A"
for /f "usebackq delims=" %%A in (`git -C "%SUBMODULE_PATH%" merge-base HEAD "%UPSTREAM%"`) do set "BASE_HEAD=%%A"

if "%LOCAL_HEAD%"=="%REMOTE_HEAD%" (
  call :log "submodule is already up to date"
  call :finish
  exit /b 0
)

if not "%LOCAL_HEAD%"=="%BASE_HEAD%" (
  call :log "submodule has local commits or diverged history; skipping automatic pull"
  call :finish
  exit /b 0
)

git -C "%SUBMODULE_PATH%" pull --ff-only --quiet
if errorlevel 1 (
  call :log "failed to fast-forward submodule"
  call :finish
  exit /b 0
)

if not exist "%SYNC_SCRIPT_PATH%" (
  call :log "sync script not found: %SYNC_SCRIPT_PATH%"
  call :finish
  exit /b 0
)

call :log "running sync script: %SYNC_SCRIPT_PATH% -DryRun"
call "%SYNC_SCRIPT_PATH%" -DryRun 1>&2
if errorlevel 1 (
  call :log "sync script failed"
  call :finish
  exit /b 0
)

call :finish
exit /b 0

:log
echo sync-submodule-on-start: %~1 1>&2
exit /b 0

:finish
echo {}
exit /b 0
