# restart-volumn — 容器重啟與自動修復

## 功能概述

執行 Docker 容器的重啟/重建，包含完整的前置檢查、健康驗證、日誌掃描與自動錯誤修復流程。

## 目錄結構

```
restart-volumn/
├── README.md    ← 本文件
└── SKILL.md     ← Skill 定義與完整流程
```

## 使用方式

```
/restart-volumn                          # 自動判斷需重啟的容器
/restart-volumn api-gateway              # 指定單一服務
/restart-volumn training-service worker  # 指定多個服務
/restart-volumn all                      # 重啟所有服務
```

## 執行流程

1. **確認重啟目標** — 依據最近 commit 自動判斷或手動指定
2. **Pre-flight 檢查** — 容器狀態、背景任務、串流服務、掛載方式判斷
3. **執行重啟** — volume 掛載用 restart，映像打包用 build + up
4. **健康檢查** — 等待啟動完成，確認 Status
5. **日誌掃描** — 偵測 ImportError / ConnectionRefused / 其他錯誤
6. **自動修復** — `--no-cache` rebuild、等待依賴服務、埠號衝突處理
7. **最終驗證** — API 可達性、Worker 連線確認、輸出報告

## 自動修復涵蓋範圍

| 錯誤類型 | 修復策略 |
|---------|---------|
| ImportError / ModuleNotFoundError | `--no-cache` rebuild |
| ConnectionRefused | 等待依賴服務 healthy → retry |
| Port conflict | down → up |
| Build cache corruption | `--no-cache` rebuild |

## 與 restart-eval 的差異

| | restart-eval | restart-volumn |
|---|---|---|
| 目的 | **評估**需重啟的容器 | **執行**重啟並驗證 |
| 輸出 | 對照表 + 指令建議 | 實際執行 + 健康檢查報告 |
| 錯誤處理 | 無 | 自動診斷 + 修復 |
| 觸發時機 | commit 後自動觸發 | 手動呼叫 |

---

## Overview (English)

Execute Docker container restart/rebuild with full lifecycle management: pre-flight checks (active tasks, streaming services, mount type detection) → restart/rebuild → health verification → log scanning → automatic error recovery (no-cache rebuild, dependency wait, port conflict resolution) → final report. Complements `restart-eval` (which only evaluates) by actually executing and verifying the restart.
