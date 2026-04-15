# 版控邊界

**所有 Skill 相關檔案不屬於專案版控：**

| 路徑 | 版控歸屬 | 說明 |
|------|---------|------|
| `.claude/skills/` | 不入版控 | 專案專屬 Skill，僅本地使用 |
| `Sekai_workflow/` | Sekai_workflow 遠端倉庫 | 通用 Skill 模板 |
| `CLAUDE.md` | 不入版控 | Claude Code 專案規範，僅本地使用 |

**原則：專案 git 僅追蹤專案程式碼。Skill 變更統一透過 `Sekai_workflow/`（自身為 git repo）推送至遠端倉庫管理。**

**版控保護由 `_bootstrap/sp-init.bat` 安裝的 pre-commit hook 強制執行（不依賴規則約束）。**

---

## 初始化 vs 同步的分工

| 任務 | 負責工具 | 說明 |
|------|---------|------|
| 新專案初始化 | `Sekai_workflow/_bootstrap/sp-init.bat` | 建立 `.claude/skills/`、`Sekai_workflow/`、`CLAUDE.md`、`.gitignore`、pre-commit hook |
| 驗證環境完整性 | `Sekai_workflow/_bootstrap/sp-verify.bat` | 檢查所有保護層是否就位 |
| 遠端同步 | `/setup sync`（本 Skill） | Fetch/pull/merge/push Sekai_workflow 遠端 |
| 規則歸類評估 | `/setup sync`（本 Skill） | 評估新規則應放入 Skill / CLAUDE.md / Memory |

> **不要用 `/setup sync` 做初始化。** 若環境未就緒，請執行 `Sekai_workflow/_bootstrap/sp-init.bat`。
