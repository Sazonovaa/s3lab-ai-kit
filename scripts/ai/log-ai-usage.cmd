@echo off
setlocal

set "VENDOR=%~1"
set "EVENT=%~2"
set "RESULT=%~3"
set "SKILL=%~4"
set "SUBAGENT=%~5"

if "%VENDOR%"=="" set "VENDOR=unknown"
if "%EVENT%"=="" set "EVENT=unknown"

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0log-ai-usage.ps1" -Vendor "%VENDOR%" -Event "%EVENT%" -Result "%RESULT%" -Skill "%SKILL%" -Subagent "%SUBAGENT%" >nul 2>nul

echo {}
exit /b 0
