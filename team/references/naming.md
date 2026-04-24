# 檔名與時間規範（naming conventions）

> `/team board`、`/team decide`、`/team note` 等產生互動檔案的子指令必須遵循本檔規範。
> SKILL.md 只放對外行為，細節規則在此。

## 1. 檔名統一格式

| 類型 | 目錄 | 檔名格式 | 範例 |
|---|---|---|---|
| whiteboard | `.local/docs/whiteboards/` | `YYMMDD_<topic>_board.md` | `260422_auth_refactor_board.md` |
| decision | `.local/docs/decisions/` | `YYMMDD_<topic>_decision.md` | `260422_team_followup_decision.md` |
| ~~summary~~ | ~~`.local/docs/summary/`~~ | ~~`YYMMDD_<topic>_summary.md`~~ | ⚠️ 廢棄（2026-04-22）結案摘要改 append 於 CLOSED_ 原檔末尾（見 §5） |
| handoff | `.local/docs/handoff/` | `YYMMDD_handoff.md` | `260422_handoff.md` |
| tech-note | `.local/docs/tech-note/` | `<topic-category>_<specific-topic>.md` | `sql_comments.md` |
| report | `.local/report/` | 見 SKILL.md §F | — |

### 原則
- **YYMMDD 前綴建議**：年月日各兩碼（如 `260422` = 2026-04-22），跨檔排序天然成立。既有無前綴檔（例：`route-a-implementation-plan.md`）仍有效，不強制 rename
- **`_<type>` 類型後綴建議**：board / decision — follow-up 解析器以後綴**優先**判別類型；若檔名不含後綴，退回以「所在目錄」判別（`decisions/` → decision，`whiteboards/` → board）
- **topic 用 snake_case**：全小寫、連字符改底線，避免空格與大寫。**既有含連字符檔名不強制 rename**
- **新檔建議**：新建檔使用完整 `YYMMDD_<topic>_<type>.md`；既有不合規檔案以目錄位置為權威，不回溯 rename

## 2. 時間同步（避免 context 日期漂移）

Claude context 的 `currentDate` 於對話啟動時注入。若對話跨日或 Claude Code 未重啟，`currentDate` 與實際日期會漂移。

### 強制規則
**每次產生 whiteboard / decision / summary / handoff / modify_log 檔案前，必須先呼叫：**
```bash
date '+%Y-%m-%d %H:%M'
```
以 Bash 輸出為準，不得直接套用 `currentDate`。

### 適用範圍
此規則適用於所有需要日期戳的產出：
- `/team board` / `/team decide` / `/team handoff` / `/team report` 建立檔案時
- `/commit-push` 寫 modify_log 時
- `/team journal` 更新「最後更新」戳時

### 注意
- 檔名 YYMMDD 取系統時間**當日**即可（不精確到秒）
- 檔案內容的「建立：YYYY-MM-DD HH:MM」戳應包含小時分鐘
- Windows 非 WSL 環境下 Bash 可能行為不同 → 仍以 `date '+%Y-%m-%d %H:%M'` 為準，不可用 PowerShell 的 `Get-Date`（輸出格式不同）

## 3. 結案機制

### 3.1 檔案層級：`CLOSED_` 前綴
結案時將檔名改為：
```
YYMMDD_topic_board.md   → CLOSED_YYMMDD_topic_board.md
YYMMDD_topic_decision.md → CLOSED_YYMMDD_topic_decision.md
```

### 3.2 `/team follow-up` 對 `CLOSED_*` 的行為
- **靜默過濾**：候選列舉階段就排除 `CLOSED_*` 檔
- 使用者若精確輸入 `CLOSED_xxx` 檔名 → 提示「此檔已結案，請改讀 summary」並附 summary 路徑

### 3.3 區塊層級結案標記（新）
決策文件或白板內某個 `§n.m` 區塊已結案、不再需要 follow-up 處理時，有兩種標記方式：

**方式 A — emoji 標記**（Claude 自動或使用者手動）
```markdown
### §4.1 decision 檔 follow-up 後的行為 ✅
```
標題末加 `✅` = 區塊已結案。

**方式 B — HTML 註解**（使用者手動）
```markdown
### §4.1 decision 檔 follow-up 後的行為
<!-- closed -->
...
```
區塊起始處加 `<!-- closed -->` = 區塊已結案。

### 3.4 互通原則
- Claude 自動結案 → 加 `✅` emoji
- 使用者手動加 `<!-- closed -->` → Claude 下次 follow-up 偵測到，**自動補 `✅`** 於標題末（增加視覺可讀性）
- follow-up 解析器遇到區塊標題含 `✅` **或** 區塊本文含 `<!-- closed -->` → 跳過該區塊，不重覆處理

### 3.5 解析順序（follow-up 執行時）
```
for block in document.blocks:
    if "✅" in block.heading or "<!-- closed -->" in block.body:
        補 emoji 若缺（維持視覺一致）
        continue  # 跳過此區塊
    else:
        解析此區塊的 [x] 與補充說明
```

## 4. 違反修正責任
- 修改任一 skill 時同步檢查並修正檔名格式
- 若發現既有檔違反格式 → 標示於當次 commit message，rename 至標準格式
- 本檔是 `/team` skill 的權威參考，與 SKILL.md 衝突時以本檔為準

## 5. 內嵌摘要模板（CLOSED_ 結案統一格式）

> 2026-04-22 改版：取代舊有獨立 `summary/` 目錄機制。decision 與 whiteboard 結案時在原檔末尾 append 本區塊，然後 rename `CLOSED_`。

### 5.1 插入位置
- **append 於檔案末尾**（不覆蓋原 §1-§n 決策區）
- 原決策文本保留完整 — 勾選痕跡、補充說明、Claude 回應（§6 之類）全部留存
- 內嵌區塊以 `---` 分隔開於原文，清楚標示「此為結案摘要」

### 5.2 統一模板

```markdown
---

# 結案摘要（Closure Summary）

> **結案時間**：YYYY-MM-DD HH:MM
> **狀態**：✅ 已執行 / ⏸ 暫停
> **Commits**：`<hash>`（若已 commit；未 commit 則寫 pending）

## 背景
（1-3 句：為何觸發此決策）

## 最終決策（依決策項目 §n.m 逐項列出）
| 項目 | 採納選項 | 備註 |
|---|---|---|
| §1.1 | §1.1.b | （選項標題摘要） |
| §2.1 | §2.1.c「其他：直接刪除」 | （引用補充說明） |

## 變更清單
| 檔案 | 變更 |
|---|---|
| path/to/file | 新增 / 修改 / 刪除 / rename |

## 🔖 保留候選（僅非單一路線決策適用）
（若本決策**所有**區塊都是單一路線 → 寫「無」）
（若有非單一路線區塊 → 逐項列未採納選項、未採納原因、重啟時機）

- **候選 X（來源 §n.m）**：<描述>
  - 未採納原因：...
  - 重啟時機：...

## 未解決遺留項
（若無 → 寫「無」；若有 → 逐項列，含負責人與時限建議）
```

### 5.3 保留候選規則（對應 CLAUDE.md Rule 17）

- **單一路線區塊（互斥選項）**：只記最終採納項，**不保留**未選項（選 A 即 preclude B，保留無實際價值）
- **非單一路線區塊（可複選 / 多選）**：未勾的選項列入「🔖 保留候選」區塊，附：
  - 未採納原因（使用者補充 or Claude 推斷）
  - 重啟時機（什麼情境下值得重新評估）
- 超過 6 個月未重啟或被新決策取代 → 標註「已作廢」但**不刪除**
- 新對話遇類似需求 → 先讀 living doc 的「🔖 保留候選」表，評估能否重啟

### 5.4 結案流程順序

1. 使用者確認實作完成（tool approval）
2. **append** §5.2 模板區塊至原檔末尾（保留原 §1-§n 全文）
3. `mv YYMMDD_<topic>_<type>.md CLOSED_YYMMDD_<topic>_<type>.md`
4. 更新 `.local/docs/living/PROJECT_JOURNAL.md`：
   - 決策紀錄表加一列，「來源文件」直接連 `CLOSED_*_decision.md`（**不再連 summary 檔，因為沒有**）
   - 若內嵌摘要有「🔖 保留候選」→ 同步 append 到 living doc 的「🔖 保留候選」表

### 5.5 遺留事項

`.local/docs/summary/` 目錄已於 2026-04-22 直接刪除（依本決策 §2.1.c + §6.1.a.1）。新流程無此目錄，若 Claude 於實作中仍寫 summary 檔即為違規，應立即改寫為內嵌模式。

## 6. Skill 子目錄規範（`.claude/skills/<skill>/*`）

### 6.1 子目錄職責分工

| 子目錄 | 職責 | 內容類型 | 禁止內容 |
|---|---|---|---|
| `references/` | 細節規則文件，Claude 按需 Read | `.md` 規格 / 導覽 / 參考表 | 可執行檔、範例資料、二進位 |
| `assets/` | 模板 + 範例資料 | 模板 `.md`、範例 `.json` / `.yaml` / 資料檔 | 可執行腳本、規則文件 |
| `agents/` | 子代理 prompt 模板（延遲導入，見 §4.2.a） | Agent 派遣用 `.md` prompt | 規格、範例資料 |
| `scripts/` | 可執行邏輯（有條件導入，見 §4.2.b） | `.py` / `.js` / `.sh` / `.cjs` | 模板、規則文件、範例資料 |

### 6.2 assets/ 規範（新，回應 §4.2.d.1）

- **只放**：互動模板（如決策表模板、白板模板）、範例資料（用於 Claude 理解輸出格式）
- **禁止**：任何可執行檔（`.py` / `.js` / `.sh` / `.cjs` / `.exe` 等 — 可執行屬 `scripts/` 或專案根 `.claude/hooks/`）
- **禁止**：規格/規則文件（屬 `references/`）
- 既有 `/team/assets/` 下 `collab-template.md` + `whiteboard-template.md` 符合規範，無需調整

### 6.3 職責混淆時的判斷準則

使用者或 Claude 新增檔案時，依下表決定放何處：

1. 「Claude 需讀來遵守規則」→ `references/`
2. 「Claude 需複製或填入後產出檔案」→ `assets/`
3. 「Claude 需 Agent 派遣時複用」→ `agents/`
4. 「Claude 需 Bash 執行」→ `scripts/` 或 `.claude/hooks/`（後者跨 skill 共用）

不合上述四類 → 不屬於 skill 子目錄，放專案 `.local/` 或 `docs/`。
