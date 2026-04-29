# Proxy 與網路環境設定指南

> 日期：2026-04-01
> 適用環境：使用 ISA Server / HTTP Proxy 的內網環境
> 目標機器：Ubuntu 22.04 LTS（<RUNNER_BANNER> / <RUNNER_HOST_IP>）

---

## 目錄

1. [背景說明](#1-背景說明)
2. [網路架構](#2-網路架構)
3. [診斷流程](#3-診斷流程)
4. [系統層 Proxy 設定](#4-系統層-proxy-設定)
5. [Docker 層 Proxy 設定](#5-docker-層-proxy-設定)
6. [Runner 服務層 Proxy 設定](#6-runner-服務層-proxy-設定)
7. [三層設定總覽](#7-三層設定總覽)
8. [驗證步驟](#8-驗證步驟)
9. [常見問題排除](#9-常見問題排除)

---

## 1. 背景說明

公司內網透過 ISA Server（HTTP Proxy）存取外部網路。部分內部服務（Docker Registry、Gitea、K8s）
不需要透過 Proxy，甚至會被 Proxy 阻擋。因此需要正確設定 `no_proxy`，讓內部流量繞過 Proxy 直連。

### 為什麼需要設定？

| 情境 | 走 Proxy | 繞過 Proxy |
|------|:--------:|:----------:|
| 下載 npm 套件（外部） | 需要 | - |
| 推送 image 到 Registry（內部） | 會被擋（502） | 需要 |
| Runner 連線 Gitea（內部） | 可能被擋 | 需要 |
| kubectl 連線 K8s（內部） | 可能被擋 | 需要 |

---

## 2. 網路架構

```
                    ┌─────────────────┐
                    │   ISA Proxy     │
                    │ <HTTP_PROXY_HOST>    │
                    │ :15629          │
                    └────────┬────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │ 需走 Proxy         │                     │ 不走 Proxy（no_proxy）
        │                    │                     │
   ┌────┴────┐         ┌────┴────┐          ┌─────┴──────────────┐
   │ npm     │         │ gitea   │          │ Docker Registry    │
   │ registry│         │ .com    │          │ registry.compeq    │
   │ (外部)  │         │ (外部)  │          │ .com.tw:5000       │
   └─────────┘         └─────────┘          └────────────────────┘

當前設定：
  Proxy:    http://<HTTP_PROXY_HOST>:15629
  no_proxy: localhost,127.0.0.1,<REGISTRY_HOSTNAME>,.<CORP_DOMAIN>
```

---

## 3. 診斷流程

遇到連線問題時，按以下順序排查：

### 3.1 確認 DNS 解析

```bash
nslookup <目標主機>
# 範例：nslookup <REGISTRY_HOSTNAME>
```

正常回傳 IP 位址即為解析成功。

### 3.2 確認端口連通

```bash
nc -zv <主機> <端口> -w 5
# 範例：nc -zv <REGISTRY_HOSTNAME> 5000 -w 5
```

`succeeded` 表示端口可連。

### 3.3 確認是否被 Proxy 攔截

```bash
# 走 Proxy
curl -vk https://<目標>:<端口>/path 2>&1 | tail -20

# 繞過 Proxy
curl -vk --noproxy <主機> https://<目標>:<端口>/path 2>&1 | tail -20
```

**比較兩者結果：**

| 走 Proxy 結果 | 繞過 Proxy 結果 | 判斷 |
|---------------|-----------------|------|
| 502 Proxy Error | 200 成功 | 被 Proxy 擋，需加入 no_proxy |
| 000 連線失敗 | 200 成功 | Proxy 不支援該端口 |
| 200 成功 | 200 成功 | 正常，不需特別設定 |
| 失敗 | 失敗 | 網路本身不通，非 Proxy 問題 |

### 3.4 ISA Server 常見錯誤特徵

被 ISA Proxy 攔截時，會回傳含有以下特徵的 HTML 錯誤頁面：

- 標題：`網路存取訊息: 無法顯示網頁`
- 內容含：`The specified Secure Sockets Layer (SSL) port is not allowed`
- 伺服器：`<PROXY_HOSTNAME>`
- 錯誤碼：`10060: 連線逾時` 或 `502 Proxy Error`

看到這些即可確認是 Proxy 問題。

---

## 4. 系統層 Proxy 設定

系統層的 Proxy 設定影響：`curl`、`wget`、`act_runner`、`kubectl` 等所有使用環境變數的程式。

### 4.1 查看目前設定

```bash
env | grep -i proxy
```

### 4.2 設定檔位置

```bash
# 查看設定來源
grep -r "proxy" /etc/environment /etc/profile.d/ ~/.bashrc ~/.profile 2>/dev/null | grep -i proxy
```

### 4.3 新增 / 修改 no_proxy

編輯 `~/.bashrc`：

```bash
nano ~/.bashrc
```

確認包含以下三行：

```bash
export http_proxy="http://<HTTP_PROXY_HOST>:15629"
export https_proxy="http://<HTTP_PROXY_HOST>:15629"
export no_proxy="localhost,127.0.0.1,<REGISTRY_HOSTNAME>,.<CORP_DOMAIN>"
```

存檔後載入：

```bash
source ~/.bashrc
```

### 4.4 驗證

```bash
echo $no_proxy
# 預期：localhost,127.0.0.1,<REGISTRY_HOSTNAME>,.<CORP_DOMAIN>

curl -sk https://<REGISTRY_HOSTNAME>:5000/v2/
# 預期：{} 或空白（HTTP 200）
```

> **注意**：`source ~/.bashrc` 只對當前 shell 生效。
> 新開的 SSH 連線會自動載入。
> systemd 服務不會讀取 `.bashrc`，需另外設定（見第 6 節）。

---

## 5. Docker 層 Proxy 設定

Docker daemon 有獨立的 Proxy 設定，不會讀取系統環境變數。

### 5.1 查看目前設定

```bash
# Docker daemon 的 Proxy 設定
docker info 2>&1 | grep -i proxy

# 設定檔內容
cat /etc/systemd/system/docker.service.d/http-proxy.conf
```

### 5.2 設定檔位置

`/etc/systemd/system/docker.service.d/http-proxy.conf`

### 5.3 修改設定

```bash
sudo nano /etc/systemd/system/docker.service.d/http-proxy.conf
```

確認內容為：

```ini
[Service]
Environment="HTTP_PROXY=http://<HTTP_PROXY_HOST>:15629"
Environment="HTTPS_PROXY=http://<HTTP_PROXY_HOST>:15629"
Environment="NO_PROXY=localhost,127.0.0.1,.local,<REGISTRY_HOSTNAME>,.<CORP_DOMAIN>"
```

### 5.4 重啟 Docker 生效

```bash
sudo systemctl daemon-reload
sudo systemctl restart docker
```

> **警告**：重啟 Docker 會中斷所有正在運行的容器。
> 請確認沒有重要容器正在運行，或在維護時段執行。

### 5.5 驗證

```bash
docker info 2>&1 | grep -i proxy
```

確認 `No Proxy` 包含 `<REGISTRY_HOSTNAME>`。

```bash
# 測試 pull
docker pull <REGISTRY_HOSTNAME>:5000/<APP_NAME>:latest
```

---

## 6. Runner 服務層 Proxy 設定

act_runner 以 systemd 服務運行時，不會繼承使用者的環境變數，需在服務檔案中單獨設定。

### 6.1 設定檔位置

`/etc/systemd/system/act_runner.service`

### 6.2 設定內容

在 `[Service]` 段中加入：

```ini
Environment="http_proxy=http://<HTTP_PROXY_HOST>:15629"
Environment="https_proxy=http://<HTTP_PROXY_HOST>:15629"
Environment="no_proxy=localhost,127.0.0.1,<REGISTRY_HOSTNAME>,.<CORP_DOMAIN>"
```

### 6.3 修改後重啟

```bash
sudo systemctl daemon-reload
sudo systemctl restart act_runner
```

### 6.4 為什麼 Runner 需要 Proxy？

| 操作 | 需要 Proxy | 需要 no_proxy |
|------|:----------:|:-------------:|
| 從 Gitea 拉程式碼 | 可能 | 如果 Gitea 是內部服務 |
| `docker build` 中的 `npm ci` | 需要（下載外部套件） | - |
| `docker push` 到 Registry | - | 需要（內部服務） |
| `kubectl` 操作 | - | 需要（內部服務） |

Runner 服務同時需要 Proxy（存取外部）和 no_proxy（繞過內部），缺一不可。

---

## 7. 三層設定總覽

| 層級 | 設定檔 | 影響範圍 | 何時需要修改 |
|------|--------|----------|--------------|
| **系統** | `~/.bashrc` | SSH 登入後的所有指令 | 手動測試 curl、kubectl 等 |
| **Docker** | `/etc/systemd/system/docker.service.d/http-proxy.conf` | Docker daemon（build、push、pull） | Docker 相關操作 |
| **Runner** | `/etc/systemd/system/act_runner.service` | act_runner 服務（CI/CD 流程） | CI/CD 自動化 |

### 修改任一層後的重載指令

```bash
# 系統層
source ~/.bashrc

# Docker 層
sudo systemctl daemon-reload && sudo systemctl restart docker

# Runner 層
sudo systemctl daemon-reload && sudo systemctl restart act_runner
```

### no_proxy 語法說明

```
no_proxy="localhost,127.0.0.1,<REGISTRY_HOSTNAME>,.<CORP_DOMAIN>"
```

| 值 | 匹配範圍 |
|----|----------|
| `localhost` | 精確匹配 localhost |
| `127.0.0.1` | 精確匹配 127.0.0.1 |
| `<REGISTRY_HOSTNAME>` | 精確匹配此主機 |
| `.<CORP_DOMAIN>` | 匹配所有 `*.<CORP_DOMAIN>` 的子網域 |

> **提示**：`.<CORP_DOMAIN>`（開頭有點）是萬用匹配，涵蓋所有子網域。
> 如果已加入 `.<CORP_DOMAIN>`，理論上不需要再單獨列 `<REGISTRY_HOSTNAME>`，
> 但為了明確性和相容性，建議兩者都保留。

---

## 8. 驗證步驟

設定完成後，依序驗證三層：

### 8.1 系統層

```bash
# 確認 no_proxy 設定
echo $no_proxy

# 測試 Registry 連通（不用 --noproxy 參數）
curl -sk -o /dev/null -w "%{http_code}" https://<REGISTRY_HOSTNAME>:5000/v2/
# 預期：200

# 測試外部連通（透過 Proxy）
curl -s -o /dev/null -w "%{http_code}" https://www.google.com
# 預期：200
```

### 8.2 Docker 層

```bash
# 確認 Docker Proxy 設定
docker info 2>&1 | grep -i proxy
# 確認 No Proxy 包含 <REGISTRY_HOSTNAME>

# 測試 Docker push（用測試 tag）
docker pull nginx:alpine
docker tag nginx:alpine <REGISTRY_HOSTNAME>:5000/test:proxy-check
docker push <REGISTRY_HOSTNAME>:5000/test:proxy-check
docker rmi <REGISTRY_HOSTNAME>:5000/test:proxy-check
```

### 8.3 Runner 層

```bash
# 確認 Runner 服務的環境變數
sudo systemctl show act_runner | grep -i environment
# 確認包含 no_proxy 設定

# 確認 Runner 在線
sudo systemctl status act_runner
# 確認 Active: active (running)
```

---

## 9. 常見問題排除

### 9.1 curl 回傳 502 Proxy Error

```
HTTP/1.1 502 Proxy Error ( The specified Secure Sockets Layer (SSL) port is not allowed. )
```

**原因**：ISA Proxy 只允許 443 端口的 HTTPS，非標準端口（如 5000）被擋。

**解法**：將目標主機加入 no_proxy：

```bash
export no_proxy="$no_proxy,<目標主機>"
```

### 9.2 curl 回傳空白但無錯誤

```bash
curl -sk https://<REGISTRY_HOSTNAME>:5000/v2/
# 無輸出
```

**確認方式**：加上 `-w "%{http_code}"` 看狀態碼。

```bash
curl -sk -o /dev/null -w "%{http_code}" https://<REGISTRY_HOSTNAME>:5000/v2/
```

- `200` → 正常，只是回傳內容是 `{}`（空 JSON）
- `000` → 連線失敗

### 9.3 Docker build 時 npm ci 失敗

```
npm ERR! network request to https://registry.npmjs.org/xxx failed
```

**原因**：Docker build 時容器內無法存取 npm registry。

**解法**：在 Dockerfile 中加入 Proxy 設定，或在 docker build 時傳入：

```bash
docker build \
  --build-arg http_proxy=http://<HTTP_PROXY_HOST>:15629 \
  --build-arg https_proxy=http://<HTTP_PROXY_HOST>:15629 \
  -t <image> .
```

> **注意**：如果 Docker daemon 已設定 Proxy，build 時通常會自動繼承。
> 但某些情況下需要手動傳入 build-arg。

### 9.4 no_proxy 設定了但不生效

**檢查清單：**

1. 確認環境變數名稱大小寫：
   - 系統層通常用小寫：`no_proxy`
   - Docker / systemd 用大寫：`NO_PROXY`
   - 建議大小寫都設定以確保相容

2. 確認 `source ~/.bashrc` 已執行（或開新的 SSH 連線）

3. 確認 systemd 服務已重啟：`sudo systemctl restart <service>`

4. 確認值的格式正確：
   - 多個值用逗號分隔，**不要有空格**
   - 錯誤：`no_proxy="a, b, c"`
   - 正確：`no_proxy="a,b,c"`

### 9.5 新增內部服務到 no_proxy

如果未來有新的內部服務需要繞過 Proxy，需要在三層都加入：

```bash
# 1. 系統層 — 編輯 ~/.bashrc
nano ~/.bashrc
# 修改 no_proxy 行，加入新的主機

# 2. Docker 層 — 編輯 Docker Proxy 設定
sudo nano /etc/systemd/system/docker.service.d/http-proxy.conf
# 修改 NO_PROXY 行

# 3. Runner 層 — 編輯 act_runner 服務
sudo nano /etc/systemd/system/act_runner.service
# 修改 no_proxy 行

# 重載全部
source ~/.bashrc
sudo systemctl daemon-reload
sudo systemctl restart docker
sudo systemctl restart act_runner
```

> **提示**：如果新服務的網域也是 `*.<CORP_DOMAIN>`，
> 已有的 `.<CORP_DOMAIN>` 萬用匹配就能涵蓋，不需額外新增。
