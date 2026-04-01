# commit-push — 提交與推送

## 功能概述

完整的 Git 提交流程自動化，依序執行品質檢查、修改日誌、README 更新、暫存、提交、推送、服務重啟評估、Context 清理共九個步驟。

## 目錄結構

```
commit-push/
├── README.md    ← 本文件
└── SKILL.md     ← Skill 定義與執行流程
```

## 使用方式

```
/commit-push [可選：commit 訊息覆蓋]
```

## 執行流程

| 步驟 | 說明 |
|------|------|
| 1. 品質檢查 | 掃描死碼、冗餘邏輯、硬編碼值、缺少錯誤處理；評估上下游影響；檢查 Skill 是否需更新 |
| 2. 修改日誌 | 自動建立版本化日誌 `YYYYMMDD_v[版本號].md`，含變更摘要、影響範圍、重啟需求 |
| 3. README 更新 | 檢查受影響目錄的 README.md 是否需要同步更新，缺少則自動建立 |
| 4. 暫存檔案 | 使用 `git add <file>` 逐一暫存，避免 `git add -A` 意外加入敏感檔案 |
| 5. 提交 | 自動偵測專案 commit 訊息慣例，使用 HEREDOC 格式撰寫多行訊息 |
| 6. 推送 | 執行 `git push`，失敗時提示使用者手動處理 |
| 7. 重啟評估 | 讀取 `docker-compose.yml` 分析掛載方式，列出需重啟的服務與指令 |
| 8. skill_personal 同步 | 若有 skill_personal 異動，同步至遠端倉庫 |
| 9. Context 清理 | 自動執行 context-guard 摘要、建立 README、執行 /clear |

## 特性

- 自動偵測專案的 commit 訊息語言與格式慣例
- 支援 `.gitignore` 例外檔案（`git add -f`）
- 支援容器化與非容器化專案
- 非容器化專案自動跳過重啟評估步驟

---

## Overview (English)

Automated Git commit workflow executing 9 sequential steps: quality check → modify log → README update → stage → commit → push → service restart evaluation → skill_personal sync → context cleanup.

Automatically detects commit message conventions, handles `.gitignore` exceptions, and evaluates container restart requirements. Works with both containerized and non-containerized projects.
