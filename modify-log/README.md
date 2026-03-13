# modify-log — 修改日誌

## 功能概述

建立結構化的版本化修改紀錄，記錄每次程式碼變更的原因、影響範圍與技術細節。

## 目錄結構

```
modify-log/
├── README.md    ← 本文件
└── SKILL.md     ← Skill 定義與日誌格式規範
```

## 使用方式

```
/modify-log [主題描述]
```

主題描述用於檔名生成與內容聚焦，例如：`/modify-log 冷卻時間邏輯重構`

## 檔名規則

- 格式：`YYYYMMDD_v[版本號].md`
- 同日首次 → `v1`，已有 `v1` → `v2`，依此類推
- 自動偵測專案的日誌存放目錄

## 日誌結構

| 欄位 | 說明 |
|------|------|
| 日期時間 | `YYYY-MM-DD HH:MM` |
| 版本號 | 當日遞增版本 |
| 變更原因 | 修改動機或問題描述 |
| 變更明細 | 每個檔案的影響行數與摘要（表格） |
| 技術說明 | 非顯而易見的邏輯、資料流、架構決策 |
| 影響範圍 | 受影響模組、服務重啟需求、DB migration |
| 潛在風險 | 已知的邊界條件或相容性問題 |

## 特性

- 自動偵測專案語言慣例（中/英文）
- 使用 `git diff --numstat` 取得精確的行數變更
- 非顯而易見的變更附帶程式碼片段
- 前後對照使用表格、資料流使用 ASCII 圖

---

## Overview (English)

Creates structured, versioned modification logs (`YYYYMMDD_v[VERSION].md`) documenting code changes with required fields: date, version, motivation, per-file impact, technical notes, scope, and risks. Auto-detects project language and log directory conventions.
