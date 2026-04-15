# ask — 系統文件與報告

## 功能說明

整合系統資訊查詢與文件管理、端到端資料流追蹤、工作報告生成三項職能。

## 使用方式

```
/ask <query|trace|report> [args...]
```

## Model

- **建議 model**: `opus`
- **Effort**: `medium`
- **理由**: 需要跨檔分析、使用 Agent 子代理進行深度追蹤

## 觸發條件

- `query`：詢問系統問題時自動觸發 / 手動
- `trace`：手動呼叫
- `report`：手動呼叫

## 執行流程

| 子命令 | 用途 |
|---|---|
| `query [topic]` | 系統資訊查詢與文件管理（搜尋 → 擴充 → 新建） |
| `trace <field>` | 端到端資料流追蹤（UI → API → DB → Processing） |
| `report [scope]` | 從修改紀錄生成簡報用工作報告 |

## 目錄結構

```
ask/
├── SKILL.md
└── README.md
```

## 整合來源

| 原 Skill | 對應子命令 |
|---|---|
| sys-info | `query` |
| trace-flow | `trace` |
| report | `report` |
