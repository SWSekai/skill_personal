# .gitignore 安全規則

## Staging 前必做

讀取 `.gitignore` 驗證：

- **所有符合 `.gitignore` 樣式的檔案都不得 stage — 無例外**
- 包含：`.env`、`*.log`、`__pycache__/`、secrets、二進位檔、`CLAUDE.md`、`.claude/skills/`、`.local/`、`sekai-workflow/`、或任何專案特定忽略路徑
- **嚴禁使用 `git add -f`** — `.gitignore` 中的檔案依設計排除於專案版控之外
- 若即將 stage 的檔案命中 `.gitignore`，**警告使用者並跳過**

## Staging 指令

- 僅使用 `git add <檔名>` 具體檔名
- **嚴禁** `git add -f`（強制加入任何檔案）
- **嚴禁** `git add -A` / `git add .`（有加入 secrets 或二進位的風險）

## Pre-commit Hook（最後一道防線）

> Pre-commit hook（由 `sp-init.bat` 安裝）提供硬性阻擋作為最後一道防線。
> 即使使用了 `git add -f`，若 staged 內容含 `.claude/`、`sekai-workflow/`、`CLAUDE.md`，commit 仍會被拒絕。
> 執行 `sekai-workflow/_bootstrap/sp-verify.bat` 確認 hook 啟用中。
