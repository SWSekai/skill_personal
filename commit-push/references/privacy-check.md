# 隱私掃描（Privacy Check）

> `/commit-push` Step 7.1 在 push 前對 `sekai-workflow/` 待 commit 檔案做內容掃描，避免個人識別字串、憑證、內網資訊被意外推送至公開倉庫。

---

## 掃描來源（雙清單）

| 檔案 | 位置 | 內容 | 攜帶方式 |
|---|---|---|---|
| `publish-blocklist.txt` | `sekai-workflow/_bootstrap/` | 通用樣式（憑證前綴、設定字串） | 隨 sekai-workflow 倉庫 |
| `publish-blocklist.txt` | `~/.claude/` | 個人識別（姓名、公司、專案名） | user-global，跨專案共用 |

## 掃描邏輯

```bash
cd sekai-workflow
HITS=""
while IFS= read -r f; do
    # 跳過二進位與已刪除檔案
    [ -f "$f" ] || continue
    # 逐行比對 blocklist（註解與空行需過濾）
    while IFS= read -r pat; do
        case "$pat" in ''|\#*) continue ;; esac
        if grep -inF "$pat" "$f" >/dev/null 2>&1; then
            HITS="${HITS}
$f: $pat"
        fi
    done < _bootstrap/publish-blocklist.txt
done < <(git diff --cached --name-only)
```

## 命中處理

1. **列出命中清單**：`檔案:命中 pattern`
2. **停止 push**：不 commit、不 push，交由使用者決定
3. **建議處置**：
   - 替換為通用字串 / 變數 / 佔位符
   - 確認是否為誤報（例如字串是文件說明）→ 加入 `publish-blocklist.ignore`（未來擴充）
   - 確認字串無敏感性 → 暫時註解該 blocklist 行

## 新增 pattern 時機

- 新發現的個人識別字串（姓名、公司、email、IP）
- 新專案名（若 skill 不該提及特定專案）
- 新的憑證前綴（AWS / GitHub / OpenAI token 等）
- 內網路徑 / VPN 名稱

## 與 pre-commit hook 的差異

| 檢查層 | 觸發 | 範圍 | 用途 |
|---|---|---|---|
| pre-commit hook（`_bootstrap/hooks/pre-commit`）| 專案 git commit | 專案根倉庫 | 阻擋 `.claude/ Sekai_workflow/ CLAUDE.md` 等入版控 |
| Privacy check（本文件）| `/commit-push` Step 7.1 | `sekai-workflow/` 待 push 檔案 | 阻擋敏感字串推送至公開倉庫 |

兩者互補，互不取代。
