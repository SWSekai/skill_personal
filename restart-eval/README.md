# restart-eval — 服務重啟評估

## 功能概述

分析程式碼變更後，哪些 Docker 服務或系統服務需要重啟、重建或無需動作，並輸出具體執行指令。

## 目錄結構

```
restart-eval/
├── README.md    ← 本文件
└── SKILL.md     ← Skill 定義與評估規則
```

## 使用方式

```
/restart-eval [可選：commit 範圍，如 abc123..def456]
```

未指定範圍時，比對最新一次 commit 的變更。

## 評估邏輯

### 掛載類型與動作對照

| 掛載方式 | 有 Auto-reload？ | 需要的動作 |
|----------|------------------|------------|
| Volume 掛載 | 有（如 `--reload`） | 無需動作，自動生效 |
| Volume 掛載 | 無 | `docker compose restart <service>` |
| 程式碼打包進映像 | — | `docker compose build <service> && docker compose up -d <service>` |
| 靜態檔案（Web server） | — | 瀏覽器重新整理 |
| DB 初始化腳本 | — | 手動 migration（ALTER TABLE 等） |
| Dockerfile | — | `docker compose build <service> && docker compose up -d <service>` |
| Compose 檔案 | — | `docker compose up -d` |
| 設定/環境變數檔案 | — | `docker compose restart <service>` 或重建 |
| 文件/非部署檔案 | — | 無需動作 |

### 影響評估

重啟前評估副作用：Web server 短暫斷線、串流服務連線中斷、背景 worker 任務可能中斷、資料庫斷開所有 session。

## 輸出格式

1. **對照表**：變更檔案 → 服務 → 動作
2. **指令清單**：去重後依建議順序排列
3. **警告**：每個重啟的副作用
4. **DB migration**：若初始化腳本變更且資料庫已存在

## 非容器化專案

自動偵測 PM2、systemd、supervisor 等程序管理工具，提供對應的重啟指令。

---

## Overview (English)

Evaluates which Docker services or system services need restart/rebuild after code changes. Reads `docker-compose.yml` to classify files by mount type (volume vs baked-in), checks for auto-reload capability, and outputs grouped, deduplicated restart commands with side-effect warnings. Supports non-containerized projects (PM2, systemd, supervisor).
