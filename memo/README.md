# memo — Memory 跨專案攜帶

> **2026-04-17 改名**：`/memory-portable` → `/memo`（名稱過長、補全體驗差）。對應的 `memory-portable/` 資料夾也一併更名為 `memo/`。`sp-init.bat`、`sp-pack.sh`、`CLAUDE.md.template` 的 8 處硬編碼同步更新。

跨專案可攜帶的 Claude Code Memory。

## 設計

- 只收錄 `feedback` 和 `user` type 的 memory（跨專案通用的偏好與習慣）
- `project` 和 `reference` type 留在專案本地（跟專案綁定）
- 隨 Sekai_workflow git 攜帶，任何帳號 clone 後 `sp-init.bat` 即還原

## 自動化流程

| 動作 | 觸發 | 說明 |
|------|------|------|
| 還原 | `sp-init.bat` | 複製到當前帳號的 `~/.claude/projects/{project}/memory/` |
| 回寫 | `sp-pack.sh` | 打包時將新的 feedback/user memory 回寫到此目錄 |
| 推送 | Sekai_workflow commit+push | 偏好隨 git 帶走 |

## 注意事項

- 還原時不覆蓋已存在的同名檔案（保留專案本地修改）
- MEMORY.md 索引會自動生成/合併
- 新增 memory 後記得 commit + push Sekai_workflow

---

## 相關 Skills 與檔案

- **呼叫**：讀取 `~/.claude/projects/<path>/memory/`（memory 歸檔來源）、寫入 `sekai-workflow/memory-portable/`（跨專案攜帶儲存）
- **被呼叫**：`/skm pack`（pack 流程歸檔 memory 至可攜形式）、`_bootstrap/sp-init.bat` Step 3（新專案 init 自動還原 memory）
- **共用資源**：`manifest.json` 的 `memory-portable` 條目（manifest 追蹤 memory 歸檔）
- **改名歷史（本 skill 自身）**：skill 名稱 `memory-portable` → `memo`（2026-04-24）；全域改名請見 `_bootstrap/RENAME_HISTORY.md`
