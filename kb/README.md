# kb — 知識庫管理（Knowledge Base Manager）

## 功能說明

維護 `sekai-workflow/knowledge_base/` 作為**跨專案通用知識庫**，集中存放 Docker/K8s 模板、ETL 邏輯、常用算法最佳實踐、後端設計模式等可重複使用的技術筆記。目標：

- **工程師**：面對不熟悉領域或實作新專案時，可直接查閱筆記，不需從零學習
- **模型**：回答技術問題時先掃描知識庫，避免重複思考、提供更一致的答案
- **決策歸檔**：`/team decide` 或 `/team board` 結案時，自動檢查內容是否值得抽取為通用知識

## 使用方式

```
/kb <add|search|extract> [topic|query|source-path]
/kb <query>              # 無子命令時視為 search
```

## Model

- **建議 model**：`sonnet`
- **Effort**：`medium`
- **理由**：需要多步驟讀寫檔案、分類判斷、跨目錄搜尋，屬執行屬性任務

## 觸發條件

| 觸發 | 說明 |
|---|---|
| 手動 `add` | 新增或更新一筆知識筆記 |
| 手動 `search` | 查詢知識庫 |
| 手動 `extract <path>` | 從指定 decision/board 檔案抽取可重用內容 |
| **自動** — `/team` 結案 | `/team decide` 或 `/team board` 產生 `CLOSED_*` 檔時，自動掃描可抽取項 |
| **自動** — 技術提問 | 使用者提問技術性主題時（後端、基礎設施、演算法），先查 knowledge_base，有相關文件就引用 |

## 執行流程

### A. `/kb add <topic>` — 新增/更新知識文件

1. **分類判斷** — 依關鍵字對應到 `docker/` / `kubernetes/` / `etl/` / `algorithms/` / `backend/` / `_general/`
2. **檢查既有檔案** — `sekai-workflow/knowledge_base/<category>/<topic>.md` 已存在則更新，否則新建
3. **使用模板撰寫** — 依 `assets/kb-doc-template.md` 結構（Overview / Quick Reference / Details / Examples / References）
4. **更新索引** — 在 `knowledge_base/_index.md` 加入或更新該筆
5. **commit & push** — 推送至 `sekai-workflow` 遠端

### B. `/kb search <query>` — 查詢

1. 關鍵字解析
2. Grep knowledge_base（依 title → heading → body 頻率排序）
3. **直接於對話中回傳內容**（不要求使用者開檔），末尾附檔案路徑供深讀
4. 若查無結果 → 用模型知識回答，若答案完整則詢問是否執行 `/kb add` 歸檔

### C. `/kb extract [source]` — 從結案文件抽取

1. 來源判定：手動傳入路徑，或 `/team` 結案自動觸發讀取 `CLOSED_*` 檔
2. 掃描可重用模式：config snippet、演算法描述、API 設計、ETL schema、架構決策理由
3. **排除專案特定內容**：業務邏輯、公司內部 URL、臨時 workaround、一次性決定
4. 列出可抽取項 → AskUserQuestion 多選 → 使用者勾選後逐一執行 `/kb add`

### D. 自動觸發 — 提問增強

回答技術問題時自動執行：
1. Glob `sekai-workflow/knowledge_base/**/*.md` 找相關檔
2. 有相關文件 → 以知識庫內容為基礎回答，末尾附來源路徑
3. 無相關文件 → 用模型知識回答；答案超過 200 字時主動詢問是否 `/kb add` 歸檔

## 目錄結構

```
.claude/skills/kb/
├── SKILL.md
├── README.md
└── assets/
    └── kb-doc-template.md     ← 知識文件統一模板

sekai-workflow/knowledge_base/   ← 實際知識庫（跨專案共享）
├── _index.md                    ← 主題索引
├── docker/
├── kubernetes/
├── etl/
├── algorithms/
├── backend/
└── _general/                    ← 跨領域或分類未明
```

## 參數說明

| 參數 | 說明 |
|---|---|
| `add <topic>` | 建立/更新主題文件（topic 為 kebab-case 檔名） |
| `search <query>` | 自由文字查詢；關鍵字空白分隔 |
| `extract [source]` | 抽取路徑；省略時讀最近一個 `CLOSED_*` 檔 |

## 與其他 Skill 關係

- **`/ask info`**：專案內的系統資訊追蹤（程式碼、架構）→ 專案專屬
- **`/kb search`**：跨專案通用技術筆記（Docker、演算法、後端模式）→ 通用
- 兩者互補：`/ask` 回答「這個專案怎麼做」；`/kb` 回答「一般而言怎麼做」
- **`/team decide` / `/team board`** 結案時自動呼叫 `/kb extract`，確保通用內容不被遺忘於單一決策檔
