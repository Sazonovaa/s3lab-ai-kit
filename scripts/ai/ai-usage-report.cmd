@echo off
setlocal EnableExtensions

set "LOG_PATH=%~1"

if "%LOG_PATH%"=="" (
  call :ResolveDefaultLogPath
)

if not exist "%LOG_PATH%" (
  echo No AI usage log found: %LOG_PATH%
  exit /b 0
)

for /f %%C in ('find /c /v "" ^< "%LOG_PATH%"') do set "EVENT_COUNT=%%C"

echo AI usage log: %LOG_PATH%
echo Total events: %EVENT_COUNT%
exit /b 0

:ResolveDefaultLogPath
for /f "delims=" %%R in ('git rev-parse --show-toplevel 2^>nul') do set "REPO_ROOT=%%R"
if not defined REPO_ROOT set "REPO_ROOT=%~dp0..\.."
set "LOG_PATH=%REPO_ROOT%\logs\ai-usage.jsonl"
exit /b 0
