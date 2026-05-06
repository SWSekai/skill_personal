# CI/CD Workflow YAML — Gitea Actions / GitHub Actions

> Added: 2026-05-06 | Updated: 2026-05-06 | Category: _general

## Overview

Gitea Actions 與 GitHub Actions 使用幾乎相同的 YAML 語法定義自動化工作流程（workflow）。本筆記涵蓋 workflow 結構、常見步驟模式（Checkout、Build Docker、Push、部署 K8s）、密鑰注入、以及常見坑。適用於任何需要在 self-hosted 或 cloud runner 上執行 CI/CD 流程的專案。

---

## Quick Reference

```yaml
name: Build and Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: self-hosted          # 或 ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4  # Gitea 可用 actions/checkout，或自行 git clone

      - name: Build
        run: docker build -t myimage:${{ github.sha }} .

      - name: Setup kubeconfig     # 從 secret 注入，不依賴 runner 主機環境
        run: |
          mkdir -p $HOME/.kube
          printf '%s' "${{ secrets.KUBECONFIG }}" > $HOME/.kube/config
          chmod 600 $HOME/.kube/config

      - name: Deploy
        run: kubectl set image deployment/myapp myapp=myimage:${{ github.sha }} -n mynamespace

      - name: Wait for rollout
        run: kubectl rollout status deployment/myapp -n mynamespace --timeout=120s
```

---

## Details

### 1. Workflow 基本結構

```yaml
name: <工作流程名稱>

on:                    # 觸發條件
  push:
    branches: [main]
  pull_request:        # 可同時定義多個觸發
    branches: [main]

jobs:
  <job-id>:
    runs-on: <runner>  # self-hosted 或 ubuntu-latest 等
    steps:
      - name: <步驟名稱>
        run: <shell command>
        # 或
        uses: <action>@<version>
        with:
          <input>: <value>
```

### 2. 變數與 Context

| 語法 | 說明 |
|---|---|
| `${{ github.sha }}` | 完整 commit hash |
| `${{ github.ref_name }}` | 分支名稱 |
| `${{ github.repository }}` | `owner/repo` |
| `${{ github.server_url }}` | Gitea/GitHub 伺服器 URL |
| `${{ github.token }}` | 自動產生的 GITHUB_TOKEN（Gitea 為 GITEA_TOKEN） |
| `${{ secrets.MY_SECRET }}` | 在 repo settings 設定的 secret |
| `${{ env.MY_VAR }}` | 同一 job 中寫入 GITHUB_ENV 的變數 |

### 3. 跨步驟傳遞變數

```yaml
- name: Set short SHA
  run: echo "SHORT_SHA=$(echo ${{ github.sha }} | cut -c1-7)" >> $GITHUB_ENV

- name: Use it
  run: echo "Image tag: ${{ env.SHORT_SHA }}"
```

### 4. Docker Build + Push 模式

```yaml
- name: Build Docker image
  run: |
    docker pull registry.example.com/myapp:latest || true   # 暖快取
    docker build \
      --cache-from registry.example.com/myapp:latest \
      -t registry.example.com/myapp:${{ env.SHORT_SHA }} \
      -t registry.example.com/myapp:latest \
      .

- name: Push to registry
  run: |
    docker push registry.example.com/myapp:${{ env.SHORT_SHA }}
    docker push registry.example.com/myapp:latest
```

> **注意**：若 registry 需登入，先加 `docker login` 步驟並將帳密存在 secrets。

### 5. Kubeconfig 注入（K8s 部署必備）

**不要**依賴 runner 主機上的 `~/.kube/config`（容易因 token 過期、機器重裝、runner 切換而失效）。

```yaml
- name: Setup kubeconfig
  run: |
    mkdir -p $HOME/.kube
    printf '%s' "${{ secrets.KUBECONFIG }}" > $HOME/.kube/config
    chmod 600 $HOME/.kube/config
    kubectl config current-context   # 立即驗證，失敗早報
```

Gitea repo 設定：**Settings → Secrets and Variables → Actions** 新增 `KUBECONFIG`，內容為整份 kubeconfig YAML。

> **安全建議**：kubeconfig 內的 token 應使用**專用 service account**，而非個人帳號；token 權限收斂到最小必要 namespace。

### 6. Checkout（Gitea self-hosted 無法使用 actions marketplace 時）

```yaml
- name: Checkout
  run: |
    rm -rf ./* ./.git 2>/dev/null || true
    git clone --depth 1 --branch ${{ github.ref_name }} \
      ${{ github.server_url }}/${{ github.repository }}.git \
      --config http.extraHeader="Authorization: token ${{ github.token }}" .
```

### 7. 常見坑

| 問題 | 症狀 | 解法 |
|---|---|---|
| `system:unauthenticated` | kubectl 403 | kubeconfig 遺失或 token 過期，改用 secret 注入 |
| Docker cache miss | 每次全量 build | 加 `docker pull ... || true` + `--cache-from` |
| 環境變數跨步驟消失 | `$VAR` 空值 | 改用 `$GITHUB_ENV` 機制 |
| self-hosted runner SSL 錯誤 | `git fetch` 失敗 | 更新憑證或設定 `GIT_SSL_NO_VERIFY`（僅內網） |
| Docker push 401 | 未登入 | 加 `docker login` 步驟 |
| rollout timeout | 超過 `--timeout` | 調高秒數或先 `describe pod` 排查 ImagePullBackOff |

---

## Examples

### Example 1：基本 Node.js 專案 CI（build + test）

```yaml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: 20

      - name: Install & Test
        run: |
          npm ci
          npm test
```

### Example 2：完整 Dockerized 服務部署到 K8s（self-hosted runner）

```yaml
name: Build and Deploy

on:
  push:
    branches: [main]

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

      - name: Set short SHA
        run: echo "SHORT_SHA=$(echo ${{ github.sha }} | cut -c1-7)" >> $GITHUB_ENV

      - name: Build Docker image
        run: |
          docker pull registry.example.com/myapp:latest || true
          docker build \
            --cache-from registry.example.com/myapp:latest \
            -t registry.example.com/myapp:${{ env.SHORT_SHA }} \
            -t registry.example.com/myapp:latest .

      - name: Push to registry
        run: |
          docker push registry.example.com/myapp:${{ env.SHORT_SHA }}
          docker push registry.example.com/myapp:latest

      - name: Setup kubeconfig
        run: |
          mkdir -p $HOME/.kube
          printf '%s' "${{ secrets.KUBECONFIG }}" > $HOME/.kube/config
          chmod 600 $HOME/.kube/config
          kubectl config current-context

      - name: Deploy to K8s
        run: |
          kubectl set image deployment/myapp \
            myapp=registry.example.com/myapp:${{ env.SHORT_SHA }} \
            -n mynamespace

      - name: Wait for rollout
        run: kubectl rollout status deployment/myapp -n mynamespace --timeout=120s
```

---

## References

- [GitHub Actions 官方文件](https://docs.github.com/en/actions)
- [Gitea Actions 文件](https://docs.gitea.com/usage/actions/overview)
- [Kubernetes kubectl set image](https://kubernetes.io/docs/reference/kubectl/generated/kubectl_set/kubectl_set_image/)
- 相關筆記：`kubernetes/` 目錄（K8s manifest 設定）
