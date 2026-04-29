# Sekai-workflow 快速上手指南

> **對象**：使用 Claude Code 協作開發的團隊成員
> **前提**：已安裝 [Claude Code CLI](https://claude.com/claude-code)

---

## 這是什麼？

**Sekai-workflow** 是一組可攜式的 Claude Code 自動化指令（Skills），讓 AI 助手在任何專案中都能遵循一致的工作流程：自動品質檢查、結構化 commit、修改日誌、容器重啟評估等。

你不需要手動設定每個專案的 AI 行為 — 只要初始化一次，所有規則和指令就會自動就位。

---

## 30 秒快速開始

```bash
# 1. Clone 到本地（與專案目錄同層）
git clone https://github.com/SWSekai/sekai-workflow.git

# 2. 進入你的專案目錄，執行一鍵建置
cd /path/to/your-project
/path/to/sekai-workflow/Sekai_workflow/_bootstrap/sp-init.bat
```

完成後你的專案會多出：
- `.claude/skills/` — 專案專屬 Skill（已客製化）
- `Sekai_workflow/` — 通用模板同步用（指向本倉庫）
- `CLAUDE.md` — AI 行為規範
- `.git/hooks/pre-commit` — 防止 Skill 檔案誤入版控

**以上全部已加入 `.gitignore`，不會影響專案版控。**

---

## 指令一覽（合併版 6 Skill）

| Skill | 指令 | 用途 |
|---|---|---|
| **build** | `/build <flow\|plan\|impl\|test\|quality\|review\|deploy>` | 開發全流程 |
| **team** | `/team <todo\|board\|decide\|note\|handoff\|report\|journal\|follow-up>` | 互動協作（原 team-office） |
| **skm** | `/skm <new\|sync\|pack\|update\|refactor>` | Skill 管理（2026-04-24 由 `/skill` 改名，避免與內建 `/skills` 衝突） |
| **kb** | `/kb <add\|search\|extract>` | Knowledge Base 管理（2026-04-24 新增） |
| **ask** | `/ask <info\|trace>` | 系統文件追蹤（report 已併入 `/team report`） |
| **clean** | `/clean [check\|force]` | Context 清理（繼承 context-guard 功能） |
| **memo** | `/memo` | Memory 跨專案攜帶（原 memory-portable） |
| **commit-push** | `/commit-push [--meta] [--no-subagent]` | Commit & Push 主入口 |
| **hello** | `/hello` | 對話初始化 + Skill 同步 + 工作狀態重建 |
| **dispatch** | `/dispatch <task>` | 任務分派（Rule 18 model 三層分工） |

---

## 運作原理（3 分鐘理解）

### 三層架構

```
sekai-workflow (遠端倉庫)      ← 通用模板，跨專案共享
       ↓ clone / sync
Sekai_workflow/ (專案內)       ← 通用模板本地副本
       ↓ customize
.claude/skills/ (專案內)       ← 專案專屬 Skill，可客製化
```

- **上游更新**：有人改進通用 Skill → `/skm sync` 自動拉取並合併
- **下游回流**：你在專案中改進了某個 Skill 且具通用性 → 自動回流至遠端倉庫

### 版控邊界

| 東西 | 歸誰管 | 進專案 git？ |
|------|--------|:------------:|
| 你的程式碼 | 專案 git | ✓ |
| `.claude/skills/` | 本地，不版控 | ✗ |
| `Sekai_workflow/` | sekai-workflow 遠端倉庫 | ✗ |
| `CLAUDE.md` | 本地，不版控 | ✗ |
| 修改日誌 / 摘要 | 本地工作紀錄 | ✗ |

**原則：專案 git 只追蹤程式碼，AI 相關檔案全部由本地或個人倉庫管理。**

---

## 常見情境

### 「我改完 code 想提交」
直接告訴 Claude：「提交」或輸入 `/build commit`。Claude 會自動：
1. 掃描品質 → 2. 列出變更 → 3. commit → 4. push → 5. 建修改日誌 → 6. 告訴你哪些容器要重啟

### 「我想知道這個欄位怎麼從前端到後端」
輸入 `/ask trace 欄位名`，Claude 會逐層追蹤並標註資料遺失風險。

### 「上週做了什麼？」
輸入 `/ask report weekly`，Claude 從修改日誌生成簡報格式的週報。

### 「對話太長了，AI 開始忘東忘西」
輸入 `/clean`，Claude 會整理摘要存檔，然後執行 `/clear` 釋放空間。下次開對話時 UserPromptSubmit hook 自動恢復。

### 「有設計決策要跟 AI 討論」
輸入 `/team decide 主題`，Claude 生成一份 Markdown 核取表，你勾選後回覆，Claude 按你的選擇實作。

---

## 客製化

每個 Skill 都可以針對專案調整。編輯 `.claude/skills/<skill-name>/SKILL.md`：

- **路徑**：修改日誌存放位置、文件目錄等
- **服務名稱**：Docker 容器名稱、compose 檔路徑
- **語言**：commit 訊息語言、UI 文字偏好
- **流程**：增減步驟、調整觸發條件

修改後的專案版 Skill 不會影響通用模板，除非你判定改進具通用性。

---

## 驗證環境

```bash
# 檢查所有保護層是否就位
Sekai_workflow/_bootstrap/sp-verify.bat /path/to/your-project
```

驗證項目：`.gitignore` 規則、hook 安裝、目錄結構、遠端連線。

---

> **manifest.json** 提供機器可讀的完整 Skill 索引，AI 讀取此檔即可掌握全貌。
> 
> 本指南會隨 Skill 新增/修改自動更新。
