# Multi-Platform Skill Refactor — Beta Plan

| 欄位 | 值 |
|---|---|
| **Beta 分支** | `beta/multi-platform-refactor` |
| **啟動日期** | 2026-05-08 |
| **狀態** | Stage 1 待開工 |
| **參照** | [iannuttall/dotagents](https://github.com/iannuttall/dotagents) |
| **來源決策** | `.hanschen/decision/260508_multi_platform_skill_refactor_decision.md`（私有） |

---

## 目標

將現行單一 Claude Code 平台的 sekai-workflow skill 體系擴展至多 CLI（**Codex CLI / Gemini CLI / OpenCode**），同時保留三特性：

| 特性 | 實作要點 |
|---|---|
| **易維護** | symlink/junction 為 OS 層別名（非複製），編輯成本常數 1 — 修一次同步多 CLI |
| **跨平台** | `.agents/` 對接層 + 各 skill `platforms:` 欄位 selective link，各 CLI 各取所需 |
| **持續學習** | 加新 skill 自動繼承跨平台能力（manifest 自動匯總、sp-platform-link 自動偵測），零手動 link |

---

## 採納關鍵決策摘要

| 決策點 | 採納方案 | 偏離預設處 |
|---|---|---|
| 不改檔名語意 | symlink/junction 為 OS 別名（非複製） | — |
| 目標平台 | Claude / Codex / Gemini / OpenCode | 移除 Cursor、加入 OpenCode |
| 頂層架構 | 混合：保留 `sekai-workflow/` + 新增 `.agents/` 對接層 | — |
| canonical 規範檔 | `AGENTS.md`（dotagents 模型） | 翻 .a → .b |
| Symlink 機制 | Windows junction 主、symlink fallback；POSIX `ln -s` | — |
| Hooks 策略 | Hybrid：`.cjs` 保留 Claude-only + `hooks/portable/*.sh` 雙軌並行 | 偏離 .a |
| Memory 策略 | 共用化：`.agents/memory/` 集中、Claude memory symlink 反向 | 翻 .a → .b |
| Manifest | frontmatter 為 source、manifest 自動匯總 `platforms_index` | — |
| 推進策略 | 五階段獨立 commit，每階段暫停確認 | — |
| Legacy 旗標 | 永久保留 `--legacy`（不限期） | 偏離 .a |

---

## 最終架構圖

```
sekai-workflow-edit/                                ← 主專案（非 git repo）
├── AGENTS.md                                       ★ canonical 規範（原 CLAUDE.md，§5.1.b）
├── CLAUDE.md                       → symlink ───→  AGENTS.md
├── sekai-workflow/                                 ★ skill 規範本體（保留原名）
│   ├── _bootstrap/
│   │   ├── sp-init.bat                             (重寫，加 --legacy 永久保留)
│   │   ├── sp-sync.sh                              (重寫，僅做 link verify)
│   │   ├── sp-pack.sh                              (加 dangling-link safe handling)
│   │   ├── sp-platform-link.sh                     (新增主控)
│   │   └── sp-verify.bat                           (加 link integrity check)
│   ├── manifest.json                               (加 platforms_index 自動匯總)
│   ├── handbook/multi-platform.md                  (新增技術筆記)
│   ├── hooks/                                      (.cjs 不動 + portable/ 新增)
│   │   ├── *.cjs                                   (Claude-only)
│   │   └── portable/                               ★ 新增
│   │       ├── check_yn_question.sh                (移植版 git pre-commit)
│   │       └── check_skill_sync.sh                 (移植版 CLI 命令)
│   └── <每個 skill>/SKILL.md                       (frontmatter 加 platforms: [...])
│
├── .agents/                                        ◇ 純 symlink 對接層
│   ├── skills/   ─── junction ─→  ../sekai-workflow/
│   ├── hooks/    ─── junction ─→  ../sekai-workflow/hooks/
│   ├── memory/                                     ★ 共用 memory 真檔
│   │   ├── MEMORY.md
│   │   ├── feedback_*.md, project_*.md, ...
│   │   └── README.md
│   ├── AGENTS.md ─── symlink ─→  ../AGENTS.md
│   ├── CLAUDE.md ─── symlink ─→  ../AGENTS.md     (兩個 symlink 指同一真檔)
│   └── GEMINI.md ─── symlink ─→  ../AGENTS.md
│
├── .hanschen/                                      (跨機器共享文件，已存在)
└── .local/                                         (機器專屬 state，已存在)

外部對接（platform-link 安裝後）：
~/.claude/skills/                ─ junction ─→  <proj>/.agents/skills/
~/.claude/hooks/                 ─ junction ─→  <proj>/.agents/hooks/
~/.claude/projects/<enc>/memory/ ─ symlink  ─→  <proj>/.agents/memory/
~/.codex/prompts/                ─ junction ─→  <proj>/.agents/skills/
~/.gemini/commands/              ─ junction ─→  <proj>/.agents/skills/
~/.config/opencode/commands/     ─ junction ─→  <proj>/.agents/skills/
project-root AGENTS.md (Codex 通讀，已是真檔)
project-root GEMINI.md           ─ symlink  ─→  AGENTS.md
```

---

## 首發 Skill Platform 矩陣

| Skill | 預設 platforms | 理由 |
|---|---|---|
| `kb` | `[claude, codex, gemini, opencode]` | **首發跨平台 skill** — 純文字 KB add/search/extract |
| `build` | `[claude]` | 重度 Tool/Agent + 多 sub-agent |
| `team` | `[claude]` | AskUserQuestion + 多步驟 + 自動 hook |
| `skm` | `[claude]` | 同上 |
| `commit-push` | `[claude]` | 多 sub-agent + 流水線 |
| `ask` | `[claude]` | Tool/Agent for trace |
| `clean` | `[claude]` | /clear 整合 |
| `memo` | `[claude]` | Memory dependent |
| `dispatch` | `[claude]` | Agent tool only |
| `hello` | `[claude]` | 多步驟初始化 |

**首發策略**：以 `/kb` 為唯一跨平台 skill 驗證 multi-platform link 機制；其餘 9 個 skill 暫保留 Claude-only，Stage 3 個別測試後微調。

---

## Stage 清單與進度追蹤

### Stage 1 — 低風險新增（純 additive，零破壞）

- [ ] 1. 解 sekai-workflow remote 分歧（`git diff origin/main..HEAD --stat`，已比對：local 96 commit 為 author-rewrite、remote 2 個新 commit 已透過此 beta 分支起點包含）
- [ ] 2. **AGENTS.md 升 canonical**：`git mv CLAUDE.md AGENTS.md` 於主專案 root，保留 git history
- [ ] 3. 建 symlink `CLAUDE.md` → `AGENTS.md`
- [ ] 4. AGENTS.md 開頭加 multi-platform disclaimer
- [ ] 5. 建 `.agents/` 目錄結構：`junction skills/`、`junction hooks/`、`symlink AGENTS.md/CLAUDE.md/GEMINI.md`
- [ ] 6. 建 `_bootstrap/sp-platform-link.sh` stub（先只支援 Claude，其他平台預留 TODO）
- [ ] 7. 開 TODO Pending：「Stage 2-5 細項」、「Memory 雙向同步 Phase 2」

**Stage 1 暫停點**：user 檢查 `.agents/` 結構與符號連結正確。

### Stage 2 — Memory 共用化（**高風險**）

- [ ] 8. 備份既有 Claude Memory：`cp -r ~/.claude/projects/<enc>/memory/ .local/memory_backup_pre_stage2/`
- [ ] 9. 將 memory 真檔搬至 `.agents/memory/`：`mv ~/.claude/projects/<enc>/memory/* <proj>/.agents/memory/`
- [ ] 10. 建 symlink：`~/.claude/projects/<enc>/memory/` → `<proj>/.agents/memory/`
- [ ] 11. 驗證：開新 Claude 對話寫入新 memory entry，確認 file 寫到 `.agents/memory/`
- [ ] 12. 寫 `.agents/memory/README.md` 跨平台使用說明

**Stage 2 暫停點**：user 確認 Memory 寫入正常無漂移。

### Stage 3 — Skill metadata + 完整 platform link

- [ ] 13. `kb` skill SKILL.md 加 `platforms: [claude, codex, gemini, opencode]`
- [ ] 14. 其他 9 個 skill 加 `platforms: [claude]`
- [ ] 15. 完整實作 `sp-platform-link.sh`：偵測 `~/.codex/prompts/`、`~/.gemini/commands/`、`~/.config/opencode/commands/`
- [ ] 16. 跑 `sp-platform-link.sh --dry-run` 給 user 看 plan
- [ ] 17. user 確認後跑 actual link
- [ ] 18. 各 skill `README.md` 加「相容平台」段落

**Stage 3 暫停點**：user 在 Codex / Gemini / OpenCode 任一 CLI 嘗試呼叫 `/kb`，確認運作。

### Stage 4 — Bootstrap rewrite + Hook hybrid

- [ ] 19. `sp-init.bat` 重寫：default → 呼叫 `sp-platform-link.sh`；加 `--legacy` 永久保留
- [ ] 20. `sp-sync.sh` 重寫：移除複製邏輯，改為 link verification + manifest 重生
- [ ] 21. `sp-pack.sh` 加 dangling-link safe handling
- [ ] 22. `sp-verify.bat`：加 symlink target 驗證、CLI 偵測、跨平台 link 完整性
- [ ] 23. **Hook hybrid 實作**：
  - [ ] 23a. `hooks/portable/check_yn_question.sh`（POSIX shell 版，git pre-commit）
  - [ ] 23b. `hooks/portable/check_skill_sync.sh`（CLI 命令版）
  - [ ] 23c. 既有 6 個 `.cjs` 不動

**Stage 4 暫停點**：user 跑一次 `sp-verify.bat` 看全部綠燈。

### Stage 5 — 文件結案與合併

- [ ] 24. CLAUDE.md（即 AGENTS.md）新增 Rule 26「Multi-platform skill portability」
- [ ] 25. 寫 `sekai-workflow/handbook/multi-platform.md`
- [ ] 26. `_bootstrap/RENAME_HISTORY.md` 加一行：`CLAUDE.md → AGENTS.md (檔案 rename，2026-05-08)`
- [ ] 27. 結案決策表 rename 為 `CLOSED_260508_multi_platform_skill_refactor_decision.md`
- [ ] 28. 結案訊息 append `PROJECT_JOURNAL.md`
- [ ] 29. 未解決遺留項 append `TODO.md` Pending（OpenCode 評估、Memory 雙向同步、其他 skill 跨平台 enable）
- [ ] 30. **Beta branch 合併至 main**（達合併條件後）

---

## 風險回顧

| Stage | 主要風險 | 回滾方法 |
|---|---|---|
| 1 | symlink 建立失敗（Windows 無 Dev Mode） | junction fallback；極端情況 `rmdir .agents/` + `git mv AGENTS.md CLAUDE.md` |
| 2 | Memory 搬遷時 Claude Code 正在寫入 → race condition | 備份 + 暫停 Claude Code session 再執行 |
| 3 | Codex / Gemini / OpenCode 不支援目錄式 commands | platform-link 加 `--undo` flag，逐一移除 link |
| 4 | sp-init/sp-sync 改寫破壞既有專案 | `--legacy` 永久保留作為 escape hatch |
| 5 | Rule 26 與既有規則衝突 | 預配 Rule 26 編號（Rule 25 已用） |

---

## 合併條件（Beta → main）

Beta 分支合併至 `main` 的條件：

1. ✅ Stage 1-4 全部完成且驗收通過
2. ✅ `sp-verify.bat` 全綠（含 multi-platform link integrity）
3. ✅ `/kb` skill 在至少 **2 個非 Claude CLI**（Codex / Gemini / OpenCode 任二）成功呼叫
4. ✅ user 確認願意作為 default 行為

未達上述條件 → beta 分支保留、不 merge；Claude Code 用戶繼續走 main（legacy 模式）。

---

## 平台對接路徑速查

| 平台 | commands 路徑 | context 檔 |
|---|---|---|
| Claude Code | `~/.claude/skills/`（skill 形式）+ `~/.claude/commands/`（flat 形式） | `~/.claude/CLAUDE.md` 或 project-root `CLAUDE.md` |
| Codex CLI | `~/.codex/prompts/` | project-root `AGENTS.md` |
| Gemini CLI | `~/.gemini/commands/` | `~/.gemini/GEMINI.md` 或 project-root |
| OpenCode | `~/.config/opencode/commands/` | project-root `AGENTS.md` |
| ~~Cursor~~ | ~~`~/.cursor/commands/`~~ | ~~`.cursorrules` / `AGENTS.md`~~ |

Cursor 已從目標平台移除（user 無使用習慣）。
