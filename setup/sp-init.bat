@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM  Skill-personal project init script
REM  Usage: setup\sp-init.bat [project-path]
REM  If no argument given, uses current directory as target
REM ============================================================

REM Get script directory (setup/) and repo root (parent)
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
for %%I in ("%SCRIPT_DIR%\..") do set "REPO_ROOT=%%~fI"

REM Get target project path
if "%~1"=="" (
    set "PROJECT_DIR=%CD%"
) else (
    set "PROJECT_DIR=%~f1"
)

echo.
echo ====================================================
echo   Skill-personal Project Init
echo ====================================================
echo.
echo   Repo:    %REPO_ROOT%
echo   Target:  %PROJECT_DIR%
echo.

REM Validate target path
if not exist "%PROJECT_DIR%" (
    echo [ERROR] Target path does not exist: %PROJECT_DIR%
    exit /b 1
)

REM Check if target is a git repo
if not exist "%PROJECT_DIR%\.git" (
    echo [WARN] Target is not a git repository. Continuing anyway.
    echo.
)

REM Prevent running in Skill-personal repo itself
if "%PROJECT_DIR%"=="%REPO_ROOT%" (
    echo [ERROR] Cannot run this script inside the Skill-personal repo itself.
    echo         Run from the target project directory, or pass the project path as argument.
    exit /b 1
)

REM ============================
REM  Step 1: Create .claude/skills/
REM ============================
echo [1/6] Setting up .claude/skills/ ...

if exist "%PROJECT_DIR%\.claude\skills" (
    echo       Already exists - merge mode, will not overwrite existing skills
    set "MODE=merge"
) else (
    mkdir "%PROJECT_DIR%\.claude\skills" 2>nul
    echo       Created .claude/skills/
    set "MODE=init"
)

REM ============================
REM  Step 2: Copy skill folders
REM ============================
echo [2/6] Copying skill files...

set "SKILL_COUNT=0"
for /d %%D in ("%REPO_ROOT%\*") do (
    call :CopySkill "%%D" "%%~nxD"
)

REM Copy root README.md to .claude/skills/ (init mode only)
if "!MODE!"=="init" (
    if exist "%REPO_ROOT%\README.md" (
        copy /Y "%REPO_ROOT%\README.md" "%PROJECT_DIR%\.claude\skills\README.md" >nul 2>&1
        echo       + README.md
    )
)

echo       Processed !SKILL_COUNT! skills

REM ============================
REM  Step 3: Create .skill_personal/
REM ============================
echo [3/6] Setting up .skill_personal/ ...

if exist "%PROJECT_DIR%\.skill_personal" (
    echo       .skill_personal/ already exists - skipped
) else (
    xcopy "%REPO_ROOT%" "%PROJECT_DIR%\.skill_personal\" /E /I /Y /Q >nul 2>&1
    REM Re-init git and link to remote repo
    if exist "%PROJECT_DIR%\.skill_personal\.git" (
        rmdir /S /Q "%PROJECT_DIR%\.skill_personal\.git" 2>nul
    )
    pushd "%PROJECT_DIR%\.skill_personal"
    git init >nul 2>&1
    git remote add origin https://github.com/SWSekai/Skill-personal.git >nul 2>&1
    git fetch origin >nul 2>&1
    git branch -M main >nul 2>&1
    git reset --mixed origin/main >nul 2>&1
    popd
    echo       Created .skill_personal/ - independent git, remote: Skill-personal
)

REM ============================
REM  Step 4: Create CLAUDE.md
REM ============================
echo [4/6] Setting up CLAUDE.md...

if exist "%PROJECT_DIR%\CLAUDE.md" (
    echo       CLAUDE.md already exists - skipped, check manually if update needed
) else (
    set "TEMPLATE=%SCRIPT_DIR%\templates\CLAUDE.md.template"
    if not exist "!TEMPLATE!" (
        echo       WARN: Template file not found - skipped
        goto :DoneClaude
    )
    REM Get project folder name
    for %%F in ("%PROJECT_DIR%") do set "PROJECT_NAME=%%~nxF"
    REM Copy template and replace placeholder
    powershell -NoProfile -Command "(Get-Content '!TEMPLATE!' -Raw) -replace '\{\{PROJECT_NAME\}\}', '!PROJECT_NAME!' | Set-Content '%PROJECT_DIR%\CLAUDE.md' -Encoding UTF8"
    echo       Created CLAUDE.md from template
)
:DoneClaude

REM ============================
REM  Step 5: Install pre-commit hook
REM ============================
echo [5/6] Installing pre-commit hook...

if not exist "%PROJECT_DIR%\.git" (
    echo       WARN: Not a git repository - hook install skipped
    goto :DoneHook
)

if not exist "%PROJECT_DIR%\.git\hooks" (
    mkdir "%PROJECT_DIR%\.git\hooks" 2>nul
)

set "HOOK_SRC=%SCRIPT_DIR%\hooks\pre-commit"
set "HOOK_DST=%PROJECT_DIR%\.git\hooks\pre-commit"

if not exist "!HOOK_SRC!" (
    echo       WARN: setup/hooks/pre-commit source not found - skipped
    goto :DoneHook
)

if exist "!HOOK_DST!" (
    fc /B "!HOOK_SRC!" "!HOOK_DST!" >nul 2>&1
    if errorlevel 1 (
        echo       Hook exists but differs - backing up to pre-commit.bak
        copy /Y "!HOOK_DST!" "!HOOK_DST!.bak" >nul 2>&1
        copy /Y "!HOOK_SRC!" "!HOOK_DST!" >nul 2>&1
        echo       Installed pre-commit hook - old version backed up
    ) else (
        echo       pre-commit hook already installed and up-to-date
    )
) else (
    copy /Y "!HOOK_SRC!" "!HOOK_DST!" >nul 2>&1
    echo       Installed pre-commit hook
)

:DoneHook

REM ============================
REM  Step 6: Claude Code environment
REM  (statusline + hooks)
REM ============================
echo [6/6] Setting up Claude Code environment...

set "CLAUDE_HOME=%USERPROFILE%\.claude"
set "SL_SRC=%SCRIPT_DIR%\templates\statusline.sh"
set "SL_DST=%CLAUDE_HOME%\statusline.sh"
set "USER_SETTINGS=%CLAUDE_HOME%\settings.json"
set "HOOKS_SRC=%SCRIPT_DIR%\templates\hooks.json"
set "LOCAL_SETTINGS=%PROJECT_DIR%\.claude\settings.local.json"

if not exist "%CLAUDE_HOME%" mkdir "%CLAUDE_HOME%" 2>nul

REM --- 6a: Statusline ---
echo       [6a] Statusline...
if not exist "!SL_SRC!" (
    echo            WARN: templates/statusline.sh not found - skipped
) else if exist "!SL_DST!" (
    fc /B "!SL_SRC!" "!SL_DST!" >nul 2>&1
    if errorlevel 1 (
        copy /Y "!SL_SRC!" "!SL_DST!" >nul 2>&1
        echo            Updated statusline.sh
    ) else (
        echo            Already up-to-date
    )
) else (
    copy /Y "!SL_SRC!" "!SL_DST!" >nul 2>&1
    echo            Installed statusline.sh
)

REM Ensure statusLine in user settings.json
if exist "!USER_SETTINGS!" (
    findstr /C:"statusLine" "!USER_SETTINGS!" >nul 2>&1
    if errorlevel 1 (
        powershell -NoProfile -Command "$j = Get-Content '!USER_SETTINGS!' -Raw | ConvertFrom-Json; $j | Add-Member -NotePropertyName 'statusLine' -NotePropertyValue ([PSCustomObject]@{type='command';command='bash ~/.claude/statusline.sh'}) -Force; $j | ConvertTo-Json -Depth 10 | Set-Content '!USER_SETTINGS!' -Encoding UTF8"
        echo            Added statusLine to settings.json
    )
) else (
    powershell -NoProfile -Command "@{statusLine=@{type='command';command='bash ~/.claude/statusline.sh'}} | ConvertTo-Json -Depth 10 | Set-Content '!USER_SETTINGS!' -Encoding UTF8"
    echo            Created settings.json with statusLine
)

REM --- 6b: Hooks (into project .claude/settings.local.json) ---
echo       [6b] Hooks...
if not exist "!HOOKS_SRC!" (
    echo            WARN: templates/hooks.json not found - skipped
    goto :DoneEnv
)

if not exist "%PROJECT_DIR%\.claude" mkdir "%PROJECT_DIR%\.claude" 2>nul

if exist "!LOCAL_SETTINGS!" (
    findstr /C:"hooks" "!LOCAL_SETTINGS!" >nul 2>&1
    if errorlevel 1 (
        REM settings.local.json exists but no hooks - merge hooks from template
        powershell -NoProfile -Command "$local = Get-Content '!LOCAL_SETTINGS!' -Raw | ConvertFrom-Json; $tmpl = Get-Content '!HOOKS_SRC!' -Raw | ConvertFrom-Json; $local | Add-Member -NotePropertyName 'hooks' -NotePropertyValue $tmpl.hooks -Force; $local | ConvertTo-Json -Depth 20 | Set-Content '!LOCAL_SETTINGS!' -Encoding UTF8"
        echo            Merged hooks into settings.local.json
    ) else (
        echo            Hooks already configured
    )
) else (
    REM Create settings.local.json from hooks template (without _comment/_design)
    powershell -NoProfile -Command "$tmpl = Get-Content '!HOOKS_SRC!' -Raw | ConvertFrom-Json; $out = @{hooks=$tmpl.hooks}; $out | ConvertTo-Json -Depth 20 | Set-Content '!LOCAL_SETTINGS!' -Encoding UTF8"
    echo            Created settings.local.json with hooks
)

:DoneEnv

REM ============================
REM  Done
REM ============================
echo.
echo ====================================================
echo   Init complete!
echo ====================================================
echo.
echo   Created:
echo     - .claude/skills/     - Claude Code skill definitions
echo     - .skill_personal/    - Skill template for sync
echo     - pre-commit hook     - blocks skill files from project git
echo     - CLAUDE.md           - project rules, customize as needed
echo     - statusline.sh       - Claude Code status bar script
echo     - hooks               - auto-trigger for skill/memory sync (local only)
echo.
echo   Next steps:
echo     1. Add .skill_personal/ to .gitignore
echo     2. Customize CLAUDE.md for your project
echo     3. Customize .claude/skills/ SKILL.md files
echo     4. Run /skill-sync in Claude Code to verify
echo.

endlocal
exit /b 0

REM ============================
REM  Subroutine: CopySkill
REM  %~1 = full path to skill dir
REM  %~2 = directory name
REM ============================
:CopySkill
set "SKILL_PATH=%~1"
set "DIRNAME=%~2"

REM Skip non-skill directories
if "%DIRNAME%"==".git" exit /b 0
if "%DIRNAME%"=="setup" exit /b 0
if "%DIRNAME%"=="docs" exit /b 0
if "%DIRNAME:~0,1%"=="." exit /b 0

if "!MODE!"=="init" (
    xcopy "%SKILL_PATH%" "%PROJECT_DIR%\.claude\skills\%DIRNAME%\" /E /I /Y /Q >nul 2>&1
    echo       + %DIRNAME%/
    set /a SKILL_COUNT+=1
) else (
    if not exist "%PROJECT_DIR%\.claude\skills\%DIRNAME%" (
        xcopy "%SKILL_PATH%" "%PROJECT_DIR%\.claude\skills\%DIRNAME%\" /E /I /Y /Q >nul 2>&1
        echo       + %DIRNAME%/ [new]
        set /a SKILL_COUNT+=1
    ) else (
        echo       ~ %DIRNAME%/ [exists - keeping project version]
    )
)
exit /b 0
