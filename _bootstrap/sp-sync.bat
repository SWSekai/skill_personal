@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

:: ============================================================
:: sp-sync.bat — Sekai_workflow 遠端同步 + 專案 Skills 更新
:: 用法：在專案根目錄執行 Sekai_workflow\setup\sp-sync.bat
:: ============================================================

echo.
echo ========================================
echo  Sekai_workflow Sync Tool
echo ========================================
echo.

:: --- 定位路徑 ---
set "SCRIPT_DIR=%~dp0"
pushd "%SCRIPT_DIR%..\" && set "SP_DIR=!CD!" && popd
pushd "%SCRIPT_DIR%..\..\" && set "PROJECT_DIR=!CD!" && popd
set "SKILLS_DIR=%PROJECT_DIR%\.claude\skills"

echo [INFO] Sekai_workflow : %SP_DIR%
echo [INFO] Project skills : %SKILLS_DIR%
echo.

:: --- Step 1: Git fetch + pull ---
echo [Step 1] Fetching remote updates...
pushd "%SP_DIR%"

git fetch origin 2>nul
if errorlevel 1 (
    echo [ERROR] git fetch failed. Check network or remote config.
    popd
    goto :end
)

for /f %%i in ('git rev-list HEAD..origin/main --count 2^>nul') do set "BEHIND=%%i"
for /f %%i in ('git rev-list origin/main..HEAD --count 2^>nul') do set "AHEAD=%%i"

if "%BEHIND%"=="0" if "%AHEAD%"=="0" (
    echo [INFO] Already up to date with remote.
    echo.
)

if not "%BEHIND%"=="0" (
    echo [INFO] Remote: %BEHIND% commit^(s^) behind, %AHEAD% commit^(s^) ahead
    echo [Step 1a] Pulling %BEHIND% new commit^(s^)...
    git pull --rebase origin main
    if errorlevel 1 (
        echo [ERROR] git pull failed. Resolve conflicts manually.
        popd
        goto :end
    )
    echo [OK] Pull successful.
    echo.
)
popd

:: --- Step 2: Compare and sync skills ---
echo [Step 2] Comparing skills...
echo.

set "UPDATED=0"
set "ADDED=0"
set "UNCHANGED=0"

if not exist "%SKILLS_DIR%" mkdir "%SKILLS_DIR%"

for /d %%D in ("%SP_DIR%\*") do (
    set "SKILL_NAME=%%~nxD"
    set "SKIP=0"
    if /I "!SKILL_NAME!"=="setup" set "SKIP=1"
    if /I "!SKILL_NAME!"=="docs" set "SKIP=1"
    if /I "!SKILL_NAME!"==".git" set "SKIP=1"

    if "!SKIP!"=="0" if exist "%%D\SKILL.md" (
        set "TARGET=%SKILLS_DIR%\!SKILL_NAME!"

        if not exist "!TARGET!" (
            echo   [ADD]    !SKILL_NAME!
            mkdir "!TARGET!" 2>nul
            copy /y "%%D\SKILL.md" "!TARGET!\SKILL.md" >nul
            if exist "%%D\README.md" copy /y "%%D\README.md" "!TARGET!\README.md" >nul
            set /a ADDED+=1
        ) else (
            set "NEED_UPDATE=0"
            fc /b "%%D\SKILL.md" "!TARGET!\SKILL.md" >nul 2>&1
            if errorlevel 1 set "NEED_UPDATE=1"

            if exist "%%D\README.md" if exist "!TARGET!\README.md" (
                fc /b "%%D\README.md" "!TARGET!\README.md" >nul 2>&1
                if errorlevel 1 set "NEED_UPDATE=1"
            )

            if "!NEED_UPDATE!"=="1" (
                echo   [UPDATE] !SKILL_NAME!
                copy /y "%%D\SKILL.md" "!TARGET!\SKILL.md" >nul
                if exist "%%D\README.md" copy /y "%%D\README.md" "!TARGET!\README.md" >nul
                set /a UPDATED+=1
            ) else (
                echo   [OK]     !SKILL_NAME!
                set /a UNCHANGED+=1
            )
        )
    )
)

:: --- Step 3: Summary ---
echo.
echo ========================================
echo  Sync Summary
echo ========================================
echo   Added    : %ADDED%
echo   Updated  : %UPDATED%
echo   No change: %UNCHANGED%
echo ========================================
echo.

if %ADDED% GTR 0 (
    echo [REMINDER] New skills added. Update CLAUDE.md "Available Skills" section.
)

if not "%AHEAD%"=="0" (
    echo [INFO] Local has %AHEAD% unpushed commit^(s^).
    echo        Run: cd Sekai_workflow ^&^& git push origin main
)

:end
endlocal
echo [DONE]
