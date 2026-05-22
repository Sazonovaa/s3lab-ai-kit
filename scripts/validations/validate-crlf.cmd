@echo off
setlocal EnableExtensions EnableDelayedExpansion

for /f "delims=" %%R in ('git rev-parse --show-toplevel 2^>nul') do set "REPO_ROOT=%%R"
if not defined REPO_ROOT exit /b 0

pushd "%REPO_ROOT%" >nul

git diff --cached --check
if errorlevel 1 (
  popd >nul
  exit /b 1
)

set "VIOLATIONS="
for /f "delims=" %%F in ('git diff --cached --name-only --diff-filter^=ACMR') do call :CheckFile "%%F"

if defined VIOLATIONS (
  echo CRLF validation failed. Staged text files without CRLF line endings:!VIOLATIONS! 1>&2
  echo Convert these files to CRLF before commit. 1>&2
  popd >nul
  exit /b 1
)

popd >nul
exit /b 0

:CheckFile
set "FILE=%~1"
set "EOLLINE="

for /f "delims=" %%L in ('git ls-files --eol -- "%FILE%" 2^>nul') do set "EOLLINE=%%L"

if not defined EOLLINE exit /b 0
echo !EOLLINE! | findstr /C:"eol=lf" >nul && exit /b 0
echo !EOLLINE! | findstr /C:"w/crlf" >nul && exit /b 0
echo !EOLLINE! | findstr /C:"w/-text" >nul && exit /b 0
echo !EOLLINE! | findstr /C:"w/none" >nul && exit /b 0

set "VIOLATIONS=!VIOLATIONS! %FILE%"
exit /b 0
