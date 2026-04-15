# Skill 文件產出參考表

> 所有 Skill 會自動產生的文件、觸發時機、存放位置、用途一覽。
>
> Last updated: 2026-04-08

---

## 本地工作紀錄（不入版控，在 `.local/` 下）

| Skill | 觸發時機 | 產出檔案格式 | 存放位置 | 用途 |
|-------|---------|-------------|---------|------|
| **modify-log** | commit 後自動觸發 | `YYMMDD_TopicDescription.md` | `.local/modify_logs/` | 記錄每次 commit 的變更內容、影響範圍、風險評估 |
| **restart-eval** | commit 後自動觸發 | 可選存檔 | `.local/modify_logs/` | 評估哪些容器/服務需要重啟 |
| **restart-volumn** | 手動觸發 | 可選存檔 | `.local/modify_logs/` | 執行容器重啟並記錄結果 |
| **context-guard** | 系統壓縮通知 / 手動 `/context-guard` | `YYMMDD_HHMM_TopicDescription.md` | `.local/summary/` | 保存當前工作上下文摘要，供下次對話恢復 |
| **context-guard** | 同上 | `current_topic.md` | `.local/summary/` | 記錄當前工作主題，用於任務切換偵測 |
| **sys-info** | 詢問系統架構/功能時自動觸發 | `[topic_description].md` | `.local/docs/` | 系統知識庫，記錄架構、資料流、設定等 |
| **commit-push** (Step 10) | commit 後，若含踩坑經驗 | guide 文件 | `.local/docs/` | 實戰經驗指南（症狀→原因→解法） |
| **md-collab** | 手動觸發 | 互動式決策表 | `.local/docs/`（預設） | 生成 checkbox/table 供使用者勾選決策 |
| **report** | 手動 `/report` | `YYMMDD_[type]_report.md` | `.local/reports/` | 從 modify_logs 統整工作報告（簡報用） |
| **todo** | 手動 `/todo` | `TODO.md` | `.local/collab/` | AI 待辦事項清單，追蹤任務進度 |
| **pack** | 手動 `/pack` | 打包結果 + `manifest.txt` | `.local/ai-context/` | 收集所有 AI 上下文，準備遷移或清理 |

---

## 入版控文件

| Skill | 觸發時機 | 產出檔案格式 | 存放位置 | 用途 |
|-------|---------|-------------|---------|------|
| **commit-push** (Step 2) | commit 前自動觸發 | `README.md` | 變更目錄下 | 自動更新目錄說明文件 |

---

## Skill / 設定檔（由 skill-sync 管理）

| Skill | 觸發時機 | 產出檔案格式 | 存放位置 | 用途 |
|-------|---------|-------------|---------|------|
| **skill-sync** | 對話開始 / 手動 `/skill-sync` | `SKILL.md`, `README.md` | `.claude/skills/[name]/` | 同步 Sekai_workflow 至專案 |
| **create-skill** | 手動 `/create-skill` | `SKILL.md`, `README.md` | `.claude/skills/[name]/` + `Sekai_workflow/` | 建立新 Skill 定義 |

---

## 目錄結構總覽

```
.local/
├── modify_logs/   ← modify-log、restart-eval、restart-volumn
├── docs/          ← sys-info、commit-push (lessons)、md-collab
├── summary/       ← context-guard
├── reports/       ← report
├── collab/        ← todo
└── ai-context/    ← pack（打包時產生）
```

---

## 備註

- `.local/` 整個目錄由 `.gitignore` 排除，不入專案版控
- 目錄由各 Skill 首次使用時自動建立
- `/report` 依賴 `.local/modify_logs/` 的內容來生成報告
- `/pack` 會收集 `.local/` 下所有子目錄打包至 `.local/ai-context/`
