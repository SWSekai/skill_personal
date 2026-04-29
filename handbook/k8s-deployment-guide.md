# Kubernetes 部署指南

本文件說明如何將應用程式部署至 RKE2 Kubernetes 集群。

---

## 部署流程總覽

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│  1. 登入    │    │  2. 建立    │    │  3. 下載    │    │  4. 打包    │    │  5. 部署    │
│  Rancher   │───▶│  Namespace  │───▶│ KubeConfig │───▶│  推送映像   │───▶│  到 K8s    │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
                   （首次才需要）
```

---

## 目錄

1. [事前準備](#事前準備)
2. [步驟一：登入 Rancher](#步驟一登入-rancher)
3. [步驟二：建立 Project 與 Namespace](#步驟二建立-project-與-namespace)
4. [步驟三：下載 KubeConfig](#步驟三下載-kubeconfig)
5. [步驟四：建置並推送 Docker 映像](#步驟四建置並推送-docker-映像)
6. [步驟五：部署至 Kubernetes](#步驟五部署至-kubernetes)
7. [驗證與除錯](#驗證與除錯)
8. [版本更新流程](#版本更新流程)

---

## 事前準備

### 必要檔案

| 檔案 | 說明 |
|------|------|
| `Dockerfile` | 定義如何打包應用程式成 Docker 映像 |
| `k8s-deployment.yaml` | 定義 K8s 要部署哪些資源（Pod、Service、Ingress 等） |
| `package.json` | Node.js 專案配置 |
| `pnpm-lock.yaml` 或 `package-lock.json` | 套件版本鎖定檔 |

### 本機環境

| 工具 | 用途 |
|------|------|
| Docker Desktop | 打包應用程式成映像檔 |
| kubectl | 對 K8s 集群下指令 |

### Docker 設定（首次）

私有 Registry 若使用 HTTP，需加入信任清單：

1. Docker Desktop → Settings → Docker Engine
2. 加入：
   ```json
   {
     "insecure-registries": ["<registry>:<port>"]
   }
   ```
3. Apply & Restart

---

## 步驟一：登入 Rancher

**Rancher** 是 K8s 的圖形化管理介面，可以在網頁上管理集群。

```
┌────────────────────────────────────────┐
│              Rancher                   │
│  ┌──────────────────────────────────┐  │
│  │  Cluster A    Cluster B    ...   │  │  ◄── 管理多個 K8s 集群
│  └──────────────────────────────────┘  │
└────────────────────────────────────────┘
```

**操作步驟：**
1. 開啟 Rancher 網址
2. 選擇 **Log in with Active Directory**
3. 輸入 AD 帳號密碼登入

---

## 步驟二：建立 Project 與 Namespace

> 若已有對應的 Project 和 Namespace，可跳過此步驟。

### Project 與 Namespace 的關係

```
Cluster（集群）
│
├── Project A（專案）─────────── Rancher 用來分組管理
│   ├── Namespace A-1           可設定：權限、資源配額
│   └── Namespace A-2
│
└── Project B（專案）
    ├── Namespace B-1 ────────── K8s 用來隔離資源
    └── Namespace B-2            裡面放：Pod、Service、ConfigMap...
```

### 什麼是 Project？

**Rancher 專有的分組單位**，用於：
- 把相關的 Namespace 群組在一起
- 統一設定權限（誰可以存取）
- 統一設定資源配額（CPU、記憶體上限）

### 什麼是 Namespace？

**K8s 原生的資源隔離空間**，用於：
- 區隔不同的應用程式或環境（dev / staging / prod）
- 避免資源名稱衝突（不同 Namespace 可以有同名的 Service）

### 建立方式

**建立 Project：**
1. Rancher → 選擇集群 → Cluster → Projects/Namespaces
2. Create Project → 填寫名稱 → Create

**建立 Namespace：**
1. 在 Project 下點 Create Namespace
2. 填寫名稱 → Create

---

## 步驟三：下載 KubeConfig

**KubeConfig** 是 kubectl 連線到 K8s 集群所需的憑證檔案。

```
┌──────────────┐     KubeConfig      ┌──────────────┐
│   你的電腦   │ ──────────────────▶ │   K8s 集群   │
│   kubectl    │   (含認證資訊)      │              │
└──────────────┘                     └──────────────┘
```

### 下載方式

1. Rancher → 選擇集群
2. 右上角 ⋮ → Download KubeConfig
3. 儲存到本機

### 使用方式

```powershell
# 設定環境變數（當前視窗有效）
$env:KUBECONFIG = "C:\path\to\kubeconfig.yaml"

# 驗證連線
kubectl get nodes
```

---

## 步驟四：建置並推送 Docker 映像

### 映像建置與推送流程

```
┌─────────────┐    docker build    ┌─────────────┐    docker push    ┌─────────────┐
│   原始碼    │ ─────────────────▶ │  Docker     │ ─────────────────▶│  Registry   │
│ Dockerfile  │                    │  映像       │                    │  (倉庫)     │
└─────────────┘                    └─────────────┘                    └─────────────┘
                                                                            │
                                                                            │ K8s 部署時
                                                                            ▼ 自動下載
                                                                      ┌─────────────┐
                                                                      │   K8s Pod   │
                                                                      └─────────────┘
```

### 建置映像

**Docker 映像**是應用程式的打包檔，包含程式碼、執行環境、相依套件。

```powershell
docker build -t <registry>:<port>/<app>:<version> .
```

### 推送至 Registry

**Registry** 是存放映像的倉庫，K8s 會從這裡下載映像來執行。

```powershell
docker push <registry>:<port>/<app>:<version>
```

### 驗證

```powershell
curl http://<registry>:<port>/v2/<app>/tags/list
```

---

## 步驟五：部署至 Kubernetes

### K8s 資源架構

```
                           使用者請求
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ Ingress                                                     │
│ 外部入口，設定域名和路徑                                      │
│ 例：https://myapp.example.com/api                           │
└─────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ Service                                                     │
│ 內部負載平衡，把流量分配給多個 Pod                            │
└─────────────────────────────────────────────────────────────┘
                               │
              ┌────────────────┼────────────────┐
              ▼                ▼                ▼
        ┌──────────┐     ┌──────────┐     ┌──────────┐
        │   Pod    │     │   Pod    │     │   Pod    │
        │ (容器)   │     │ (容器)   │     │ (容器)   │
        └──────────┘     └──────────┘     └──────────┘
              │                │                │
              └────────────────┴────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ ConfigMap / Secret                                          │
│ 環境變數和設定（資料庫連線、API Key 等）                      │
└─────────────────────────────────────────────────────────────┘
```

### 更新版本號

編輯 `k8s-deployment.yaml`，確認映像版本正確：

```yaml
image: <registry>:<port>/<app>:<version>
```

### 執行部署

```powershell
kubectl apply -f k8s-deployment.yaml
```

`kubectl apply` 會根據 YAML 檔案建立或更新資源。

### 確認部署狀態

```powershell
# 等待部署完成
kubectl rollout status deployment/<deployment> -n <namespace>

# 查看 Pod 狀態
kubectl get pods -n <namespace>
```

Pod 狀態為 `Running` 且 READY 為 `1/1` 表示正常。

---

## 驗證與除錯

### 常用指令

| 指令 | 用途 |
|------|------|
| `kubectl get pods -n <ns>` | 查看 Pod 列表與狀態 |
| `kubectl describe pod <pod> -n <ns>` | 查看 Pod 詳細資訊與事件 |
| `kubectl logs <pod> -n <ns>` | 查看應用程式日誌 |
| `kubectl logs <pod> -n <ns> --previous` | 查看上一次執行的日誌（崩潰時用） |
| `kubectl exec -it <pod> -n <ns> -- /bin/sh` | 進入容器內部除錯 |

### Pod 狀態說明

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│    Pending      │────▶│    Running      │────▶│   Completed     │
│   （等待調度）   │     │   （執行中）     │     │   （已結束）     │
└─────────────────┘     └─────────────────┘     └─────────────────┘
        │                       │
        ▼                       ▼
┌─────────────────┐     ┌─────────────────┐
│ ImagePullBackOff│     │ CrashLoopBackOff│
│ （拉取映像失敗） │     │ （程式崩潰重啟） │
└─────────────────┘     └─────────────────┘
```

| 狀態 | 說明 | 處理方式 |
|------|------|----------|
| `Running` | 正常運作 | 無需處理 |
| `Pending` | 等待調度 | 檢查資源是否足夠 |
| `ImagePullBackOff` | 無法拉取映像 | 確認映像名稱、Registry 可連線 |
| `CrashLoopBackOff` | 程式啟動後崩潰 | 用 `kubectl logs --previous` 查看錯誤 |

---

## 版本更新流程

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│  修改程式碼  │───▶│  建置映像   │───▶│  推送映像   │───▶│ kubectl apply│
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
                                                                │
                                           ┌────────────────────┘
                                           ▼
                                    ┌─────────────┐
                                    │  滾動更新   │
                                    │ 新 Pod 啟動 │
                                    │ 舊 Pod 關閉 │
                                    └─────────────┘
```

### 指令

```powershell
# 1. 建置新版本映像
docker build -t <registry>:<port>/<app>:<new-version> .

# 2. 推送映像
docker push <registry>:<port>/<app>:<new-version>

# 3. 更新 k8s-deployment.yaml 中的版本號

# 4. 套用更新
kubectl apply -f k8s-deployment.yaml

# 5. 確認部署成功
kubectl rollout status deployment/<deployment> -n <namespace>
```

### 回滾

若新版本有問題，可快速回到上一版：

```powershell
kubectl rollout undo deployment/<deployment> -n <namespace>
```

---

## 附錄：k8s-deployment.yaml 資源說明

| 資源 | 用途 |
|------|------|
| Namespace | 資源隔離的空間 |
| ConfigMap | 儲存非敏感的設定（環境變數） |
| Secret | 儲存敏感資料（密碼、金鑰） |
| Deployment | 定義要跑幾個 Pod、用什麼映像 |
| Service | 讓 Pod 可以被其他服務存取（內部負載平衡） |
| Ingress | 設定外部網址，讓使用者可以從外面連進來 |
