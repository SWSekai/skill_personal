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

REM Prevent running in Skill-personal repo itself or any of its subdirectories
set "CHECK_DIR=%PROJECT_DIR%"
:CheckRepoLoop
if /I "!CHECK_DIR!"=="%REPO_ROOT%" (
    echo [ERROR] Cannot run this script inside the Skill-personal repo or any subdirectory of it.
    echo         Current target: %PROJECT_DIR%
    echo         Run from your target project directory, or pass the project path as argument.
    exit /b 1
)
for %%I in ("!CHECK_DIR!\..") do set "PARENT_DIR=%%~fI"
if /I not "!PARENT_DIR!"=="!CHECK_DIR!" (
    set "CHECK_DIR=!PARENT_DIR!"
    goto :CheckRepoLoop
)

REM ============================
REM  Step 1: Create .claude/skills/
REM ============================
echo [1/9] Setting up .claude/skills/ ...

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
echo [2/9] Copying skill files...

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
REM  Step 3: Create .Sekai_workflow/
REM ============================
echo [3/9] Setting up .Sekai_workflow/ ...

if exist "%PROJECT_DIR%\.Sekai_workflow" (
    echo       .Sekai_workflow/ already exists - skipped
) else (
    xcopy "%REPO_ROOT%" "%PROJECT_DIR%\.Sekai_workflow\" /E /I /Y /Q >nul 2>&1
    REM Re-init git and link to remote repo
    if exist "%PROJECT_DIR%\.Sekai_workflow\.git" (
        rmdir /S /Q "%PROJECT_DIR%\.Sekai_workflow\.git" 2>nul
    )
    pushd "%PROJECT_DIR%\.Sekai_workflow"
    git init >nul 2>&1
    git remote add origin https://github.com/SWSekai/Skill-personal.git >nul 2>&1
    git fetch origin >nul 2>&1
    git branch -M main >nul 2>&1
    git reset --mixed origin/main >nul 2>&1
    popd
    echo       Created .Sekai_workflow/ - independent git, remote: Skill-personal
)

REM ============================
REM  Step 4: Create CLAUDE.md
REM ============================
echo [4/9] Setting up CLAUDE.md...

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
    powershell -NoProfile -Command "(Get-Content '!TEMPLATE!' -Raw -Encoding UTF8) -replace '\{\{PROJECT_NAME\}\}', '!PROJECT_NAME!' | Set-Content '%PROJECT_DIR%\CLAUDE.md' -Encoding UTF8"
    echo       Created CLAUDE.md from template
)
:DoneClaude

REM ============================
REM  Step 5: Update .gitignore
REM ============================
echo [5/9] Updating .gitignore...

set "GITIGNORE=%PROJECT_DIR%\.gitignore"

REM Create .gitignore if not exists
if not exist "!GITIGNORE!" (
    type nul > "!GITIGNORE!"
    echo       Created new .gitignore
)

REM Define required entries
set "GI_ENTRIES=CLAUDE.md .claude/ Sekai_workflow/ .Sekai_workflow/ .local/"

for %%E in (%GI_ENTRIES%) do (
    findstr /X /C:"%%E" "!GITIGNORE!" >nul 2>&1
    if errorlevel 1 (
        echo.>>"!GITIGNORE!"
        echo %%E>>"!GITIGNORE!"
        echo       + %%E
    ) else (
        echo       ~ %%E [already present]
    )
)

REM Clean up: remove consecutive blank lines (PowerShell one-liner)
powershell -NoProfile -Command "$nl = [Environment]::NewLine; [System.IO.File]::WriteAllText('!GITIGNORE!', ([System.IO.File]::ReadAllText('!GITIGNORE!') -replace '(\r?\n){3,}', ($nl + $nl)).Trim(), (New-Object System.Text.UTF8Encoding $false))"

REM ============================
REM  Step 6: Install pre-commit hook
REM ============================
echo [6/9] Installing pre-commit hook...

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
REM  Step 7: Claude Code environment
REM  (statusline + hooks)
REM ============================
echo [7/9] Setting up Claude Code environment...

set "CLAUDE_HOME=%USERPROFILE%\.claude"
set "SL_SRC=%SCRIPT_DIR%\templates\statusline.sh"
set "SL_DST=%CLAUDE_HOME%\statusline.sh"
set "USER_SETTINGS=%CLAUDE_HOME%\settings.json"
set "HOOKS_SRC=%SCRIPT_DIR%\templates\hooks.json"
set "LOCAL_SETTINGS=%PROJECT_DIR%\.claude\settings.local.json"

if not exist "%CLAUDE_HOME%" mkdir "%CLAUDE_HOME%" 2>nul

REM --- 7a: Statusline ---
echo       [7a] Statusline...
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

REM --- 7b: Hook scripts (copy .cjs files to .claude/hooks/) ---
echo       [7b] Hook scripts...
set "HOOK_SCRIPTS_SRC=%REPO_ROOT%\hooks"
set "HOOK_SCRIPTS_DST=%PROJECT_DIR%\.claude\hooks"

if not exist "!HOOK_SCRIPTS_SRC!" (
    echo            WARN: hooks/ directory not found in Sekai_workflow - skipped
) else (
    if not exist "!HOOK_SCRIPTS_DST!" mkdir "!HOOK_SCRIPTS_DST!" 2>nul
    set "HOOK_COPIED=0"
    for %%F in ("!HOOK_SCRIPTS_SRC!\*.cjs") do (
        copy /Y "%%F" "!HOOK_SCRIPTS_DST!\%%~nxF" >nul 2>&1
        set /a HOOK_COPIED+=1
    )
    echo            Copied !HOOK_COPIED! hook scripts
)

REM --- 7c: Hooks config (into project .claude/settings.local.json) ---
echo       [7c] Hooks config...
if not exist "!HOOKS_SRC!" (
    echo            WARN: templates/hooks.json not found - skipped
    goto :DoneEnv
)

if not exist "%PROJECT_DIR%\.claude" mkdir "%PROJECT_DIR%\.claude" 2>nul

REM Convert PROJECT_DIR to forward-slash path for hooks.json
set "PROJECT_DIR_FWD=%PROJECT_DIR:\=/%"

if exist "!LOCAL_SETTINGS!" (
    findstr /C:"hooks" "!LOCAL_SETTINGS!" >nul 2>&1
    if errorlevel 1 (
        REM settings.local.json exists but no hooks - merge hooks from template
        powershell -NoProfile -Command "$local = Get-Content '!LOCAL_SETTINGS!' -Raw -Encoding UTF8 | ConvertFrom-Json; $tmpl = (Get-Content '!HOOKS_SRC!' -Raw -Encoding UTF8) -replace '\{\{PROJECT_DIR\}\}', '!PROJECT_DIR_FWD!' | ConvertFrom-Json; $local | Add-Member -NotePropertyName 'hooks' -NotePropertyValue $tmpl.hooks -Force; $local | ConvertTo-Json -Depth 20 | Set-Content '!LOCAL_SETTINGS!' -Encoding UTF8"
        echo            Merged hooks into settings.local.json
    ) else (
        echo            Hooks already configured - updating hook paths
        REM Update existing hooks with current project path
        powershell -NoProfile -Command "$content = Get-Content '!LOCAL_SETTINGS!' -Raw -Encoding UTF8; $tmpl = (Get-Content '!HOOKS_SRC!' -Raw -Encoding UTF8) -replace '\{\{PROJECT_DIR\}\}', '!PROJECT_DIR_FWD!' | ConvertFrom-Json; $local = $content | ConvertFrom-Json; $local.hooks = $tmpl.hooks; $local | ConvertTo-Json -Depth 20 | Set-Content '!LOCAL_SETTINGS!' -Encoding UTF8"
    )
) else (
    REM Create settings.local.json from hooks template
    powershell -NoProfile -Command "$tmpl = (Get-Content '!HOOKS_SRC!' -Raw -Encoding UTF8) -replace '\{\{PROJECT_DIR\}\}', '!PROJECT_DIR_FWD!' | ConvertFrom-Json; $out = @{hooks=$tmpl.hooks}; $out | ConvertTo-Json -Depth 20 | Set-Content '!LOCAL_SETTINGS!' -Encoding UTF8"
    echo            Created settings.local.json with hooks
)

:DoneEnv

REM ============================
REM  Step 8: Restore portable memory
REM ============================
echo [8/9] Restoring portable memory...

set "MEM_PORTABLE=%REPO_ROOT%\memory-portable"

if not exist "!MEM_PORTABLE!" (
    echo       WARN: memory-portable/ not found in Sekai_workflow - skipped
    goto :DoneMemory
)

REM Detect Claude Code memory path for this project
REM Claude Code encodes project path as: D--project_name (drive + path with separators replaced)
for %%F in ("%PROJECT_DIR%") do set "PROJ_DRIVE=%%~dF"
set "PROJ_DRIVE_LETTER=%PROJ_DRIVE:~0,1%"
for %%F in ("%PROJECT_DIR%") do set "PROJ_PATH_RAW=%%~pnxF"
REM Remove leading backslash, replace \ with -
set "PROJ_PATH_CLEAN=%PROJ_PATH_RAW:~1%"
set "PROJ_PATH_CLEAN=%PROJ_PATH_CLEAN:\=-%"

REM Search for matching memory directory under ~/.claude/projects/
set "CLAUDE_PROJECTS=%USERPROFILE%\.claude\projects"
set "MEMORY_TARGET="

if not exist "%CLAUDE_PROJECTS%" mkdir "%CLAUDE_PROJECTS%" 2>nul

REM Try exact encoded path first
set "EXACT_PATH=%CLAUDE_PROJECTS%\%PROJ_DRIVE_LETTER%--%PROJ_PATH_CLEAN%\memory"
if exist "%EXACT_PATH%" (
    set "MEMORY_TARGET=!EXACT_PATH!"
) else (
    REM Fallback: search for directory containing project folder name
    for %%F in ("%PROJECT_DIR%") do set "PROJ_BASENAME=%%~nxF"
    for /d %%D in ("%CLAUDE_PROJECTS%\*") do (
        echo %%~nxD | findstr /I "!PROJ_BASENAME!" >nul 2>&1
        if not errorlevel 1 (
            if exist "%%D\memory" (
                set "MEMORY_TARGET=%%D\memory"
            )
        )
    )
)

REM If still not found, create the directory using exact encoded path
if "!MEMORY_TARGET!"=="" (
    set "MEMORY_TARGET=!EXACT_PATH!"
    mkdir "!MEMORY_TARGET!" 2>nul
    echo       Created memory directory: !MEMORY_TARGET!
)

REM Copy portable memories (skip existing to preserve local modifications)
set "MEM_RESTORED=0"
set "MEM_SKIPPED=0"
for %%F in ("!MEM_PORTABLE!\*.md") do (
    if /I not "%%~nxF"=="README.md" (
        if exist "!MEMORY_TARGET!\%%~nxF" (
            set /a MEM_SKIPPED+=1
        ) else (
            copy /Y "%%F" "!MEMORY_TARGET!\%%~nxF" >nul 2>&1
            set /a MEM_RESTORED+=1
        )
    )
)

REM Generate/update MEMORY.md index
if !MEM_RESTORED! GTR 0 (
    REM Rebuild MEMORY.md from all .md files in memory dir
    powershell -NoProfile -Command "$dir='!MEMORY_TARGET!'; $entries=@(); Get-ChildItem $dir -Filter '*.md' | Where-Object { $_.Name -ne 'MEMORY.md' -and $_.Name -ne 'README.md' } | ForEach-Object { $content=Get-Content $_.FullName -Raw -Encoding UTF8; if($content -match 'name:\s*(.+)') { $name=$Matches[1].Trim() } else { $name=$_.BaseName }; if($content -match 'description:\s*(.+)') { $desc=$Matches[1].Trim() } else { $desc='' }; $entries += ('- [{0}]({1}) - {2}' -f $name, $_.Name, $desc) }; ($entries -join [Environment]::NewLine) | Set-Content (Join-Path $dir 'MEMORY.md') -Encoding UTF8"
    echo       Restored !MEM_RESTORED! memories, skipped !MEM_SKIPPED! ^(already exist^)
    echo       Rebuilt MEMORY.md index
) else (
    echo       All portable memories already present ^(!MEM_SKIPPED! skipped^)
)

:DoneMemory

REM ============================
REM  Step 9: Run skill-sync
REM ============================
echo [9/9] Running skill-sync...

set "SYNC_BAT=%SCRIPT_DIR%\sp-sync.bat"
set "SYNC_SH=%SCRIPT_DIR%\sp-sync.sh"

if exist "!SYNC_BAT!" (
    call "!SYNC_BAT!"
) else if exist "!SYNC_SH!" (
    bash "!SYNC_SH!"
) else (
    echo       WARN: sp-sync script not found - skipped
)

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
echo     - .Sekai_workflow/    - Skill template for sync
echo     - .gitignore          - auto-added exclusion entries
echo     - pre-commit hook     - blocks skill files from project git
echo     - CLAUDE.md           - project rules, customize as needed
echo     - statusline.sh       - Claude Code status bar script
echo     - hooks               - auto-trigger for skill/memory sync (local only)
echo     - portable memory     - restored user preferences and habits
echo     - skill-sync          - synced with remote
echo.
echo   Next steps:
echo     1. Customize CLAUDE.md for your project
echo     2. Customize .claude/skills/ SKILL.md files
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
if "%DIRNAME%"=="hooks" exit /b 0
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
