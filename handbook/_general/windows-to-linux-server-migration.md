# Windows → Linux Server 通用轉移指南

**版本**：1.0（2026-05-15）  
**適用情境**：將運行於 Windows（含 Task Scheduler + 腳本）的服務棧遷移至 Ubuntu Linux，並以 Docker Compose 容器化管理。  
**脫敏說明**：本文不含任何公司特定 IP、hostname、帳密或業務邏輯，可直接納入跨專案手冊。

---

## 目錄

1. [遷移前盤點](#1-遷移前盤點)
2. [環境差異快查](#2-環境差異快查)
3. [排程任務遷移](#3-排程任務遷移)
4. [Docker 容器化注意事項](#4-docker-容器化注意事項)
5. [時區管理](#5-時區管理)
6. [物件儲存（MinIO）清理任務](#6-物件儲存minio清理任務)
7. [企業內網 Proxy 與映像拉取](#7-企業內網-proxy-與映像拉取)
8. [行尾符號（CRLF vs LF）](#8-行尾符號crlf-vs-lf)
9. [驗證 Checklist](#9-驗證-checklist)
10. [常見採坑與解法](#10-常見採坑與解法)

---

## 1. 遷移前盤點

遷移前必須留存「基線快照」，避免事後追溯耗時。

### 1.1 必記項目

| 項目 | Windows 端確認 | Linux 端預填 |
|---|---|---|
| 排程任務清單 | 工作排程器 → 匯出 XML | — |
| 腳本清單 | 路徑、觸發頻率、執行帳號 | — |
| 資料目錄 | 路徑、大小、是否仍在寫入 | 對應 Linux 路徑 |
| 環境變數 / 設定檔 | `.env`、`config.ini`、Registry 值 | — |
| 服務相依（DB、物件儲存、外部 API）| 連線字串、帳號 | — |
| 容器拓樸（若已部分容器化）| `docker ps -a` 輸出 | — |

### 1.2 判斷目錄是否仍在寫入

在 Linux 端做，避免清除仍活躍的資料：

```bash
# 監看目錄最近 60 秒是否有新檔案
watch -n 10 "find /path/to/dir -newer /tmp/.ts -ls 2>/dev/null | head" 
# 或查 inode change time
stat /path/to/dir/somefile
```

---

## 2. 環境差異快查

| 面向 | Windows | Ubuntu Linux |
|---|---|---|
| 路徑分隔符 | `\` | `/` |
| 排程管理 | Task Scheduler（GUI/XML） | cron / systemd timer / Docker cron |
| Python 執行器 | `python` | `python3`（需確認版本） |
| 環境變數存放 | 系統屬性 / Registry | `/etc/environment`、`.bashrc`、`/etc/profile.d/` |
| 行尾符號 | CRLF | LF |
| 預設時區 | 本地時間 | 通常 UTC（**需手動設容器 TZ**）|
| 服務管理 | SCM、Task Scheduler | systemd、Docker Compose |

---

## 3. 排程任務遷移

### 3.1 選型比較

| 方案 | 適用情境 | 優點 | 缺點 |
|---|---|---|---|
| **容器內 cron daemon**（推薦）| 任務屬某個服務的一部分 | 與 docker-compose 統一管理、log 可 `docker logs` | cron 不繼承容器環境變數（需額外處理）|
| systemd timer | 宿主機級別排程 | 成熟、可依賴、支援 OnCalendar | 與容器生命週期脫鉤；若換 K8s 需重寫 |
| Kubernetes CronJob | 已在 K8s 架構 | 官方支援、自動重試 | 需 K8s 環境 |

### 3.2 容器內 cron：標準 Dockerfile 模板

```dockerfile
FROM python:3.10-slim

# 安裝 cron
RUN apt-get update && apt-get install -y --no-install-recommends cron && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .

# ⚠️ 只用一種 cron 安裝方式（見採坑 §10.1）
COPY crontab /etc/cron.d/my-job
RUN chmod 0644 /etc/cron.d/my-job

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
```

### 3.3 crontab 格式（`/etc/cron.d/` 專用）

```
# /etc/cron.d/my-job  ← 6 欄格式，第 6 欄為執行 user
0 4 * * *  root  /usr/local/bin/python /app/script.py > /proc/1/fd/1 2>/proc/1/fd/2
```

> **重要**：`/etc/cron.d/` 的檔名**不可含 `.`**，cron 會略過含點的檔案。

### 3.4 entrypoint.sh 標準模板

```bash
#!/bin/bash
set -e

# 把容器環境變數注入 /etc/environment（供 cron job 讀取）
printenv | grep -E '^(MINIO_|APP_|DB_|S3_)' > /etc/environment || true

# 支援 args passthrough（讓 docker compose run 可傳入 --dry-run 等旗標）
if [ "$#" -gt 0 ]; then
    exec "$@"
fi

# 前景模式啟動 cron（log 才能被 docker logs 收到）
exec cron -f
```

---

## 4. Docker 容器化注意事項

### 4.1 環境變數注入 cron 的完整流程

cron daemon 不繼承容器啟動時的 `ENV` / `environment:`，需在 entrypoint.sh 主動導出：

```bash
# Debian 系（python:*-slim、ubuntu）走 PAM，/etc/environment 會被 pam_env 注入
printenv | grep -E '^MY_VAR_PREFIX' > /etc/environment || true
```

Alpine 等非 PAM 環境此法無效，需在 crontab 檔頂部直接設定：

```
MINIO_ENDPOINT=http://minio:9000
0 4 * * * root /usr/local/bin/python /app/script.py ...
```

### 4.2 docker-compose.yml 範本片段

```yaml
services:
  my-cron-service:
    build: ./my-cron-service
    container_name: app-my-cron-service
    restart: unless-stopped
    env_file: .env
    environment:
      - TZ=Asia/Taipei
    volumes:
      - /host/data/path:/data
    networks:
      - app-network
    depends_on:
      - minio
```

---

## 5. 時區管理

### 5.1 關鍵事實

- Ubuntu Server 預設時區常為 **UTC**
- Docker 容器繼承宿主機 `/etc/localtime`，但若宿主機是 UTC，容器也是 UTC
- cron 排程依賴容器時區，若未設定 `TZ`，`0 4 * * *` 代表 **UTC 04:00**，非台北 04:00

### 5.2 正確設定方式

**方法 A**（推薦）：`docker-compose.yml` 設 `TZ` 環境變數

```yaml
environment:
  - TZ=Asia/Taipei
```

**方法 B**：Dockerfile 內設

```dockerfile
ENV TZ=Asia/Taipei
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
```

### 5.3 驗證指令

```bash
# 驗證容器時區
docker exec <container> date
# 應顯示：Fri May 15 04:00:00 CST 2026（CST = Asia/Taipei +0800）
```

---

## 6. 物件儲存（MinIO）清理任務

### 6.1 MinIO 物件刪除的非同步回收

呼叫 MinIO `remove_object()` 後，儲存空間**不會立即釋出**。MinIO 有一個後台 GC 流程（`.minio.sys/tmp`）非同步清理刪除物件的底層 chunk。

**觀察現象**：
- Python 腳本刪除 10 GB 物件，`df -h` 顯示磁碟仍被占用
- 等 1–2 分鐘後才釋放

**實務建議**：
- 不要在腳本結束後立刻驗證磁碟用量
- 若需要空間告警，在刪除後等待 ≥ 2 分鐘再取樣

### 6.2 Dry-run 必須先跑

```python
# 建議所有清理腳本支援 --dry-run 旗標
import argparse
parser = argparse.ArgumentParser()
parser.add_argument('--dry-run', action='store_true')
args = parser.parse_args()

if args.dry_run:
    print(f"[DRY-RUN] 將刪除：{obj.object_name}")
else:
    client.remove_object(bucket, obj.object_name)
```

測試指令：

```bash
docker compose run --rm my-cron-service --dry-run
```

### 6.3 MinIO boto3 過濾範例

```python
from minio import Minio
from datetime import datetime, timezone, timedelta

client = Minio(endpoint, access_key=ak, secret_key=sk, secure=False)
cutoff = datetime.now(timezone.utc) - timedelta(days=7)

for obj in client.list_objects(bucket, recursive=True):
    if obj.last_modified < cutoff:
        print(f"刪除：{obj.object_name}（{obj.last_modified}）")
        client.remove_object(bucket, obj.object_name)
```

---

## 7. 企業內網 Proxy 與映像拉取

### 7.1 問題場景

公司內網機台若需透過 proxy 存取 Docker Hub，`docker pull` 會失敗。解法不是在 Dockerfile 裡設 proxy，而是在 **Docker daemon 層**設定。

### 7.2 設定 Docker daemon proxy

```bash
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo tee /etc/systemd/system/docker.service.d/http-proxy.conf <<EOF
[Service]
Environment="HTTP_PROXY=http://<PROXY_HOST>:<PORT>"
Environment="HTTPS_PROXY=http://<PROXY_HOST>:<PORT>"
Environment="NO_PROXY=localhost,127.0.0.1,<INTERNAL_REGISTRY>"
EOF

sudo systemctl daemon-reload
sudo systemctl restart docker
```

### 7.3 BuildKit 與 proxy

啟用 BuildKit 時（Docker 23+ 預設），`build` 指令同樣走 daemon proxy 設定，**不需在 Dockerfile 加 `ENV HTTP_PROXY`**。

```bash
# 驗證 proxy 設定
docker info | grep -i proxy
```

### 7.4 首次部署的預載策略

首次部署若映像不在 cache，build 時 `FROM python:3.10-slim` 等基底映像需走 proxy 拉取，時間較長（依網速 1–10 分鐘）。策略：

```bash
# 先手動 pull 基底映像，確認 proxy 正常
docker pull python:3.10-slim
# 再執行 build
docker compose build
```

---

## 8. 行尾符號（CRLF vs LF）

### 8.1 問題

在 Windows 上編輯的 shell script（`entrypoint.sh`、`run.sh`），若含 CRLF 行尾，複製到 Linux 執行會報錯：

```
/bin/bash: /entrypoint.sh: /bin/bash^M: bad interpreter: No such file or directory
```

`^M` 即 CR（`\r`），`bash` 無法識別。

### 8.2 根本解法：`.gitattributes`

```gitattributes
# .gitattributes
*.sh   text eol=lf
*.py   text eol=lf
crontab text eol=lf
*.bat  text eol=crlf
```

提交後，git 在 checkout 時自動轉換，無論在哪台機器上 clone 都正確。

### 8.3 緊急修復（已污染的檔案）

```bash
# 在 Linux 端手動轉換
sed -i 's/\r//' entrypoint.sh
# 或
dos2unix entrypoint.sh
```

---

## 9. 驗證 Checklist

部署後依序執行：

```bash
# 1. 容器正常運行
docker compose ps

# 2. 時區正確
docker exec <container> date
# 預期：顯示 CST（+0800）

# 3. cron 排程已載入（/etc/cron.d/ 方案）
docker exec <container> cat /etc/cron.d/my-job
# 預期：看到 crontab 內容

# 4. 環境變數注入 /etc/environment
docker exec <container> cat /etc/environment
# 預期：看到注入的 MINIO_* 等變數

# 5. 手動觸發 dry-run
docker compose run --rm <service> --dry-run
# 預期：列出待刪除物件，但不實際刪除

# 6. 首次正式執行
docker compose run --rm <service>
# 預期：成功並回傳刪除數量

# 7. log 可見
docker logs <container>
# 預期：看到腳本輸出（cron 首次排程觸發後再確認）
```

---

## 10. 常見採坑與解法

### 10.1 cron 雙路徑重複執行（高頻）

**症狀**：排程每次觸發兩次，其中一次報 `root: command not found`。

**原因**：Dockerfile 同時做了 `COPY crontab /etc/cron.d/` **和** `RUN crontab <file>`，兩條路徑都生效。`/etc/cron.d/` 格式含 user 欄位（`root`），被 `crontab` 安裝為個人 crontab 後，`root` 被誤判為指令。

**解法**：擇一機制。推薦只用 `/etc/cron.d/`，刪除所有 `RUN crontab` 指令。

---

### 10.2 entrypoint.sh 不支援 args passthrough

**症狀**：`docker compose run my-service --dry-run` 無效，`--dry-run` 被忽略。

**原因**：`entrypoint.sh` 最後是 `exec cron -f`，沒有處理 `$@`。

**解法**：

```bash
if [ "$#" -gt 0 ]; then
    exec "$@"
fi
exec cron -f
```

---

### 10.3 cron log 不可見

**症狀**：`docker logs` 看不到 cron job 的 print 輸出。

**原因**：cron 預設把 stdout/stderr 發 mail 給本地 MTA，容器內沒有 MTA。

**解法**：crontab 最後重導向至 PID 1：

```
0 4 * * * root python /app/script.py > /proc/1/fd/1 2>/proc/1/fd/2
```

同時 entrypoint.sh 用前景模式 `exec cron -f`（非背景 daemon）。

---

### 10.4 多個 Docker Stack 共用宿主機目錄

**情境**：Linux 機台同時跑多個 docker-compose stack（如 `vision-ai` + `cctv-web`），某個 stack 的清理腳本需存取另一個 stack 寫入的目錄。

**策略**：
1. 清理腳本 volume 掛載**宿主機絕對路徑**（非 named volume），如 `/home/<user>/data:/data`
2. 確認目錄 owner / permission 允許 container user 讀寫
3. 驗證：`docker exec <container> ls /data` 應看到預期內容

---

### 10.5 MinIO 非同步空間回收（見誤報空間未釋放）

**症狀**：刪除大量物件後，`df -h` 或 MinIO Console 顯示空間未減少。

**原因**：MinIO 的 chunk GC 是後台非同步流程，通常 1–2 分鐘後才反映。

**解法**：等待 2–5 分鐘後再確認；不要在自動化腳本中以「刪除後立即確認空間」作為成功條件。

---

## 參考資料

- [Docker 官方：設定 daemon 使用 proxy](https://docs.docker.com/engine/daemon/proxy/)
- [cron 手冊：`/etc/cron.d/` 格式說明](https://manpages.ubuntu.com/manpages/jammy/en/man8/cron.8.html)
- [MinIO Python SDK：`remove_object`](https://min.io/docs/minio/linux/developers/python/API.html)
- 相關筆記：`handbook/_general/cicd-gitea-actions-yaml.md`（同宿主多 stack 的 CI/CD 模式）
