# ask — 資料流追蹤

> **一行定位**：追蹤一個欄位／功能從前端到資料庫的完整路徑與遺失風險。

> **2026-05-06 範圍縮減**：原 `info` 子指令與 `ask_info_router.cjs` UserPromptSubmit hook 已移除。系統資訊查詢請直接以對話形式問 Claude（不需 skill 包裝）；專案知識記錄請改用 `/team note`（專案本地）或 `/kb add`（跨專案）。`trace` 保留是因為含結構化追蹤方法論，純對話無法等價取代。

## 功能說明

對指定欄位或功能進行 **end-to-end** 逐層追蹤（UI → API → 服務層 → 儲存層 → 處理層），輸出每一跳的檔案／行號／變數名／轉換／預設值／資料遺失風險，最後給出「能否可靠傳遞」的判定。

## 使用方式

```
/ask <欄位名或功能描述>
```

範例：`/ask user_id`、`/ask "登入後的 session token"`

## 最常見用法

`/ask user_id` — 追蹤 user_id 欄位從前端表單到資料庫，找出哪一層可能遺失或預設值不一致。

## Model

- **建議 model**：`opus`
- **Effort**：`medium`
- **理由**：跨檔分析、Agent 子代理深度追蹤，需 thinking 能力

## 觸發條件

僅手動呼叫（2026-05-06 起不再有 hook 自動路由）

## 執行流程

| 步驟 | 內容 |
|---|---|
| 1. 理解架構 | 讀 `docker-compose.yml` / `package.json` / 根 README，識別分層與序列化邊界 |
| 2. 逐層追蹤 | Frontend → API → Service → Storage 每層走過 |
| 3. 紀錄每跳 | 檔案:行號 / 變數名 / 轉換 / 預設 / 風險 |
| 4. 輸出表格 | 完整資料流表格 + 「能否可靠傳遞」結論 |

## 目錄結構

```
ask/
├── SKILL.md
└── README.md
```

無 `references/` 或 `assets/`（追蹤方法論已內嵌於 SKILL.md）。

---

## 相關 Skills 與檔案

- **呼叫**：無（純讀取分析，不寫檔）
- **被呼叫**：無（2026-05-06 後使用者主動觸發；原 `ask_info_router.cjs` 自動路由 hook 已移除）
- **共用資源**：無
- **改名歷史（本 skill 自身，90 天內）**：
  - 2026-04-24：`/ask report` 子指令移交至 `/team report --daily`
  - 2026-05-06：`/ask info` 子指令 + 對應 hook 移除（Plan A — info 與純對話功能重複；專案知識改走 `/team note` 或 `/kb add`）

全域改名歷史見 `_bootstrap/RENAME_HISTORY.md`。
