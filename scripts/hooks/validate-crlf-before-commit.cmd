@echo off
setlocal EnableExtensions

set "INPUT_FILE=%TEMP%\validate-crlf-before-commit-%RANDOM%-%RANDOM%.json"
more > "%INPUT_FILE%"

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0validate-crlf-before-commit.ps1" -HookInputPath "%INPUT_FILE%"
set "EXIT_CODE=%ERRORLEVEL%"

del /q "%INPUT_FILE%" >nul 2>nul
exit /b %EXIT_CODE%
