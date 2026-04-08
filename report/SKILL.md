---
name: report
description: "Generate a concise work report from modification logs for 2-3 minute presentations. Supports full, weekly, or date-range reports."
model: haiku
effort: low
argument-hint: "[full|weekly|MMDD-MMDD]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(git log*), Bash(git diff*), Bash(ls *), Bash(date *)
---

# Report — 工作報告生成

## 用途

從專案的修改紀錄中，自動統整生成適合 **2～3 分鐘簡報** 的工作報告。

## 觸發方式

- `/report` — 生成全量報告（所有修改紀錄）
- `/report weekly` — 生成近 7 天的週報
- `/report YYMMDD YYMMDD` — 生成指定期間報告（起始日 結束日）

---

## 報告生成流程

### Step 1: 確定報告範圍

根據參數決定要讀取的修改紀錄範圍：

- 無參數 / `full` → 讀取全部
- `weekly` → 讀取近 7 天（依檔名日期前綴篩選）
- `YYMMDD YYMMDD` → 讀取指定區間

修改紀錄存放於 `.local/modify_logs/`（由 `setup.bat` 建立）。

### Step 2: 讀取並分析所有紀錄

逐一讀取範圍內的修改紀錄，提取：
- 改動主題與分類
- 影響的檔案與服務
- 技術亮點
- 潛在風險與待追蹤事項

### Step 3: 生成報告

**檔名規則**：
- 全量：`YYMMDD_full_report.md`
- 週報：`YYMMDD_weekly_report.md`
- 期間：`YYMMDD_report_[起始]_to_[結束].md`

**報告結構**（針對 2～3 分鐘簡報最佳化）：

```markdown
# [專案名稱] 開發進度報告

> 報告日期：YYYY-MM-DD
> 涵蓋期間：YYYY-MM-DD ～ YYYY-MM-DD
> 修改紀錄數：N 筆

---

## 一、重點成果摘要
（2～3 句話總結本期工作量與核心方向，讓聽眾 30 秒內掌握全貌）

---

## 二、功能開發分類統整
（依功能領域分組，每組用表格列出項目 + 一句話說明）

| 項目 | 說明 |
|------|------|
| ... | ... |

---

## 三、關鍵技術亮點
（3～5 個 bullet，挑出值得提的技術決策或設計模式）

---

## 四、影響的服務與容器
（表格列出各服務被改動的項目數與主要內容）

| 服務 | 涉及項目數 | 主要改動 |
|------|-----------|---------|
| ... | ... | ... |

---

## 五、待追蹤事項
（列出已知的風險、未完成的項目、需後續驗證的功能）
```

### Step 4: 輸出報告

將報告寫入 `.local/reports/`。

---

## 報告撰寫原則

1. **簡報導向**：每個段落都要能在 30 秒內講完，避免冗長技術細節
2. **表格優先**：用表格取代長篇敘述，一目了然
3. **分類清晰**：依功能領域分組，不按時間排列（避免流水帳）
4. **技術亮點精煉**：只挑 3～5 個最值得提的設計決策
5. **可行動的追蹤事項**：待追蹤項目要具體，不要模糊的「持續優化」
6. **語言**：自動偵測專案語言慣例

Arguments: $ARGUMENTS (可選：full / weekly / YYMMDD YYMMDD)
