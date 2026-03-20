# sys-info — System Information & Documentation Management

## 功能概述

當用戶詢問系統相關問題時自動觸發。搜尋現有文件引導用戶，不足則擴充，無相關文件則新建。自動執行冗餘檢查避免文件重複。

## 目錄結構

```
sys-info/
├── README.md    ← 本文件
└── SKILL.md     ← Skill 定義與文件管理流程
```

## 使用方式

```
/sys-info [系統相關問題]
```

## 執行流程

| 步驟 | 說明 |
|------|------|
| 1. 搜尋文件 | 掃描專案內所有文件來源 |
| 2. 回應路徑 | A) 文件已有 → 引導至段落；B) 不足 → 擴充；C) 無 → 新建 |
| 3. 冗餘檢查 | 檢查重複主題、內容重疊、過時資訊 |

## 特性

- 自動偵測專案文件慣例（語言、格式、存放路徑）
- 優先擴充既有文件，避免零碎小文件
- 新建文件目錄時同步建立 README.md

---

## Overview (English)

Auto-triggered when users ask about system architecture, features, data flow, configuration, or deployment. Searches existing docs, expands incomplete ones, or creates new documentation. Performs redundancy checks to prevent duplication.
