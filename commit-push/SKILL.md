---
name: commit-push
description: "Commit & Push standalone entry — quality check (Opus) → modify log (Haiku) → README sync → commit → push → restart evaluation → Context cleanup. Built-in complete commit flow, all logs kept local only, not under version control. Supports --meta flag for skill-maintenance commits (skips modify_log + daily report append) and --no-subagent flag for 1M-context / sub-agent-avoidance runs."
model: sonnet
effort: medium
argument-hint: "[--meta] [--no-subagent] [commit message override]"
allowed-tools: Read, Write, Edit, Glob, Grep, Agent, Bash(git *), Bash(ls *), Bash(date *), Bash(docker *)
---

# /commit-push — Complete Commit and Push Flow

Execute the following steps in order. **Do not skip steps** (unless `--meta` flag skips designated steps). This Skill is the **primary commit entry point**, complementing other `/build` subcommands (flow / plan / impl / test / quality / log / review / deploy).

**Model Division of Labor (aligned with CLAUDE.md Rule 18)**:
- The main flow is executed by **Sonnet** (standard development tasks, file read/write, git operations)
- Step 1 "Quality Check" embeds **Opus** for deep analysis (evaluation, planning attributes)
- Step 5 "Modify Log" embeds **Haiku** for structured output (plain text writing attributes)

## `--meta` Flag (Skill Maintenance Mode)

When `$ARGUMENTS` contains `--meta`, this commit is classified as **skill / environment maintenance** rather than project product work:

- **Skip Step 5** (Modify Log creation) — meta commits are not project contributions
- **Skip Step 11** (Daily Report append) — meta commits should not appear in daily Teams report
- **Keep all other steps**: quality check, README sync, stage, commit, push, sekai-workflow sync, restart eval, context cleanup, experience guide

Triggered automatically by `/skm new` Step 10 (see `skm/SKILL.md` §A). Users may also invoke manually: `/commit-push --meta <message>`.

Rationale: skill/rule edits are meta-level work bound to tooling, not the project's functional deliverable. Tracking them in `modify_log` / daily report would pollute the work ledger. See CLAUDE.md Rule 20.

## `--no-subagent` Flag (1M Context / Sub-agent Avoidance Mode)

When `$ARGUMENTS` contains `--no-subagent`, **all steps run inline in the main session** — no `Agent` tool invocations are made:

- **Step 1 Quality Check**: main session performs the audit directly (no Opus sub-agent spawn)
- **Step 5 Modify Log**: main session writes the log directly (no Haiku sub-agent spawn)
- **All other steps**: unchanged

**When to use**:
- Current session runs in **Opus 4.7 1M context** mode without `/extra-usage` enabled — sub-agent spawn hits the API gateway's extra-usage wall and halts the flow mid-run. Detection hint: model id suffix `[1m]`, or a prior run aborted with `API Error: Extra usage is required for 1M context`.
- User wants a single-transcript audit trail (all reasoning visible in main session, not buried in sub-agent logs).
- Debugging a Skill behavior and need step-by-step visibility of the audit/log decisions.

**Trade-off**: default mode optimises for model specialisation (Opus depth on audit, Haiku brevity on log writing). Inline mode trades that for reliability under 1M-gate / visibility; the Sonnet main session is still fully capable of both duties.

**Combinable with `--meta`**: e.g. `/commit-push --meta --no-subagent <msg>` — skill-maintenance commit in 1M mode, skips modify_log + daily report AND avoids sub-agent spawn.

---

## Step 1: Quality Check (embedded Opus deep analysis)

Perform a complete quality audit on all changes in the staging area / working tree.

**Default**: invoke via Agent tool as an Opus subtask for deep-analysis capability.
**`--no-subagent` mode**: main Sonnet session performs the audit inline using the same 1.1–1.7 checklist below (no Agent call).

### 1.1 Scan Items

For each changed file, check:

- **Dead code**: unused imports, unreachable branches, commented-out code
- **Redundancy**: cross-file duplicate logic, copy-paste that should be abstracted
- **Hard-coding**: magic values that should live in config / constants
- **Error handling**: try/catch at system boundaries (APIs, external calls, file IO)
- **Type consistency**: mismatched data types across layers
- **Serialization risk**: fields that may be lost during JSON / protobuf / form processing
- **Security**: SQL injection, XSS, command injection, sensitive info leakage, OWASP Top 10

### 1.2 Architectural Consistency

Read 3–5 existing files in the same directory to understand conventions (naming, error handling, log style, response format), then list deviations with existing examples attached.

### 1.3 Impact Assessment (Upstream / Downstream Matrix)

| Dimension | Question |
|---|---|
| Upstream | Who calls this function / endpoint? Will it break? |
| Downstream | Who does this function call? Is the contract still valid? |
| State | Does it touch DB schema, cache key, file path, env var? |
| Concurrency | Race conditions under multi-user / multi-worker? |
| Backward compat | Are existing DB records, saved configs, cache values still usable? |
| API contract | If request / response shape changed, have all clients been updated? |

### 1.4 Risk Report

| Severity | File | Description | Mitigation |
|---|---|---|---|
| High / Med / Low | ... | ... | ... |

- **High**: may cause data loss, crash, security vulnerability → **stop commit**, fix first
- **Medium**: may cause behavioral error or performance regression → notify user, let them decide whether to block
- **Low**: code smell or minor inconsistency → report only, do not block

When no risk exists, explicitly output: "Quality check passed, no risks"

### 1.5 Skill Update Hint (new pattern detection)

If this change introduces **new conventions, patterns, or workflow requirements**:

- Directly execute the corresponding SKILL.md Edit; let the Tool Confirmation UI handle approve / deny (aligned with CLAUDE.md Rule 15)
- **Do not** use text-based prompts like "Do you want to update the Skill definition?"

### 1.6 Skill Integrity Check (if Skill files were changed)

If this change touches any SKILL.md / README.md / new Skill directory, verify item by item:

1. **Each skill directory** contains both `SKILL.md` and `README.md`
2. **Three-part sync of Skills README**:
   - `.claude/skills/README.md` command overview table is updated
   - Detailed description sections are updated
   - Directory structure tree is updated
3. **Generic vs project-specific decision tree**:
   - Generic improvements (not bound to project details) → sync to `sekai-workflow/`, **stripping all project-specific hard-coded values**
   - Project-specific fixes → keep in `.claude/skills/` only, **do not sync**
4. **Generic skills README** (`sekai-workflow/README.md`) is updated
5. **"Available Skills" list in CLAUDE.md** is updated
6. **Explicit declaration**: Skill changes go through the `sekai-workflow` standalone remote repo (`https://github.com/SWSekai/sekai-workflow.git`), **not** the project git

If any item fails → stop commit and ask the user to complete it.

### 1.7 Post-Implementation Data Flow Re-read

After implementation and before commit, **re-read** the modified code and walk through it layer by layer:

| Check Item | Result | Notes |
|---|:---:|---|
| Data flow completeness | ✓/✗ | |
| Cross-layer type consistency | ✓/✗ | |
| Edge case handling | ✓/✗ | |
| Unchanged logic unaffected | ✓/✗ | |

Any ✗ must be fixed before entering the commit flow.

---

## Step 2: Auto-update README.md

Scan the directories containing changed files. If that directory contains `README.md` and its structure / functionality is affected, update it in sync.

**New functional directories** → create README containing:
- Directory purpose
- File / subdirectory structure
- Overview of key functionality

---

## Step 3: Status Overview and Staging

### 3.1 Display Full Pending Status

```bash
git status
git diff --stat
git log --oneline origin/$(git rev-parse --abbrev-ref HEAD)..HEAD
```

List to the user:

- **Unstaged modifications**: one-line summary per file
- **Staged but not committed**: same as above
- **Committed but not pushed**: list commit hash + message
- If there is nothing pending → notify the user and stop

### 3.2 Read `.gitignore` to Confirm Safety

Read `.gitignore` and confirm files about to be staged are not in the ignore list. Full rules in `references/gitignore-safety.md`.

**Forbidden commands**:
- `git add -f` (force add ignored files)
- `git add -A` / `git add .` (may accidentally include sensitive or binary files)

### 3.3 Stage Files

- Use `git add <file>` with specific filenames
- Include any updated README.md

### 3.4 Proceed Directly to staging + commit (no extra confirmation message)

After listing the summary, **directly** execute `git add` + `git commit`. The user decides approve / deny through the Tool Confirmation UI (aligned with CLAUDE.md Rule 15). **Do not** emit text-based confirmations like "Continue?" or "Shall I execute?"

---

## Step 4: Commit

Use **Conventional Commits** format + HEREDOC template. Full spec in `references/commit-conventions.md`.

### 4.1 Prefix Set (11 items)

`feat / fix / ui / docs / refactor / test / chore / perf / build / ci / revert`

See the type mapping table in `references/commit-conventions.md` for details.

### 4.2 Dynamic Co-Author Rules

Fill in the Co-Author string based on the **actual Skill model executing this commit**:

| Execution Context | Co-Author |
|---|---|
| This Skill (`/commit-push`) executes directly | `Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>` |
| Pre-stage produced main decisions from an Opus Skill such as `/build plan` / `/ask` | Append `Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>` as a second line |
| If the change is mainly text / log / docs (the modify log from Step 5 of this Skill) | The log block is produced by Haiku, but the commit itself still uses Sonnet as the primary Co-Author |

### 4.3 Format Rules

- First line: short summary, within 72 characters
- Blank line
- Body: bullet points
- Blank line
- Co-Authored-By line

Example:

```bash
git commit -m "$(cat <<'EOF'
feat: 新增 Teams 告警通知節點

- 整合 webhook 推送機制
- 新增 alert_cooldown 欄位
- 測試涵蓋 9/9 容器

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Step 5: Create Modify Log (embedded Haiku structured output)

> **`--meta` mode**: skip this step entirely. Skill maintenance commits do not generate modify logs (CLAUDE.md Rule 20).
> **`--no-subagent` mode**: main Sonnet session writes the log inline using the same 5.1–5.4 format (no Haiku Agent spawn).

**Default**: invoke a Haiku subtask via the Agent tool to generate the log (structured text-writing attribute).

**All logs are kept local only and must never enter version control.**

### 5.1 Filename Rule

`.local/modify_log/YYMMDD_topic_description.md` (6-digit date + descriptive topic name)

Example: `260313_video_h264_reencode.md`

- **Same day + same topic** → update that file
- **Different topic** → create a new file

### 5.2 Collect Change Info

```bash
git log --oneline -1                    # get commit hash
git diff --stat HEAD~1                  # change stats
git diff --name-only HEAD~1             # list of changed files
git diff --numstat HEAD~1               # added / deleted lines per file
```

### 5.3 Log Format (aligned with user's original standard template)

```markdown
# [Title — one-line description of this change]

## 基本資訊
- **日期時間**：YYYY-MM-DD HH:MM
- **Git 版本**：`<short-hash>` (e.g. `9fe154c`)
- **更動原因**：[motivation / problem description / requirement source]

## 影響檔案
| 檔案 | 變更行數 | 說明 |
|------|---------|------|
| `path/to/file.py` | +12 -5 | what was done, why |
| `path/to/file.js` | +30 -8 | what was done, why |

## 影響範圍
- Affected modules / features
- Container restart requirement (if any)
- DB migration requirement (if any)

## 技術說明
(Write only for non-obvious changes: data flow, logic explanation, architectural decisions)

## 潛在風險
- Edge cases or compatibility issues
- If none: "無已知風險"
```

**Key Format Characteristics**:
- Line count format `+N -M` (space-separated, **not** `+N/-M`)
- Section order: **Impact Scope comes before Technical Notes**
- Field name: **Git 版本** (not just "版本")

### 5.4 Rules

- Language aligned with project convention (this project uses Traditional Chinese, Taiwan)
- **Non-obvious changes** include a code snippet
- **Before / after comparisons** use tables
- **Data flow / decision logic** use ASCII diagrams (especially suitable for sys-info handoff / explanation docs)
- Same day + same topic → update that file instead of creating a new one
- **Local only, never enters version control**

---

## Step 6: Push

```bash
git push
```

If push fails (auth / hook / remote error), report the error with suggestions. **Do not attempt `--force`**, do not attempt `--no-verify`.

---

## Step 7: Sync `sekai-workflow/` to Remote (**Depends on Switch**)

### 7.0 Check Flowback Switch (Mandatory)

Read `sekai_workflow.flowback.push` from `.claude/settings.local.json`:

| State | Behavior |
|---|---|
| `true` | Enter 7.1 to execute the full flow |
| `false` | Skip locally only (no commit, no push); notify the user "Flowback switch is off, this change remains local only" |
| Unset | Treat as `false` (privacy first, default is no push) |

**User prompt when disabled**:
```
⚠️ sekai-workflow flowback disabled (settings.local.json: sekai_workflow.flowback.push=false)
This change remains in local sekai-workflow/ only; not pushed to remote.
To enable, edit .claude/settings.local.json and set flowback.push to true.
```

### 7.1 Privacy Scan (runs when push=true)

**Dual-list scan** (full logic in `references/privacy-check.md`):

- `sekai-workflow/_bootstrap/publish-blocklist.txt` — generic patterns (private keys, credential prefixes), carried with sekai-workflow
- `~/.claude/publish-blocklist.txt` — personal identifiers (name, company, project name), user-global shared across projects

For every file to be committed, use both lists with `grep -iF` matching; filter out comments and blank lines.

- **Any pattern hit** → stop push, list hit files and line numbers, ask user to handle it
- **No hit** → proceed to 7.2
- **Skip self**: `publish-blocklist*.txt` are list files themselves and are not scanned

### 7.2 Execute commit & push

If this run contains changes under `sekai-workflow/`:

```bash
cd sekai-workflow
git add <files>
git commit -m "<mirrored message>"
git push
```

If push fails → notify the user; do not block the main flow.

**If SKILL.md / README.md were changed**, auto-update in sync:
- `sekai-workflow/manifest.json` — corresponding skill entry
- `sekai-workflow/README.md` — command table and descriptions

### 7.3 How to Toggle the Switch

The user can toggle via:
- **Command**: `/update-config` → edit `sekai_workflow.flowback.push`
- **Direct edit**: `.claude/settings.local.json`, set `sekai_workflow.flowback.push` to `true` or `false`

---

## Step 8: Service Restart Evaluation (invoke `/build deploy --plan`)

Enter the evaluation mode of `/build deploy` and output a command list:

```bash
# Pseudo-command, actual work handled by /build deploy --plan
git diff --name-only HEAD~1
docker compose config
```

Output: changed file → service → action mapping table + deduplicated command list + side-effect warnings.

If anything needs executing → prompt that the user can run `/build deploy --run` directly. If there is no containerization → skip.

---

## Step 9: Context Cleanup and Summary (Automatic)

After completing the commit-push flow (including modify log), proactively manage context:

### 9.1 Run context-guard Summary

Follow the Step 2–3 logic of the `context-guard` Skill:

1. Check whether `.local/context_summary/` already has a **same-day + same-topic** summary:
   - Yes → merge (append the new commit info to the existing summary)
   - No → create `YYMMDD_HHMM_topic_description.md`
2. Update `current_topic.md` to record the current working topic
3. Summary contents: in-progress work, completed work, uncommitted changes, todos, key decisions, container restart requirements

### 9.2 Create README.md (for quick user lookup)

Create or **overwrite** README.md in the context summary directory:
- Directory purpose
- List of existing summary files (scan the directory)
- Topic and date of each summary
- Usage notes (how to restore context, how to clean expired summaries)

### 9.3 Prompt User to Run `/clear` ✗ Cannot Be Automated

`/clear` is a built-in CLI command and cannot be programmatically triggered by Claude. After saving the summary, prompt the user: "Summary saved; suggest running `/clear` to free the context window."

---

## Step 10: Experience Sync-back to Guide

If this change contains **non-obvious root causes, workarounds, or config differences**:

1. **Criteria for judgment**:
   - Did the issue take a noticeable amount of time to diagnose?
   - Is the root cause non-obvious (e.g. auth hang, environment differences)?
   - Does the config differ from docs / defaults?
   - Is it a workaround for a tool / platform limitation?

2. **If yes**, update the corresponding `.local/docs/guide/<topic>.md`:
   - Add a troubleshooting / FAQ section
   - Format: **Symptom** → **Cause** → **Resolution** → **Notes**
   - If no matching guide exists → create one under `.local/docs/guide/`

3. **Inform the user**: "This experience has been written into `.local/docs/guide/<topic>.md` and will be carried along when `/skm pack` runs."

This ensures operational knowledge is deposited in portable documentation rather than left in conversation history.

---

## Step 11: Auto-Append to Daily Report (Mandatory, silent)

> **`--meta` mode**: skip this step entirely. Skill maintenance commits do not land in daily report (CLAUDE.md Rule 20).
> ⚠️ **Audience rule (MANDATORY)**: the daily report is written for the user's supervisor, not as a dev diary. When populating §1 本日完成 / §5 本日決策 from this commit, follow `team/references/daily-report.md` §4.0 — outcomes first, no function names / parameter values / decision-doc paths in body text, quantify with KPI, never mention Claude internals. Commit message and modify_log may contain implementation detail; do NOT copy them verbatim into the daily report body.

Append this commit's record to today's daily report `.local/report/YYMMDD_daily_report.md` per `team/references/daily-report.md` §7.3. Every `/commit-push` run must land in the daily report so that daily work ledger is complete regardless of trigger count.

### 11.1 Resolve target

1. Get today's date: `date '+%y%m%d'` → `YYMMDD`
2. Target path: `.local/report/YYMMDD_daily_report.md`
3. If daily report does not exist → create from `team/assets/daily-report-template.md` skeleton with header filled in

### 11.2 Append commit row to §6 作業記錄

Find the `## 作業記錄` → `### commit 記錄` table. Append one row:

```
| {HH:MM} | `{short_hash}` | {commit message first line} | ✅ |
```

Mark ✅ because `/commit-push` guaranteed `modify_log` was written in Step 5 — the daily report's integrity cross-check (spec §3.6) will see this commit covered.

### 11.3 Refresh other auto-updated sections

Per `references/daily-report.md` §6.1, also smart-update §1 本日完成 / §2 進行中 / §3 待辦與阻塞 / §5 本日決策與討論結論 from current TODO.md and any CLOSED_ files dated today. §4 交接事項 is preserved (not touched).

### 11.4 Update header stamp

Update the header line to:
```
> 最後更新：{YYYY-MM-DD HH:MM} | 來源：commit-push (hash {short_hash})
```

### 11.5 Silent mode

No user prompt, no handoff question. This is equivalent to calling `/team report --daily` in automatic mode on the current commit — the daily report is a **daily accumulator** that captures every commit even if the user skips `/commit-push` later (see `references/daily-report.md` §3.6 integrity mechanism for bypassed commits).

### 11.6 Self-check

- [ ] `.local/report/YYMMDD_daily_report.md` exists after this step
- [ ] This commit's hash appears in §6 commit 記錄 table with ✅
- [ ] Header "最後更新" timestamp advanced
- [ ] §4 交接事項 content unchanged from previous state

---

Arguments: $ARGUMENTS (optional commit message override)
