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
4. **收集通用指南** — 掃描 `.local/docs/`、`docs/`、專案根目錄，收集含 `guide` 或 `指南` 的文件至 `guides/`
5. **產生 manifest.txt** — 打包時間、檔案清單、還原指引
6. **清除** — 刪除 `.claude/skills/`、`skill_personal/`、`CLAUDE.md`

## 腳本執行後 — AI 合併指南（必須執行）

腳本完成後，Claude **必須** 對 `.local/ai-context/guides/` 進行智慧合併：

1. **讀取所有收集到的指南文件**
2. **識別重複/重疊主題** — 例如多份 K8s 部署指南、多份 CI/CD 指南
3. **合併同主題文件** — 規則：
   - 盡力保留所有資訊，不丟棄任何實務細節
   - 合併後的文件以主題命名（如 `guide-k8s-deployment.md`、`guide-cicd-pipeline.md`）
   - 保留每份來源文件的出處（在合併文件頂部註明原始路徑）
   - 衝突資訊並列保留，標註差異
   - 目標：產出可作為日後閱讀的「實務精華」
4. **刪除已合併的原始檔案**，只保留合併後的版本
5. **無重疊的獨立指南** 保持原樣，僅重新命名為乾淨的主題名稱

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
