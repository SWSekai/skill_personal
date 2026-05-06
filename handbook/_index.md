# Engineering Handbook Index

跨專案工程手冊索引（人讀 + 機讀）。新增筆記時由 `/kb add` 自動更新此檔。

> **目錄身份**：此為 `sekai-workflow/` 下的**資料目錄**，不是 skill（無 `SKILL.md`）。由 `/kb` skill 管理。
> **原名**：`knowledge_base/`（2026-04-24 改為 `handbook/`，避免與頂層 skill 目錄混淆）。

## 使用方式

- 查詢：`/kb search <關鍵字>` — 模型直接回傳相關內容
- 新增：`/kb add <topic>` — 互動式建立/更新一筆筆記
- 抽取：`/kb extract <path>` — 從 decision/board 結案檔案抽取可重用內容
- 自動：`/team` 結案時自動掃描可抽取項目

## 目錄分類

| 目錄 | 用途 |
|---|---|
| `docker/` | Docker、Compose、Dockerfile 模板與除錯 |
| `kubernetes/` | K8s manifest、Helm chart、Ingress、資源設定 |
| `etl/` | ETL pipeline、Airflow、Spark、資料清洗模式 |
| `algorithms/` | 演算法實作與複雜度分析 |
| `backend/` | API 設計、驗證機制、資料庫模式、常見框架慣例 |
| `_general/` | 跨領域或暫未明確分類 |

## 筆記索引

| Topic | Category | 說明 | Added |
|---|---|---|---|
| cicd-gitea-actions-yaml | _general | Gitea/GitHub Actions YAML 結構、Docker Build、K8s 部署、kubeconfig 注入、常見坑 | 2026-05-06 |

## 規則

1. 筆記內容必須為**通用可重用**：不含專案特定業務邏輯、內部 URL、認證資訊
2. 每筆使用 `assets/kb-doc-template.md` 結構
3. 跨專案共享透過 `sekai-workflow` git 遠端
4. 衝突內容以**並列**方式保留（不覆蓋），註記差異來源
