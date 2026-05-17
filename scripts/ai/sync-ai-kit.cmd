@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "DRY_RUN=0"
set "KIT_PATH=%AI_KIT_PATH%"
set "EXTRA_EXCLUDES=;"

:parse_args
if "%~1"=="" goto after_args
if /I "%~1"=="-DryRun" (
  set "DRY_RUN=1"
  shift
  goto parse_args
)
if /I "%~1"=="-KitPath" (
  set "KIT_PATH=%~2"
  shift
  shift
  goto parse_args
)
if /I "%~1"=="-Exclude" (
  set "EXTRA_EXCLUDES=!EXTRA_EXCLUDES!%~2;"
  shift
  shift
  goto parse_args
)
shift
goto parse_args

:after_args
for %%I in ("%~dp0..\..") do set "REPO_CANDIDATE=%%~fI"
set "REPO_ROOT_FILE=%TEMP%\sync-ai-kit-root-%RANDOM%-%RANDOM%.txt"
git rev-parse --show-toplevel > "%REPO_ROOT_FILE%" 2>nul
if errorlevel 1 git -C "%REPO_CANDIDATE%" rev-parse --show-toplevel > "%REPO_ROOT_FILE%" 2>nul
if not errorlevel 1 set /p "REPO_ROOT="<"%REPO_ROOT_FILE%"
del /q "%REPO_ROOT_FILE%" >nul 2>nul

if not defined REPO_ROOT (
  echo Not a git repository ^(git rev-parse --show-toplevel failed^). 1>&2
  exit /b 1
)

if not defined KIT_PATH call :read_default_kit_path
if not defined KIT_PATH set "KIT_PATH=platform\ai-standard"

call :is_absolute_path "%KIT_PATH%"
if errorlevel 1 set "KIT_PATH=%REPO_ROOT%\%KIT_PATH%"

for %%I in ("%KIT_PATH%") do set "KIT_PATH=%%~fI"
if not exist "%KIT_PATH%\" (
  echo Kit path not found: %KIT_PATH% 1>&2
  echo Options: 1^) git submodule add ^<kit-url^> ^<folder^> then git submodule update --init 1>&2
  echo          2^) set AI_KIT_PATH or pass -KitPath ^(absolute or relative to repo root^) 1>&2
  echo          3^) edit scripts\ai\ai-kit.default-path with one non-comment line 1>&2
  exit /b 1
)

set "EXCLUDE_NAMES=;.git;scripts;README.md;"
call :load_exclude_file
set "EXCLUDE_NAMES=!EXCLUDE_NAMES!!EXTRA_EXCLUDES!"

echo Repo root: %REPO_ROOT%
echo Kit root:  %KIT_PATH%
echo Excluded top-level names: !EXCLUDE_NAMES!
if "%DRY_RUN%"=="1" echo DRY-RUN ^(no writes^)

set "FOUND_ITEMS=0"
for /f "usebackq delims=" %%I in (`dir /a /b "%KIT_PATH%"`) do (
  call :sync_item "%%I"
)

if "%FOUND_ITEMS%"=="0" (
  echo No items to copy ^(kit empty or all excluded^). 1>&2
  exit /b 0
)

echo Done. Review git diff and commit if OK.
exit /b 0

:read_default_kit_path
set "DEFAULT_PATH_FILE=%~dp0ai-kit.default-path"
if not exist "%DEFAULT_PATH_FILE%" exit /b 0
for /f "usebackq tokens=* delims=" %%A in ("%DEFAULT_PATH_FILE%") do (
  set "LINE=%%A"
  if defined LINE (
    if not "!LINE:~0,1!"=="#" (
      set "KIT_PATH=!LINE!"
      exit /b 0
    )
  )
)
exit /b 0

:load_exclude_file
exit /b 0

:sync_item
set "ITEM_NAME=%~1"
call :is_excluded "%ITEM_NAME%"
if not errorlevel 1 exit /b 0

set "FOUND_ITEMS=1"
set "SRC_FULL=%KIT_PATH%\%ITEM_NAME%"
set "DST_FULL=%REPO_ROOT%\%ITEM_NAME%"

if exist "%SRC_FULL%\" (
  if "%DRY_RUN%"=="1" (
    echo WOULD SYNC  %ITEM_NAME%  ^(DIR^)  -^>  %DST_FULL%
    exit /b 0
  )

  if exist "%DST_FULL%\" rmdir /s /q "%DST_FULL%"
  robocopy "%SRC_FULL%" "%DST_FULL%" /E /NFL /NDL /NJH /NJS /NC /NS /NP >nul
  if %ERRORLEVEL% GEQ 8 exit /b %ERRORLEVEL%
  echo DIR   %ITEM_NAME%
  exit /b 0
)

if "%DRY_RUN%"=="1" (
  echo WOULD SYNC  %ITEM_NAME%  ^(FILE^)  -^>  %DST_FULL%
  exit /b 0
)

copy /Y "%SRC_FULL%" "%DST_FULL%" >nul
echo FILE  %ITEM_NAME%
exit /b 0

:is_excluded
echo !EXCLUDE_NAMES! | findstr /I /C:";%~1;" >nul
if errorlevel 1 exit /b 1
exit /b 0

:is_absolute_path
set "PATH_TO_CHECK=%~1"
if "%PATH_TO_CHECK:~1,2%"==":\" exit /b 0
if "%PATH_TO_CHECK:~0,2%"=="\\" exit /b 0
exit /b 1
