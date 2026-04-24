# Sekai-workflow

**專為 [Claude Code](https://claude.com/claude-code) 打造的可攜式工作流程包 — 丟進任何專案，AI 助手立即知道如何規劃、實作、提交與交接工作。**

[English](./README.md) · **繁體中文** · [日本語](./README.ja.md)

---

## 這是什麼？

Sekai-workflow 是一組為 Claude Code 打造的 **Skills**（斜線指令）與 hooks，封裝完整的工程工作流程：規劃、實作、測試、品質審查、commit/push、跨對話 context 交接。

**刻意設計為與專案無關**：不含服務名稱、不寫死路徑、不綁業務邏輯。一條指令安裝，讓任何 repository 都擁有一致的 AI 協作行為。

> 把它想成針對 Claude Code 協作方式的 `eslint + prettier + Conventional Commits + 團隊風格指南`。

## 為什麼要用？

跨專案使用 AI 程式助手時，常見的痛點幾乎一模一樣：

- 🔁 **每次新對話都要重新解釋同樣的規則**（請用 Conventional Commits、不要改自動產生檔、修改日誌格式⋯）
- 🧩 **對話之間 context 流失** — 長對話觸及壓縮上限後，先前的決策有一半被忘掉
- 🏗️ **各自為政的工作流** — 每位開發者驅動 Claude 的方式略有不同，團隊產出難以一致
- 🧹 **改完後的收尾被省略** — 品質檢查、冗餘掃描、修改日誌、容器重啟評估在趕工時一律跳過

Sekai-workflow 透過一組**可重用的斜線指令**與守門 hooks，把這些重複性的工作自動跑完。

## 功能總覽

9 個指令入口（全部以 `/command` 呼叫）：

| 指令 | 用途 | 典型觸發時機 |
|---|---|---|
| `/hello` | 對話初始化 — 拉取更新、恢復先前 context、狀態總覽 | 每次對話開始 |
| `/build <all\|plan\|do\|test\|check\|review\|deploy>` | 開發全流程：分析 → 設計 → 實作 → 測試 → 品質 → review → 部署 | 要動工時 |
| `/commit-push [msg]` | 主要 commit 入口 — 品質檢查 → 修改日誌 → README 同步 → commit → push → 部署評估 → context 清理 | 完成一段連貫工作後 |
| `/team <todo\|board\|decide\|note\|handoff\|report\|living\|follow-up>` | 人機協作：TODO、白板、Markdown 決策表、技術筆記、交接文件 | 規劃與決策時刻 |
| `/ask <info\|trace>` | 詢問 codebase 資訊、端對端追蹤欄位資料流 | 「某欄位怎麼流的？」類問題 |
| `/skm <new\|sync\|pack\|update>` | 管理 Skill 環境本身 — 建立、與上游同步、打包交接（2026-04-24 由 `/skill` 改名，避免與內建 `/skills` 衝突）| Skill 維護 |
| `/clean [check\|force]` | Context window 清理 — 摘要、封存、`/clear`、自動恢復 | 對話變長時 |
| `/memo` | Feedback / 偏好記憶跨專案攜帶 | 接手新專案時 |
| `/dispatch <task>` | 依 model 層級（Opus / Sonnet / Haiku）透過 Agent 派遣任務 | 需要真實 model 切換時 |

## 快速開始

### 前置需求

- 已安裝並登入 [Claude Code CLI](https://claude.com/claude-code)
- Git
- 一個專案目錄（新或舊）— 甚至空資料夾也可以

### 安裝（30 秒）

```bash
# 1. 將 sekai-workflow clone 到專案之外（或任意位置）
git clone https://github.com/SWSekai/sekai-workflow.git

# 2. 進入你的專案根目錄，執行 bootstrap
#    Windows：
C:\path\to\sekai-workflow\_bootstrap\sp-init.bat

#    macOS / Linux / WSL（即將支援 — 目前可透過 Wine 執行 sp-init.bat，
#    或參考 docs/QUICKSTART.md 的手動步驟）
```

Bootstrap 會自動：

1. 建立 `.claude/skills/` 並複製所有 Skill 到你的專案
2. 建立本地 `Sekai_workflow/`（首次執行後自動更名為 `.sekai-workflow/`），追蹤上游倉庫更新
3. 產生針對 Claude Code 調校的 `CLAUDE.md` 規則檔
4. 安裝 `pre-commit` hook，防止 Skill 檔案誤入你的專案版控
5. 自動更新 `.gitignore` 排除所有 AI 相關檔案

以上全部都在你的專案版控之外 — **你的 repo 只 commit 你的程式碼。**

### 驗證

```bash
# 檢查所有保護層是否就位
C:\path\to\sekai-workflow\_bootstrap\sp-verify.bat C:\your\project
```

## 第一次走完整個流程

安裝完成後，在專案中開啟 Claude Code，依序試試：

```
/hello          # 恢復 context + 檢查上游更新
/build plan     # 描述一項功能 → 產出結構化計畫（Opus）
/build do       # Claude 逐步實作，自動勾選完成項目
/commit-push    # 品質掃描 → 修改日誌 → README 調整 → commit → push
/clean          # 對話變長時：摘要、封存、/clear
```

這就是完整的內循環。每個指令對應的 `SKILL.md` 與 `README.md` 都在各自資料夾內 — Claude 會自動讀取，你不必背任何語法。

## 運作原理

三層架構，單一事實來源：

```
┌──────────────────────────────────────────────────────────┐
│  github.com/SWSekai/sekai-workflow   （本倉庫）          │  ← 上游模板
└─────────────────────────┬────────────────────────────────┘
                          │ clone / /skm sync
                          ▼
┌──────────────────────────────────────────────────────────┐
│  <你的專案>/.sekai-workflow/   （模板本地副本）          │  ← 不入版控
└─────────────────────────┬────────────────────────────────┘
                          │ sp-init.bat / /skm sync
                          ▼
┌──────────────────────────────────────────────────────────┐
│  <你的專案>/.claude/skills/    （實際使用的 Skills）     │  ← 不入版控
└──────────────────────────────────────────────────────────┘
```

- **上游更新** — 有人改進 Skill → `/hello` 或 `/skm sync` 自動拉入你的專案
- **下游回流** — 你在本地改進 Skill → 若具通用性，`/skm sync` 會詢問是否推回上游（需明確同意；預設僅本地）
- **專案特化修改**留在 `.claude/skills/`，不會回流

### 版控邊界

| 路徑 | 歸屬 | 進你專案的 git？ |
|---|---|:---:|
| 你的程式碼 | 你的專案 | ✅ |
| `.claude/skills/` | 本地 | ❌ |
| `.sekai-workflow/` | 本上游倉庫 | ❌ |
| `CLAUDE.md` | 本地 | ❌ |
| `.local/`（日誌、摘要、報告） | 本地工作紀錄 | ❌ |

Bootstrap 會自動設定 `.gitignore`。**絕對不要對 AI 檔案使用 `git add -f`** — pre-commit hook 會擋下來。

## 客製化

每個 Skill 都可調整。打開 `.claude/skills/<skill>/SKILL.md` 修改：

- **路徑** — 修改日誌、摘要、決策表的存放位置
- **服務** — Docker 容器名稱、compose 檔案路徑、部署指令
- **語言** — commit 訊息語言、UI 文字偏好
- **流程** — 增減步驟、調整觸發條件

你的調整只留在本地。若判定改動足夠通用，可標記出來，`/skm sync` 會協助回流至上游。

## 文件

- [QUICKSTART](./docs/QUICKSTART.md) — 含情境範例的完整導覽
- [檔案輸出對照](./docs/file-output-reference.md) — 每個指令寫出的檔案位置
- [`manifest.json`](./manifest.json) — 機器可讀的 Skill 索引，含 model 層級與 allowed tools
- 各 Skill 專屬文件位於對應資料夾（`build/README.md`、`team/README.md` …）

## Model 三層分工

Skill 依工作屬性指派 model 層級：

- **Opus** — 規劃、品質審查、架構決策、深度分析
- **Sonnet** — 多步驟執行、檔案編輯、標準開發任務
- **Haiku** — 結構化文字產出（修改日誌、狀態檢查、模板）

`/dispatch` 透過 Agent 工具提供**真實**的 model 切換，適用單一任務需要特定 model 時。完整對照見 [`references/model-routing.md`](./references/model-routing.md)。

## 貢獻

歡迎 issues 與 PR。主倉庫在 [github.com/SWSekai/sekai-workflow](https://github.com/SWSekai/sekai-workflow)。

貢獻 Skill 改動前，先執行 `/skm sync` 確保 diff 基於最新上游版本。

歡迎貢獻 README 翻譯 — 新增 `README.<lang>.md` 到本目錄，並更新每份 README 頂部的語言切換列。

## License

若有 [LICENSE](./LICENSE) 以該檔案為準；否則暫視為保留所有權利，待上游倉庫明確授權。

---

> **在找詳細操作手冊？**過去本 README 承載的細節已搬移至 [docs/QUICKSTART.md](./docs/QUICKSTART.md) 以及各 Skill 資料夾內的 `README.md`，讓本頁保持對首次訪客友善。
