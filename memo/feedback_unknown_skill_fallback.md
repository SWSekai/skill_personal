---
name: Unknown command 自動 fallback Read SKILL.md
description: slash command 回 "Unknown command: /<name>" 時，Claude 自動 Read .claude/skills/<name>/SKILL.md 走流程，不再要求使用者重啟或提示
type: feedback
---

**規則**：當使用者下 `/<skill_name>` 觸發 Skill tool 後，harness 回 `Unknown command: /<skill_name>`（或 system reminder skill 列表中無該名稱）時，Claude **必須**自動 fallback：

1. `Read .claude/skills/<skill_name>/SKILL.md`
2. 若有 args（如 `/skm new`）→ 依 SKILL.md 子指令路由表（通常在 SKILL.md 開頭表格或 frontmatter `argument-hint`）解析 `args` 對應的 step section
3. 直接依 SKILL.md 的 step 執行（含 references/、assets/ 中的補充規則）
4. **不要**要求使用者「重啟對話」「重新提示」或「再執行一次」
5. **不要**回 "Unknown command, please ..."

**Why（根因）**：

Claude Code harness 在 session 啟動時將 skill 列表凍結進 system prompt。當使用者於 session 中**編輯 Sekai_workflow 回流區域**（如 `.sekai-workflow/<skill>/SKILL.md` 等遠端上傳前的 skill 檔案）→ harness 將 cwd 或 skill 掃描路徑指向該回流目錄而非 `.claude/skills/` → skill 列表掃不到 project-level skill。

關鍵特徵：
- `.claude/skills/` 是 runtime 副本（被 harness 掃描以注入 skill 列表）
- `.sekai-workflow/<skill>/` 是回流源（用於 push 到遠端 sekai-workflow repo），**非** harness 期待的 skill 路徑
- 使用者編輯回流源是合法行為（同步原則），但會觸發 harness 路徑追蹤偏移
- 已注入的 system reminder（含 skill 列表）**不會動態刷新**；session 中 `cd` 回正確目錄也救不回來

但 Claude 仍可主動 `Read .claude/skills/<name>/SKILL.md` 取得完整流程（檔案系統永遠是真相來源）。SKILL.md 進 context 約 5–15 KB，可接受成本。

**How to apply**：

| 場景 | 行為 |
|---|---|
| `/skm new` 回 Unknown | 立即 Read `.claude/skills/skm/SKILL.md` → 依 `## new` section 走流程 |
| `/team board` 回 Unknown | Read `.claude/skills/team/SKILL.md` → 依 `## B. /team board` section 走流程 |
| `/build flow` 回 Unknown | Read `.claude/skills/build/SKILL.md` → 依對應 subcommand section |
| skill 列表中名稱拼寫不確定 | 先 `ls .claude/skills/` 列出實際 skill 目錄 |
| `.claude/skills/<name>/` 不存在 | 才回「skill 真的不存在」並列出可用 skill；不要先假設不存在 |

**邊界**：

- 此規則只適用 project-level skill（`.claude/skills/`）；user-level skill（`~/.claude/skills/`）同理但路徑不同
- 若 SKILL.md 結構複雜需多 reference 才能執行 → 一次 Read 完主檔再依需要 Read references/ 子檔，不要重啟
- 此 fallback 不應 silent — 一句話告知使用者「skill 列表偏移、走 SKILL.md 直讀模式」即可，後續直接執行

**歷史脈絡**：

- 2026-04-29 PDF_Detector 對話：使用者**編輯了 `.sekai-workflow/` 回流區域的 skill 檔案**（非 `.claude/skills/` runtime 副本）→ harness skill 掃描路徑偏移 → `/skm` 回 Unknown command。使用者 `cd ..` 回專案根目錄無效（已注入的 system reminder 不刷新），問「以後遇到此問題仍要提供此訊息給你？是否有一勞永逸的方法？」
- 第一層備援即此規則（fallback Read SKILL.md）
- 第二層備援（hook 偵測 cwd 偏移、或檢測 `.sekai-workflow/` 編輯後自動 sync 至 `.claude/skills/`）暫不實作，待此規則無效時再評估
- 對應 CLAUDE.md Rule 24（同步新增）

**反例**（禁止）：

- ❌ 回「Unknown command, 請重啟對話」
- ❌ 回「請再 `cd` 回正確目錄試一次」
- ❌ 回「skill 列表似乎沒包含此 skill，是否要我 ...」（違反 Rule 15）
- ❌ 不 fallback 直接拒絕執行
