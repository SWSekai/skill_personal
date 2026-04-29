# Gitea Actions Runner 架設指南

> 日期：2026-04-01
> 適用版本：Gitea 1.19+、act_runner v0.2.11
> 目標機器：Ubuntu 22.04 LTS（<RUNNER_BANNER> / <RUNNER_HOST_IP>）

---

## 目錄

1. [前置需求](#1-前置需求)
2. [環境確認](#2-環境確認)
3. [安裝 kubectl](#3-安裝-kubectl)
4. [安裝 act_runner](#4-安裝-act_runner)
5. [註冊 Runner](#5-註冊-runner)
6. [設定為系統服務](#6-設定為系統服務)
7. [驗證與管理](#7-驗證與管理)
8. [常見問題排除](#8-常見問題排除)

---

## 1. 前置需求

Runner 機器需滿足以下條件：

| 需求 | 用途 | 必要性 |
|------|------|--------|
| Docker | 執行 `docker build` / `docker push` | 必要 |
| kubectl + kubeconfig | 執行 `kubectl` 部署到 K8s cluster | 必要 |
| Registry 網路連通 | push image 到 Docker Registry | 必要 |
| Gitea 網路連通 | Runner 與 Gitea 通訊 | 必要 |

---

## 2. 環境確認

SSH 連線到目標機器：

```bash
ssh <使用者>@<主機IP>
# 範例：ssh <RUNNER_USER>@<RUNNER_HOST_IP>
```

> 如果 SSH port 非預設 22：`ssh -p <port> <使用者>@<主機IP>`

### 2.1 確認 OS

```bash
cat /etc/os-release
```

預期輸出包含 `Ubuntu 22.04` 或其他 Linux 發行版。

### 2.2 確認 Docker

```bash
docker info 2>&1 | head -20
```

預期看到 `Server Version: xx.x.x` 和 `Running: N` 等資訊。

**如果 Docker 未安裝**，請參考 [Docker 官方安裝指南](https://docs.docker.com/engine/install/ubuntu/)。

### 2.3 確認 kubectl

```bash
kubectl version --client 2>&1
```

如果顯示 `kubectl: command not found`，見下一節安裝。

### 2.4 確認 K8s cluster 連通

```bash
kubectl get nodes
```

- 成功 → 顯示節點列表，kubeconfig 已就緒
- 失敗 → 需設定 kubeconfig，見 [2.6 設定 kubeconfig](#26-設定-kubeconfig)

### 2.5 確認 Docker Registry 連通

```bash
# 先嘗試直連
curl -sk https://<REGISTRY_HOSTNAME>:5000/v2/

# 如果失敗，確認狀態碼
curl -sk -o /dev/null -w "%{http_code}" https://<REGISTRY_HOSTNAME>:5000/v2/
```

- 回傳 `{}` 或狀態碼 `200` → 正常
- 回傳 `000` 或 `502` → 可能被 Proxy 擋，見 [Proxy 設定指南](guide-proxy-network-setup.md)

### 2.6 設定 kubeconfig

如果 kubectl 無法連到 cluster，需要將 kubeconfig 檔案放到 Runner 機器上。

**方法一：從本機傳送**

如果你的開發機上已有 kubeconfig（如 `<K8S_CLUSTER_NAME>.yaml`）：

```bash
# 在 Runner 機器上建立目錄
mkdir -p ~/.kube

# 在你的本機執行 SCP 傳送
scp <K8S_CLUSTER_NAME>.yaml <使用者>@<Runner IP>:~/.kube/config
# 範例：scp <K8S_CLUSTER_NAME>.yaml <RUNNER_USER>@<RUNNER_HOST_IP>:~/.kube/config
```

**方法二：從 Rancher 下載**

1. 登入 Rancher 管理介面
2. 選擇目標 Cluster
3. 點擊「Kubeconfig File」
4. 複製內容，存為 `~/.kube/config`

**驗證：**

```bash
kubectl get nodes
kubectl get deployment <APP_NAME> -n <NAMESPACE_PROD>
```

### 2.7 確認 Gitea 連通

```bash
curl -sI https://<GITEA_HOSTNAME> | head -5
```

預期看到 `HTTP/1.1 200` 或 `HTTP/1.1 404`（表示能連通，404 是因為未登入）。

---

## 3. 安裝 kubectl

如果 `kubectl` 未安裝：

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && chmod +x kubectl && sudo mv kubectl /usr/local/bin/
```

驗證：

```bash
kubectl version --client
```

> **注意**：如果機器有 Proxy 且無法直接下載，從可上網的電腦下載後用 SCP 傳送：
> 1. 瀏覽器下載：`https://dl.k8s.io/release/stable.txt` 查看最新版本
> 2. 下載對應版本：`https://dl.k8s.io/release/v1.35.3/bin/linux/amd64/kubectl`
> 3. SCP 傳送：`scp kubectl <使用者>@<IP>:~/`
> 4. 在伺服器上：`chmod +x ~/kubectl && sudo mv ~/kubectl /usr/local/bin/`

---

## 4. 安裝 act_runner

### 4.1 下載

**方法一：直接下載（需要外網存取）**

```bash
curl -L -o act_runner https://gitea.com/gitea/act_runner/releases/download/v0.2.11/act_runner-0.2.11-linux-amd64
```

**方法二：本機下載後 SCP 傳送（Proxy 環境推薦）**

1. 在可上網的電腦用瀏覽器下載：
   > `https://gitea.com/gitea/act_runner/releases/download/v0.2.11/act_runner-0.2.11-linux-amd64`

2. SCP 傳送到伺服器：
   ```bash
   scp act_runner-0.2.11-linux-amd64 <使用者>@<IP>:~/
   ```

> **注意**：Windows SCP 需使用 IP 位址，hostname 可能無法解析。
> 範例：`scp act_runner-0.2.11-linux-amd64 <RUNNER_USER>@<RUNNER_HOST_IP>:~/`

### 4.2 安裝到系統路徑

```bash
chmod +x ~/act_runner-0.2.11-linux-amd64
sudo mv ~/act_runner-0.2.11-linux-amd64 /usr/local/bin/act_runner
```

### 4.3 驗證

```bash
act_runner --version
```

預期輸出：`act_runner version v0.2.11`

---

## 5. 註冊 Runner

### 5.1 取得 Registration Token

根據 Runner 類型，從不同位置取得 Token：

| Runner 類型 | 取得位置 | 適用場景 |
|-------------|----------|----------|
| **全域** | 網站管理 → Actions → Runners → 建立 Runner | 服務所有 Repo |
| **組織** | 組織設定 → Actions → Runners → 建立 Runner | 服務該組織的 Repo |
| **Repo** | Repo → Settings → Actions → Runners → 建立 Runner | 僅服務該 Repo |

> **注意**：全域 Runner 需要 Gitea **管理員權限**。
> 確認方式：右上角頭像選單中是否有「網站管理」選項。
> 如果沒有，請管理員提供全域 Token，或改用 Repo 層級 Runner。

### 5.2 執行註冊

```bash
act_runner register --instance https://<GITEA_HOSTNAME> --token <你的Token> --name <RUNNER_BANNER>-Runner --labels ubuntu-latest:docker://node:20,self-hosted:host --no-interactive
```

**參數說明：**

| 參數 | 說明 |
|------|------|
| `--instance` | Gitea 伺服器網址 |
| `--token` | Registration Token（不要加角括號 `< >`） |
| `--name` | Runner 顯示名稱 |
| `--labels` | Runner 標籤，格式為 `標籤名:模式` |
| `--no-interactive` | 非互動模式，直接註冊 |

**Labels 模式說明：**

| 標籤定義 | 模式 | 說明 |
|----------|------|------|
| `ubuntu-latest:docker://node:20` | Docker 容器 | Job 在 Docker 容器內執行 |
| `self-hosted:host` | 主機模式 | Job 直接在主機上執行，可存取本機 Docker 和 kubectl |

> **重要**：CI/CD pipeline 需要存取 Docker daemon 和 kubectl，
> 因此 workflow 的 `runs-on` 應使用 `self-hosted`（主機模式）。

預期輸出：

```
INFO Registering runner, arch=amd64, os=linux, version=v0.2.11.
WARN Runner in user-mode.
DEBU Successfully pinged the Gitea instance server
INFO Runner registered successfully.
```

> `WARN Runner in user-mode` 是正常提示，不影響功能。
> Runner 類型（全域/個人）取決於 Token 來源，而非此提示。

### 5.3 驗證註冊

手動啟動測試：

```bash
act_runner daemon
```

到 Gitea 管理頁面確認 Runner 狀態為「閒置」（Online/Idle）。

確認後按 `Ctrl+C` 停止，接下來設定為系統服務。

---

## 6. 設定為系統服務

將 act_runner 設為 systemd 服務，確保開機自動啟動、異常自動重啟。

### 6.1 建立服務檔案

```bash
sudo nano /etc/systemd/system/act_runner.service
```

貼入以下內容：

```ini
[Unit]
Description=Gitea Actions Runner
After=network.target docker.service

[Service]
Type=simple
User=z30
WorkingDirectory=/home/<RUNNER_USER>
ExecStart=/usr/local/bin/act_runner daemon
Restart=always
RestartSec=5
Environment="http_proxy=http://<HTTP_PROXY_HOST>:15629"
Environment="https_proxy=http://<HTTP_PROXY_HOST>:15629"
Environment="no_proxy=localhost,127.0.0.1,<REGISTRY_HOSTNAME>,.<CORP_DOMAIN>"

[Install]
WantedBy=multi-user.target
```

存檔：`Ctrl+O` → `Enter` → `Ctrl+X`

**欄位說明：**

| 欄位 | 說明 | 需修改 |
|------|------|--------|
| `User` | 執行 act_runner 的系統使用者 | 改為你的使用者名稱 |
| `WorkingDirectory` | `.runner` 註冊檔所在目錄 | 改為你的家目錄 |
| `Environment` | Proxy 設定 | 根據實際環境調整，無 Proxy 可移除 |

> **注意**：如果環境沒有 Proxy，移除三行 `Environment` 設定即可。

### 6.2 啟動服務

```bash
sudo systemctl daemon-reload
sudo systemctl enable act_runner
sudo systemctl start act_runner
sudo systemctl status act_runner
```

預期看到 `Active: active (running)`。

### 6.3 驗證

到 Gitea 管理頁面確認 Runner 狀態為「閒置」。

---

## 7. 驗證與管理

### 常用管理指令

```bash
# 查看服務狀態
sudo systemctl status act_runner

# 查看即時 log
journalctl -u act_runner -f

# 重啟服務
sudo systemctl restart act_runner

# 停止服務
sudo systemctl stop act_runner

# 開機自啟（已在安裝時啟用）
sudo systemctl enable act_runner

# 停用開機自啟
sudo systemctl disable act_runner
```

### 重要檔案位置

| 檔案 | 路徑 | 說明 |
|------|------|------|
| act_runner 執行檔 | `/usr/local/bin/act_runner` | 主程式 |
| Runner 註冊檔 | `/home/<RUNNER_USER>/.runner` | 包含 Runner ID 和認證資訊 |
| 系統服務設定 | `/etc/systemd/system/act_runner.service` | systemd 服務檔 |
| kubeconfig | `/home/<RUNNER_USER>/.kube/config` | K8s 連線憑證 |

---

## 8. 常見問題排除

### 8.1 Runner 顯示「離線」

```bash
# 確認服務是否在跑
sudo systemctl status act_runner

# 查看 log 找錯誤原因
journalctl -u act_runner --no-pager -n 50
```

常見原因：
- 服務未啟動 → `sudo systemctl start act_runner`
- Gitea 網路不通 → 確認 `curl -sI https://<GITEA_HOSTNAME>`
- `.runner` 檔案損壞 → 刪除後重新註冊（見 8.4）

### 8.2 註冊為「個人」而非「全域」

原因：使用的 Token 來源不對。

- 個人設定頁面的 Token → 註冊為個人 Runner
- 網站管理頁面的 Token → 註冊為全域 Runner

解決：取得正確的 Token 後重新註冊（見 8.4）。

### 8.3 下載 act_runner 失敗（Proxy 阻擋）

公司 Proxy（ISA Server）可能阻擋外部下載。解決方式：

1. 在可上網的電腦用瀏覽器下載
2. 用 SCP 傳到伺服器（用 IP 位址，不要用 hostname）

```bash
# Windows 範例
scp act_runner-0.2.11-linux-amd64 <RUNNER_USER>@<RUNNER_HOST_IP>:~/
```

### 8.4 需要重新註冊 Runner

```bash
# 1. 停止服務
sudo systemctl stop act_runner

# 2. 刪除舊的註冊檔
rm -f ~/.runner

# 3. 到 Gitea 管理頁面刪除舊的 Runner 記錄（編輯 → 刪除）

# 4. 重新註冊
act_runner register --instance https://<GITEA_HOSTNAME> --token <新Token> --name <RUNNER_BANNER>-Runner --labels ubuntu-latest:docker://node:20,self-hosted:host --no-interactive

# 5. 重啟服務
sudo systemctl start act_runner
```

### 8.5 kubectl 連線被拒

```
The connection to the server localhost:8080 was refused
```

表示 kubeconfig 未設定或路徑不對：

```bash
# 確認 kubeconfig 存在
ls -la ~/.kube/config

# 如果不存在，從本機傳送
# （在你的電腦上執行）
scp <K8S_CLUSTER_NAME>.yaml <RUNNER_USER>@<RUNNER_HOST_IP>:~/.kube/config
```

### 8.6 Workflow 步驟報 `npm: command not found` 或其他工具找不到

**症狀**：Workflow 中直接執行 `npm`、`node`、`npx` 等命令時報 command not found。

**原因**：Runner 使用 `self-hosted:host` 模式，直接在主機上執行命令。主機是精簡 Linux 環境，未安裝 Node.js / npm。

**解決方式**：不要在 workflow step 中直接呼叫需要額外工具的命令。改為：
- 將這些步驟放入 **Dockerfile 的 build stage**（已有 node:20-alpine）
- 或使用 `docker run` 在容器中執行

**原則**：self-hosted runner 只應執行 `docker`、`kubectl`、`git` 等基礎命令，其餘一律在容器內完成。

### 8.7 Docker push 到 Registry 失敗

可能是 Proxy 攔截，確認 Docker 的 no_proxy 設定：

```bash
docker info 2>&1 | grep -i proxy
```

如果 `No Proxy` 不包含 `<REGISTRY_HOSTNAME>`，見 [Proxy 設定指南](guide-proxy-network-setup.md)。
