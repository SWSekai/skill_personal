# Rename History — 全域改名工作清單

> **本檔角色**：**過渡期工作清單**，**不是永久史冊**。每次目錄、skill、subcommand 改名時於此記錄、執行 Checklist、驗收完成後依保留政策淘汰。
>
> 個別 skill 的 SKILL.md / README.md 末尾「Cross-Skill References」段落只列**自己直接相關**的改名歷史，不重複本檔的全域清單。

## 保留政策（重要）

| 階段 | 動作 |
|---|---|
| 改名啟動 | 在下方表格新增一筆，含 Checklist |
| 全域 `grep` 確認舊名消失 | 該筆標 ✅ 已完成 |
| **改名日期 + 90 天** | 從表格移除該筆（git log 仍可考古，本檔不留長期史） |
| 個別 skill 的 `Rename History` 段落 | 同樣 90 天淘汰；除非 skill 仍有 alias / 過渡 path 才保留 |

**理由**：舊名全域消失後，使用者與 Claude 不會再看到舊名 → history 失去解釋價值；長期保留只會累積噪音、降低本檔信噪比。git log + CLOSED 決策檔已是足夠的考古來源。

**例外**：若 skill 仍有現役 alias（如同名指令暫時還能 route 到新路徑），則該筆條目須保留至 alias 移除後才開始計算 90 天。

---

## 改名清單（時序由舊至新；超過 90 天請刪除）

| 日期 | 舊名 | 新名 | 範圍 | 全域影響檔案 |
| 改名日期 | 舊名 | 新名 | 範圍 | 全域影響檔案 | 淘汰日期 (≥) |
|---|---|---|---|---|---|
| 2026-04-17 | `/setup` | `/skill` | Skill 管理 subcommand | 全 skill 系統 README/SKILL、CLAUDE.md | 2026-07-16 |
| 2026-04-22 | `.local/docs/summary/` 目錄機制 | 內嵌結案摘要 append 至 CLOSED_ 原檔末尾 | team decide / board 結案流程 | `team/SKILL.md`、`team/references/naming.md`、所有 CLOSED 決策檔 | 2026-07-21 |
| 2026-04-24 | `Sekai_workflow/`（駝峰底線）| `sekai-workflow/`（小寫連字號，源 repo）；`.sekai-workflow/`（init 後專案內隱藏目錄）| 全域路徑 | bootstrap 腳本、所有路徑引用、hooks | 2026-07-23 |
| 2026-04-24 | `/skill` | `/skm` | Skill 管理 subcommand（避免與內建 `/skills` 衝突）| 全 skill 系統 README/SKILL、CLAUDE.md、`_bootstrap/templates/` | 2026-07-23 |
| 2026-04-24 | `/team living` | `/team journal` | team subcommand（專案 journal）| `team/SKILL.md`、`team/references/`、CLAUDE.md Available Skills | 2026-07-23 |
| 2026-04-24 | `team-office` (skill 名) | `team` | 互動協作 skill | 全 skill 系統 README/SKILL、CLAUDE.md | 2026-07-23 |
| 2026-04-24 | `memory-portable` (skill 名) | `memo` | Memory 跨專案攜帶 skill | 全 skill 系統 README/SKILL、CLAUDE.md | 2026-07-23 |
| 2026-04-24 | `knowledge_base/` | `handbook/` | 跨專案技術手冊目錄 | bootstrap 腳本 SKIP_DIRS、`kb` skill、`manifest.json` | 2026-07-23 |
| — | `context-guard` (獨立 skill) | 合併入 `/clean` | Context 清理流程 | `clean/SKILL.md`、`hello/SKILL.md`、`commit-push/SKILL.md` Step 9、所有引用 `context_summary/` 的 skill | 改名日期不詳，下次檢查時補 |
| — | `/ask report` | `/team report` | 工作報告子指令遷移 | `ask/SKILL.md`、`team/SKILL.md` §F | 改名日期不詳，下次檢查時補 |

---

## 改名執行 Checklist（CLAUDE.md Rule 23 + Rule 24 對應）

> 本 Checklist 為**永久機制模板**（不依 90 天淘汰），上方表格才依政策淘汰。

每次改名時依序檢查：

### 1. 程式 / 腳本層
- [ ] `_bootstrap/sp-init.bat` — 跳過清單、目錄遍歷
- [ ] `_bootstrap/sp-sync.sh` — `SKIP_DIRS` 變數、複製邏輯
- [ ] `_bootstrap/sp-pack.sh` — preserve-before-delete 清單
- [ ] `_bootstrap/sp-verify.bat` — 驗證 checklist
- [ ] `manifest.json` — skill 條目 / 資料夾分類
- [ ] `file_manifest.json` — 檔案層級紀錄
- [ ] `.claude/hooks/*.cjs` — 任何硬編碼的舊路徑 / 舊命令名

### 2. 文件層
- [ ] `CLAUDE.md` — Available Skills、Rule 內提及之指令名
- [ ] `_bootstrap/templates/CLAUDE.md.template` — 全域模板
- [ ] `sekai-workflow/README.md` — 主 README
- [ ] `.claude/skills/README.md` — 本地 skill 索引
- [ ] `sekai-workflow/docs/QUICKSTART.md`
- [ ] `sekai-workflow/docs/file-output-reference.md`
- [ ] 個別 skill 的 SKILL.md `## Cross-Skill References`（只列自己相關）

### 3. 設定層
- [ ] `.claude/settings.local.json` `_doc` 欄位
- [ ] `.claude/settings.json`（若有）

### 4. 全域驗證
- [ ] `grep -rn '<舊名>' . --include='*.md' --include='*.json' --include='*.bat' --include='*.sh' --include='*.cjs'`
- [ ] CLOSED 決策檔不修改（保留歷史脈絡）
- [ ] `.local/modify_log/`、`.local/docs/decision/CLOSED_*` 視為歷史紀錄，不需改寫

### 5. 本檔自身
- [ ] 將本次改名 append 到上方表格（含日期、舊名、新名、範圍）
- [ ] 排程 90 天後檢查：屆時舊名仍未在 grep 出現 → 從表格移除該筆

---

## 名詞職責劃分

| 名詞 | 角色 |
|---|---|
| **STALE** | 舊名仍被當作生效指令引用 → 必須改 |
| **HISTORICAL** | 舊名出現於「文件改名說明」段落（如「2026-04-24 由 /skill 改名」）→ 保留 |
| **AMBIGUOUS** | 上下文不清楚 → 人工 review |

清理時：先用 grep 找全部，再以上述三類分類，只動 STALE。
