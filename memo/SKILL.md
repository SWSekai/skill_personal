---
name: memo
description: "Memory cross-project portability: feedback/user type memory is carried with Sekai_workflow git and automatically restored during new project initialization."
model: sonnet
effort: low
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(ls *), Bash(cp *), Bash(git *)
---

## Memory Cross-Project Portability

Manages `feedback` and `user` type memory files so they can be carried with Sekai_workflow to new projects.

---

### Step 1: Identify Portable Memory

Scan the current project's memory directory (`~/.claude/projects/{project}/memory/`) and filter:

- **Portable**: `feedback` and `user` types (cross-project preferences and habits)
- **Not portable**: `project` and `reference` types (bound to a specific project)

Decision basis: read the frontmatter `type` field of each `.md` file.

---

### Step 2: Sync to Sekai_workflow

Copy the filtered memory files to `Sekai_workflow/memo/`:

```bash
cp ~/.claude/projects/{project}/memory/feedback_*.md Sekai_workflow/memo/
cp ~/.claude/projects/{project}/memory/user_*.md Sekai_workflow/memo/
```

- **Do not overwrite existing files with the same name** (preserve existing version)
- Update the file list in `Sekai_workflow/memo/README.md`

---

### Step 3: Restore (triggered by sp-init.bat)

Executed automatically during new project initialization:

1. Copy `Sekai_workflow/memo/*.md` to the current account's `~/.claude/projects/{project}/memory/`
2. Do not overwrite existing files with the same name
3. Automatically generate or merge the `MEMORY.md` index

---

### Step 4: Write-Back (triggered by sp-pack.sh)

During project packaging:

1. Scan the memory directory to find newly added feedback/user memory
2. Copy them to `Sekai_workflow/memo/`
3. commit + push Sekai_workflow

---

### Step 5: Proactive Write-Back During Conversation (mandatory, aligned with CLAUDE.md rule 9)

**Do not rely solely on sp-pack.sh** — if a new `feedback` / `user` type memory is written during a conversation, **in the same reply** determine whether it is cross-project general:

1. **Yes** (e.g. "commit format", "model tier split", "UI preferences") → immediately `cp` to `sekai-workflow/memo/` + commit + push
2. **No** (e.g. "this project's alert_rules field name") → keep it only in the project memory

**Ordering pitfall**: This Skill's hook (`memory_skill_sync.cjs`) tracks write order. If skills are written first and memory second, the flag persists → the Stop hook displays "incomplete". Correct order:

```
1. Write memory file first (Write ~/.claude/projects/.../memory/xxx.md)
2. Then write the corresponding skill change (Write sekai-workflow/xxx/SKILL.md or .claude/skills/xxx/SKILL.md)
```

If the order is reversed, the flag can be cleared by "writing any skill file again".

---

## Portable Memory Directly Benefiting This Skill

- `feedback_model_tier.md` — Skill model three-tier split (Opus / Sonnet / Haiku), affects the `model:` field selection in Skill frontmatter
- `feedback_commit_format.md` — Strict format for Commit Message and Modify Log, affects `/commit-push` execution

A new project's `sp-init.bat` will automatically bring in these two — no manual action needed.

---

## Cross-Skill References

| Direction | Target | Trigger / Purpose |
|---|---|---|
| → Reads | `~/.claude/projects/<path>/memory/` | Source for memory archival to portable bag |
| → Writes | `sekai-workflow/memory-portable/` | Cross-project portable memory store |
| ← Called by | `/skm pack` | Pack flow archives memory into portable form |
| ← Called by | `_bootstrap/sp-init.bat` Step 3 | New-project init auto-restores memory from portable store |
| ↔ Shared | `manifest.json` `memory-portable` entry | Manifest tracks the memory archive |

**Rename History (this skill only)**: skill name `memory-portable` → `memo` (2026-04-24). Global rename history: see `_bootstrap/RENAME_HISTORY.md`.

---

Arguments: $ARGUMENTS (optional — new project sp-init.bat triggers Step 3 automatically)
