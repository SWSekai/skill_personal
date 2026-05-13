# commit-push — 提交與推送（主要入口）

## 功能概述

完整的 Git 提交推送流程自動化，**為本工作區的主要 commit 入口**。依序執行 10 個步驟：
品質檢查（Opus 內嵌）→ README 同步 → 狀態總覽 + staging → commit → 修改日誌（Haiku 內嵌）→ push → sekai-workflow 同步 → deploy 評估 → Context 清理 → 經驗回流。

與 `/build` 的關係：`/build` 負責 commit **前**的開發（plan / impl / test / quality / review）與 commit **後**的部署（deploy）；`/commit-push` 專責 commit 本身。`/build all` 串接時會自動呼叫本 Skill。

## 目錄結構

```
commit-push/
├── README.md                            ← 本文件
├── SKILL.md                             ← Skill 定義與執行流程
└── references/
    ├── commit-conventions.md            ← Commit message 完整規範（11 個 prefix + 動態 Co-Author）
    └── gitignore-safety.md              ← .gitignore 安全規則
```

## 使用方式

```
/commit-push [--meta] [--no-subagent] [--skip-divergence-check] [可選：commit 訊息覆蓋]
```

## 旗標

| 旗標 | 說明 |
|---|---|
| `--meta` | Skill 維護模式：跳過 Step 5（修改日誌）與 Step 11（每日報告），避免污染工作記錄 |
| `--no-subagent` | 1M context 模式：所有步驟於主 session 內嵌執行，不啟動 Agent 子任務 |
| `--skip-divergence-check` | 跳過 Step 0 雙 clone rebase 分歧偵測（CLAUDE.md Rule 28），commit message 須註記 `(rule-28 skipped: <reason>)` |
| 組合用法 | 三個 flag 可任意組合，例如 `--meta --no-subagent --skip-divergence-check` |

## Model 分工（對齊 CLAUDE.md 第 18 條）

| 步驟 | Model | 原因 |
|---|---|---|
| Step 1 品質檢查 | **Opus** | 深度架構分析、風險評估（thinking 屬性） |
| Step 2–4、6–10 主流程 | **Sonnet** | 檔案讀寫、git 操作（execution 屬性） |
| Step 5 修改日誌 | **Haiku** | 結構化模板填寫（文字產出屬性） |

跨 model 透過 Agent 工具呼叫子任務，Skill 本體 `model: sonnet`。

## 執行流程

| 步驟 | 說明 |
|------|------|
| 0. 分歧偵測（Rule 28，新增 2026-05-13） | `git rev-list --left-right --count` 偵測雙 clone rebase 反模式；3+ 分歧顯示警示、10+ 阻擋 commit；可用 `--skip-divergence-check` 跳過 |
| 1. 品質檢查 | 7 小項：死碼/冗餘/硬編碼/錯誤處理/型別/序列化/安全性 + 架構一致性 + Upstream/Downstream 影響 + 風險報告 + **Step 1.6 規則 / Skill 整合性檢查（含 Rule 27 ripple checklist）** + 實作後資料流重讀 |
| 2. README 更新 | 掃描變更檔所屬目錄，同步或新建 README.md |
| 3. 狀態總覽 + staging | `git status` / `diff --stat` / `log origin..HEAD` 三段展示 → `.gitignore` 安全檢查 → `git add <檔名>` |
| 4. Commit | Conventional Commits 11 個 prefix + HEREDOC + **動態 Co-Author** |
| 5. 修改日誌 | `.hanschen/modify_log/YYMMDD_主題.md`，格式對齊原版：基本資訊 → 影響檔案（`+N -M`）→ 影響範圍 → 技術說明 → 潛在風險 |
| 6. Push | `git push`，失敗不 `--force` |
| 7. sekai-workflow 同步 | 若動到 `sekai-workflow/` → 獨立遠端 commit & push |
| 8. Deploy 評估 | 呼叫 `/build deploy --plan` 輸出重啟計畫 |
| 9. Context 清理 | context-guard 摘要 + `.local/context_summary/` 維護 + 提示 `/clear` |
| 10. 經驗回流 | 非顯而易見修正寫入 `.hanschen/guides/<topic>.md` |

## 特性

- **完整流程**：10 個步驟一次到位，不需手動串接
- **三層 model 分工**：品質用 Opus、主流程用 Sonnet、日誌用 Haiku
- **動態 Co-Author**：根據實際執行 model 填入版本（不再寫死）
- **原版格式日誌**：對齊使用者 `.\modify_log\` 原始標準模板
- **6 項 Skill 完整性檢查**：恢復 refactor 時遺失的判斷樹
- **支援容器化與非容器化**：非容器化專案自動跳過 deploy 評估
- **tool UI 處理 Y/N**：不發多餘確認訊息（對齊 CLAUDE.md 第 15 條）

## 相關規則（CLAUDE.md）

- 第 1 條：Commit 格式與 prefix（11 個）
- 第 3 條：修改日誌必備欄位
- 第 4 條：`sekai-workflow/` 同步規則
- 第 5 條：`.gitignore` 安全檢查
- 第 9 條：Memory / Skill / sekai-workflow 三向連動
- 第 15 條：Y/N 由 tool confirmation UI 處理
- 第 18 條：Skill Model 三層分層原則
- **第 27 條**：規則異動後檢核清單回填（Step 1.6 強制執行點）
- **第 28 條**：雙 clone rebase 反模式預防（Step 0 強制執行點）

## 相關 Skills 與檔案

- **呼叫**：`/build deploy --plan`（Step 8 服務重啟評估）、`/team report --daily`（Step 11 每日報告 append）、`/clean` 流程（Step 9 context 清理）
- **被呼叫**：`/skm new` Step 10 自動以 `--meta` 呼叫、`/skm update` Step 7 鏡像 commit、`/build all` 串接結尾
- **共用資源**：與 `/hello` 共用 Rule 28 分歧偵測邏輯（兩者都實作 Step 0）；`team/references/daily-report.md` §4.0 audience rule / §7.3 commit-row append spec；`references/commit-conventions.md` 11 prefix 規範
- **改名歷史**：見 `_bootstrap/RENAME_HISTORY.md`
