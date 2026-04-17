# Model Routing Reference

> 最後更新：2026-04-10

本文件定義 skill 執行時的 model 選擇規則。每個 skill 的 `model` frontmatter 欄位應依此規則設定。

---

## Model 能力概覽

| Model | 代號 | 特長 | 適用場景 |
|-------|------|------|----------|
| Claude Opus 4.6 | `opus` | 深度推理、多檔架構分析、安全審計 | 跨層追蹤、品質審計、複雜決策 |
| Claude Sonnet 4.6 | `sonnet` | 平衡速度與能力、多步驟流程 | 標準開發工作流、檔案讀寫、編排任務 |
| Claude Haiku 4.5 | `haiku` | 快速、結構化輸出、低延遲 | 模板填充、狀態檢查、日誌生成 |

---

## 路由決策樹

依序檢查，符合第一個條件即選用該 model：

```
1. 是否使用 Agent 工具做跨檔分析？ ──→ opus
2. 是否需要安全掃描或架構一致性評估？ ──→ opus
3. 是否涉及多步驟編排或需要判斷力？ ──→ sonnet
4. 是否為固定流程的結構化輸出？ ──→ haiku
5. 不確定？ ──→ sonnet（預設）
```

---

## Effort 對照

| Effort | 適用情境 | 對應 model |
|--------|----------|-----------|
| `high` | 深度分析、跨檔追蹤、安全審計 | opus |
| `medium` | 多步驟工作流、標準開發任務 | sonnet |
| `low` | 模板填充、狀態檢查、程序化操作 | haiku / sonnet |

---

## 完整分配表（合併後 6 Skill）

| Skill | Model | Effort | 理由 | 子命令 effort 備註 |
|-------|-------|--------|------|-------------------|
| build | sonnet | medium | 多步驟編排流程 | quality 子命令內部用 high/Agent |
| team-office | sonnet | medium | 增量式互動 markdown | — |
| setup | sonnet | medium | 多檔生成 + Git 同步 | — |
| ask | opus | medium | 跨檔分析、Agent 子代理 | report 子命令可用 low |
| context-guard | sonnet | low | 摘要生成，固定模板 | — |
| memory-portable | sonnet | low | 檔案複製操作 | — |

### 子命令級 effort 參考（合併前原始值）

| 原 Skill → 子命令 | 原 Model | 原 Effort |
|---|---|---|
| commit-push → `/build commit` | sonnet | medium |
| quality-check → `/build check` | opus | high |
| modify-log → `/build log` | haiku | low |
| restart-volumn → `/build restart` | haiku | low |
| restart-eval → `/build eval` | haiku | low |
| todo → `/team todo` | sonnet | medium |
| whiteboard → `/team board` | sonnet | medium |
| md-collab → `/team decide` | sonnet | medium |
| tech-notes → `/team note` | sonnet | medium |
| create-skill → `/skill new` | sonnet | medium |
| skill-sync → `/skill sync` | sonnet | medium |
| pack → `/skill pack` | sonnet | low |
| sys-info → `/ask info` | opus | medium |
| trace-flow → `/ask trace` | opus | high |
| report → `/team report` | haiku | low |

---

## Override 政策

- `model` frontmatter 是**建議值**，非強制
- 使用者可透過 `$ARGUMENTS` 或對話指示覆寫
- 若 sonnet 級 skill 遇到預期外的複雜度，應在輸出中註明，但不自動升級 model
- `effort` 僅在 Opus 4.6 下生效，其他 model 會忽略此欄位
