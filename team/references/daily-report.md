# /team report --daily — Daily Daily Report Mode Spec

> Full specification for the `--daily` flag of `/team report`; `team/SKILL.md §F` keeps only the external contract.
> Aligned with decision `260424_team_daily report_subcommand_decision.md`.

## 1. Purpose and Scope

`/team report --daily` is a **daily Teams-renderable daily report** mode layered on top of `/team report`. Differences from the default mode:

| Aspect | `/team report` (existing) | `/team report --daily` (new mode) |
|---|---|---|
| Purpose | Long-cycle formal report (weekly / range) | Daily message pastable into Microsoft Teams |
| Primary sources | `modify_log` | closure summaries (board + decide) + TODO deltas + `modify_log` + user handoff |
| Time unit | Weekly / range | Today (default) / specified day / specified range |
| Output file | `.local/report/YYMMDD_<scope>_report.md` | `.local/report/YYMMDD_daily_report.md` |
| Format | Table-heavy, formal | Teams-safe subset, plain bullets (`-`) |
| Trigger | Manual | Manual + board closure auto + decide closure auto + `/commit-push` auto |
| Update model | One-shot generation | Daily accumulator (smart merge each trigger) |

The `--daily` flag and scope arguments (`full` / `weekly` / `YYMMDD YYMMDD`) are compatible:
- `/team report --daily` → today (default)
- `/team report --daily YYMMDD` → specified day
- `/team report --daily YYMMDD YYMMDD` → range

If both `weekly` and `--daily` appear, `--daily` wins (daily semantics override weekly).

---

## 2. File Location and Naming

- **Path**: `.local/report/YYMMDD_daily_report.md`
- **One file per day**: same-day re-invocation → smart update (see §7), never a second file
- **Cross-day separation**: filename `YYMMDD_` prefix naturally partitions history
- **No auto-deletion**: yesterday's daily report and earlier are preserved as history (do not rename to `CLOSED_`; the `CLOSED_` prefix is reserved for board/decision files)
- **No version control**: lives under `.local/` which is gitignored

---

## 3. Data Sources (per decision §2.1)

All sources merge into one daily daily report via smart update. Selected sources: **a + b + c + d + f**.

### 3.1 Whiteboard Closure Summary (§2.1.a)

For each `.local/docs/whiteboards/CLOSED_YYMMDD_*_board.md` within scope:

1. Read the "# 結案摘要（Closure Summary）" block at file end
2. Extract 「最終決策」 table → append to daily report's **「本日決策與討論結論」** section as one row per decision: `(topic) | (outcome) | [link to CLOSED file]`
3. Extract 「背景」 → used as narrative in 「本日完成」 one-line entry

### 3.2 Decision Closure Summary (§2.1.b)

For each `.local/docs/decisions/CLOSED_YYMMDD_*_decision.md` within scope:

1. Read the inline "# 結案摘要（Closure Summary）" block at file end
2. Extract 「最終決策（逐項目 §n.m）」 → append to daily report's **「本日決策與討論結論」** section
3. Multiple decision rows per file → one daily report row per major decision topic (collapse §n.m sub-items into one summary line)

### 3.3 TODO State Changes (§2.1.c)

Scan TODO.md (resolve: `./TODO.md` project root → `.local/collab/TODO.md` legacy):

- **Completed today**: parse `## Completed` section, filter entries with `done YYYY-MM-DD HH:MM` matching scope → fill daily report's **「本日完成」**
- **In Progress**: parse `## In Progress` section → fill daily report's **「進行中」**
- **Pending**: parse `## Pending` section → fill daily report's **「待辦與阻塞」**
  - Items tagged `@blocked` or in a "Blocker" sub-section → annotate with blocker reason if present
- If `TODO.md` does not exist → TODO-based sections empty, do not fail

### 3.4 modify_log Summary (§2.1.d)

For each `.local/modify_log/YYMMDD_*.md` within scope:

1. Read "## 基本資訊" block → extract commit hash, 更動原因
2. Read "# <Title>" → one-line summary
3. Append to **「作業記錄 → commit 記錄」** table row: `HH:MM | hash | title | ✅ modify_log present`

### 3.5 User Handoff Input (§2.1.f, §6.2 hybrid)

Per decision §6.2 (selected options: b + c with hybrid rule「若未能從todo抓取對應資料則詢問」):

1. **Primary — TODO `@handoff:<name>` tag**: scan `TODO.md` (any section) for lines containing `@handoff:<name>` pattern
   - Matched → extract item text + `<name>` → fill daily report's **「交接事項」** as `交給 @<name>：<text>`
   - Regex: `@handoff:(\w+)` (case-insensitive)
2. **Fallback — AskUserQuestion**: if no `@handoff:*` tags found AND trigger is **manual**, ask:
   > 今日是否有需要交接的事項？若有，請提供：交給誰、要告訴他什麼。
   
   Options (single-select):
   - 有交接事項（填補充說明）
   - 今日無需交接
3. **Automatic triggers do NOT ask**: per decision §3.3.a, auto-triggers (board / decide / commit-push) silently update data-source sections only; handoff section is left untouched if user has not populated it
4. If manual trigger + user answers "無需交接" → write "無" in handoff section

### 3.6 Commit vs modify_log Cross-Check (Integrity Warning)

After §3.4 collects modify_log entries, cross-check against today's git commits:

```bash
git log --since="YYYY-MM-DD 00:00" --until="YYYY-MM-DD 23:59" --pretty=format:"%h|%H|%s|%ci"
```

For each commit:
- Commit hash appears in any `.local/modify_log/` file content → mark ✅
- Not found → mark ⚠️ **「modify_log 缺失，建議改走 /commit-push」**

Append all commits (including missing-log ones) to **「作業記錄 → commit 記錄」** table. ⚠️ rows preserve order — do not drop.

This is the integrity mechanism answering the user's concern about bypass of `/commit-push` (see decision §3.1.e 補充). The daily report does not block commits; it surfaces the gap.

---

## 4. Output Content Structure (per decision §6.1)

### 4.0 Audience and Writing Style (MANDATORY)

**Primary audience**: the user's **supervisor / manager / external stakeholder** — someone who skims the report to track progress and outcomes, not the engineer who produced it.

**Writing rules**:

- **Outcomes first, implementation last** — lead with what was achieved (metrics, user-visible behaviour). If context is needed, one plain-language sentence. Reserve parameter values, function names, code paths, and decision-doc references for `modify_log` / CLOSED files, not the daily report.
- **No internal jargon in body text** — avoid function names (`enhance_roi_for_ocr`), flag names (`PDFDET_DEBUG_VALUE`), branch names (`conservative branch`), parameter tuples (`min=8, param2=30`). If a reader outside the project cannot parse the sentence, rewrite it.
- **Quantify where possible** — "Recall 37.7 → 44.6 % (+6.9 pp)" beats "大幅改善". Use the same KPI the team tracks.
- **Transparency on blockers** — name the blocker plainly, name the short-term workaround, name when the long-term fix is planned. Do not hide or spin.
- **Engineering detail belongs in the appendix** — §6 作業記錄 and linked `modify_log` / CLOSED docs carry the depth. The main body should read in under 60 seconds.
- **No Claude / tooling commentary** — never mention Claude Code internals, model tiers, context modes, Skill names, or flow interruptions. The supervisor does not care which AI tool was used.

**Failure mode to avoid**: a daily report that reads like a dev diary (exhaustive, commit-by-commit, with jargon) buries the actual progress signal. If the reader has to re-read a sentence to understand what was accomplished, the style has failed.

### 4.1 Section Structure

Daily Report content has 6 sections. Sections 1–5 are user-facing; section 6 is engineering detail.

1. **本日完成** — completed items (TODO done + whiteboard outcomes)
2. **進行中** — in-progress items (TODO in_progress)
3. **待辦與阻塞** — pending items, blockers annotated
4. **交接事項** — handoff (manual-only section, see §3.5)
5. **本日決策與討論結論** — decision table (from closures)
6. **作業記錄** (附錄 / appendix) — commit + closure cross-check

Full template: `team/assets/daily-report-template.md`.

---

## 5. Teams Markdown Rules (per decision §5)

### 5.1 Allowed subset
- Headings H1–H3
- Bold / italic
- Bulleted lists (**max 2 levels of nesting**)
- Simple tables (≤ 4 columns recommended for mobile)
- Links `[text](url)`
- Inline code `code`
- Code blocks (fenced triple-backtick) — post-only, may render as plain text in chat messages
- Emoji (✅ ⚠️ 🔖 📝 🚧 etc.)

> **Note**: `- [ ]` / `- [x]` checkboxes are NOT used in daily report body text (see §5.3). Retained only for Claude's internal self-check lists inside `commit-push/SKILL.md` / this spec — never output into the report.

### 5.2 Avoid
- Deep nesting (> 2 levels) — Teams flattens or breaks
- Raw HTML (`<details>` `<br>` `<img>`) — not rendered
- Complex tables with merged cells
- Task lists rendered as interactive (GitHub-only)
- Very long lines (> 120 chars) — mobile truncation risk

### 5.3 Bullet format (updated 2026-04-24)

**Use plain bullets (`-`) in body text; do NOT use `- [ ]` / `- [x]` checkboxes.**

Rationale: the three primary sections (§1 本日完成 / §2 進行中 / §3 待辦與阻塞) carry their status via section heading itself — the `[ ]` / `[x]` marker is redundant visual noise when the outcome is "today already closed / still ongoing / pending". Plain bullets render cleaner in Teams and remove the interactive-checkbox misconception (Teams renders them static anyway).

- ✅ Correct: `- 廠區下拉只顯示有啟用資料的廠區`
- ❌ Wrong: `- [x] 廠區下拉只顯示有啟用資料的廠區`

Other markers remain unchanged:
- 🚧 for blockers within §3 待辦與阻塞
- ✅ reserved for closure / cross-check cells (commit table's modify_log column, closure records)
- ⚠️ for `modify_log` missing warnings in §6 commit 記錄 table

When smart-updating sections §9.4, scan lines regardless of checkbox prefix (legacy reports may still contain `- [ ]` / `- [x]` — normalize to `- ` on rewrite).

---

## 6. Smart Update Strategy (per decision §4.3.a)

When same-day daily report exists:

### 6.1 Auto-updated sections (overwrite each trigger)
- §1 本日完成
- §2 進行中
- §3 待辦與阻塞
- §5 本日決策與討論結論
- §6 作業記錄

### 6.2 Preserved sections (never overwritten by auto-update)
- §4 交接事項 — only manual trigger updates this section (per decision §3.3.a)

### 6.3 Last-updated stamp
Update header line `> 最後更新：YYYY-MM-DD HH:MM | 來源：<auto|manual>` each time.

### 6.4 Trigger source tag
In the header, append the latest triggering source:
- `board closure (CLOSED_260424_xxx_board.md)`
- `decide closure (CLOSED_260424_xxx_decision.md)`
- `commit-push (hash abc123)`
- `manual`

---

## 7. Trigger Hooks (per decision §3.1)

### 7.1 `/team board` closure — Step 3.5 (new)

Inserted in `team/SKILL.md §B Step 3` after Step 3.4 (self-check). After living doc update completes:

1. Detect date: if today has existing `.local/report/YYMMDD_daily_report.md` → smart-update §1/§3/§5/§6 from this closed whiteboard
2. If no daily report yet today → create new daily report using template, fill §1/§5 from this closure, leave other sections to next trigger
3. Silent mode: no handoff prompt, no user confirmation
4. Append to trigger source tag

### 7.2 `/team decide` closure — Step 6.6 (new)

Inserted in `team/SKILL.md §C Step 6` after Step 6.5 (self-check). Same behavior as 7.1 but reading the CLOSED decision file.

### 7.3 `/commit-push` — Step 10+ (new mini-step)

Inserted in `commit-push/SKILL.md` after Step 10 (experience sync-back). After commit + push + modify_log + cleanup complete:

1. Detect date from the commit timestamp (normally "today")
2. If daily report exists → append this commit row to §6 作業記錄 (auto-mark ✅ since commit-push writes modify_log)
3. If no daily report yet → create new daily report, write §6 with this commit as seed, other sections populated from TODO.md + existing CLOSED files within today
4. Silent mode (no handoff prompt)

### 7.4 Manual — `/team report --daily` direct call

Full interactive flow per §3.5 item 3 (TODO @handoff → fallback AskUserQuestion). Otherwise identical merge.

---

## 8. `/hello` Cross-Day Check (per decision §3.1.e)

Inserted in `hello/SKILL.md` Step 3 (Restore Context) as sub-step 3.4 (new):

### 8.1 Detection logic
1. Get today's date: `date '+%Y%m%d'` (convert to YYMMDD: last 6 chars)
2. Glob `.local/report/*_daily report.md` → pick the latest by filename sort
3. Compare latest daily report's YYMMDD vs today's YYMMDD:

| Condition | Display |
|---|---|
| No daily report files | Skip |
| Latest = today | `本日 daily report: N 完成 / M 進行中 / K 待辦`（concise inline） |
| Latest < today | See §8.2 |

### 8.2 Yesterday's daily report reminder (cross-day)

Display block in status overview:

```
━━━ 跨日檢查 ━━━
昨日 daily report：.local/report/YYMMDD_daily_report.md
  未處理交接：N 項（若 §4 非「無」）
  modify_log 缺失：M 筆（若 §6 有 ⚠️ 標記）
今日 daily report：尚未建立（將於今日首次觸發時新建）
━━━━━━━━━━━━━━
```

### 8.3 No cleanup / no rename
Per decision §8.1.a, do NOT rename yesterday's daily report to `CLOSED_` (reserved for decision/whiteboard). "Cleanup" semantics is satisfied by natural `YYMMDD` partition — yesterday's file becomes a historical artifact automatically when today writes a new `YYMMDD_daily_report.md`.

### 8.4 Optional promotion of yesterday handoffs
If yesterday's daily report §4 交接事項 is non-empty and non-"無" → `/hello` Step 3.4 output includes a subtle hint:

> 昨日有 N 項交接事項未確認。如需延續到今天，執行 `/team report --daily` 手動合併。

Do not auto-merge — let the user decide.

---

## 9. Parser Rules

### 9.1 CLOSED closure summary block detection

In target file, locate block starting with:
```
# 結案摘要（Closure Summary）
```
Extract the block via `naming.md §5.2` template. Fields of interest:
- `最終決策` table (`| 項目 | 採納選項 | 備註 |` or `| 項目 | 結果 | 備註 |`)
- `背景` paragraph
- `變更清單` table (for modify_log cross-check supplement)

### 9.2 TODO @handoff regex

```
Pattern: @handoff:([a-zA-Z0-9_\-]+)
Flags: case-insensitive, global
Capture: <name> — the recipient identifier
```

Extract full line containing the tag + strip the tag itself for handoff text.

### 9.3 modify_log commit hash extraction

In each `YYMMDD_*.md`, find pattern `\bGit 版本\b.*\b([a-f0-9]{7,40})\b` → collect short-hash list for cross-check.

### 9.4 Daily Report section boundary recognition

When smart-updating, locate sections by H2 heading exact match:
- `## 本日完成`
- `## 進行中`
- `## 待辦與阻塞`
- `## 交接事項`  ← **preserved; never overwrite in auto mode**
- `## 本日決策與討論結論`
- `## 作業記錄`

Unknown sections → preserve as-is (future-extensibility).

---

## 10. Edge Cases

| Case | Handling |
|---|---|
| No TODO.md | Skip TODO-derived sections; continue |
| No closure files within scope | §1/§5 filled from TODO only |
| No commits today | §6 table shows "無 commit 紀錄" |
| Daily Report exists but malformed | Back up `YYMMDD_daily_report.md.bak`, regenerate from template |
| Range spans multiple days | Aggregate all days; single output file with the **end-date** as filename YYMMDD |
| Cross-day trigger (commit-push at 00:05) | Use commit timestamp's YYMMDD, not wall-clock — so late commits land in yesterday's daily report |
| User's `--daily` with empty everything | Still produce daily report file with all sections "無"; serves as "today had no activity" record |

---

## 11. Model (per decision §7.1.a)

Sonnet — main flow runs inline (read multi-file + smart-merge + write). No Agent sub-dispatch needed for standard execution.

Exception: if daily report generation must summarize 10+ closure files → dispatch Haiku Agent for structured text assembly, Sonnet remains primary.
