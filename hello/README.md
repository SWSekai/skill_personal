# hello — 對話初始化

## 功能說明

每次新對話開始時的一站式初始化入口，核心目標是**讓使用者快速進入工作狀態、延續上次的思維脈絡**。

執行流程：拉取專案更新 → 同步 Skill（合併原 `/skm sync` 流程一）→ **工作狀態重建**（掃描開放決策表、白板、context summary，提取未完成項目整合進 TODO）→ 狀態總覽。

取代 CLAUDE.md Rule 12 舊有的「對話開始自動同步」機制，改為使用者主動呼叫。

## 使用方式

```
/hello
```

## Model

- **建議 model**: `sonnet`
- **Effort**: `low`
- **理由**: 執行類操作（git pull / sp-sync.sh / 讀取摘要），無需深度分析

## 執行流程

| 步驟 | 說明 |
|---|---|
| 1. 拉取專案更新 | `git fetch` + 列出新 commit → **AskUserQuestion 確認後**才套用 |
| 2. 同步 Skill | 預覽全域 Skill 庫新版本 → **AskUserQuestion 確認後**才執行 `sp-sync.sh` |
| 3. 工作狀態重建 | 3.1 讀取 context_summary 抽取未完成候選 → 3.2 掃描開放 decision/whiteboard 抽取 `[ ]` 項 → 3.3 與 TODO.md 去重 → 3.4 寫入 TODO.md Pending → 3.5 跨日報告檢查 → 3.6 展示重建摘要 |
| 4. 狀態總覽 | 一屏精簡輸出：分支 / commit / 同步結果 / 待辦 / 未提交變更 |
| 5. 環境檢查 | 有 Docker 才執行，列出容器狀態（可選） |

## 目錄結構

```
hello/
├── SKILL.md
└── README.md
```

## 與其他 Skill 的關係

| Skill | 關係 |
|---|---|
| `/skm sync` | hello 合併 sync 流程一（遠端同步）；sync 保留流程二（規則評估與三向連動）|
| `/clean` | hello 讀取 `/clean` 產出的摘要（已合併 context-guard 職責）|
| `/team handoff` | handoff 產出的 AI bundle 可在 hello 後指示 AI 讀取 |
| `/skm pack` | 互斥：pack 後環境已清除，hello 無法執行 |

---

## 相關 Skills 與檔案

- **呼叫**：`/skm sync` Flow 1（Step 2 內嵌：遠端拉取 + skill diff）、讀取 `.local/context_summary/` 與 `.local/docs/decision/` `.local/docs/whiteboard/`、寫入 `.local/collab/TODO.md`
- **被呼叫**：無（使用者於對話開始輸入 `/hello`）
- **共用資源**：`team/TODO.md` schema（重建內容須符合 `/team todo` 格式）、`clean/` 的 context_summary 目錄（讀取上次 session 寫入的摘要）
- **改名歷史（本 skill 自身）**：2026-04-24 吸收 `/skm sync` Flow 1（遠端同步從 `/skm` 移入 `/hello` Step 2）；全域改名請見 `_bootstrap/RENAME_HISTORY.md`
