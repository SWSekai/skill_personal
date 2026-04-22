# Supported Interaction Modes

Pick the mode that best fits the topic. Output text in the mode templates below uses Traditional Chinese (project language) — the rule text is English to match SKILL.md conventions.

**Mode A — Single-Select Matrix** (e.g. permission level configuration)
```markdown
| # | 項目 | [ ] 低 | [ ] 中 | [ ] 高 |
```
Each row admits exactly one check, representing the chosen level/category.

**Mode B — Multi-Select List** (e.g. feature flags, migration items)
```markdown
| # | 項目 | 說明 | [ ] 啟用 |
```
Multiple rows may be checked; each check represents "enabled / selected".

**Mode C — Free-Form Input** (e.g. parameter values, name mappings)
```markdown
| # | 項目 | 現狀 | 新值（請填寫） |
```
User types values directly into the table cells. For standalone free-form questions (outside tables), use the unified syntax defined in `SKILL.md §C.2` and `followup.md §6`:
```markdown
**答案**: ____________
```

**Mode D — Hybrid**
The modes above may be mixed; different sections within one document may use different modes.
