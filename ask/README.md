# /info — 系統文件與報告合併 Skill

整合 sys-info、trace-flow、report 三個原始 Skill。

## 使用方式

| 指令 | 說明 |
|---|---|
| `/info info [topic]` | 系統資訊查詢與文件管理 |
| `/info trace <field>` | 端到端資料流追蹤 |
| `/info report [scope]` | 從修改紀錄生成簡報用工作報告 |

## Model

- **Skill model**：`opus`
- **info**：跨檔案搜尋、文件決策需深度判斷（原 sys-info 為 opus）
- **trace**：跨層分析、需呼叫 Agent（原 trace-flow 為 opus）
- **report**：表格統整為主，可在子命令內降低 effort

## 觸發

- **手動**：使用者呼叫 `/info <subcommand>`
- **自動**：
  - `info`：使用者詢問系統架構、功能、資料流、設定、部署、運作方式時自動觸發

## 主要流程

### `/info info`
搜尋既有文件 → 三條路徑（已涵蓋 / 需擴充 / 需新建）→ 冗餘檢查與合併

### `/info trace`
讀架構 → 逐層追蹤（Frontend → API → Service → Storage）→ 每 hop 記錄 → 輸出風險表 → 判定能否端到端傳遞

### `/info report`
確定範圍（full / weekly / 期間）→ 讀 `.local/modify_logs/` → 生成 5 段式報告 → 寫入 `.local/reports/`

## 檔案結構

```
.claude/skills/info/
├── SKILL.md
└── README.md
```

## 對應原 Skill

| 原 Skill | 子命令 |
|---|---|
| sys-info | `/info info` |
| trace-flow | `/info trace` |
| report | `/info report` |
