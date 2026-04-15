---
name: ask
description: "系統文件與報告一站式入口：系統資訊查詢、資料流追蹤、工作報告生成。子命令路由 info / trace / report。"
model: opus
effort: medium
argument-hint: "<query|trace|report> [args...]"
allowed-tools: Read, Write, Edit, Glob, Grep, Agent, Bash(ls *), Bash(find *), Bash(git log*), Bash(git diff*), Bash(date *)
---

# /info — 系統文件與報告合併 Skill

整合 sys-info、trace-flow、report 三項職能。透過第一個參數決定子命令。

## 子命令路由

| 子命令 | 用途 | 對應原 Skill |
|---|---|---|
| `/info query [topic]` | 系統資訊查詢與文件管理 | sys-info |
| `/info trace <field>` | 端到端資料流追蹤 | trace-flow |
| `/info report [scope]` | 從修改紀錄生成工作報告 | report |

無參數時要求使用者指定子命令。

---

## A. `/info query` — 系統資訊查詢與文件管理

當使用者詢問系統如何運作，本子命令同時管理「答覆」與「文件生命週期」。

### Step 1：搜尋既有文件

掃描所有文件來源：

```
.local/infos/      ← 主要知識庫（本子命令管理）
docs/             ← 官方專案文件
**/README.md      ← 各目錄 README
```

### Step 2：依結果走三條路徑之一

#### 路徑 A — 文件已涵蓋

引導使用者至**具體段落**：

```
相關文件：`docs/event_recording.md`

請看這幾節：
- 第 2 節：錄製觸發流程 — 解釋完整資料流
- 第 3 節：MinIO 上傳 — 解釋儲存與 URL 生成
```

附簡短摘要協助理解，**不修改檔案**。

#### 路徑 B — 文件存在但不完整

1. 先回答問題
2. 評估缺失資訊，**擴充既存檔案**至適當位置
3. 告知使用者更新

#### 路徑 C — 無相關文件

1. 先回答問題
2. 整理為結構化文件，存至 `.local/infos/[topic_description].md`
3. 告知使用者新檔位置

### Step 3：冗餘檢查

新增/更新文件後掃描整個 docs 目錄：

- **重複主題**：兩份描述同一件事 → 合併到較完整的那份
- **重疊內容**：跨檔案重複的段落 → 留在最佳位置，其他處改用 cross-reference
- **過時資訊**：與現行程式碼不符的描述 → 標註或更新

發現冗餘 → 告知使用者並執行合併。

### 文件格式

```markdown
# [主題標題]

> 最後更新：YYYY-MM-DD

## 1. 概述

（一段話總結）

## 2. 細節

（按子主題分節）

## 3. 相關文件

- `docs/xxx.md` — 描述
- `path/to/README.md` — 描述
```

### 規則

- 對齊專案語言（vision-ai 為台灣繁體中文）
- 檔名：`[topic_description].md`，簡潔具描述性
- 不複製大段程式碼進文件 → 用 `file_path:line_number` 引用
- 優先擴充既有檔案，避免過多小檔

---

## B. `/info trace` — 端到端資料流追蹤

追蹤指定欄位或功能在系統中的完整流動，識別資料遺失風險。

### Step 1：認識架構

追蹤前先了解專案架構：
- 讀 `docker-compose.yml`、`package.json`、根目錄 README 或同等檔案
- 識別分層：frontend → API → services → storage → processing
- 標註序列化邊界（JSON、protobuf、form data 等）

### Step 2：逐層追蹤

對 `$ARGUMENTS` 描述的欄位/功能，走過每一層：

#### Frontend（UI → 用戶端邏輯 → API call）
- 值在哪裡輸入或顯示？（HTML element、component）
- 如何儲存於用戶端 state？（React state、Vue ref、JS 變數）
- 如何序列化以供 API call？（JSON body、query param、form data）
- **風險**：JS `undefined` 會被 `JSON.stringify` 移除；optional 欄位可能漏傳

#### API 層（接收 → 驗證 → 儲存 → 轉發）
- 哪個 endpoint 接收？
- 套用什麼驗證？（schema、type、constraint）
- 是否寫入 DB？哪張表/哪個欄位？
- 是否轉發給下游服務？用什麼 key 名？
- **風險**：欄位不在 schema 中 → 靜默丟棄；型別轉換問題

#### Service 層（接收 → 快取 → 解析 → 使用）
- 如何從 API 層接收？
- 是否快取？（Redis、in-memory）如何序列化？
- 如何從 payload 解析/抽出？
- runtime 如何使用？
- **風險**：解析時未抽出 → 遺失；快取過期 → 舊值

#### Storage 層（若適用）
- DB column type 與 constraint
- DB 層 vs 應用層的預設值
- Schema 變更的 migration 需求

### Step 3：每個 hop 都要記錄

- **檔案**：精確路徑與行號
- **變數名**：在這層叫什麼（跨層常改名）
- **轉換**：mapping、rename、型別轉換、預設值
- **預設/Fallback**：值缺漏時會發生什麼
- **資料遺失風險**：哪裡可能靜默遺失

### Step 4：輸出

| Layer | File:Line | Variable | Type | Default | Risk |
|---|---|---|---|---|---|
| Frontend UI | `index.html:42` | `#myInput` | string | `""` | None |
| Frontend JS | `app.js:100` | `config.myField` | number | `30` | `undefined` 被移除 |
| API endpoint | `routes/api.py:50` | `request.my_field` | Optional[int] | `None` | Missing → None |
| Cache | `redis_service.py:20` | `rules.myField` | JSON | N/A | Key 不存在 |
| Processing | `processor.py:80` | `parsed["my_field"]` | int | `60` | Fallback 不一致 |

**判定**：值能否可靠地端到端傳遞？若不能，明確指出在哪壞掉，並建議修法。

---

## C. `/info report` — 工作報告生成

從專案修改紀錄統整生成 **2～3 分鐘簡報** 用的工作報告。

### 觸發

| 用法 | 行為 |
|---|---|
| `/info report` | 全量報告（全部修改紀錄） |
| `/info report weekly` | 近 7 天週報 |
| `/info report YYMMDD YYMMDD` | 指定期間 |

### Step 1：確定範圍

- 無參數 / `full` → 讀全部
- `weekly` → 近 7 天（依檔名日期前綴篩選）
- `YYMMDD YYMMDD` → 指定區間

來源：`.local/modify_logs/`

### Step 2：讀取並分析

逐份讀取範圍內的修改紀錄，提取：
- 改動主題與分類
- 影響的檔案與服務
- 技術亮點
- 潛在風險與待追蹤

### Step 3：生成報告

**檔名規則**：
- 全量：`YYMMDD_full_report.md`
- 週報：`YYMMDD_weekly_report.md`
- 期間：`YYMMDD_report_[起始]_to_[結束].md`

**報告結構**（針對 2～3 分鐘簡報最佳化）：

```markdown
# [專案名稱] 開發進度報告

> 報告日期：YYYY-MM-DD
> 涵蓋期間：YYYY-MM-DD ～ YYYY-MM-DD
> 修改紀錄數：N 筆

## 一、重點成果摘要
（2～3 句話總結本期工作量與核心方向，30 秒內掌握全貌）

## 二、功能開發分類統整
（依功能領域分組，每組用表格列出項目 + 一句話說明）

| 項目 | 說明 |
|---|---|

## 三、關鍵技術亮點
（3～5 個 bullet，挑出值得提的技術決策或設計模式）

## 四、影響的服務與容器

| 服務 | 涉及項目數 | 主要改動 |
|---|---|---|

## 五、待追蹤事項
（已知風險、未完成項目、需後續驗證的功能）
```

### Step 4：輸出

寫入 `.local/reports/`。

### 撰寫原則

1. **簡報導向**：每段在 30 秒內可講完
2. **表格優先**：用表格取代長篇敘述
3. **分類清晰**：依功能領域分組，**不**按時間排列
4. **技術亮點精煉**：只挑 3～5 個
5. **可行動的追蹤事項**：具體，不要「持續優化」
6. **語言**：對齊專案慣例（vision-ai 為台灣繁體中文）

---

Arguments: $ARGUMENTS （第一個 token 為子命令，其餘為該子命令參數）
