# 多平台 CLI Skill Project 重構決策表

> 觸發：使用者 `/skm refactor all` — 將現行 `sekai-workflow/` skill 體系從 Claude Code 單平台擴展至多 CLI（Cursor / Codex / Gemini / Factory / OpenCode），參照 [iannuttall/dotagents](https://github.com/iannuttall/dotagents) 設計。
>
> **核心訴求**：「multi-platform 切換 smoothly、不想為了 CLI 之間改檔名」。
>
> 規則依據：CLAUDE.md Rule 17（互動式 Markdown）／Rule 21（pre-modification protocol）／Rule 22（Planning-First 至少兩套方案）／Rule 23（非 skill 頂層目錄變更必檢 bootstrap 腳本）。
>
> 完成後請於對話回覆「OK」或「完成」，Claude 重讀本檔解析勾選與補充，依採納方案產生變更摘要並執行實作。

---

## §0 Preflight 風險與遠端狀態（必讀）

### §0.1 sekai-workflow remote 狀態（2026-05-08 fetch 結果）

```
+ 664b9f9...514ccfb main -> origin/main  (forced update)
左/右分歧：98 (remote ahead) / 96 (local ahead)
```

**判讀**：遠端被 force-push 過，本地與遠端**雙向分歧**。歷史記憶提示這多半是過往的 author-rewrite（tree 內容一致、僅 commit hash 改變）；但無法在不比對 tree 的情況下保證。

實作前必須擇一處理：

- [ ] §0.1.a — **驗證 tree 內容一致**（`git diff origin/main..HEAD --stat`），若無內容差異 → `git reset --hard origin/main` 對齊（**會丟棄 96 個 local commit hash，但內容保留**）
- [x] §0.1.b — 由我（Claude）先跑 `git diff` 比對，把差異清單貼給使用者，再決定處理
- [ ] §0.1.c — 暫時不處理，僅在 `.hanschen/` 範圍內推進此決策表，sekai-workflow 寫入時再回頭解
- [ ] 其他（填補充說明）

**補充說明：**
> 💡 預填建議：選 §0.1.b — 先看內容差異再決策最安全。若確認是純 author-rewrite，後續可一鍵 hard-reset；若有真實內容差異則必須個別檢視。**§0.1.c 是當前可推進的最小阻力選項**，因為本次重構的「決策階段」全部寫在 `.hanschen/`（隨主專案 git，不涉及 sekai-workflow），不會被 remote 衝突阻擋；等決策定案、進入實作階段再解。

### §0.2 風險全清單（Rule 21 強制）

| 風險 | 類型 | 嚴重度 | 緩解 |
|---|---|:---:|---|
| `sekai-workflow/` 改名 → `.agents/` | 不可回復（git history） | 🔴 高 | 走 `git mv` 保留歷史；或保留 `sekai-workflow/` 名稱、僅加 symlink 別名 |
| Windows symlink 需 Dev Mode/admin | 環境依賴 | 🟡 中 | 改用 `mklink /J` directory junction，不需特殊權限 |
| 各 CLI frontmatter 解析差異 | 靜默失效 | 🔴 高 | SKILL.md frontmatter 為 Claude 專屬；其他 CLI 視為註解，需驗證 |
| Hooks (`.cjs`) 僅 Claude Code | 平台不相容 | 🟡 中 | 文件清楚標示；非 Claude 平台不安裝 hooks |
| Memory（`MEMORY.md`） Claude 專屬 | 平台不相容 | 🟡 中 | 暫不跨平台支援 |
| `sp-init.bat` 邏輯改寫 | 既有使用者破壞 | 🟡 中 | 加版本號／向下相容旗標 |
| 主專案 `CLAUDE.md` 與 `AGENTS.md` 同步漂移 | 一致性 | 🟡 中 | 強制 symlink 不複製 |
| Slash 命令在 Cursor/Gemini 步驟式內容無法執行 | 功能弱化 | 🟢 低 | 文件清楚標示哪些 skill 為 Claude-only |

---

## §1 核心訴求釐清

### §1.1 「不想改檔名」的精確語意

- [x] §1.1.a — **檔名語意**：每個 skill / 命令只有一份**規範檔案**（如 `team/SKILL.md`），透過 symlink / junction 出現在各 CLI 期待的位置（`~/.claude/`, `~/.cursor/commands/`, `~/.codex/prompts/` 等），無需為任何 CLI 額外複製或改名
- [ ] §1.1.b — **目錄語意**：連 `sekai-workflow/` 這個資料夾名都不能改，所有 dotagents 風格的 `.agents/` 重構皆不採納
- [ ] §1.1.c — **內容語意**：每個 skill 的 SKILL.md 內容也不為任何 CLI 客製分支
- [ ] 其他（填補充說明）

**補充說明：**
> 💡 預填建議：選 §1.1.a。Dotagents 的核心優勢即在於「檔名單一、symlink 多名」— 完全契合此訴求。若 §1.1.b（連目錄都不改）也成立則需在 §2 進一步確認「`.agents/` 是新增別名，原 `sekai-workflow/` 保留」。**§1.1.c 內容客製分支的代價**：每個 skill 要維護 N 份，違背 DRY，建議排除。

### §1.2 目標平台清單（multi-select）

- [x] §1.2.a — Claude Code（現有，必選）
- [ ] §1.2.b — Cursor
- [x] §1.2.c — Codex CLI
- [x] §1.2.d — Gemini CLI
- [ ] §1.2.e — Factory
- [ ] §1.2.f — OpenCode
- [ ] §1.2.g — 其他（填補充說明指明）

**補充說明：**
> 💡 預填建議：勾選 a/b/c/d 四個主流。Factory 與 OpenCode 預設不啟用 — 若你日常不使用可省略 symlink 安裝邏輯（仍可在 `manifest.json` 留 platform 欄位以利日後加入）。請告知實際使用 / 計畫使用的 CLI。

---

## §2 頂層架構：dotagents 風格的採納程度

### §2.1 核心目錄佈局

- [ ] §2.1.a — **完全 dotagents**：`sekai-workflow/` → `.agents/`，子目錄重整為 `.agents/skills/`、`.agents/commands/`、`.agents/hooks/`、`.agents/CLAUDE.md`、`.agents/AGENTS.md`。優：對齊社群慣例。劣：大規模 rename，遠端 force-push 風險，違反 §1.1 若選 b。
- [x] §2.1.b — **混合（保留 + 新增）**：`sekai-workflow/` 維持原名與既有結構；新增 `.agents/` 作為**指向 sekai-workflow 子目錄的 symlink 集合**（`.agents/skills/ → sekai-workflow/`、`.agents/CLAUDE.md → CLAUDE.md`），各 CLI 的入口都從 `.agents/` 過 — 對齊 dotagents 慣例同時零破壞。
- [ ] §2.1.c — **純別名**：不建 `.agents/`，直接從 `sekai-workflow/` 對各 CLI 目錄做 symlink。優：最小改動。劣：放棄 dotagents 對接點，未來社群工具（如 dotagents NPM CLI）難以接入。
- [ ] 其他（填補充說明）

**補充說明：**
> 💡 預填建議：選 §2.1.b。`.agents/` 作為「平台對接層」、`sekai-workflow/` 作為「skill 規範層」— 兩層職責分明，對外相容 dotagents 生態，對內保留現有資產與 git 歷史。改動範圍：新增 `.agents/` + 一支 platform-link 腳本，sekai-workflow 內部 0 改動。

### §2.2 各 CLI 對應路徑（symlink target 一覽）

預計 link 對應（依 §1.2 移除 Cursor 後更新）：

| 來源（canonical） | 各 CLI symlink 目標 |
|---|---|
| `.agents/skills/` | `~/.claude/skills/`（已存在；改為 link） |
| `.agents/commands/` | `~/.claude/commands/`、`~/.codex/prompts/`、`~/.gemini/commands/` |
| `.agents/hooks/` | `~/.claude/hooks/`（其他 CLI 無對應 — skip） |
| `.agents/AGENTS.md`（**canonical 候選**） | project-root `AGENTS.md`（Codex 通讀）／`.agents/CLAUDE.md` 與 `.agents/GEMINI.md` 反向 link 至此 |
| `.agents/CLAUDE.md` | project-root `CLAUDE.md`、`~/.claude/CLAUDE.md`（皆為 symlink） |
| `.agents/GEMINI.md` | `~/.gemini/GEMINI.md` |

- [x] §2.2.a — 採用上表預設
- [x] §2.2.b — 自訂（請於補充說明列差異）
- [ ] 其他（填補充說明）

**補充說明：**
> 💡 預填建議：採用預設。實作時 platform-link 腳本會逐一檢查目標目錄是否存在（CLI 已安裝），不存在則 skip 該 link，避免污染未使用平台。
> 改為.agents/AGENTS.md 提供對應檔案指向比較通用一點，另外想確認統一入口進行個別對應比較好，還是各個入口對應至同一說明文件比較常見，請說明優劣，畢竟若要修改skill，要所有的相關說明文件憶起修正，會耗費大量的token，並請說明目前link的方式，我有點搞不清楚
>
> 📝 **Claude 回應（2026-05-08）— Symlink 是 OS 層別名、非複製；編輯成本是常數 1 不論幾個 CLI；canonical 改 AGENTS.md 建議同步翻 §5.1.b**
>
> **(A) 目前 link 方式（具體圖解）**
>
> ```
> sekai-workflow-edit/                  ← 主專案（git repo）
> ├── sekai-workflow/                   ★ 真實檔案：10 個 skill 規範本體
> │   ├── team/SKILL.md                 (實體檔，硬碟上唯一存在)
> │   ├── build/SKILL.md                (實體檔)
> │   ├── ...
> │   └── hooks/check_yn_question.cjs   (實體檔)
> ├── AGENTS.md                         ★ 真實檔案：context 規範本體（候選 canonical）
> ├── CLAUDE.md                         → symlink → AGENTS.md
> ├── .agents/                          ◇ 全部是 symlink/junction，**沒有任何實體檔**
> │   ├── skills/  ─────junction─────→  ../sekai-workflow/
> │   ├── hooks/   ─────junction─────→  ../sekai-workflow/hooks/
> │   ├── AGENTS.md ────symlink──────→  ../AGENTS.md
> │   ├── CLAUDE.md ────symlink──────→  ../AGENTS.md   (同檔)
> │   └── GEMINI.md ────symlink──────→  ../AGENTS.md   (同檔)
> └── ~/.claude/skills/  ──junction──→  <proj>/.agents/skills/
>     ~/.codex/prompts/  ──junction──→  <proj>/.agents/skills/
>     ~/.gemini/commands/ ─junction──→  <proj>/.agents/skills/
> ```
>
> **關鍵：** symlink/junction 在 OS 層解析路徑，**不複製檔案**。當 Claude 讀 `~/.claude/skills/team/SKILL.md`，OS 直接讀的是 `<proj>/sekai-workflow/team/SKILL.md` 那一份硬碟 inode。所有 CLI 共讀同一個 inode。
>
> **(B) Mode A 與 Mode B 比較（針對你的兩個術語）**
>
> | 模式 | 結構 | 例子 | 適用場景 | 編輯成本 |
> |---|---|---|---|---|
> | **Mode A 統一入口、個別對應** | 一個 hub 檔案內含多個指標，連到多個獨立子檔案 | `AGENTS.md` 內列 `@team`, `@build`, `@skm`...，每個指向自己的 SKILL.md | 跨 skill 索引、目錄式導航 | 修 hub 一次 + 修 spoke 一次（兩處） |
> | **Mode B 多入口、共指同檔** | 多個入口名稱（CLAUDE.md / AGENTS.md / GEMINI.md）全部 symlink 至同一份規範本體 | 三檔皆指向 `AGENTS.md` 真檔 | context 文件、跨 CLI 共享規範 | **修一次、N 個 CLI 同步看到** |
>
> **本次 §2.2 的設計同時用兩種**：
> - **Skill 本體用 Mode A**：每個 skill 是獨立檔案 (`team/SKILL.md`, `build/SKILL.md`)，沒有 hub；各 CLI 直接讀目錄
> - **Context 文件用 Mode B**：`CLAUDE.md` / `AGENTS.md` / `GEMINI.md` 三個入口名都 symlink 至同一份 canonical（內容 100% 相同）
>
> **(C) Token 成本實測（你最關心的）**
>
> 假設要修改 `/team` skill：
>
> | 架構 | 需編輯的實體檔 | 修一個 skill 的 token 成本 |
> |---|---|---|
> | **本決策表（symlink）** | `sekai-workflow/team/SKILL.md` × 1 | **常數 1**（不論 N 個 CLI） |
> | 複製模式（per-CLI 變體） | `team/SKILL.md` × claude + cursor + codex + gemini | 4 倍（且漂移風險） |
> | per-platform 變體（§4.1.c） | `team.claude.md`, `team.codex.md`, `team.gemini.md` | 3 倍（DRY 違規） |
>
> **結論：本決策表的 Mode B（symlink 共指）正是為了把編輯成本壓到常數 1 而設計，完全對齊你的關切。**
>
> **(D) Canonical 改 `AGENTS.md` 的影響評估**
>
> 你的提議「`.agents/AGENTS.md` 為比較通用的指向」相當於翻 §5.1 的 `.a` → `.b`（AGENTS.md 升格 canonical）。
>
> | 面向 | canonical = `CLAUDE.md`（§5.1.a，原預填） | canonical = `AGENTS.md`（§5.1.b，你的提議） |
> |---|---|---|
> | 對齊 dotagents 慣例 | 中 | **強**（dotagents 預設用 AGENTS.md） |
> | 既有 28KB CLAUDE.md 內部「自指」引用 | 不需改（檔名仍存在，是 symlink） | 不需改（同上） |
> | 既有 skill 文件中的 `CLAUDE.md` 字面引用 | 不影響 | 不影響（symlink 透通） |
> | 平台中立感（檔名無 `CLAUDE` 字樣） | 弱 | **強** |
> | git mv 紀錄 | 無 | 一次 `git mv CLAUDE.md AGENTS.md`，保留 history |
> | 風險 | 0 | 低（rename 一次性，符號連結反向回 CLAUDE.md 即可） |
>
> **建議**：**接受你的提議**，正式翻 §5.1 為 `.b`：實體檔改為 `AGENTS.md`、`CLAUDE.md` 改為 symlink。請至 §5.1 將 `[x]` 從 `.a` 移到 `.b` 確認；若同意我直接翻請於下方補一行「✅ 翻 §5.1 → .b」。
>
> **(E) §1.2 移除 Cursor 已反映**：上方 link table 已移除 `~/.cursor/commands/` 與 `.cursorrules` 兩列。§5.2 的 Cursor 相關討論在實作階段直接 skip，不再作為決策點。
> ✅ 翻 §5.1 → .b

---

## §3 Symlink 機制（Windows 特化）

### §3.1 連結技術

- [ ] §3.1.a — **Symbolic Link**（`mklink` / `New-Item -ItemType SymbolicLink`）— 真正的符號連結，跨檔案/目錄通用。代價：**Windows 需 Developer Mode 或 Administrator**，否則建立失敗。
- [x] §3.1.b — **Directory Junction**（`mklink /J`）— 目錄專用、無權限要求。檔案級用 hard link（`mklink /H`）。優：零權限阻力。劣：junction 僅限同一 NTFS volume；hard link 無法跨 volume；無法 link 到 `~/.claude/CLAUDE.md`（檔案）若 volume 不同需 fallback symlink 或 copy。
- [ ] §3.1.c — **檔案複製 + git hooks 觸發同步**（pre-commit 重新複製）— 不依賴 OS link。代價：失去「即改即生效」、需多一層腳本維護。
- [ ] §3.1.d — **複製 + watcher 常駐**（chokidar / inotify）— 自動同步。代價：常駐程式資源 + 複雜度。
- [ ] 其他（填補充說明）

**補充說明：**
> 💡 預填建議：選 §3.1.b 為主、symbolic link 為 fallback。實作策略：platform-link 腳本先嘗試 junction（不需 admin），volume 不同或為檔案連結時 fallback 至 symbolic link，失敗則提示 user `Enable Developer Mode`。**避免 §3.1.c/d** — 既有 sp-sync.sh 已是「複製模式」，多平台層若再走複製路線會放大現有的同步漂移問題。

### §3.2 Linux/macOS 行為

- [x] §3.2.a — 一律使用 POSIX `ln -s`（symbolic link，無權限阻力）
- [ ] 其他

**補充說明：**
> 💡 預填建議：採預設。POSIX 環境完全無 Windows 那層權限痛點，腳本以 `case "$(uname -s)"` 分支即可。

---

## §4 Slash 命令格式相容性

### §4.1 各 CLI 對 SKILL.md frontmatter 的處理

現況：Claude Code 解析 `model` / `effort` / `argument-hint` / `allowed-tools` 等欄位；其他 CLI 通常**視 frontmatter 為文件 metadata 或忽略**。

- [x] §4.1.a — **保持 Claude 完整 frontmatter**：其他 CLI 載入時 frontmatter 變為純文字 prefix（無害但畫面雜訊）；命令本體仍可執行。優：單一規範檔。劣：Cursor/Codex 等使用者首次看到會有疑惑。
- [ ] §4.1.b — **frontmatter 移至註解區段**：用 HTML comment `<!-- ... -->` 包裹 Claude-specific metadata，其他 CLI 完全不顯示。代價：Claude Code 需確認仍能解析（**可能要客製 hook 或不能採用**）。
- [ ] §4.1.c — **per-platform 變體**：在 `.agents/commands/` 為各 CLI 產生不同檔案（`team.claude.md`, `team.cursor.md`），symlink 時挑對應檔。代價：違反 §1.1 單檔規範。
- [ ] 其他（填補充說明）

**補充說明：**
> 💡 預填建議：選 §4.1.a — 對齊 dotagents 慣例（dotagents 也保留 frontmatter）。Cursor / Codex / Gemini 對開頭 `---` block 普遍能容忍，會視為文字。文件中加一段「為何前面有 YAML」的說明即可。**§4.1.b 風險**：Claude Code 是否會解析 HTML comment 中的 metadata 我不確定，需先實測一個 sample skill；若無法解析則否決此選項。

### §4.2 步驟式 SKILL.md 在 Cursor/Gemini 的執行

現實：Claude Code 的 `### Step N:` 結構是 prompt-as-instruction；其他 CLI 把整份檔案塞進 system prompt — 多步驟 / Tool 呼叫 / Sub-agent 等行為**會弱化或失敗**。

- [x] §4.2.a — **誠實標註**：在每個 skill 的 SKILL.md `frontmatter` 加 `platforms: [claude, cursor, ...]` 欄位，platform-link 腳本依此**只把對應 skill link 進對應 CLI**。複雜 skill（如 `/commit-push`、`/build`）保留 Claude-only。
- [ ] §4.2.b — **全平台一律安裝、執行時自然弱化**：使用者自行體會差異。
- [ ] §4.2.c — **重寫所有 skill 為平台中立**：去除 Tool/Agent 假設。代價極高、放棄 Claude 進階能力。
- [ ] 其他（填補充說明）

**補充說明：**
> 💡 預填建議：選 §4.2.a。每個 skill 在 SKILL.md frontmatter 加一行 `platforms:`，platform-link 腳本讀取後只 link 至支援的 CLI 命令目錄。**初版建議**：`team`/`commit-push`/`build`/`skm`/`ask`/`clean` 標 `claude-only`；`memo`/`dispatch` 視能力評估；通用文字輸出類（如未來新增的 readme generator）標全平台。最終各 skill 的 platforms 清單在實作階段個別評估。

---

## §5 Context File（CLAUDE.md / AGENTS.md / GEMINI.md）統一

### §5.1 規範檔（canonical）放哪

- [ ] §5.1.a — 規範檔保持 project-root `CLAUDE.md`（現狀），其他平台 context 檔（`AGENTS.md`, `GEMINI.md`）為**指向它的 symlink**，內容完全一致。
- [x] §5.1.b — 規範檔升格為 `AGENTS.md`（dotagents 模型），`CLAUDE.md` 改為 symlink。代價：所有現存 `CLAUDE.md` 引用、Memory 路徑、文件需大規模搜改。**（依 §2.2 補充說明 user 指示翻面 .a → .b）**
- [ ] §5.1.c — 三檔分別維護，內容部分共用（dotagents fallback 模型）。代價：同步漂移風險。
- [ ] 其他（填補充說明）

**補充說明：**
> 💡 預填建議：選 §5.1.a。當前 `CLAUDE.md` 是 28KB 的核心規範，所有 reference 路徑 / Skill 文件 / Memory entries 全部指向它，貿然改名/搬遷風險極高。symlink AGENTS.md → CLAUDE.md 即可達到 dotagents 多平台目標而零破壞。`GEMINI.md` 同理。

### §5.2 Cursor 的 `.cursorrules` 處理

- [ ] §5.2.a — 在 `.agents/` 中建立 `.cursorrules` symlink → `CLAUDE.md`，Cursor 自動讀取
- [x] §5.2.b — 跳過 `.cursorrules`，僅依賴 Cursor 對 `AGENTS.md` 的支援（若 Cursor 版本足夠新）
- [ ] §5.2.c — 兩者都建（雙保險）
- [ ] 其他（填補充說明）

**補充說明：**
> 💡 預填建議：選 §5.2.b 為主、§5.2.c 為次選。Cursor 較新版本支援 `AGENTS.md`；若你使用的版本不支援、或仍偏好傳統 `.cursorrules`，回填 §5.2.c。我沒有使用cursor的習慣，可以移除
>
> 📝 **Claude 回應（2026-05-08）— 確認移除 Cursor 全線決策點**
>
> 與 §1.2 一致：`.cursorrules`、`~/.cursor/commands/` 路徑全部不建立。§5.2 整節在實作階段 skip，platform-link 腳本不偵測 Cursor。日後若使用習慣改變，重新加回成本低（在 §12 final 架構保留 hook 點供未來擴充）。

---

## §6 Hooks / Memory 跨平台處理

### §6.1 Hooks（`.cjs` 檔，Claude Code 專屬）

- [x] §6.1.a — **Claude-only**：platform-link 腳本只在偵測到 `~/.claude/` 時 link `hooks/`，其他平台完全不安裝、文件清楚標示「Claude 專屬」
- [ ] §6.1.b — 嘗試移植至他平台（如 Cursor 的 `.cursor/extensions/`）— **不確定可行性**
- [x] §6.1.c — 重寫為平台中立 shell 腳本（git hook 或 task runner）
- [x] 其他（填補充說明）

**補充說明：**
> 💡 預填建議：選 §6.1.a。Hooks 深度依賴 Claude Code 的 PreToolUse/PostToolUse/Stop 事件機制，他平台目前沒有對等抽象；勉強移植會變成半殘功能。明確標 Claude-only，未來他平台支援 hooks 再評估。採用C但保留claude only避免hook遺失
>
> 📝 **Claude 回應（2026-05-08）— 確認 Hybrid 策略：原 .cjs hooks 不動，另寫 portable shell 雙軌並行**
>
> 解讀「採 C 但保留 Claude only 避免 hook 遺失」=**雙軌策略**：
>
> | 軌道 | 位置 | 角色 | 觸發條件 |
> |---|---|---|---|
> | **既有 Claude-only hooks** | `sekai-workflow/hooks/*.cjs` | 不動，繼續走 Claude `PreToolUse/PostToolUse/Stop` | 僅 Claude Code |
> | **Portable hooks（新增）** | `sekai-workflow/hooks/portable/*.sh` 或 git hooks | 寫平台中立邏輯（檢查 commit 訊息、提醒、log） | 各 CLI 各取所需 + git hook 共用 |
>
> **逐 hook 評估（Stage 2 細項）**：
> - `check_yn_question.cjs`：純文字檢測 → 可移植為 git pre-commit hook
> - `check_context_reminder.cjs`：依賴 Claude session state → **保留 Claude-only**
> - `check_skill_sync.cjs`：偵測 skill 漂移 → 可移植為獨立 CLI 命令（`sekai-workflow check-sync`）
> - `log_agent_dispatch.cjs`：寫 `.local/model_dispatch.log` → 依賴 Claude Agent tool，**保留 Claude-only**
> - `memory_skill_sync.cjs`：依賴 Claude Memory write event → **保留 Claude-only**
> - `inject_context_on_resume.cjs`：依賴 Claude UserPromptSubmit → **保留 Claude-only**
>
> 結論：6 個 hook 中 **2 個可移植**（`check_yn_question`, `check_skill_sync`）、4 個 Claude-only。Stage 2 處理 portable rewrite。

### §6.2 Memory（`~/.claude/projects/<path>/memory/`，Claude Code 專屬）

- [ ] §6.2.a — **Claude-only**，不跨平台
- [x] §6.2.b — 在 `.agents/memory/` 維護一份共用版（純 Markdown），Claude Memory 改為 symlink 至此（複雜：Claude Memory 路徑為 absolute home dir，需 platform-link 腳本處理）
- [ ] §6.2.c — pack 時把 Memory 匯出為 plain text，他平台 import 時手動載入
- [ ] 其他（填補充說明）

**補充說明：**
> 💡 預填建議：選 §6.2.a。Memory 是 Claude Code 的獨家 file-based 持久化機制，他平台沒有對應 API。若有跨平台需求，先用 `/memo pack` 導出 + 手動帶到他平台 system prompt 即可，無需架構變動。
>
> 📝 **Claude 回應（2026-05-08）— 確認 §6.2.b 翻面：Memory 共用化**
>
> 偏離預設處 — user 主動翻至 .b（共用 memory），重要影響：
>
> **架構**：
> ```
> .agents/memory/                              ★ 共用 memory 真檔
> ├── MEMORY.md                                (索引)
> ├── feedback_*.md, project_*.md, ...         (各條目)
> └── README.md                                (跨平台說明)
>
> ~/.claude/projects/<path>/memory/   ───symlink───→  <proj>/.agents/memory/
> ~/.gemini/memory/<proj>/             ───symlink───→  <proj>/.agents/memory/  (若 Gemini 支援)
> ~/.codex/memory/<proj>/              ───symlink───→  <proj>/.agents/memory/  (若 Codex 支援)
> ```
>
> **複雜度警示（要 user 知曉）**：
> 1. **Claude Memory 路徑為 absolute** — `~/.claude/projects/<path-encoded>/memory/`，路徑 encode 規則（如 D--hanschen-personal-work-sekai-workflow-edit）需 platform-link 腳本處理
> 2. **記憶體初次建立時** Claude Code 自動建目錄；改 symlink 需先 `rm -rf` 既有真目錄（**會破壞當前 Memory**），須先 `cp -r` 至 `.agents/memory/` 再建 symlink
> 3. **Codex / Gemini 是否支援 file-based memory** — 兩者目前都沒有官方 Claude-style memory 機制；symlink 至他平台 home 目錄純粹為「資料就緒」，他平台**不會自動讀取** — 需各 CLI 在 system prompt / config 中手動 include
>
> **Stage 影響**：原 Stage 2 多一節「Memory 共用化遷移」，需 user 在執行該步驟時專門確認（含一次 Memory 備份）。
>
> **建議降級選項**（若 Stage 2 評估太風險）：先做 §6.2.b 的「Phase 1」=只把 Claude Memory 透過 symlink 集中至 `.agents/memory/`（單方向），他平台讀取機制等實際使用 Codex/Gemini 時再評估。完整雙向同步列為未來嘗試項。

---

## §7 安裝器與 Bootstrap 重塑（Rule 23 必檢）

### §7.1 sp-init.bat / sp-sync.sh / sp-pack.sh / sp-verify.bat 影響

實作後的腳本職責變化：

| 腳本 | 現狀 | 重構後 |
|---|---|---|
| `sp-init.bat` | 複製 `sekai-workflow/<skill>/` → `.claude/skills/<skill>/` | 改為呼叫新增的 `sp-platform-link.sh`（建立 `.agents/` symlink 樹），保留 `--legacy` 旗標走舊複製模式 |
| `sp-sync.sh` | `git pull` + 比對 + 複製 | `git pull` 後**檢查 symlink 完整性**；不再複製檔案（symlink 自動同步） |
| `sp-pack.sh` | 收集 + 刪除 `.claude/skills/`、`sekai-workflow/`、`CLAUDE.md` | 收集後解除 symlink 並還原 — 需處理 dangling link 風險 |
| `sp-verify.bat` | 檢查目錄存在 + 檔案 hash | 加入 symlink target 驗證、CLI 偵測、跨平台 link 完整性 |
| `sp-platform-link.sh` | （新增） | 核心 — 偵測各 CLI 安裝狀態並建立對應 symlink/junction，支援 `--platform <list>`、`--dry-run`、`--undo` |

- [x] §7.1.a — 採上表方案，新增 `sp-platform-link.sh` 為主控、現有腳本改寫為呼叫它
- [ ] §7.1.b — 不新增腳本，把 link 邏輯併入 `sp-init.bat`
- [ ] §7.1.c — 全面棄用現有腳本，改採 dotagents NPM 套件路線（`npx @iannuttall/dotagents`）
- [ ] 其他（填補充說明）

**補充說明：**
> 💡 預填建議：選 §7.1.a。新增專責腳本 + 改寫現有腳本職責 — 比併入 sp-init.bat 清晰，比改 NPM 路線改動小。**§7.1.c 風險**：dotagents 是 ian 個人套件，依賴外部上游、與本專案的 `manifest.json` / `_bootstrap/` 慣例不對齊；建議僅參考其設計、不直接依賴。

### §7.2 manifest.json 擴充

加入欄位：
- 每個 skill `platforms: [claude, cursor, codex, gemini]`（決定哪些 CLI 該 link）
- 每個 skill `requires_hooks: bool`（hook 依賴標示，他平台 skip）
- top-level `platform_targets:` 描述各 CLI 的安裝路徑慣例

- [x] §7.2.a — 採上述擴充
- [ ] §7.2.b — 不擴充 manifest，platforms 欄位放在每個 SKILL.md frontmatter
- [ ] §7.2.c — 雙寫（manifest + frontmatter）
- [ ] 其他（填補充說明）

**補充說明：**
> 💡 預填建議：選 §7.2.b — 每個 skill 自帶 platform 欄位，single source of truth；manifest 透過程式產生匯總。**§7.2.a 與 §7.2.b 二擇一**：a 容易漂移、b 較 DRY。但若你偏好集中管理（一個檔看完所有 skill 平台支援度）→ a；若偏好分散自治 → b。**預填 b** 但若你常需要全域檢視 → 改 a。
>
> 📝 **Claude 回應（2026-05-08）— 確認 §7.2.a：採 frontmatter 為 source、manifest 自動匯總**
>
> 為避免漂移，採「**SKILL.md frontmatter = 唯一寫入點、manifest.json = 程式自動生成索引**」：
>
> 1. 每個 skill 在 SKILL.md frontmatter 加 `platforms: [claude, codex, gemini]`（per §4.2.a）
> 2. `_bootstrap/sp-platform-link.sh` 啟動時 `grep -r "^platforms:"` 各 skill SKILL.md，匯總後寫入 `manifest.json` 的 `platforms_index:` 欄位
> 3. Manifest 欄位**唯讀**，CLAUDE 與 user 改的都只是 frontmatter；manifest 透過 sp-sync 重生
>
> 此模式同時滿足你的「集中檢視」需求（manifest 提供全局視圖）與 §4.2.a 的 frontmatter 標註。**§7.2.c 雙寫被排除**（漂移風險）。

---

## §8 遷移節奏

### §8.1 推進策略

- [ ] §8.1.a — **大爆炸**：一次完成 `.agents/` 建立 + 所有 skill platforms 標註 + 所有 sp-* 腳本改寫 + 移除舊路徑 — 一輪 commit
- [x] §8.1.b — **三階段**：①建 `.agents/` symlink 層（不破壞現有）→ ②各 skill 標 `platforms:` + sp-platform-link.sh → ③改寫 sp-init/sp-sync 為新模式並提供 `--legacy` 兼容旗標。每階段獨立 commit + 驗收
- [ ] §8.1.c — **實驗分支**：在 `multi-platform` branch 推進、main 不動，驗證滿意後再 merge
- [ ] 其他（填補充說明）

**補充說明：**
> 💡 預填建議：選 §8.1.b。三階段對應三個 PR / commit batch，每階段都可單獨 rollback。第一階段最小（只新增）、第二階段中度（標 metadata + 新腳本）、第三階段最大（改寫安裝邏輯）。**§8.1.c 在當前 sekai-workflow 已 force-pushed 過的狀態下風險中等** — 若你希望嚴格隔離可選 c。

### §8.2 向下相容窗口

- [ ] §8.2.a — `sp-init.bat --legacy` 維持舊複製行為，三個月後移除
- [ ] §8.2.b — 立即切換、不保留 legacy
- [x] §8.2.c — 永久保留 legacy 旗標
- [ ] 其他（填補充說明）

**補充說明：**
> 💡 預填建議：選 §8.2.a。給仍在用舊安裝模式的個人專案緩衝期；三個月後若無問題即清理。
> 請確認我的目的，專案現在以Claude Code習慣為主，但根據跨平台需求和多agent實做需要更通用的skill適配更多的模型(opencode platform, gemini cli, codex cli)我需要一個清楚的清單何架構管理這些skill並且通用，需要具備易維護、跨平台、持續學習的特性，請根據這些性質進一步處理並提供詳細的清單跟我做最終修改確認

---

## §9 跨專案攜帶與 Memory 連動

### §9.1 `/memo` skill 是否受影響

`/memo` 目前負責 `~/.claude/projects/<path>/memory/` 隨 Sekai_workflow git 攜帶。

- [x] §9.1.a — `/memo` 行為不變（Claude-only）
- [ ] §9.1.b — `/memo` 增加 `--platform <name>` 旗標，匯出至 `.agents/memory/<platform>.md` 供他平台手動載入
- [ ] §9.1.c — 重寫 `/memo` 為平台中立
- [ ] 其他（填補充說明）

**補充說明：**
> 💡 預填建議：選 §9.1.a。Memory 跨平台支援列為**未來嘗試項**（依 Rule 17.1.7 進 TODO Pending），先聚焦此次 multi-platform 重構的核心：commands/skills 的 symlink 化。

---

## §10 文件 / CLAUDE.md 規則更新

### §10.1 是否新增 CLAUDE.md Rule 26（多平台規則）

- [x] §10.1.a — 新增 Rule 26「Multi-platform skill portability」，涵蓋 platforms frontmatter 欄位、symlink 機制要求、新 skill 必填 platforms 標註、CI 驗證 link 完整性
- [ ] §10.1.b — 不新增 Rule，僅在 `skm/SKILL.md` 與 `_bootstrap/` 文件描述
- [ ] §10.1.c — 寫入 `handbook/multi-platform.md` 作為技術筆記
- [ ] 其他（填補充說明）

**補充說明：**
> 💡 預填建議：選 §10.1.a + §10.1.c（Rule 為強制規範、handbook 為技術細節）。本決策表結案後同步寫入 RENAME_HISTORY.md（若有目錄 rename）與 handbook。

---

## §11 結案與下一步

### §11.1 採納全部預設方案的後續行動清單（自動產生）

若全部沿用 `[x]` 預填，實作分三階段：

**Stage 1（低風險，最小可行）**
1. 解 §0.1 sekai-workflow remote 分歧（`git diff --stat` 比對 + 必要時 hard reset）
2. 在 project root 建 `.agents/` 目錄，建立指向 `sekai-workflow/` / `CLAUDE.md` 的 symlink/junction
3. 新增 `AGENTS.md` symlink → `CLAUDE.md`、`GEMINI.md` symlink → `CLAUDE.md`
4. 新增 `_bootstrap/sp-platform-link.sh` 雛型（僅支援 Claude，已存在則跳過）
5. 加入 TODO：「未來嘗試 /memo 跨平台 export」

**Stage 2（核心功能）**
6. 為每個 skill 在 SKILL.md frontmatter 加 `platforms:` 欄位（個別評估）
7. 完整實作 `sp-platform-link.sh`：偵測 Cursor / Codex / Gemini 安裝、建立對應 symlink
8. `sp-verify.bat` 加入 symlink 完整性檢查
9. 各 skill `README.md` 加「相容平台」段落

**Stage 3（清理與文件）**
10. `sp-init.bat` 加 `--legacy` 旗標、預設改呼叫 `sp-platform-link.sh`
11. `sp-sync.sh` 移除複製邏輯、改為 link verification
12. `sp-pack.sh` 加 dangling link 處理
13. CLAUDE.md 新增 Rule 26（多平台規則）
14. `handbook/multi-platform.md` 寫入技術筆記
15. `_bootstrap/RENAME_HISTORY.md` 不更新（無 rename）

每階段結束 commit & push（依 flowback.push 開關）。

- [ ] §11.1.a — 採此清單
- [x] §11.1.b — 採此清單，但**回覆 OK 後 Claude 重讀並再次列出每階段細項供你檢視**才動手
- [ ] §11.1.c — 不採；先看修正後的清單再決定
- [ ] 其他（填補充說明）

**補充說明：**
> 💡 預填建議：選 §11.1.b — 重要架構變動，每階段開工前再確認一次。Stage 1 完成後我會主動暫停、待你檢查 `.agents/` 結構與 link 是否合預期，再進 Stage 2。

---

## §12 最終架構清單與最終確認（2026-05-08 補增）

> **觸發**：使用者於 §8.2 補充說明明確要求「**請根據這些性質進一步處理並提供詳細的清單跟我做最終修改確認**」，三特性指明：**易維護 / 跨平台 / 持續學習**。
>
> 整合本表所有已確認決策（含偏離預設處），列出最終架構視圖、特性對應、平台支援矩陣、修訂後 Stage 清單，與最後 OK 閘門。**這是實作前最後一個確認點**。

### §12.1 最終架構圖（整合所有已確認決策）

```
sekai-workflow-edit/                                ← 主專案 git repo
├── AGENTS.md                                       ★ canonical 規範（原 CLAUDE.md，§5.1.b）
├── CLAUDE.md                       → symlink ───→  AGENTS.md
├── sekai-workflow/                                 ★ skill 規範本體（保留原名，§2.1.b）
│   ├── _bootstrap/
│   │   ├── sp-init.bat                             (重寫，加 --legacy 永久保留 §8.2.c)
│   │   ├── sp-sync.sh                              (重寫，僅做 link verify)
│   │   ├── sp-pack.sh                              (加 dangling-link safe handling)
│   │   ├── sp-platform-link.sh                     (新增主控，§7.1.a)
│   │   └── sp-verify.bat                           (加 link integrity check)
│   ├── manifest.json                               (加 platforms_index 自動匯總，§7.2.a)
│   ├── handbook/multi-platform.md                  (新增，§10.1.c)
│   ├── hooks/                                      (.cjs 不動 + portable/ 新增，§6.1.c hybrid)
│   │   ├── check_yn_question.cjs                   (Claude-only)
│   │   ├── check_skill_sync.cjs                    (Claude-only)
│   │   ├── ... (其他 .cjs)                         (Claude-only)
│   │   └── portable/                               ★ 新增
│   │       ├── check_yn_question.sh                (移植版，git pre-commit)
│   │       └── check_skill_sync.sh                 (移植版，CLI 命令)
│   └── <每個 skill>/SKILL.md                       (frontmatter 加 platforms: [...]，§4.2.a)
│
├── .agents/                                        ◇ 純 symlink 對接層（§2.1.b）
│   ├── skills/   ─── junction ─→  ../sekai-workflow/
│   ├── hooks/    ─── junction ─→  ../sekai-workflow/hooks/
│   ├── memory/                                     ★ 共用 memory 真檔（§6.2.b）
│   │   ├── MEMORY.md
│   │   ├── feedback_*.md, project_*.md, ...
│   │   └── README.md
│   ├── AGENTS.md ─── symlink ─→  ../AGENTS.md
│   ├── CLAUDE.md ─── symlink ─→  ../AGENTS.md     (兩個 symlink 指同一真檔)
│   └── GEMINI.md ─── symlink ─→  ../AGENTS.md     (三個 symlink 指同一真檔)
│
├── .hanschen/                                      (跨機器共享文件，已存在)
└── .local/                                         (機器專屬 state，已存在)

外部對接（platform-link 安裝後）：
~/.claude/skills/                ─ junction ─→  <proj>/.agents/skills/
~/.claude/hooks/                 ─ junction ─→  <proj>/.agents/hooks/
~/.claude/projects/<enc>/memory/ ─ symlink  ─→  <proj>/.agents/memory/    (§6.2.b)
~/.codex/prompts/                ─ junction ─→  <proj>/.agents/skills/    (skill platforms 含 codex)
~/.gemini/commands/              ─ junction ─→  <proj>/.agents/skills/    (skill platforms 含 gemini)
project-root AGENTS.md (Codex 通讀，已是真檔)
project-root GEMINI.md           ─ symlink  ─→  AGENTS.md                (Gemini CLI 期望)
```

### §12.2 平台清單再確認（§1.2 vs §8.2 補充說明衝突）

§8.2 補充說明文字提到「opencode platform」但 §1.2.f OpenCode 未勾選。請二擇一：

- [ ] §12.2.a — 維持 §1.2 現勾選（Claude / Codex / Gemini，**不含 OpenCode**），OpenCode 列入 TODO 未來嘗試項
- [x] §12.2.b — **加入 OpenCode 為首發平台**之一（與 Codex / Gemini 並列），platform-link 腳本含 `~/.config/opencode/commands/` 偵測
- [ ] §12.2.c — 加入 OpenCode 但僅做檔案就緒、不做 symlink 偵測（保留入口）
- [ ] 其他（填補充說明）

**補充說明：**
> 💡 預填建議：選 §12.2.b。你的 §8.2 文字明確列舉「opencode platform, gemini cli, codex cli」三者並列；§1.2.f 未勾選可能只是 §1.2 階段考慮不足。OpenCode 的 commands path（`~/.config/opencode/commands/`）已在 dotagents 列表，加入成本低（多一行偵測），不加成本是「日後再加要重跑 platform-link」。**若你日常確實不用 OpenCode，回 .a**；若使用或計畫用，建議 .b 一次到位。

### §12.3 三特性 ↔ 架構決策對應表（user 指定的三特性檢核）

| 特性 | 對應決策 | 實作要點 | 持續性保障 |
|---|---|---|---|
| **易維護**（low maintenance） | §1.1.a + §2.1.b + §5.1.b | symlink (Mode B) 編輯成本常數 1；canonical 唯一檔 (`AGENTS.md`)；manifest 自動匯總（§7.2.a） | 修任何 skill / context 一次同步全 CLI |
| **跨平台**（cross-platform） | §1.2 + §2.2 + §3.1.b + §4.2.a | `.agents/` 對接層；junction 主 / symlink fallback；skill frontmatter `platforms:` selective link；OpenCode hook 點（§12.2 待定） | 加新 CLI 只需擴 `sp-platform-link.sh` 一個函數 |
| **持續學習**（continuous evolvement） | §7.1.a + §7.2.a + §8.1.b + §10.1.a | `sp-platform-link.sh` 集中邏輯；manifest 自動匯總 platforms；三階段獨立 commit 可單獨 rollback；CLAUDE.md Rule 26 強制新 skill 標 platforms | 加新 skill 自動繼承跨平台能力（直接出現在所有 CLI），無需逐一手動 link |

**易維護驗證**：修一行 `team/SKILL.md` → `~/.claude/skills/team/SKILL.md`、`~/.codex/prompts/team/SKILL.md`、`~/.gemini/commands/team/SKILL.md`、`~/.config/opencode/commands/team/SKILL.md` 全部立即生效（OS 解析同一 inode）。

**跨平台驗證**：未來新增 platform X，只需在 `sp-platform-link.sh` 加 `link_to_platform "X" "$HOME/.X/commands"`，所有現有 skill 含 `platforms: [..., x]` 自動就位。

**持續學習驗證**：新 skill `foo/` 加入 `sekai-workflow/foo/SKILL.md`（含 `platforms: [...]`）→ 下次 `sp-sync.sh` 跑 → `manifest.json` 自動匯總 → `sp-platform-link.sh` 偵測新 skill → 各 CLI 命令目錄自動出現 `foo`。**零手動干預**。

### §12.4 修訂後 Skill Platform 矩陣（初版分類，可在 Stage 3 個別微調）

| Skill | 預設 platforms | 理由 |
|---|---|---|
| `build` | `[claude]` | 重度 Tool/Agent + 多 sub-agent |
| `team` | `[claude]` | AskUserQuestion + 多步驟 + 自動 hook |
| `skm` | `[claude]` | 同上 |
| `commit-push` | `[claude]` | 多 sub-agent + 流水線 |
| `ask` | `[claude]` | Tool/Agent for trace |
| `clean` | `[claude]` | /clear 整合 |
| `memo` | `[claude]` | Memory dependent |
| `dispatch` | `[claude]` | Agent tool only |
| `kb` | `[claude, codex, gemini, opencode]` | 純文字 KB add/search/extract，多平台可用 |
| `hello` | `[claude]` | 多步驟初始化 |

**首發跨平台 skill：`/kb`**（最單純的純文字 input/output，最適合驗證 multi-platform link 是否正常）

**其餘 9 個 skill 後續評估**：取決於 Codex / Gemini / OpenCode 對「步驟式 prompt」「系統工具呼叫」的支援度，留待 Stage 3 個別測試後微調。

### §12.5 修訂 Stage 清單（依使用者實際選擇）

#### Stage 1 — 低風險新增（純 additive，零破壞）

1. 解 §0.1 sekai-workflow remote 分歧：`git diff origin/main..HEAD --stat`，若 0 byte 差異直接 `git reset --hard origin/main`
2. **AGENTS.md 升 canonical**：`git mv CLAUDE.md AGENTS.md` 於主專案 root；保留 git history
3. 建 symlink `CLAUDE.md` → `AGENTS.md`（PowerShell `New-Item -ItemType SymbolicLink` 或 `mklink` 需 Dev Mode）
4. AGENTS.md 開頭加 multi-platform disclaimer（一段 50 字說明此檔為各 CLI 共用）
5. 建 `.agents/` 目錄結構：`junction skills/`、`junction hooks/`、`symlink AGENTS.md/CLAUDE.md/GEMINI.md`
6. 建 `_bootstrap/sp-platform-link.sh` stub：先只支援 Claude，其他平台預留 TODO
7. 開 TODO Pending：「Stage 2-5 細項」、「OpenCode 加入評估（若 §12.2 選 .a）」、「Memory 共用 Phase 2 雙向同步」

**Stage 1 暫停點**：建立完成後 user 檢查 `.agents/` 結構與符號連結正確，再進 Stage 2。

#### Stage 2 — Memory 共用化（重點高風險步驟）

8. 備份既有 Claude Memory：`cp -r ~/.claude/projects/<enc>/memory/ .local/memory_backup_pre_stage2/`
9. 將 memory 真檔搬至 `.agents/memory/`：`mv ~/.claude/projects/<enc>/memory/* <proj>/.agents/memory/`
10. 建 symlink：`~/.claude/projects/<enc>/memory/` → `<proj>/.agents/memory/`
11. 驗證：開新 Claude 對話寫入新 memory entry，確認 file 寫到 `.agents/memory/`
12. 寫 `.agents/memory/README.md` 跨平台使用說明

**Stage 2 暫停點**：user 確認 Memory 寫入正常無漂移，才進 Stage 3。

#### Stage 3 — Skill metadata + 完整 platform link

13. 為 `kb` skill SKILL.md 加 `platforms: [claude, codex, gemini, opencode]`（如 §12.2 含 opencode）
14. 為其他 9 個 skill 加 `platforms: [claude]`
15. 完整實作 `sp-platform-link.sh`：偵測 `~/.codex/prompts/`、`~/.gemini/commands/`、`~/.config/opencode/commands/` 存在性，建立對應 junction
16. 跑 `sp-platform-link.sh --dry-run` 給 user 看 plan
17. user 確認後跑 actual link
18. 各 skill `README.md` 加「相容平台」段落

**Stage 3 暫停點**：user 在 Codex / Gemini / OpenCode 任一 CLI 嘗試呼叫 `/kb`，確認可運作。

#### Stage 4 — Bootstrap rewrite + Hook hybrid

19. `sp-init.bat` 重寫：default → 呼叫 `sp-platform-link.sh`；加 `--legacy` 永久保留複製模式（§8.2.c）
20. `sp-sync.sh` 重寫：移除複製邏輯，改為 link verification + manifest 重生
21. `sp-pack.sh` 重寫：解除 symlink/junction 安全；dangling link 檢測
22. `sp-verify.bat`：加 symlink target 驗證、CLI 偵測、跨平台 link 完整性
23. **Hook hybrid 實作**：
    - `hooks/portable/check_yn_question.sh`（POSIX shell 版，git pre-commit 使用）
    - `hooks/portable/check_skill_sync.sh`（CLI 命令版）
    - 既有 6 個 `.cjs` 不動

**Stage 4 暫停點**：user 跑一次 `sp-verify.bat` 看全部綠燈。

#### Stage 5 — 文件結案

24. CLAUDE.md（即 AGENTS.md）新增 Rule 26「Multi-platform skill portability」（§10.1.a）
25. 寫 `sekai-workflow/handbook/multi-platform.md`（§10.1.c）
26. 不更新 `_bootstrap/RENAME_HISTORY.md`（無目錄 rename — `sekai-workflow/` 保留原名；CLAUDE.md → AGENTS.md 是檔案 rename，於 `RENAME_HISTORY.md` 加一行記錄）
27. 本決策表結案：append 內嵌摘要 → rename 為 `CLOSED_260508_multi_platform_skill_refactor_decision.md`
28. 結案訊息 append `PROJECT_JOURNAL.md`
29. 未解決遺留項 append `TODO.md` Pending（OpenCode 評估、Memory 雙向同步、其他 skill 跨平台 enable 等）
30. 整體 commit & push（依 flowback.push 開關，每階段一個 commit）

### §12.6 風險回顧（Stage by Stage）

| Stage | 主要風險 | 回滾方法 |
|---|---|---|
| 1 | symlink 建立失敗（Windows 無 Dev Mode）→ junction fallback | `rmdir .agents/` + `git mv AGENTS.md CLAUDE.md` |
| 2 | Memory 搬遷時 Claude Code 正在寫入 → race condition | 備份 + 暫停 Claude Code session 再執行 |
| 3 | Codex / Gemini / OpenCode 不支援目錄式 commands → link 無效 | platform-link 加 `--undo` flag，逐一移除 link |
| 4 | sp-init/sp-sync 改寫破壞既有專案 → `--legacy` 旗標保住 | 永久保留 legacy（§8.2.c）作為 escape hatch |
| 5 | Rule 26 與既有規則衝突 → CLAUDE.md 規則編號重排 | 在 §10 採納時即排好編號（Rule 25 已用，Rule 26 next） |

### §12.7 最後 OK 閘門

- [x] §12.7.a — **採此最終清單**（含 §12.2 OpenCode 加入 / §12.3 三特性對應 / §12.5 五階段 Stage 清單），回覆「OK」即進 Stage 1 第 1 步（git diff 比對）。每階段結束暫停確認再進。
- [ ] §12.7.b — 採清單但僅做 Stage 1（最小可行 .agents/ 對接層）即停，Stage 2-5 列入 TODO Pending 日後再做
- [ ] §12.7.c — 進一步調整（補充說明指明改動）
- [ ] 其他（填補充說明）

**補充說明：**
> 💡 預填建議：選 §12.7.a。完整五階段對齊你的三特性需求；§11.1.b 已保證每階段確認，回滾單位最小化。**§12.7.b 是低投入選項**：若你想先驗證 .agents/ 對接層概念可行再決定是否做 Memory 共用化（最高風險步驟），可選 .b。**§12.7.c** 給你保留任意調整空間。

---



使用者回覆「OK / 完成」後：

1. **解析勾選與補充說明**，列出採納方案摘要與本表偏離預設處
2. 依 §0.1 結論先處理 sekai-workflow remote 分歧
3. 依 §11.1 結論進入 Stage 1 實作（或等待二次確認）
4. **本檔結案**：依 Rule 17 規範
   - 末尾 append 內嵌結案摘要（最終決策表 + 變更清單 + 🔖 保留候選）
   - rename 為 `CLOSED_260508_multi_platform_skill_refactor_decision.md`
   - 結案訊息 append 至 `PROJECT_JOURNAL.md`
5. **未解決遺留項** auto-append 至 `TODO.md` Pending（Rule 17.1.4 擴充）
6. **handbook entry**（若 §10.1.c 採納）寫入 `sekai-workflow/handbook/multi-platform.md`

---

> 📌 **目前狀態**：等待使用者勾選確認。所有 `[x]` 為 Claude 預填建議，使用者可任意改動。回覆「OK」即代表沿用當前勾選狀態。

---

# 📋 結案摘要（2026-05-08，內嵌於本檔末尾，永久保留）

> 結案模式：**規劃結案**（Stage 1-5 實作未開工，本檔為決策定案 + beta 分支已建立 + 計畫文件就位的里程碑）
> 結案後動作：本檔 rename 為 `CLOSED_260508_multi_platform_skill_refactor_decision.md`、PROJECT_JOURNAL append 索引、TODO.md Pending append 遺留項、sekai-workflow `beta/multi-platform-refactor` 分支鏡像歸檔。

## 背景

使用者透過 `/skm refactor all` 啟動 sekai-workflow 多平台擴展計畫，參照 [iannuttall/dotagents](https://github.com/iannuttall/dotagents) 的「單一規範檔、多 CLI symlink 別名」設計理念。核心訴求三特性：**易維護、跨平台、持續學習**；明確排除「為各 CLI 改檔名」的方案。

## 最終決策表（17 個決策塊整合）

| § | 採納方案 | 偏離預設處 | user 關鍵補充 |
|---|---|---|---|
| §0.1 | b（先 git diff 比對） | — | 實際透過 beta 分支從 origin/main 起點，自動含遠端 2 個新 commit |
| §1.1 | a（檔名語意 — symlink 多名共指） | — | — |
| §1.2 | a / c / d（Claude / Codex / Gemini） | **移除 Cursor** | §8.2 補充說明後另確認 OpenCode 也加入（§12.2.b） |
| §2.1 | b（混合：保留 sekai-workflow + 新增 .agents/） | — | — |
| §2.2 | a + b（採預設 + 自訂） | 移除 Cursor 列、AGENTS.md 升 canonical | 提問「token 編輯成本」「link 機制」「Mode A vs B」並接受 §5.1 翻面提議 |
| §3.1 | b（Windows junction 主、symlink fallback） | — | — |
| §3.2 | a（POSIX ln -s） | — | — |
| §4.1 | a（保留完整 frontmatter） | — | — |
| §4.2 | a（per-skill platforms 欄位） | — | — |
| §5.1 | **b（AGENTS.md 升 canonical）** | **翻 .a → .b** | 透過 §2.2 補充說明指示翻面 |
| §5.2 | b（skip .cursorrules） | — | 「我沒有使用 cursor 的習慣，可以移除」 |
| §6.1 | a + c **Hybrid**（.cjs 保留 + portable shell 雙軌） | **偏離 .a 純** | 「採用 C 但保留 claude only 避免 hook 遺失」 |
| §6.2 | **b（Memory 共用化）** | **翻 .a → .b** | 高風險步驟，Stage 2 需 user 親自確認 |
| §7.1 | a（新增 sp-platform-link.sh） | — | — |
| §7.2 | a + b 混合（frontmatter source + manifest auto-aggregate） | 偏離單純 .b | 集中視圖 + DRY 兼顧 |
| §8.1 | b（五階段獨立 commit） | — | — |
| §8.2 | **c（永久保留 --legacy）** | **偏離 .a 三個月 sunset** | 「請根據三特性進一步處理並提供詳細的清單跟我做最終修改確認」→ 觸發 §12 補增 |
| §9.1 | a（/memo Claude-only） | — | — |
| §10.1 | a + c（Rule 26 + handbook 雙寫入） | — | — |
| §11.1 | b（每階段確認再進） | — | — |
| §12.2 | **b（OpenCode 加入首發平台）** | **解 §1.2 vs §8.2 文字衝突** | user 訊息明列「opencode platform, gemini cli, codex cli」 |
| §12.7 | a（採五階段全做） | — | — |

## 變更清單

| 動作 | 檔案 / 命令 | Hash / 位置 |
|---|---|---|
| 建立決策表 | `.hanschen/decision/260508_multi_platform_skill_refactor_decision.md` | 本檔（即將 rename CLOSED_*） |
| 建立 beta 分支 | `git checkout -b beta/multi-platform-refactor origin/main` | `sekai-workflow` repo |
| 建立 beta 計畫文件 | `sekai-workflow/docs/multi-platform-refactor-plan.md` | commit `a893e98` 於 beta 分支 |
| 推送 beta 分支至遠端 | `git push -u origin beta/multi-platform-refactor` | https://github.com/SWSekai/sekai-workflow/tree/beta/multi-platform-refactor |
| 鏡像歸檔（本次結案動作） | `sekai-workflow/docs/decisions/CLOSED_260508_*.md` | beta 分支（user 指示「特例」放入 sekai-workflow） |
| README 更新（本次結案動作） | `README.md` / `README.zh-TW.md` / `README.ja.md` | beta 分支 |
| PROJECT_JOURNAL 索引 | `.hanschen/docs/living/PROJECT_JOURNAL.md` | append 一列 |
| TODO Pending append | `TODO.md` | append 遺留項 |

## 🔖 保留候選（未採納但可重啟）

| § | 未採納選項 | 未採納原因 | 重啟時機 |
|---|---|---|---|
| §1.2.b | Cursor 加入目標平台 | user 無使用習慣 | 使用習慣改變、或團隊成員需用 Cursor 時 |
| §3.1.a | Symbolic Link（主機制） | Windows 需 Dev Mode；junction 無權限阻力較易部署 | Windows 全面進入 Dev Mode、或非目錄連結必須 symbolic 時 fallback 啟用 |
| §6.1.a | Hooks 純 Claude-only（不寫 portable） | user 偏好 Hybrid 雙軌 | portable hooks 維護成本超過收益、降回純 Claude-only 時 |
| §6.2.a | Memory 純 Claude-only | user 翻面至 .b | Stage 2 共用化遷移實際操作中遇 race condition / 漂移問題、降回 Claude-only |
| §6.2.c | Memory pack 匯出（手動 import） | 不夠自動化 | §6.2.b symlink 方案在他平台 home dir 處理失敗時 fallback |
| §7.2.b | manifest 不擴充（僅 frontmatter） | user 想要集中視圖 | manifest 自動匯總機制維護負擔過大時 |
| §8.1.a | 大爆炸一次完成 | 風險太大 | 五階段累積疲乏、決定一鼓作氣完成剩餘時 |
| §8.1.c | 實驗分支隔離（main 不動） | beta 分支模式已涵蓋此需求 | beta 分支 vs main 漂移過大難 merge 時，可改新 branch 重做 |
| §8.2.a | --legacy 三個月 sunset | user 偏好永久保留 | 永久保留導致維護負擔過大、改 sunset 模式時 |
| §10.1.b | 不新增 Rule 26 | user 偏好強制規範 | Rule 26 落地後發現執行困難、降為文件描述時 |
| §12.7.b | 只做 Stage 1 即停 | user 採完整五階段 | Stage 1 後遭遇阻塞、決定停在最小可行版時 |

## 未解決遺留項（已 append 至 `TODO.md` Pending）

1. Stage 1 實作（git diff 驗證 → AGENTS.md 升 canonical → `.agents/` 對接層 → sp-platform-link.sh stub）
2. Stage 2 Memory 共用化高風險步驟（備份 + 遷移 + 驗證）
3. Stage 3 各 skill 加 platforms 欄位 + 完整 platform link 實作
4. Stage 4 Bootstrap rewrite + Hook hybrid（portable shell 移植）
5. Stage 5 文件結案（CLAUDE.md Rule 26 + handbook + RENAME_HISTORY）
6. OpenCode 實際使用驗證（首次在 OpenCode 跑 `/kb`）
7. Memory 雙向同步 Phase 2（他平台讀取 `.agents/memory/` 機制）
8. /kb skill 在 ≥2 個非 Claude CLI 驗證通過（合併條件 #3）
9. beta 分支合併至 main 的最終評估

## 結案宣言

決策定案 + beta 基礎設施就緒。實際代碼變更從 Stage 1 第 1 步起。**等待 user 指示開工 Stage 1**，或先檢查 beta 分支內容後再起步。

