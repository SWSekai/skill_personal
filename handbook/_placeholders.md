# Handbook Placeholder 對照表

handbook 內 guide 文件已脫敏為 placeholder，套用到實際環境時請依下表填入自身值。
**請勿在此檔填入實際值並 commit**——這檔只列 placeholder 用途，不存敏感資料。

## 主機與身份

| Placeholder | 用途說明 |
|---|---|
| `<RUNNER_HOST_IP>` | Self-hosted runner 主機 IP |
| `<RUNNER_HOST_NAME>` | Runner 主機 hostname / 內部代號 |
| `<RUNNER_BANNER>` | Runner SSH banner（部分情境會顯示）|
| `<RUNNER_USER>` | Runner 主機上跑 act_runner 的 OS user |
| `<REGISTRY_HOST_IP>` | Docker Registry 主機 IP |
| `<REGISTRY_HOSTNAME>` | Docker Registry 對外 hostname（含 :port 一般獨立） |
| `<GITEA_HOSTNAME>` | Gitea web UI hostname |
| `<RANCHER_HOSTNAME>` | Rancher Server hostname |
| `<CORP_DOMAIN>` | 公司一級域名（用於通配符 cert 等） |

## 網路

| Placeholder | 用途說明 |
|---|---|
| `<HTTP_PROXY_HOST>` | 公司內網 HTTP/HTTPS proxy 主機 IP（Docker build 用） |

## K8s 與應用

| Placeholder | 用途說明 |
|---|---|
| `<K8S_CLUSTER_NAME>` | Rancher 內 cluster 顯示名 |
| `<RANCHER_CLUSTER_ID>` | Rancher 內部 cluster ID（c-m-... 格式） |
| `<NAMESPACE_PROD>` | 正式環境 K8s namespace |
| `<NAMESPACE_TEST>` | 測試環境 K8s namespace（若無此環境可忽略） |
| `<APP_NAME>` | Application 名稱（同時用於 Docker image / K8s deployment / service） |

## 套用範例

```bash
# 一次性把 handbook 中所有 placeholder 套成你的環境值
# 注意：這份替換腳本本身含有真實值，請放在私人筆電或內網 wiki，不要 commit 進 git

cd handbook/
for f in guide-*.md; do
  sed -i \
    -e 's|<RUNNER_HOST_IP>|你的IP|g' \
    -e 's|<REGISTRY_HOSTNAME>|你的registry|g' \
    # ...其他 placeholder
    "$f"
done
```

> **安全提醒**：套用後的本地副本含敏感資訊，**絕對不要 push 回 sekai-workflow**。
> 已在 `_placeholders.md`（本檔）作為脫敏 SOP 的固定參考點。
