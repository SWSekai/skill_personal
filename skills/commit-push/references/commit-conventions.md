# Commit Message 規範

> 本文件為 `/commit-push` Step 4 的完整規範，對齊 CLAUDE.md 第 1 條與第 18 條。

## Prefix 類型表（11 個）

遵循 **Conventional Commits** 規範，本專案使用完整 11 個類型：

| Prefix | 用途 | 範例 |
|---|---|---|
| `feat` | 新功能 | `feat: 新增 Teams 告警通知節點` |
| `fix` | Bug 修復 | `fix: 修正 alert_rules 欄位不一致` |
| `ui` | 純 UI 調整（專案自訂） | `ui: 統一按鈕樣式` |
| `docs` | 純文件變更 | `docs: 更新 README 部署章節` |
| `refactor` | 重構（不改變行為） | `refactor: 抽取 alert 共用邏輯` |
| `test` | 新增或修改測試 | `test: 新增 alert_rules 整合測試` |
| `chore` | 維護、工具、設定 | `chore: 升級 dependencies` |
| `perf` | 效能改進 | `perf: 快取查詢結果避免重算` |
| `build` | 建置系統 / 外部依賴 | `build: 更新 Docker base image` |
| `ci` | CI 設定變更 | `ci: 新增 GitHub Actions 工作流程` |
| `revert` | 回滾先前 commit | `revert: 回退 alert_rules v2.2 同步` |

**選擇原則**：
- 無法明確歸類時 → 優先使用 `feat` / `fix` / `refactor`
- 同一 commit 跨多類型時 → 取**主要**影響類型
- **禁止**自創 prefix（如 `update:` / `add:`）

---

## 格式規則

- **第一行（summary）**：`<type>: <短摘要>`，**總長度 72 字元以內**
- **空行**
- **Body**：要點列表（bullet points），每點描述一個具體變更
- **空行**
- **Co-Authored-By 行**：依下方動態規則填入

---

## 動態 Co-Author 規則（對齊 CLAUDE.md 第 18 條）

根據**實際執行此 commit 的 Skill model** 動態填入 Co-Author 字串。

### 單一 model 執行

| 執行情境 | Co-Author 字串 |
|---|---|
| `/commit-push` 主流程（Sonnet）| `Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>` |
| 純規劃 / 品質評估（Opus）| `Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>` |
| 純文字 / 日誌 / 模板產出（Haiku）| `Co-Authored-By: Claude Haiku 4.5 <noreply@anthropic.com>` |

### 多 model 協作執行

當一個 commit 是多個 model 協作的產出（例如先 `/build plan`（Opus）→ `/build do`（Sonnet）→ `/commit-push`（Sonnet））：

```
Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

- **主 Co-Author**：執行 commit 的 Skill model（通常為 Sonnet）
- **次 Co-Author**：本 commit 明顯含有的其他 model 產出（Opus 規劃 / Haiku 日誌）
- 最多列兩個 Co-Author，不要堆疊

### 判斷原則

- 能清楚指名「是誰做的」→ 填該 model
- 混合且難以分離 → 只填主要執行者
- **嚴禁**填 `Claude <noreply@anthropic.com>`（無版本資訊）

---

## HEREDOC 模板

用 HEREDOC 避免 shell 跳脫問題：

```bash
git commit -m "$(cat <<'EOF'
<type>: <短摘要>

- 變更點 1
- 變更點 2
- 變更點 3

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## 完整範例

### 單一 Sonnet 執行

```bash
git commit -m "$(cat <<'EOF'
feat: 新增 Docker 容器健康監控與 Teams 告警

- 新增 monitor/docker-health-check.ps1 主監控腳本
- 整合 Task Scheduler 每分鐘呼叫
- 雙層健康檢查（docker inspect + TCP port）
- 去抖動（連續 2 次失敗才告警）
- 冷卻期（同服務 10 分鐘內只告警一次）
- 全容器回歸測試 9/9 PASS

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

### Opus 規劃 + Sonnet 實作的多 model 協作

```bash
git commit -m "$(cat <<'EOF'
refactor: 統一 commit-push 格式與 Skill Model 分層

- /commit-push 恢復獨立 Skill 為主要入口
- modify log 格式對齊原版 (+N -M 空格格式)
- quality-check Step 5/5b Skill 同步判斷樹恢復
- CLAUDE.md 新增第 18 條 Model 三層分層原則

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## 禁用模式

❌ 無 prefix：`新增告警系統`
❌ 自創 prefix：`update: 告警系統`
❌ 中英文混 prefix：`Feat: 告警系統`
❌ 第一行超過 72 字元
❌ 無 Co-Author（違反 CLAUDE.md 第 1 條）
❌ Co-Author 無版本：`Co-Authored-By: Claude <noreply@anthropic.com>`
❌ 使用中國大陸用語（視頻 / 文件 / 信息 / 默認 / 數據 / 程序 等，見 CLAUDE.md 語言規範表）
