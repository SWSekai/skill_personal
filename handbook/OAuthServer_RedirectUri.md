# OAuth RedirectUri 新增指南

## 概述

當你在本地開發或新環境部署時，如果遇到 OAuth 登入出現 **400 錯誤**（redirect_uri 不匹配），需要在 AuthServer 的資料庫中新增允許的 RedirectUri。

## 錯誤訊息範例

```
OAuth redirect_uri 不匹配
- 本地存取 URL: http://localhost:8000/
- OAuth 伺服器拒絕未註冊的 redirect_uri，回傳 400 錯誤
```

## 環境資訊

| 項目 | 值 |
|------|-----|
| OAuth 伺服器 | http://<OAUTH_SERVER_HOSTNAME>:8000 |
| 資料庫類型 | PostgreSQL |
| 資料庫主機 | <OAUTH_DB_HOST>:5432 |
| 資料庫名稱 | <OAUTH_DB_NAME> |
| 使用者 | postgres |
| 密碼 | Compeq123 |
| Client ID | test |

## 方法一：使用 Python 腳本（推薦）

### 前置需求

```bash
pip install psycopg2-binary
```

### 查詢目前的 RedirectUris

```python
import psycopg2
import json

conn = psycopg2.connect(
    host='<OAUTH_DB_HOST>',
    port=5432,
    database='<OAUTH_DB_NAME>',
    user='postgres',
    password='Compeq123'
)

cur = conn.cursor()
cur.execute('''
    SELECT "RedirectUris"
    FROM "OpenIddictApplications"
    WHERE "ClientId" = 'test'
''')

row = cur.fetchone()
uris = json.loads(row[0]) if row[0] else []

print('目前的 RedirectUris:')
for i, uri in enumerate(uris, 1):
    print(f'{i}. {uri}')

cur.close()
conn.close()
```

### 新增 RedirectUri

```python
import psycopg2
import json

# 要新增的 URI（修改這裡）
NEW_URIS = [
    'http://localhost:8000/',
    'http://<APP_SERVICE_IP>:8204',
]

conn = psycopg2.connect(
    host='<OAUTH_DB_HOST>',
    port=5432,
    database='<OAUTH_DB_NAME>',
    user='postgres',
    password='Compeq123'
)

cur = conn.cursor()

# 取得目前的 URIs
cur.execute('SELECT "RedirectUris" FROM "OpenIddictApplications" WHERE "ClientId" = %s', ('test',))
row = cur.fetchone()
current_uris = json.loads(row[0]) if row[0] else []

# 新增（避免重複）
added = []
for uri in NEW_URIS:
    if uri not in current_uris:
        current_uris.append(uri)
        added.append(uri)

if added:
    # 更新資料庫
    cur.execute(
        'UPDATE "OpenIddictApplications" SET "RedirectUris" = %s WHERE "ClientId" = %s',
        (json.dumps(current_uris), 'test')
    )
    conn.commit()
    print('成功新增:')
    for uri in added:
        print(f'  - {uri}')
else:
    print('所有 URI 都已存在，無需新增')

cur.close()
conn.close()
```

## 方法二：使用 psql 命令列

### 連線到資料庫

```bash
psql -h <OAUTH_DB_HOST> -p 5432 -U postgres -d <OAUTH_DB_NAME>
# 密碼: Compeq123
```

### 查詢目前設定

```sql
SELECT "ClientId", "RedirectUris"
FROM "OpenIddictApplications"
WHERE "ClientId" = 'test';
```

### 新增 RedirectUri（使用 JSON 操作）

```sql
-- 新增單一 URI
UPDATE "OpenIddictApplications"
SET "RedirectUris" = "RedirectUris" || '["http://localhost:8000/"]'::jsonb
WHERE "ClientId" = 'test';

-- 新增多個 URI
UPDATE "OpenIddictApplications"
SET "RedirectUris" = "RedirectUris" || '["http://localhost:8000/", "http://<APP_SERVICE_IP>:8204"]'::jsonb
WHERE "ClientId" = 'test';
```

### 驗證更新

```sql
SELECT jsonb_array_length("RedirectUris"::jsonb) as count, "RedirectUris"
FROM "OpenIddictApplications"
WHERE "ClientId" = 'test';
```

## 方法三：使用 GUI 工具

可以使用以下工具連接 PostgreSQL：

- **pgAdmin 4**（官方工具）
- **DBeaver**（跨平台）
- **DataGrip**（JetBrains）

連線後，找到 `OpenIddictApplications` 資料表，編輯 `RedirectUris` 欄位（JSON 格式）。

## 注意事項

1. **URI 格式要求**
   - 必須包含完整的 scheme（http:// 或 https://）
   - 結尾的 `/` 要一致（有加就要加，沒加就不加）
   - 範例：`http://localhost:8000/` 和 `http://localhost:8000` 是不同的

2. **生效時間**
   - OpenIddict 通常會即時讀取資料庫
   - 如果不生效，可能需要重啟 AuthServer 的 IIS Application Pool

3. **安全性提醒**
   - 生產環境不建議使用 localhost
   - 確保只新增可信任的 URI

## 資料表結構參考

```
OpenIddictApplications
├── Id (UUID)
├── ClientId (varchar) - 例如: 'test'
├── RedirectUris (text/jsonb) - JSON 陣列格式
├── PostLogoutRedirectUris (text/jsonb)
├── Permissions (text/jsonb)
└── ...其他欄位
```

## 常見問題

### Q: 新增後還是 400 錯誤？

1. 確認 URI 完全一致（包含結尾斜線）
2. 檢查是否有快取，嘗試清除瀏覽器 localStorage
3. 重啟 AuthServer

### Q: 如何刪除 RedirectUri？

```python
# 移除特定 URI
uri_to_remove = 'http://localhost:8000/'
current_uris = [u for u in current_uris if u != uri_to_remove]

cur.execute(
    'UPDATE "OpenIddictApplications" SET "RedirectUris" = %s WHERE "ClientId" = %s',
    (json.dumps(current_uris), 'test')
)
conn.commit()
```

### Q: 如何查看所有 Client？

```sql
SELECT "ClientId", "DisplayName", "RedirectUris"
FROM "OpenIddictApplications";
```
