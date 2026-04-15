# Skill-personal 快速上手指南

> **對象**：使用 Claude Code 協作開發的團隊成員
> **前提**：已安裝 [Claude Code CLI](https://claude.com/claude-code)

---

## 這是什麼？

**Skill-personal** 是一組可攜式的 Claude Code 自動化指令（Skills），讓 AI 助手在任何專案中都能遵循一致的工作流程：自動品質檢查、結構化 commit、修改日誌、容器重啟評估等。

你不需要手動設定每個專案的 AI 行為 — 只要初始化一次，所有規則和指令就會自動就位。

---

## 30 秒快速開始

```bash
# 1. Clone 到本地（與專案目錄同層）
git clone https://github.com/SWSekai/Skill-personal.git

# 2. 進入你的專案目錄，執行一鍵建置
cd /path/to/your-project
/path/to/Skill-personal/setup/sp-init.bat
```

完成後你的專案會多出：
- `.claude/skills/` — 專案專屬 Skill（已客製化）
- `.Sekai_workflow/` — 通用模板同步用（指向本倉庫）
- `CLAUDE.md` — AI 行為規範
- `.git/hooks/pre-commit` — 防止 Skill 檔案誤入版控

**以上全部已加入 `.gitignore`，不會影響專案版控。**

---

## 指令一覽

在 Claude Code 對話中輸入指令即可使用：

### 日常開發

| 指令 | 用途 | 觸發方式 |
|------|------|----------|
| `/commit-push` | 完整提交流程（品質檢查→日誌→推送→重啟評估） | 手動 |
| `/quality-check` | 程式碼品質審計 | commit 前自動 / 手動 |
| `/todo` | 處理 AI 待辦事項清單 | 手動 |

### 容器管理

| 指令 | 用途 | 觸發方式 |
|------|------|----------|
| `/restart-eval` | 分析哪些容器需重啟 | commit 後自動 / 手動 |
| `/restart-volumn api-gateway` | 執行容器重啟（含健康檢查） | 手動 |

### 追蹤與文件

| 指令 | 用途 | 觸發方式 |
|------|------|----------|
| `/trace-flow user_id` | 追蹤欄位從 UI 到 DB 的完整路徑 | 手動 |
| `/sys-info` | 查詢系統架構並管理文件 | 詢問系統問題時自動 |
| `/report weekly` | 從修改紀錄生成週報 | 手動 |

### 協作與管理

| 指令 | 用途 | 觸發方式 |
|------|------|----------|
| `/md-collab` | 生成 Markdown 決策表供互動式協作 | 手動 |
| `/context-guard` | 整理 context 摘要，釋放對話空間 | 壓縮通知自動 / 手動 |
| `/skill-sync` | 同步 Skill 環境與遠端倉庫 | 對話開始自動 / 手動 |
| `/modify-log` | 建立修改日誌 | commit 後自動 / 手動 |

---

## 運作原理（3 分鐘理解）

### 三層架構

```
Skill-personal (遠端倉庫)     ← 通用模板，跨專案共享
       ↓ clone / sync
.Sekai_workflow/ (專案內)     ← 通用模板本地副本
       ↓ customize
.claude/skills/ (專案內)      ← 專案專屬 Skill，可客製化
```

- **上游更新**：有人改進通用 Skill → `/skill-sync` 自動拉取並合併
- **下游回流**：你在專案中改進了某個 Skill 且具通用性 → 自動回流至遠端倉庫

### 版控邊界

| 東西 | 歸誰管 | 進專案 git？ |
|------|--------|:------------:|
| 你的程式碼 | 專案 git | ✓ |
| `.claude/skills/` | 本地，不版控 | ✗ |
| `.Sekai_workflow/` | Skill-personal 遠端倉庫 | ✗ |
| `CLAUDE.md` | 本地，不版控 | ✗ |
| 修改日誌 / 摘要 | 本地工作紀錄 | ✗ |

**原則：專案 git 只追蹤程式碼，AI 相關檔案全部由本地或個人倉庫管理。**

---

## 常見情境

### 「我改完 code 想提交」
直接告訴 Claude：「提交」或輸入 `/commit-push`。Claude 會自動：
1. 掃描品質 → 2. 列出變更 → 3. commit → 4. push → 5. 建修改日誌 → 6. 告訴你哪些容器要重啟

### 「我想知道這個欄位怎麼從前端到後端」
輸入 `/trace-flow 欄位名`，Claude 會逐層追蹤並標註資料遺失風險。

### 「上週做了什麼？」
輸入 `/report weekly`，Claude 從修改日誌生成簡報格式的週報。

### 「對話太長了，AI 開始忘東忘西」
輸入 `/context-guard`，Claude 會整理摘要存檔，然後你輸入 `/clear` 釋放空間。下次開對話時自動恢復。

### 「有設計決策要跟 AI 討論」
輸入 `/md-collab 主題`，Claude 生成一份 Markdown 核取表，你勾選後回覆，Claude 按你的選擇實作。

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
/path/to/Skill-personal/setup/sp-verify.bat /path/to/your-project
```

驗證項目：`.gitignore` 規則、hook 安裝、目錄結構、遠端連線。

---

## 給其他 AI 工具的說明

如果你使用的不是 Claude Code 但支援自訂 system prompt：
1. 將 `CLAUDE.md` 的內容貼入 system prompt
2. 將 `.claude/skills/` 中的 `SKILL.md` 作為工具定義參考
3. 核心概念相同：品質檢查 → commit → 日誌 → 重啟評估

---

> **manifest.json** 提供機器可讀的完整 Skill 索引，AI 讀取此檔即可掌握全貌。
> 
> 本指南會隨 Skill 新增/修改自動更新。

<!-- AUTO-GENERATED: Last updated 2026-04-01 -->
<!-- Skill count: 12 -->
