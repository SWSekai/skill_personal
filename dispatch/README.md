# dispatch — 任務分派路由器

## 功能說明

讓 CLAUDE.md Rule 18（Skill Model 三層分工原則）真正落地的執行入口。Claude Code 的主對話 model 在對話中無法被切換，唯一能在執行中產生**真實 model 切換**的機制是 `Agent` 工具的 `model` 參數。`/dispatch` 把這個能力包成可重複使用的指令：依任務類別自動挑選 Opus/Sonnet/Haiku 層級，再透過 Agent 工具派遣，並把每次派遣寫入日誌供事後驗證。

## 使用方式

```
/dispatch <任務描述> [--model opus|sonnet|haiku] [--agent <subagent_type>]
```

| 形式 | 行為 |
|------|------|
| `/dispatch <task>` | 依關鍵字啟發法自動挑層級 |
| `/dispatch <task> --model opus` | 強制指定層級 |
| `/dispatch <task> --agent Plan` | 強制指定 subagent_type |

## Model

- **建議 model**: `haiku`（本 Skill 主體）
- **Effort**: `low`
- **理由**: `/dispatch` 本身只做「文字解析 + 路由判斷」，重活在派遣後的子代理執行
- **真正的 model 分派**: 透過 Agent 工具的 `model` 參數，由 Skill 內部選擇 opus / sonnet / haiku

## 觸發條件

- **手動**: 使用者明確下 `/dispatch <task>` 指令
- **不會自動觸發**: 此 Skill 不會被其他 hook 自動呼叫；它是主動委派工具

## 模型分派啟發法

| 任務關鍵字 | 對應層級 |
|----------|---------|
| `review`, `audit`, `evaluate`, `architecture`, `design`, `decide`, `plan`, `propose`, `risk` | **opus** |
| `implement`, `refactor`, `fix`, `add`, `edit`, `modify`, `migrate`, `wire up` | **sonnet** |
| `summarize`, `format`, `template`, `fill in`, `generate log`, `write doc` | **haiku** |
| 無匹配 | **sonnet**（安全預設） |

歧義（同時匹配多層）時取**較高層級**。

## 子代理選擇

| 任務性質 | subagent_type |
|---------|---------------|
| 程式碼探索、找檔案、code 問題 | `Explore` |
| 架構規劃、實作計畫 | `Plan` |
| Claude Code / Anthropic SDK 問題 | `claude-code-guide` |
| 其他 | `general-purpose` |

## 執行流程

1. **Step 1** 解析參數：拆出 task / `--model` / `--agent`
2. **Step 2** 依啟發法選 tier（除非 `--model` 強制覆寫）
3. **Step 3** 依任務性質選 subagent_type（除非 `--agent` 強制覆寫）
4. **Step 4** 寫入 `.local/model_dispatch.log` 一行紀錄
5. **Step 5** 呼叫 `Agent({subagent_type, model, description, prompt})`
6. **Step 6** 回傳子代理結果，加上派遣 footer

## 驗證機制（雙重日誌）

| 來源 | 紀錄方式 |
|------|---------|
| `/dispatch` Skill 內 | Step 4 主動寫入 `.local/model_dispatch.log` |
| `log_agent_dispatch.cjs` PreToolUse hook | 任何 Agent 工具呼叫都會自動寫入同一份日誌（含 `[hook]` 前綴） |

**核對方式**：每次 `/dispatch` 預期產生**兩筆紀錄**（Skill 主動 + hook 自動）。
- 兩筆都在 → 派遣成功
- 只有 hook 紀錄 → 表示 Agent 是被其他路徑呼叫（非 `/dispatch`），也是有用情報
- 只有 Skill 紀錄 → 表示 Skill 寫了日誌但實際沒派遣（bug）

```bash
tail -10 .local/model_dispatch.log
```

## 與其他 Skill 的關係

- **不要**用 `/dispatch` 包裝那些**內部已自帶多層分派**的 Skill（例如 `/commit-push`，它的 Step 1 已經透過 Agent 呼叫 Opus 做品質檢查）
- 適合包裝**沒有現成 Skill** 的臨時任務、跨專案分析、單次評估
- 對於想要「強制升級 model」的場景（例如平常跑 Sonnet 但這次想用 Opus 做架構決策），`--model opus` 是最直接的方式

## 目錄結構

```
dispatch/
├── SKILL.md
└── README.md
```

無 `references/` 或 `assets/`（內容精簡，分派啟發法已寫在 SKILL.md 表格中）。

## 範例

| 輸入 | 解析結果 |
|------|---------|
| `/dispatch review the auth rewrite for race conditions` | opus · general-purpose |
| `/dispatch refactor user_service.py to use new logger` | sonnet · general-purpose |
| `/dispatch summarize this week's modify_log entries into a 5-bullet weekly` | haiku · general-purpose |
| `/dispatch find all callers of deprecated parseRequest()` | sonnet · Explore |
| `/dispatch design a migration plan for splitting the monolith db` | opus · Plan |
| `/dispatch tweak the README wording --model haiku` | haiku（強制覆寫）· general-purpose |

---

## 相關 Skills 與檔案

- **呼叫**：Agent tool（實際 model 切換機制；`/dispatch` 僅選層級與組裝 prompt）
- **被呼叫**：無（使用者隨手觸發）
- **共用資源**：`.local/model_dispatch.log`（每次派遣的稽核紀錄）、`hooks/log_agent_dispatch.cjs`（PreToolUse hook 寫入紀錄）
- **改名歷史（本 skill 自身）**：無；全域改名請見 `_bootstrap/RENAME_HISTORY.md`
