# /admin — Skill 環境管理合併 Skill

整合 create-skill、skill-sync、pack 三個原始 Skill。

## 使用方式

| 指令 | 說明 |
|---|---|
| `/admin new [name] [desc]` | 互動式建立新 Skill |
| `/admin sync` | `.skill_personal/` 遠端同步、規則評估 |
| `/admin pack` | 專案打包並清除 skill 環境 |

## Model

- **Skill model**：`sonnet`
- 三個子命令均屬於多步驟工作流，sonnet 即可

## 觸發

- **手動**：使用者呼叫 `/admin <subcommand>`
- **自動**：
  - `sync`：對話開始時、寫入 Memory 時、修改 `.skill_personal/` 時
  - `pack`：僅手動

## 主要流程

### `/admin new`
收集定義（含 model + effort）→ 衝突檢查 → 生成 SKILL.md + README.md → 評估子目錄需求 → 更新 `.claude/skills/README.md` 與 `CLAUDE.md` → 同步 `.skill_personal/`（若通用）→ 完整性驗證

### `/admin sync`
**流程一**：執行 `bash .skill_personal/setup/sp-sync.sh`，自動 fetch / pull / 比對 / 複製到 `.claude/skills/`  
**流程二**：寫入 Memory 時即時做三向連動評估（CLAUDE.md / `.skill_personal/` / 僅 Memory）

### `/admin pack`
執行 `bash .skill_personal/setup/sp-pack.sh`，收集 AI 上下文到 `.local/ai-context/`，保存專案專屬 skill，刪除 skill 環境。腳本完成後 AI 必須智慧合併 `.local/ai-context/guides/` 同主題文件。

## 檔案結構

```
.claude/skills/admin/
├── SKILL.md
└── README.md
```

## 對應原 Skill

| 原 Skill | 子命令 |
|---|---|
| create-skill | `/admin new` |
| skill-sync | `/admin sync` |
| pack | `/admin pack` |
