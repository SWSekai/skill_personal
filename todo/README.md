# todo — AI TODO Processing

## Overview

One-command processing of TODO items. AI sorts by priority, asks follow-up questions for vague descriptions, executes tasks, and marks completion with commit references.

## Directory Structure

```
todo/
├── README.md    ← This file
└── SKILL.md     ← Skill definition and execution flow
```

## Usage

```
/todo              — Process pending items (highest priority first)
/todo add <desc>   — Quick-add a new item (supports @high / @low)
/todo list         — List all pending items
```

## Execution Flow

| Step | Description |
|------|-------------|
| 1. Read & parse | Read TODO file, extract items and priorities |
| 2. Sort & select | Sort by @high → normal → @low, user picks items |
| 3. Detail confirmation | Evaluate description clarity, ask follow-up questions if needed |
| 4. Execute task | Move to "In Progress", perform actual code changes |
| 5. Completion | Move to "Completed" with commit hash, continue or finish |
| 6. Wrap-up | Present summary, offer commit-push |

## TODO Format

```markdown
## Pending
- [ ] description @high        ← high priority
- [ ] description              ← normal priority
  - supplementary notes
- [ ] description @low         ← low priority

## In Progress
- [~] description — processing (timestamp)

## Completed
- [x] description — done timestamp
  - commit: `hash` message
```
