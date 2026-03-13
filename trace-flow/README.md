# trace-flow — 資料流追蹤

## 功能概述

追蹤指定欄位或功能從前端到後端的完整資料流路徑，識別每個節點的變數名稱、型別轉換、預設值與資料遺失風險。

## 目錄結構

```
trace-flow/
├── README.md    ← 本文件
└── SKILL.md     ← Skill 定義與追蹤流程
```

## 使用方式

```
/trace-flow [欄位或功能名稱]
```

例如：`/trace-flow cooldown`、`/trace-flow page_size`、`/trace-flow auth_token`

## 追蹤流程

### 步驟 1：探索架構

讀取 `docker-compose.yml`、`package.json` 等設定檔，辨識系統分層：前端 → API → 服務 → 儲存 → 處理。

### 步驟 2：逐層追蹤

| 層級 | 追蹤重點 |
|------|----------|
| **前端 UI** | 輸入元素、顯示位置、客戶端狀態（React state / Vue ref / JS 變數） |
| **前端序列化** | 如何傳送至 API（JSON body / query param / form data）；`undefined` 被 `JSON.stringify` 移除的風險 |
| **API 層** | 接收端點、驗證邏輯、資料庫持久化、下游轉發；欄位不在 schema 中被靜默丟棄的風險 |
| **服務層** | 接收方式、快取機制（Redis / 記憶體）、解析邏輯、運行時使用方式 |
| **儲存層** | 資料庫欄位型別與約束、預設值（DB 層 vs 應用層）、migration 需求 |

### 步驟 3：記錄每個節點

每個節點記錄：
- **檔案**：精確路徑與行號
- **變數名稱**：該層使用的名稱（跨層常有重命名）
- **轉換**：映射、重命名、型別轉換、預設值設定
- **缺失處理**：值不存在時的行為
- **資料遺失風險**：值可能被靜默丟棄的位置

### 步驟 4：輸出摘要

結構化表格 + 最終判定：值是否能可靠地端到端傳遞？若不能，指出確切斷點並建議修正方案。

---

## Overview (English)

Traces a specified field or feature's complete data flow through the system — from UI input through API, services, storage, and processing layers. Documents variable names, type conversions, defaults, and data loss risks at each hop. Outputs a structured summary table with a verdict on end-to-end reliability.
