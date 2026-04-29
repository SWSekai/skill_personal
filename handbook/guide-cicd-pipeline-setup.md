# CI/CD Pipeline 設定指南

> 日期：2026-04-01
> 適用環境：Gitea Actions + Docker + K8s（RKE2）
> 專案：<PROJECT_NAME>

---

## 目錄

1. [架構概覽](#1-架構概覽)
2. [前置條件](#2-前置條件)
3. [Workflow 檔案建立](#3-workflow-檔案建立)
4. [Workflow 配置詳解](#4-workflow-配置詳解)
5. [部署策略：雙 Tag（SHA + latest）](#5-部署策略雙-tagsha--latest)
6. [觸發機制](#6-觸發機制)
7. [部署驗證](#7-部署驗證)
8. [回滾操作](#8-回滾操作)
9. [從測試分支切換到正式分支](#9-從測試分支切換到正式分支)
10. [進階配置](#10-進階配置)
11. [常見問題排���](#11-常見問題排除)
12. [完整部署流程圖（Push → 上線）](#12-完整部署流程圖push--上線)

---

## 1. 架構概覽

```
技術人員修改程式碼 / 驗證 JS
    ↓
git push 到 Gitea
    ↓
Gitea Actions 自動觸發（依設定的分支）
    ↓
┌──────────────────────────────────────────┐
│  1. Checkout 程式碼                       │
│  2. 產生 Git commit short SHA             │
│  3. Docker build                         │
│  4. Docker tag（:SHA + :latest）          │
│  5. Docker push 到 Registry              │
│  6. kubectl set image 更新 K8s deployment │
│  7. 等待 rollout 完成                     │
└──────────────────────────────────────────┘
    ↓
K8s Pod 滾動更新，新版本自動生效
```

**涉及的服務：**

| 服務 | 位址 | 用途 |
|------|------|------|
| Gitea | `<GITEA_HOSTNAME>` | 程式碼託管、CI/CD 觸發 |
| Docker Registry | `<REGISTRY_HOSTNAME>:5000` | Docker image 儲存 |
| K8s Cluster | RKE2（9 節點） | 容器部署與運行 |
| Runner | <RUNNER_BANNER>（<RUNNER_HOST_IP>） | 執行 CI/CD 任務 |

---

## 2. 前置條件

在設定 Pipeline 前，請確認以下條件已滿足：

- [ ] Gitea Actions 已啟用（Repo 頁面有 Actions 頁籤）
- [ ] Runner 已註冊且在線（見 [Runner 架設指南](guide-gitea-actions-runner-setup.md)）
- [ ] Runner 機器可執行 `docker build` / `docker push`
- [ ] Runner 機器可執行 `kubectl` 存取 K8s cluster
- [ ] Proxy 設定已完成（見 [Proxy 設定指南](guide-proxy-network-setup.md)）

---

## 3. Workflow 檔案建立

### 3.1 建立目錄結構

在專案根目錄下建立：

```
.gitea/
└── workflows/
    └── deploy.yaml
```

```bash
mkdir -p .gitea/workflows
```

### 3.2 Workflow 完整內容

`.gitea/workflows/deploy.yaml`：

```yaml
name: Build and Deploy

on:
  push:
    branches: [<DEV_BRANCH>]  # 測試階段；正式後改為 main

jobs:
  deploy:
    runs-on: self-hosted
    steps:
      - name: Checkout
        run: |
          rm -rf ./* ./.git 2>/dev/null || true
          git clone --depth 1 --branch ${{ github.ref_name }} \
            ${{ github.server_url }}/${{ github.repository }}.git \
            --config http.extraHeader="Authorization: token ${{ github.token }}" .
          echo "Checked out ${{ github.sha }}"

      - name: Set short SHA
        run: echo "SHORT_SHA=$(echo ${{ github.sha }} | cut -c1-7)" >> $GITHUB_ENV

      - name: Build Docker image
        run: |
          docker build -t <REGISTRY_HOSTNAME>:5000/<APP_NAME>:${{ env.SHORT_SHA }} .
          docker tag <REGISTRY_HOSTNAME>:5000/<APP_NAME>:${{ env.SHORT_SHA }} \
                     <REGISTRY_HOSTNAME>:5000/<APP_NAME>:latest

      - name: Push to registry
        run: |
          docker push <REGISTRY_HOSTNAME>:5000/<APP_NAME>:${{ env.SHORT_SHA }}
          docker push <REGISTRY_HOSTNAME>:5000/<APP_NAME>:latest

      - name: Deploy to K8s
        run: |
          kubectl set image deployment/<APP_NAME> \
            <APP_NAME>=<REGISTRY_HOSTNAME>:5000/<APP_NAME>:${{ env.SHORT_SHA }} \
            -n <NAMESPACE_PROD>

      - name: Wait for rollout
        run: kubectl rollout status deployment/<APP_NAME> -n <NAMESPACE_PROD> --timeout=120s
```

### 3.3 提交並推送

```bash
git add .gitea/workflows/deploy.yaml
git commit -m "feat: 新增 Gitea Actions CI/CD 自動部署 workflow"
git push origin <DEV_BRANCH>
```

推送後即會自動觸發第一次 CI/CD 流程。

---

## 4. Workflow 配置詳解

### 4.1 觸發條件（on）

```yaml
on:
  push:
    branches: [<DEV_BRANCH>]
```

當指定分支收到 push 時觸發。可指定多個分支：

```yaml
branches: [main, <DEV_BRANCH>]
```

### 4.2 執行環境（runs-on）

```yaml
runs-on: self-hosted
```

使用 `self-hosted` 標籤的 Runner，以**主機模式**執行。
主機模式可直接存取本機的 Docker daemon 和 kubectl。

> **不要使用 `ubuntu-latest`**，雖然 Runner 也有此標籤，
> 但該標籤對應 Docker 容器模式，無法存取主機的 Docker 和 kubectl。

### 4.3 各步驟說明

| 步驟 | 名稱 | 說明 |
|------|------|------|
| 1 | Checkout | 從 Gitea 拉取最新程式碼 |
| 2 | Set short SHA | 取 commit SHA 前 7 碼作為 image tag |
| 3 | Build Docker image | 執行多階段 Docker build（Node build → Nginx serve） |
| 4 | Push to registry | 推送 SHA tag 和 latest tag 到 Registry |
| 5 | Deploy to K8s | 更新 K8s deployment 的 image tag |
| 6 | Wait for rollout | 等待所有 Pod 滾動更新完成（120 秒逾時） |

### 4.4 環境變數傳遞

```yaml
# 寫入環境變數
echo "SHORT_SHA=$(echo ${{ github.sha }} | cut -c1-7)" >> $GITHUB_ENV

# 後續步驟使用
${{ env.SHORT_SHA }}
```

Gitea Actions 使用 `$GITHUB_ENV` 在步驟間傳遞變數，語法與 GitHub Actions 相同。

---

## 5. 部署策略：雙 Tag（SHA + latest）

### 5.1 策略說明

每次 CI/CD 執行時，Docker image 會被標記兩個 tag：

| Tag | 範例 | 用途 |
|-----|------|------|
| **SHA tag** | `<REGISTRY_HOSTNAME>:5000/<APP_NAME>:a36269f` | K8s 部署用，精確對應 git commit |
| **latest tag** | `<REGISTRY_HOSTNAME>:5000/<APP_NAME>:latest` | 手動測試用，永遠指向最新版 |

### 5.2 為什麼不只用 latest？

| 比較項目 | 只用 latest | SHA + latest |
|----------|:-----------:|:------------:|
| 版本追蹤 | 無法追蹤 | commit ↔ image 一對一 |
| 回滾 | 需重新 build 舊版 | `kubectl rollout undo` 一鍵回滾 |
| 問題定位 | 不知道跑的是哪版 | 從 image tag 直接查 git log |
| 多環境部署 | 無法區分版本 | 可指定任意版本部署 |

### 5.3 image tag 與 git commit 的對應

```bash
# 查看目前 K8s 跑的是哪個版本
kubectl get deployment <APP_NAME> -n <NAMESPACE_PROD> -o jsonpath='{.spec.template.spec.containers[0].image}'
# 輸出範例：<REGISTRY_HOSTNAME>:5000/<APP_NAME>:a36269f

# 查看該 commit 的內容
git log a36269f -1
```

---

## 6. 觸發機制

### 6.1 自動觸發

任何 push 到指定分支都會自動觸發 CI/CD：

```bash
# 修改程式碼後
git add .
git commit -m "feat: 更新驗證規則"
git push origin <DEV_BRANCH>
```

推送後可在 Gitea 的 **Actions 頁籤** 查看執行狀態。

### 6.2 手動查看執行結果

在 Gitea Repo 頁面：
> **Actions** → 點擊最新的 workflow run → 查看各步驟 log

### 6.3 不觸發 CI/CD

如果某次 commit 不想觸發 CI/CD，在 commit message 中加入：

```
git commit -m "docs: 更新文件 [skip ci]"
```

---

## 7. 部署驗證

### 7.1 確認 CI/CD 執行結果

在 Gitea Actions 頁面確認所有步驟顯示綠色勾號。

### 7.2 確認 K8s 部署狀態

```bash
# 確認 deployment 狀態
kubectl get deployment <APP_NAME> -n <NAMESPACE_PROD>

# 確認 Pod 狀態
kubectl get pods -n <NAMESPACE_PROD> -l app=<APP_NAME>

# 確認目前運行的 image 版本
kubectl get deployment <APP_NAME> -n <NAMESPACE_PROD> -o jsonpath='{.spec.template.spec.containers[0].image}'
```

### 7.3 確認網站可存取

瀏覽器開啟：`https://<APP_NAME>.prod.<CORP_DOMAIN>`

---

## 8. 回滾操作

### 8.1 一鍵回滾到上一版

```bash
kubectl rollout undo deployment/<APP_NAME> -n <NAMESPACE_PROD>
```

### 8.2 回滾到指定版本

```bash
# 查看部署歷史
kubectl rollout history deployment/<APP_NAME> -n <NAMESPACE_PROD>

# 回滾到指定 revision
kubectl rollout undo deployment/<APP_NAME> -n <NAMESPACE_PROD> --to-revision=3
```

### 8.3 部署指定 commit 的版本

如果知道要部署的 commit SHA：

```bash
# 用 SHA 前 7 碼
kubectl set image deployment/<APP_NAME> \
  <APP_NAME>=<REGISTRY_HOSTNAME>:5000/<APP_NAME>:a36269f \
  -n <NAMESPACE_PROD>
```

---

## 9. 從測試分支切換到正式分支

當 CI/CD 流程在 `<DEV_BRANCH>` 測試穩定後，修改觸發分支為 `main`：

### 9.1 修改 workflow

`.gitea/workflows/deploy.yaml`：

```yaml
on:
  push:
    branches: [main]  # 改為正式分支
```

### 9.2 提交到 main 分支

```bash
git checkout main
git merge <DEV_BRANCH>
git push origin main
```

此後只有 push 到 `main` 才會觸發自動部署。

---

## 10. 進階配置

### 10.1 只在特定路徑變更時觸發

例如只在程式碼或驗證 JS 變更時觸發，文件變更不觸發：

```yaml
on:
  push:
    branches: [main]
    paths:
      - 'src/**'
      - 'public/js/**'
      - 'Dockerfile'
      - 'nginx.conf'
      - 'package.json'
      - 'package-lock.json'
```

### 10.2 加入建置通知

在 workflow 最後加入通知步驟（例如透過 Webhook 發送到 Teams/Slack）：

```yaml
      - name: Notify on success
        if: success()
        run: |
          curl -X POST "<webhook-url>" \
            -H "Content-Type: application/json" \
            -d '{"text": "<APP_NAME> 部署成功：${{ env.SHORT_SHA }}"}'

      - name: Notify on failure
        if: failure()
        run: |
          curl -X POST "<webhook-url>" \
            -H "Content-Type: application/json" \
            -d '{"text": "<APP_NAME> 部署失敗，請檢查 Actions log"}'
```

### 10.3 使用 Gitea Secrets

如果需要在 workflow 中使用機密資訊（如 API Token）：

1. 到 Gitea Repo → Settings → Actions → Secrets
2. 新增 Secret（例如 `KUBE_CONFIG`）
3. 在 workflow 中使用：`${{ secrets.KUBE_CONFIG }}`

> **注意**：需要 Repo Settings 存取權限（Owner 或 Admin）。

---

## 11. 常見問題排除

### 11.1 Checkout 步驟卡住（git clone 無限等待）

**症狀：** Checkout 步驟顯示 `Cloning into '.'...` 後無限卡住，耗時 30+ 分鐘無進展。

**原因：** Self-hosted runner 以原生 `git clone` 存取私有 repo 時，若未帶入認證資訊，git 會等待密碼輸入。CI 環境沒有 tty，導致永遠等不到輸入而卡住。

**解決方式：** 使用 `github.token`（Gitea Actions 自動注入）作為認證 header：

```yaml
- name: Checkout
  run: |
    rm -rf ./* ./.git 2>/dev/null || true
    git clone --depth 1 --branch ${{ github.ref_name }} \
      ${{ github.server_url }}/${{ github.repository }}.git \
      --config http.extraHeader="Authorization: token ${{ github.token }}" .
    echo "Checked out ${{ github.sha }}"
```

**注意事項：**
- `rm -rf` 是必要的：runner 重用工作目錄，上次執行殘留的 `.git` 會導致 clone 失敗
- 不使用 `actions/checkout@v4` 是因為 self-hosted runner 主機模式下沒有 Node.js 環境
- 如果 runner 有 Node.js，可改用 `uses: http://gitea.<CORP_DOMAIN>:3000/actions/checkout@v4`（推薦，自動處理認證）

### 11.2 Actions 頁面顯示「目前還沒有工作流程」

- 確認 `.gitea/workflows/deploy.yaml` 已推送到 Gitea
- 確認檔案路徑正確（必須是 `.gitea/workflows/`，不是 `.github/workflows/`）

### 11.3 Workflow 觸發了但一直 Pending

- 確認 Runner 在線：Gitea 管理頁面 → Actions → Runners
- 確認 Runner label 匹配：workflow 的 `runs-on` 與 Runner 的 label 一致

### 11.4 Docker build 失敗

```bash
# SSH 到 Runner 機器手動測試
cd /tmp
git clone https://<GITEA_HOSTNAME>/<GITEA_ORG>/<PROJECT_NAME>.git
cd <PROJECT_NAME>
docker build -t test:latest .
```

常見原因：
- npm install 失敗 → Proxy 設定問題（npm 需要透過 Proxy 下載套件）
- Dockerfile 語法錯誤

### 11.4.1 vue-tsc: not found（alpine 環境）

**症狀：** Docker build 在 `RUN npm run build` 階段失敗，錯誤訊息 `sh: vue-tsc: not found`，即使 `npm ci` 已成功安裝。

**原因：** `node:20-alpine` 使用 busybox sh，對 `node_modules/.bin/` 的 symlink 處理與標準 Linux 不同，導致 npm 安裝的 CLI 工具不在 PATH 上。

**解決方式：** 將 type check 從 Docker build 中分離，Dockerfile 只跑 `vite build`：

```dockerfile
# Dockerfile — 只做打包，不做 type check
RUN npx vite build
```

```yaml
# deploy.yaml — 獨立 type check 步驟
- name: Type check
  run: |
    npm ci --ignore-scripts
    npx vue-tsc -b
    rm -rf node_modules
```

**注意事項：**
- 替代方案：在 Dockerfile 中加 `ENV PATH="/app/node_modules/.bin:$PATH"` 也可解決，但職責分離更佳
- 分離後 type check 失敗會立即中斷，不用等 Docker build 的 `npm ci`（480s+）

### 11.4.2 npx ETIMEDOUT（Docker build 網路受限）

**症狀：** Docker build 執行 `RUN npx vue-tsc -b` 時失敗，錯誤訊息：
```
npm error code ETIMEDOUT
npm error network request to https://registry.npmjs.org/vue-tsc failed
```

**原因：** `npx` 即使本地已安裝該套件，仍會嘗試連線 npmjs.org registry 確認版本。Docker build 環境若網路受限（proxy、防火牆），就會超時失敗。

**解決方式：** 不使用 `npx`，改用 `./node_modules/.bin/` 直接呼叫已安裝的執行檔：

```dockerfile
# 不要用 npx（會觸發 registry 查詢）
# RUN npx vue-tsc -b
# RUN npx vite build

# 改用本地 bin 直接執行
RUN ./node_modules/.bin/vue-tsc -b
RUN ./node_modules/.bin/vite build
```

**注意事項：**
- 前提是 `npm ci` 已安裝這些套件（在 devDependencies 中）
- 此方式完全不依賴外部網路，適合受限的 build 環境
- 也可用 `ENV PATH="/app/node_modules/.bin:$PATH"` 加入 PATH，效果相同

### 11.5 Docker push 失敗

```bash
# 手動測試 push
docker push <REGISTRY_HOSTNAME>:5000/<APP_NAME>:test
```

常見原因：
- Proxy 攔截 → 確認 Docker 的 no_proxy 設定
- Registry 未信任 → 確認 Docker daemon 的 insecure-registries 設定

### 11.6 kubectl 部署失敗

```bash
# 手動測試
kubectl set image deployment/<APP_NAME> \
  <APP_NAME>=<REGISTRY_HOSTNAME>:5000/<APP_NAME>:latest \
  -n <NAMESPACE_PROD>
```

常見原因：
- kubeconfig 過期 → 重新從 Rancher 下載
- 權限不足 → 確認 kubeconfig 的用戶有 `<NAMESPACE_PROD>` namespace 的部署權限

### 11.7 Rollout 逾時

```
error: timed out waiting for the condition
```

```bash
# 檢查 Pod 狀態
kubectl get pods -n <NAMESPACE_PROD> -l app=<APP_NAME>
kubectl describe pod <pod-name> -n <NAMESPACE_PROD>

# 查看 Pod log
kubectl logs <pod-name> -n <NAMESPACE_PROD>
```

常見原因：
- Image pull 失敗 → K8s 節點無法存取 Registry
- 容器啟動失敗 → 程式碼或 nginx 設定錯誤
- Health check 失敗 → 確認 liveness/readiness probe 設定

---

## 12. 完整部署流程圖（Push → 上線）

> 新增於 2026-04-08

以下流程圖涵蓋從 `git push` 到服務上線的完整路徑，包含 CI 自動化部分與需手動操作的 Ingress/DNS 部分。

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         開發端（本機）                                    │
│                                                                         │
│  1. 修改程式碼 / K8s 設定檔                                               │
│  2. git add → git commit → git push (<DEV_BRANCH>)                │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    Gitea Server (<GITEA_HOSTNAME>)                │
│                                                                         │
│  偵測到 push 事件 → 觸發 Gitea Actions workflow                          │
│  workflow 檔案：.gitea/workflows/deploy.yaml                             │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│              Gitea Actions Runner (<RUNNER_BANNER> / <RUNNER_HOST_IP>)               │
│              模式：self-hosted (主機模式)                                  │
│                                                                         │
│  Step 1: Checkout                                                       │
│  ├─ rm -rf 清除上次殘留                                                   │
│  └─ git clone --depth 1 拉取最新程式碼（使用 github.token 認證）            │
│                                                                         │
│  Step 2: Set short SHA                                                  │
│  └─ 取 commit SHA 前 7 碼（如 b1b712d）寫入環境變數                        │
│                                                                         │
│  Step 3: Build Docker image                                             │
│  ├─ docker pull registry:5000/<APP_NAME>:latest（快取層加速）            │
│  ├─ docker build（多階段：node:20-alpine build → nginx:alpine serve）     │
│  │   ├─ Stage 1: npm ci → vite build → 產出 dist/                       │
│  │   └─ Stage 2: 複製 dist/ 到 nginx，設定 nginx.conf                    │
│  ├─ tag :b1b712d（SHA tag，K8s 部署用）                                   │
│  └─ tag :latest（手動測試用）                                              │
│                                                                         │
│  Step 4: Push to Registry                                               │
│  ├─ docker push <REGISTRY_HOSTNAME>:5000/<APP_NAME>:b1b712d       │
│  └─ docker push <REGISTRY_HOSTNAME>:5000/<APP_NAME>:latest        │
│                                                                         │
│  Step 5: Deploy to K8s                                                  │
│  └─ kubectl set image deployment/<APP_NAME>                           │
│       <APP_NAME>=registry:5000/<APP_NAME>:b1b712d -n <NAMESPACE_PROD>      │
│     ⚠ 只更新 container image，不會 apply ingress/service 等其他資源        │
│                                                                         │
│  Step 6: Wait for rollout                                               │
│  └─ kubectl rollout status deployment/<APP_NAME> -n <NAMESPACE_PROD>          │
│     等待所有 Pod 滾動更新完成（timeout: 120s）                              │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                     K8s Cluster (<K8S_CLUSTER_NAME>)                        │
│                     Namespace: <NAMESPACE_PROD>                                 │
│                                                                         │
│  Deployment: <APP_NAME> (replicas: 2)                                 │
│  ├─ 收到新 image tag → 啟動新 Pod（新版本）                                │
│  ├─ readinessProbe 通過 → 新 Pod 加入 Service                            │
│  ├─ 舊 Pod 停止接收流量 → graceful shutdown                               │
│  └─ 所有 Pod 更新完成 → rollout 成功                                      │
│                                                                         │
│  Service: <APP_NAME>-svc (ClusterIP:80)                               │
│  └─ 負載平衡到所有 Ready 的 Pod                                           │
│                                                                         │
│  Ingress: <APP_NAME>-ingress                                          │
│  └─ host → Service:80 → Pod:80                                         │
│     ⚠ CI 不會自動更新 Ingress，host 變更需透過 Rancher 手動操作             │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │
             ┌──────────────────┴──────────────────┐
             │  若有 Ingress host 變更需求           │
             │  （CI 不涵蓋，需手動操作）             │
             └──────────────────┬──────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                  手動操作：透過 Rancher UI                                │
│                  Rancher: https://<REGISTRY_HOST_IP>                           │
│                                                                         │
│  1. DNS 確認                                                             │
│     └─ nslookup <新域名>，確認是否已有 wildcard DNS                        │
│                                                                         │
│  2. 編輯 Ingress                                                         │
│     └─ Rancher → <K8S_CLUSTER_NAME> → <NAMESPACE_PROD>                             │
│        → Service Discovery → Ingresses → <APP_NAME>-ingress          │
│        → Edit YAML → 修改 host + tls.hosts → Save                      │
│                                                                         │
│  3. TLS 憑證確認                                                         │
│     └─ Rancher → Storage → Secrets (type: TLS)                         │
│        確認 wildcard cert 或 cert-manager 已就位                          │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                          驗證上線                                        │
│                                                                         │
│  1. Gitea Actions 頁面 → 所有步驟綠勾                                     │
│  2. Rancher → Workload → Pods → <APP_NAME> → 狀態 Running             │
│  3. Rancher → Ingresses → HOSTS 欄顯示正確域名                            │
│  4. 瀏覽器 → https://<域名> → 頁面正常、HTTPS 無警告                       │
│                                                                         │
│  ✅ 上線完成                                                              │
└─────────────────────────────────────────────────────────────────────────┘
```

### 流程摘要

| 階段 | 自動/手動 | 工具 | 觸發條件 |
|------|-----------|------|----------|
| Code → Push | 手動 | Git | 開發完成 |
| Build → Deploy Pod | **自動** | Gitea Actions | push 到指定分支 |
| DNS 確認 | 手動 | nslookup / 找網管 | Ingress host 變更時 |
| Ingress host 更新 | 手動 | **Rancher UI** | Ingress host 變更時 |
| TLS 確認 | 手動 | **Rancher UI** | 新域名上線時 |
| 最終驗證 | 手動 | 瀏覽器 + Rancher | 每次部署後 |
