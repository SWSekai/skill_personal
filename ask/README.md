# ask — 系統文件與資料流追蹤

## 功能說明

整合系統資訊查詢與文件管理、端到端資料流追蹤兩項職能。

> **2026-04-17 調整**：原 `report` 子命令已搬移至 `/team report`（工作報告屬於協作產出，不是文件查詢）。

## 使用方式

```
/ask <info|trace> [args...]
```

## Model

- **建議 model**: `opus`
- **Effort**: `medium`
- **理由**: 需要跨檔分析、使用 Agent 子代理進行深度追蹤

## 觸發條件

- `info`：詢問系統問題時自動觸發 / 手動
- `trace`：手動呼叫

## 執行流程

| 子命令 | 用途 |
|---|---|
| `info [topic]` | 系統資訊查詢與文件管理（搜尋 → 擴充 → 新建） |
| `trace <field>` | 端到端資料流追蹤（UI → API → DB → Processing） |

## 目錄結構

```
ask/
├── SKILL.md
└── README.md
```

## 整合來源

| 原 Skill / 子命令 | 對應子命令 |
|---|---|
| sys-info | `info` |
| trace-flow | `trace` |
| ~~report~~ | 已搬移至 `/team report` |

---

## 相關 Skills 與檔案

- **呼叫**：無（純讀取分析）
- **被呼叫**：`hooks/ask_info_router.cjs`（UserPromptSubmit hook 自動路由系統資訊問題到 `/ask info`）
- **共用資源**：無
- **改名歷史（本 skill 自身）**：`/ask report` 子指令於 2026-04-24 移交至 `/team report --daily`；全域改名請見 `_bootstrap/RENAME_HISTORY.md`
