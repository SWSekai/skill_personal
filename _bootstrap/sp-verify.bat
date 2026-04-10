@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM  Skill-personal environment verification
REM  Usage: sp-verify.bat [project-path]
REM  Checks that all protection layers are in place
REM ============================================================

if "%~1"=="" (
    set "PROJECT_DIR=%CD%"
) else (
    set "PROJECT_DIR=%~f1"
)

echo.
echo ====================================================
echo   Skill Environment Verification
echo ====================================================
echo   Project: %PROJECT_DIR%
echo.

set "PASS=0"
set "FAIL=0"
set "WARN=0"

REM --- Check 1: .gitignore entries ---
echo [Check 1] .gitignore entries...
set "GI=%PROJECT_DIR%\.gitignore"
if not exist "!GI!" (
    echo       FAIL: .gitignore not found
    set /a FAIL+=1
) else (
    set "GI_OK=1"
    for %%E in (".claude/" ".skill_personal/" ".hanschen/") do (
        findstr /B /C:%%E "!GI!" >nul 2>&1
        if errorlevel 1 (
            echo       FAIL: %%~E not in .gitignore
            set "GI_OK=0"
            set /a FAIL+=1
        )
    )
    if "!GI_OK!"=="1" (
        echo       PASS: .claude/ .skill_personal/ .hanschen/ all present
        set /a PASS+=1
    )
)

REM --- Check 2: pre-commit hook ---
echo [Check 2] Pre-commit hook...
if not exist "%PROJECT_DIR%\.git\hooks\pre-commit" (
    echo       FAIL: pre-commit hook not installed
    set /a FAIL+=1
) else (
    findstr /C:"COMMIT BLOCKED" "%PROJECT_DIR%\.git\hooks\pre-commit" >nul 2>&1
    if errorlevel 1 (
        echo       WARN: pre-commit hook exists but may not be the skill guard
        set /a WARN+=1
    ) else (
        echo       PASS: skill guard pre-commit hook installed
        set /a PASS+=1
    )
)

REM --- Check 3: .claude/skills/ exists ---
echo [Check 3] .claude/skills/ directory...
if not exist "%PROJECT_DIR%\.claude\skills" (
    echo       FAIL: .claude/skills/ not found
    set /a FAIL+=1
) else (
    echo       PASS: .claude/skills/ exists
    set /a PASS+=1
)

REM --- Check 4: .skill_personal/ exists ---
echo [Check 4] .skill_personal/ directory...
if not exist "%PROJECT_DIR%\.skill_personal" (
    echo       FAIL: .skill_personal/ not found
    set /a FAIL+=1
) else (
    echo       PASS: .skill_personal/ exists
    set /a PASS+=1
)

REM --- Check 5: CLAUDE.md exists ---
echo [Check 5] CLAUDE.md...
if not exist "%PROJECT_DIR%\CLAUDE.md" (
    echo       WARN: CLAUDE.md not found
    set /a WARN+=1
) else (
    echo       PASS: CLAUDE.md exists
    set /a PASS+=1
)

REM --- Check 6: git staging test ---
echo [Check 6] Git staging protection test...
if exist "%PROJECT_DIR%\.git" (
    pushd "%PROJECT_DIR%"
    mkdir ".claude\__verify_test__" 2>nul
    echo test > ".claude\__verify_test__\test.txt"
    git add ".claude/__verify_test__/test.txt" >nul 2>&1
    git diff --cached --name-only | findstr "__verify_test__" >nul 2>&1
    if errorlevel 1 (
        echo       PASS: .gitignore correctly blocks staging
        set /a PASS+=1
    ) else (
        echo       FAIL: .gitignore did NOT block staging
        git reset HEAD ".claude/__verify_test__/test.txt" >nul 2>&1
        set /a FAIL+=1
    )
    rmdir /S /Q ".claude\__verify_test__" 2>nul
    popd
) else (
    echo       SKIP: not a git repository
)

REM --- Check 7: .hanschen/ working directory ---
echo [Check 7] .hanschen/ working directory...
if not exist "%PROJECT_DIR%\.hanschen" (
    echo       WARN: .hanschen/ not found
    set /a WARN+=1
) else (
    echo       PASS: .hanschen/ exists
    set /a PASS+=1
)

REM --- Summary ---
echo.
echo ====================================================
echo   Results: !PASS! passed, !FAIL! failed, !WARN! warnings
echo ====================================================
echo.

if !FAIL! GTR 0 (
    echo   Run sp-init.bat to fix issues:
    echo     Skill-personal\setup\sp-init.bat "%PROJECT_DIR%"
    echo.
    exit /b 1
)

if !WARN! GTR 0 (
    echo   All critical checks passed. Review warnings above.
    echo.
    exit /b 0
)

echo   All checks passed.
echo.
endlocal
exit /b 0
