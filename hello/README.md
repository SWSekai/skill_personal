# hello — 對話初始化

## 功能說明

每次新對話開始時的一站式初始化入口：拉取專案更新、同步 Skill（合併原 `/setup sync` 流程一）、恢復上次工作 context、顯示狀態總覽。

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
| 1. 拉取專案更新 | `git fetch` + 顯示 upstream 差異（不自動 merge） |
| 2. 同步 Skill | 執行 `sp-sync.sh`（原 `/setup sync` 流程一）→ sekai-workflow → .claude/skills/ |
| 3. 恢復 Context | 讀取最新 context_summary + current_topic + TODO |
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
| `/setup sync` | hello 合併 sync 流程一（遠端同步）；sync 保留流程二（規則評估與三向連動）|
| `/context-guard` | hello 讀取 context-guard 產出的摘要 |
| `/team-office handoff` | handoff 產出的 AI bundle 可在 hello 後指示 AI 讀取 |
| `/setup pack` | 互斥：pack 後環境已清除，hello 無法執行 |
