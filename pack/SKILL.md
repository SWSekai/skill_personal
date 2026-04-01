---
name: pack
description: "專案打包：收集 AI 上下文到 .local/ai-context/，保存專案專屬 skill，然後清除 skill 環境（.claude/skills/、skill_personal/、CLAUDE.md）。還給專案乾淨的版控環境。"
allowed-tools: Bash(bash *), Bash(ls *), Bash(cat *), Read
---

# Pack — 專案打包工具

## 用途

將專案中所有 AI 維護相關的檔案整理打包到 `.local/ai-context/`，然後刪除非專案版控的 skill 環境，還原乾淨的專案目錄。

## 觸發方式

手動呼叫 `/pack`

## 執行方式

**直接執行自動化腳本：**
```bash
bash skill_personal/setup/sp-pack.sh
```

## 腳本行為

1. **收集** — CLAUDE.md、.local/ 工作紀錄、Memory、skills 快照
2. **偵測專案專屬 skill** — 比對 `.claude/skills/` vs `skill_personal/`，不在 skill_personal 的就是專案專屬
3. **保存專案專屬 skill** → `.local/ai-context/project-skills/`
4. **產生 manifest.txt** — 打包時間、檔案清單、還原指引
5. **清除** — 刪除 `.claude/skills/`、`skill_personal/`、`CLAUDE.md`

## 執行後注意

- 腳本會要求使用者確認（y/N）才會執行刪除
- 打包結果在 `.local/ai-context/`（已在 .gitignore，不入版控）
- 還原方式見 `manifest.txt`

## 還原流程

1. `skill_personal/setup/sp-init.bat` — 重建 skill 環境
2. `bash skill_personal/setup/sp-sync.sh` — 同步最新 skill
3. 將 `project-skills/` 複製回 `.claude/skills/`
4. 將 `CLAUDE.md` 複製回根目錄
5. 將 `memory/` 複製回 `~/.claude/projects/.../memory/`
