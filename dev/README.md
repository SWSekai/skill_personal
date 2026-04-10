# /dev — 開發全流程 Skill

涵蓋從需求分析到部署的完整開發生命週期。

## 使用方式

### 全流程（推薦）

```
/dev flow <feature description>
```

自動串接：plan → impl → test → commit，中間不需手動呼叫。

### 分階段呼叫

| 指令 | 說明 |
|---|---|
| `/dev plan <feature>` | 需求分析 + 方案設計 + 步驟拆解 |
| `/dev impl [plan-ref]` | 按方案逐步實作 |
| `/dev test [scope]` | 測試驗證（自動 + 手動 checklist） |
| `/dev commit [msg]` | 完整提交流程 |
| `/dev quality [files]` | 獨立品質審計 |
| `/dev log [topic]` | 建立 / 更新本地修改日誌 |
| `/dev restart [services]` | 容器重啟與自動修復 |
| `/dev eval [range]` | 重啟評估（不執行） |

無參數時預設執行 `commit`。

## Model

- **Skill model**：`sonnet`
- **quality**：需深度分析，必要時呼叫 Agent
- **plan**：需深度思考架構影響

## 完整流程圖

```
/dev flow "新增使用者管理功能"
    │
    ├─ plan：掃描現有架構 → 影響評估 → 方案設計 → 步驟拆解
    │   └─ AskUserQuestion 確認方案
    │
    ├─ impl：逐步執行 → checkbox 勾對 → 偏離偵測
    │
    ├─ test：自動測試 → 手動 checklist → 邊界情境
    │   └─ 失敗 → 回 impl 修復 → 重測
    │
    └─ commit：quality → README → stage → commit → push → restart-eval
```

## 方案文件

plan 階段產生的方案文件存放於 `.local/docs/plans/YYMMDD_<feature>.md`，包含：

- 需求摘要與驗收標準
- 現況掃描結果
- 影響範圍表
- 替代方案比較（若有多種做法）
- 帶 checkbox 的實作步驟清單

方案文件的 checkbox 作為 impl 階段的進度追蹤。中斷後可用 `/dev impl <plan-file>` 恢復。

## 檔案結構

```
.claude/skills/dev/
├── SKILL.md
└── README.md
```

## 子命令對應

| 子命令 | 前身 |
|---|---|
| `/dev flow` | 新增 |
| `/dev plan` | 新增（對齊 CLAUDE.md「功能需求規劃先行」） |
| `/dev impl` | 新增 |
| `/dev test` | 新增 |
| `/dev commit` | commit-push |
| `/dev quality` | quality-check |
| `/dev log` | modify-log |
| `/dev restart` | restart-volumn |
| `/dev eval` | restart-eval |
