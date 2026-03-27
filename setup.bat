@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

REM ============================================================
REM  skill_personal 一鍵建置腳本
REM  用法：在目標專案資料夾中執行此腳本
REM    setup.bat [專案路徑]
REM    若不帶參數，則以當前目錄為目標專案
REM ============================================================

REM 取得腳本所在目錄（skill_personal 倉庫根目錄）
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

REM 取得目標專案路徑
if "%~1"=="" (
    set "PROJECT_DIR=%CD%"
) else (
    set "PROJECT_DIR=%~f1"
)

echo.
echo ====================================================
echo   skill_personal 專案建置工具
echo ====================================================
echo.
echo   Skill 來源：%SCRIPT_DIR%
echo   目標專案：  %PROJECT_DIR%
echo.

REM 檢查目標路徑是否存在
if not exist "%PROJECT_DIR%" (
    echo [ERROR] 目標路徑不存在：%PROJECT_DIR%
    exit /b 1
)

REM 檢查是否為 git 倉庫
if not exist "%PROJECT_DIR%\.git" (
    echo [WARN] 目標路徑不是 git 倉庫，將繼續執行但建議先 git init
    echo.
)

REM 防止在 skill_personal 倉庫本身執行
if "%PROJECT_DIR%"=="%SCRIPT_DIR%" (
    echo [ERROR] 不可在 skill_personal 倉庫本身執行此腳本
    echo         請在目標專案資料夾中執行，或傳入專案路徑作為參數
    exit /b 1
)

REM ============================
REM  Step 1: 建立 .claude/skills/
REM ============================
echo [1/4] 建立 .claude/skills/ 目錄...

if exist "%PROJECT_DIR%\.claude\skills" (
    echo       .claude/skills/ 已存在，將合併更新（不覆蓋已有的專案特化內容）
    set "MODE=merge"
) else (
    mkdir "%PROJECT_DIR%\.claude\skills" 2>nul
    echo       已建立 .claude/skills/
    set "MODE=init"
)

REM ============================
REM  Step 2: 複製 Skill 資料夾
REM ============================
echo [2/4] 複製 Skill 檔案...

set "SKILL_COUNT=0"
for /d %%D in ("%SCRIPT_DIR%\*") do (
    set "DIRNAME=%%~nxD"
    REM 跳過 .git 和隱藏資料夾
    if not "!DIRNAME!"==".git" (
        if not "!DIRNAME:~0,1!"=="." (
            if "!MODE!"=="init" (
                REM 全新安裝：直接複製
                xcopy "%%D" "%PROJECT_DIR%\.claude\skills\!DIRNAME!\" /E /I /Y /Q >nul 2>&1
                echo       + !DIRNAME!/
                set /a SKILL_COUNT+=1
            ) else (
                REM 合併模式：只複製目標不存在的 Skill 資料夾
                if not exist "%PROJECT_DIR%\.claude\skills\!DIRNAME!" (
                    xcopy "%%D" "%PROJECT_DIR%\.claude\skills\!DIRNAME!\" /E /I /Y /Q >nul 2>&1
                    echo       + !DIRNAME!/ (新增)
                    set /a SKILL_COUNT+=1
                ) else (
                    echo       ~ !DIRNAME!/ (已存在，保留專案版本)
                )
            )
        )
    )
)

REM 複製根目錄 README.md 至 .claude/skills/（僅全新安裝時）
if "!MODE!"=="init" (
    if exist "%SCRIPT_DIR%\README.md" (
        copy /Y "%SCRIPT_DIR%\README.md" "%PROJECT_DIR%\.claude\skills\README.md" >nul 2>&1
        echo       + README.md
    )
)

echo       共處理 %SKILL_COUNT% 個 Skill

REM ============================
REM  Step 3: 建立 skill_personal/
REM ============================
echo [3/4] 建立 skill_personal/ 目錄...

if exist "%PROJECT_DIR%\skill_personal" (
    echo       skill_personal/ 已存在，跳過
) else (
    xcopy "%SCRIPT_DIR%" "%PROJECT_DIR%\skill_personal\" /E /I /Y /Q >nul 2>&1
    REM 重新初始化 git 並連結遠端倉庫（skill_personal 需要獨立推送）
    if exist "%PROJECT_DIR%\skill_personal\.git" (
        rmdir /S /Q "%PROJECT_DIR%\skill_personal\.git" 2>nul
    )
    pushd "%PROJECT_DIR%\skill_personal"
    git init >nul 2>&1
    git remote add origin https://github.com/SWSekai/skill_personal.git >nul 2>&1
    git fetch origin >nul 2>&1
    git branch -M main >nul 2>&1
    git reset --mixed origin/main >nul 2>&1
    popd
    echo       已建立 skill_personal/（含獨立 git，remote: skill_personal）
)

REM ============================
REM  Step 4: 建立 CLAUDE.md
REM ============================
echo [4/4] 建立 CLAUDE.md...

if exist "%PROJECT_DIR%\CLAUDE.md" (
    echo       CLAUDE.md 已存在，跳過（請手動檢查是否需要更新）
) else (
    REM 取得專案資料夾名稱作為專案名稱
    for %%F in ("%PROJECT_DIR%") do set "PROJECT_NAME=%%~nxF"

    (
        echo # !PROJECT_NAME! — Claude Code 專案規範
        echo.
        echo ## 語言與格式
        echo - Commit 訊息、修改日誌、README：**繁體中文**
        echo - Commit prefix：`feat:`, `fix:`, `ui:`, `docs:`, `refactor:`
        echo - 所有 commit 附加：`Co-Authored-By: Claude Opus 4.6 ^<noreply@anthropic.com^>`
        echo.
        echo ## 核心行為規則
        echo.
        echo ### 1. 每次修改前 — 影響評估
        echo - 主動檢查改動對現有功能、架構的影響或衝突
        echo - 主動提出潛在風險（向下相容、競態條件、資料遺失）
        echo - 若無風險，明確說明「無潛在風險」
        echo.
        echo ### 2. 每次修改後 — 品質檢查
        echo - 掃描冗餘程式碼、死碼、未使用的 import
        echo - 驗證是否符合專案現有設計模式
        echo - 檢查 JSON 序列化風險
        echo.
        echo ### 3. 每次 Commit 前 — 自動化日誌
        echo - **必須**建立修改紀錄
        echo - 必備欄位：日期時間、版本號、更動原因、檔案影響行數、影響範圍、容器重啟需求
        echo.
        echo ### 4. skill_personal/ 禁止加入專案版控，變更須推送至獨立倉庫
        echo - `skill_personal/` 已加入 `.gitignore`，**絕對不可**使用 `git add -f` 或任何方式加入專案版控
        echo - `skill_personal/` 屬於 `skill_personal` 遠端倉庫（`https://github.com/SWSekai/skill_personal.git`），僅透過該倉庫管理
        echo - **每次修改 `skill_personal/` 內容後，必須同步推送至 skill_personal 倉庫**
        echo.
        echo ### 5. 每次 Commit 前 — .gitignore 安全檢查與狀態總覽
        echo - 讀取 `.gitignore`，確認即將 stage 的檔案不在忽略清單中
        echo - 列出所有待處理狀態：未暫存修改、已暫存未 commit、已 commit 未 push
        echo - 向使用者確認後才執行 commit
        echo.
        echo ### 6. 每次 Commit 後 — 容器重啟評估
        echo - 根據改動檔案列出需重啟的容器及指令
        echo.
        echo ### 7. README 維護
        echo - 具備功能的資料夾下必須有 `README.md`
        echo - 新增任何資料夾時，必須同步建立 `README.md`
        echo - Commit 時若改動影響目錄結構或功能，主動更新對應 README
        echo.
        echo ### 8. Skill 動態更新
        echo - 當對話中出現新規則或偏好時，主動詢問是否更新至 Skill 規範
        echo - 獲得確認後修改 `.claude/skills/` 對應文件
        echo.
        echo ### 9. Memory、Skill、skill_personal 三向連動
        echo - 寫入 Memory 時，評估是否應同步加入 Skill
        echo - 更新 `.claude/skills/` 或 Memory 時，評估是否應回流至 `skill_personal/`
        echo - `skill_personal/` 更新後，自動同步至 `../skill_personal/`
        echo.
        echo ### 10. 新增 Skill 後 — 完整性檢查
        echo - Skill 資料夾包含 `SKILL.md` 和 `README.md`
        echo - `.claude/skills/README.md` 已更新
        echo - `skill_personal/` 對應資料夾已同步
        echo - CLAUDE.md 可用 Skills 列表已更新
        echo.
        echo ### 11. 新專案自動初始化 Skill
        echo - 進入新專案時，自動偵測並初始化 Skill 環境
        echo - 觸發 `/skill-sync` 執行完整初始化流程
        echo.
        echo ### 12. skill_personal 遠端同步與衝突處理
        echo - 每次對話開始時自動同步
        echo - 觸發 `/skill-sync` 執行遠端同步流程
        echo.
        echo ### 13. 資訊查詢時主動建立文件
        echo - 被詢問系統架構、功能、資料流等問題時，自動觸發 `/sys-info`
        echo.
        echo ### 14. 對話中主動記錄關鍵資訊
        echo - 對話過程中若經評估含有功能相關的關鍵資訊，**主動寫入記錄檔**
        echo - 關鍵資訊範例：資料庫名稱、collection/table 名稱、待開發功能、API 端點、環境變數、業務規則、第三方服務等
        echo.
        echo ## 可用 Skills
        echo - `/commit-push` — 提交推送（含品質檢查、日誌、README 更新、容器評估）
        echo - `/modify-log` — 建立修改日誌（commit 前自動觸發）
        echo - `/restart-eval` — 容器重啟評估（commit 後自動觸發）
        echo - `/trace-flow` — 資料流端到端追蹤
        echo - `/quality-check` — 程式碼品質與影響檢查（commit 前自動觸發）
        echo - `/sys-info` — 系統資訊查詢與文件管理
        echo - `/skill-sync` — Skill 環境初始化、遠端同步、規則評估（對話開始時自動觸發）
    ) > "%PROJECT_DIR%\CLAUDE.md"

    echo       已建立 CLAUDE.md
)

REM ============================
REM  完成提示
REM ============================
echo.
echo ====================================================
echo   建置完成！
echo ====================================================
echo.
echo   已建立：
echo     - .claude/skills/   （Claude Code Skill 指令集）
echo     - skill_personal/   （通用 Skill 模板，用於回流同步）
if not exist "%PROJECT_DIR%\CLAUDE.md.existed" (
    echo     - CLAUDE.md         （專案規範，請根據專案需求調整）
)
echo.
echo   建議後續步驟：
echo     1. 將 skill_personal/ 加入 .gitignore
echo     2. 根據專案特性調整 CLAUDE.md 中的設定
echo     3. 根據專案特性調整 .claude/skills/ 中各 SKILL.md
echo     4. 啟動 Claude Code 對話，輸入 /skill-sync 進行驗證
echo.

endlocal
