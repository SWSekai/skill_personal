# quality-check — 品質與影響檢查

## 功能概述

提交前的程式碼品質審計，涵蓋死碼偵測、冗餘分析、架構一致性驗證、上下游影響評估與安全性掃描。

## 目錄結構

```
quality-check/
├── README.md    ← 本文件
└── SKILL.md     ← Skill 定義與檢查項目
```

## 使用方式

```
/quality-check [可選：指定檔案]
```

未指定檔案時，自動檢查所有已暫存或已修改的檔案。

## 檢查項目

### 1. 程式碼品質掃描

| 項目 | 說明 |
|------|------|
| 死碼 | 未使用的 import、不可達分支、被註解的程式碼區塊 |
| 冗餘 | 跨檔案重複邏輯、應抽象化的複製貼上模式 |
| 硬編碼 | 應放入設定檔的魔術數字或字串 |
| 錯誤處理 | 系統邊界缺少 try/catch（API、外部呼叫、檔案 I/O） |
| 型別一致性 | 跨層型別不符（如前端送 string、後端期望 int） |
| 序列化風險 | JSON/protobuf/form 序列化過程可能遺失的值 |
| 安全性 | SQL injection、XSS、command injection、OWASP Top 10 |

### 2. 架構一致性

讀取同目錄 3-5 個現有檔案，比對命名慣例、錯誤處理風格、日誌模式、回應格式，標記偏離之處。

### 3. 影響評估

- **上游**：誰呼叫此函式/端點？呼叫者是否會中斷？
- **下游**：此函式呼叫什麼？契約是否仍有效？
- **狀態**：是否變更 DB schema、cache key、檔案路徑、環境變數？
- **並行**：多使用者/多 worker 場景是否有 race condition？
- **向下相容**：現有資料是否仍能正常運作？

### 4. 風險報告

輸出結構化表格，嚴重度分三級：
- **High**：可能造成資料遺失、崩潰或安全漏洞
- **Medium**：可能造成錯誤行為或效能下降
- **Low**：程式碼異味或輕微不一致

### 5. Skill 更新建議

若變更引入新慣例或模式，提示是否需更新 Skill 定義。

---

## Overview (English)

Pre-commit code quality audit covering dead code detection, redundancy analysis, architecture conformance, upstream/downstream impact assessment, and OWASP Top 10 security scanning. Outputs a structured risk report with High/Medium/Low severity classification.
