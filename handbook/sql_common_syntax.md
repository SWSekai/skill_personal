# SQL 常見語法完整指南

> 建立日期: 2026-04-08 | 最後更新: 2026-04-08 | 分類: 資料庫

## 目錄
- [概述](#概述)
- [註解](#註解)
- [資料查詢 (SELECT)](#資料查詢-select)
- [條件篩選 (WHERE)](#條件篩選-where)
- [排序與分頁](#排序與分頁)
- [聚合函數與分組](#聚合函數與分組)
- [JOIN 多表連接](#join-多表連接)
- [子查詢](#子查詢)
- [資料操作 (INSERT / UPDATE / DELETE)](#資料操作-insert--update--delete)
- [表結構操作 (DDL)](#表結構操作-ddl)
- [常見陷阱與注意事項](#常見陷阱與注意事項)
- [最佳實踐](#最佳實踐)
- [延伸閱讀](#延伸閱讀)/

---

## 概述

SQL（Structured Query Language）是操作關聯式資料庫的標準語言。幾乎所有關聯式資料庫（SQL Server、MySQL、PostgreSQL、Oracle、SQLite）都支援 SQL，但各家在語法細節上有些差異。

本文涵蓋日常開發中最常用的 SQL 語法，適用於大部分關聯式資料庫。特殊語法會標註適用的資料庫。

---

## 註解

SQL 支援兩種註解方式，用於在查詢中加入說明文字，不會被執行。

### 單行註解 `--`

```sql
-- 這是單行註解，整行都不會被執行
SELECT * FROM employees  -- 行尾也可以加註解
```

### 多行註解 `/* */`

```sql
/*
  這是多行註解
  可以跨越多行
  常用於暫時停用一段查詢
*/
SELECT * FROM employees
```

### MySQL 額外支援 `#`

```sql
# 這也是單行註解（僅限 MySQL）
SELECT * FROM employees
```

> **注意**: `--` 後面必須接一個空格才會被視為註解（SQL 標準規範）。`--comment` 在某些資料庫會報錯。

---

## 資料查詢 (SELECT)

SELECT 是最常用的 SQL 語句，用於從表中讀取資料。

### 基本查詢

```sql
-- 查詢所有欄位
SELECT * FROM employees;

-- 查詢指定欄位
SELECT name, department, salary FROM employees;

-- 使用別名 (alias)
SELECT 
    name AS 姓名,
    department AS 部門,
    salary AS 薪水
FROM employees;
```

### DISTINCT — 去除重複

```sql
-- 找出所有不重複的部門
SELECT DISTINCT department FROM employees;

-- 多欄位組合去重
SELECT DISTINCT department, job_title FROM employees;
```

### TOP / LIMIT — 限制筆數

```sql
-- SQL Server: 取前 10 筆
SELECT TOP 10 * FROM employees;

-- MySQL / PostgreSQL / SQLite: 取前 10 筆
SELECT * FROM employees LIMIT 10;

-- Oracle: 取前 10 筆 (12c 以上)
SELECT * FROM employees FETCH FIRST 10 ROWS ONLY;
```

---

## 條件篩選 (WHERE)

WHERE 子句用於篩選符合條件的資料列。

### 比較運算子

```sql
-- 等於
SELECT * FROM employees WHERE department = 'Engineering';

-- 不等於（兩種寫法皆可）
SELECT * FROM employees WHERE department != 'HR';
SELECT * FROM employees WHERE department <> 'HR';

-- 大於、小於、大於等於、小於等於
SELECT * FROM employees WHERE salary > 50000;
SELECT * FROM employees WHERE salary >= 50000;
SELECT * FROM employees WHERE salary < 100000;
SELECT * FROM employees WHERE salary <= 100000;
```

### 邏輯運算子 (AND / OR / NOT)

```sql
-- AND: 同時滿足多個條件
SELECT * FROM employees
WHERE department = 'Engineering' AND salary > 60000;

-- OR: 滿足其中一個條件
SELECT * FROM employees
WHERE department = 'Engineering' OR department = 'Design';

-- NOT: 排除條件
SELECT * FROM employees
WHERE NOT department = 'HR';

-- 組合使用（用括號明確優先順序）
SELECT * FROM employees
WHERE (department = 'Engineering' OR department = 'Design')
  AND salary > 50000;
```

### BETWEEN — 範圍查詢

```sql
-- 薪水在 50000 到 100000 之間（包含端點）
SELECT * FROM employees
WHERE salary BETWEEN 50000 AND 100000;

-- 等同於
SELECT * FROM employees
WHERE salary >= 50000 AND salary <= 100000;
```

### IN — 多值匹配

```sql
-- 部門為 Engineering、Design 或 Marketing
SELECT * FROM employees
WHERE department IN ('Engineering', 'Design', 'Marketing');

-- 等同於
SELECT * FROM employees
WHERE department = 'Engineering'
   OR department = 'Design'
   OR department = 'Marketing';
```

### LIKE — 模糊匹配

```sql
-- % 匹配任意多個字元（包含零個）
SELECT * FROM employees WHERE name LIKE '陳%';       -- 姓陳的
SELECT * FROM employees WHERE name LIKE '%明%';      -- 名字含「明」的
SELECT * FROM employees WHERE email LIKE '%@gmail.com'; -- Gmail 信箱

-- _ 匹配恰好一個字元
SELECT * FROM employees WHERE name LIKE '陳_翰';     -- 陳X翰（三個字）

-- 跳脫萬用字元（查詢包含底線的值）
SELECT * FROM setup_types WHERE [SETUP-TYPE] LIKE 'CP\_%' ESCAPE '\';
```

> **重要**: `_` 在 LIKE 中是萬用字元！如果你要搜尋實際的底線字元，必須使用 `ESCAPE`。

### IS NULL / IS NOT NULL

```sql
-- 找出沒有填寫 email 的員工
SELECT * FROM employees WHERE email IS NULL;

-- 找出有填寫 email 的員工
SELECT * FROM employees WHERE email IS NOT NULL;
```

> **注意**: `NULL` 不能用 `=` 比較。`WHERE email = NULL` 永遠不會成立，必須用 `IS NULL`。

---

## 排序與分頁

### ORDER BY — 排序

```sql
-- 升冪排序（預設）
SELECT * FROM employees ORDER BY salary ASC;

-- 降冪排序
SELECT * FROM employees ORDER BY salary DESC;

-- 多欄位排序：先依部門升冪，再依薪水降冪
SELECT * FROM employees
ORDER BY department ASC, salary DESC;
```

### 分頁查詢

```sql
-- MySQL / PostgreSQL: 跳過前 20 筆，取 10 筆（第 3 頁，每頁 10 筆）
SELECT * FROM employees
ORDER BY id
LIMIT 10 OFFSET 20;

-- SQL Server: 使用 OFFSET-FETCH
SELECT * FROM employees
ORDER BY id
OFFSET 20 ROWS
FETCH NEXT 10 ROWS ONLY;
```

---

## 聚合函數與分組

### 常用聚合函數

```sql
-- COUNT: 計算筆數
SELECT COUNT(*) AS 總人數 FROM employees;
SELECT COUNT(email) AS 有填email的人數 FROM employees;  -- 不計 NULL
SELECT COUNT(DISTINCT department) AS 部門數 FROM employees;

-- SUM: 加總
SELECT SUM(salary) AS 薪水總額 FROM employees;

-- AVG: 平均
SELECT AVG(salary) AS 平均薪水 FROM employees;

-- MAX / MIN: 最大值 / 最小值
SELECT MAX(salary) AS 最高薪, MIN(salary) AS 最低薪 FROM employees;
```

### GROUP BY — 分組

```sql
-- 每個部門的人數和平均薪水
SELECT 
    department,
    COUNT(*) AS 人數,
    AVG(salary) AS 平均薪水
FROM employees
GROUP BY department;
```

### HAVING — 分組後篩選

```sql
-- 找出人數超過 5 人的部門
SELECT 
    department,
    COUNT(*) AS 人數
FROM employees
GROUP BY department
HAVING COUNT(*) > 5;
```

> **WHERE vs HAVING**: `WHERE` 在分組前篩選（篩選個別列），`HAVING` 在分組後篩選（篩選分組結果）。

---

## JOIN 多表連接

JOIN 用於合併多張表的資料。

### INNER JOIN — 內連接

只回傳兩張表都有匹配的列。

```sql
SELECT 
    e.name,
    e.department,
    d.manager
FROM employees e
INNER JOIN departments d ON e.department = d.name;
```

### LEFT JOIN — 左連接

回傳左表所有列，右表沒匹配的填 NULL。

```sql
-- 列出所有員工，即使沒有對應的部門資料
SELECT 
    e.name,
    d.manager
FROM employees e
LEFT JOIN departments d ON e.department = d.name;
```

### RIGHT JOIN — 右連接

回傳右表所有列，左表沒匹配的填 NULL。

```sql
-- 列出所有部門，即使沒有員工
SELECT 
    e.name,
    d.name AS department
FROM employees e
RIGHT JOIN departments d ON e.department = d.name;
```

### FULL OUTER JOIN — 全外連接

回傳兩張表的所有列，沒匹配的填 NULL。

```sql
SELECT 
    e.name,
    d.name AS department
FROM employees e
FULL OUTER JOIN departments d ON e.department = d.name;
```

> **MySQL 不支援 FULL OUTER JOIN**，需用 `LEFT JOIN UNION RIGHT JOIN` 模擬。

### 多表 JOIN

```sql
SELECT 
    e.name,
    d.name AS department,
    p.project_name
FROM employees e
INNER JOIN departments d ON e.department_id = d.id
INNER JOIN projects p ON e.id = p.lead_id;
```

---

## 子查詢

將一個查詢嵌套在另一個查詢中。

### WHERE 中的子查詢

```sql
-- 找出薪水高於平均的員工
SELECT * FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees);

-- 找出在 Engineering 部門有專案的員工
SELECT * FROM employees
WHERE id IN (
    SELECT lead_id FROM projects
    WHERE department = 'Engineering'
);
```

### FROM 中的子查詢（衍生表）

```sql
-- 每個部門的最高薪員工
SELECT dept_stats.department, dept_stats.max_salary
FROM (
    SELECT department, MAX(salary) AS max_salary
    FROM employees
    GROUP BY department
) AS dept_stats
WHERE dept_stats.max_salary > 80000;
```

### EXISTS — 存在性檢查

```sql
-- 找出有下屬的主管
SELECT * FROM employees e
WHERE EXISTS (
    SELECT 1 FROM employees sub
    WHERE sub.manager_id = e.id
);
```

---

## 資料操作 (INSERT / UPDATE / DELETE)

### INSERT — 新增資料

```sql
-- 插入單筆資料
INSERT INTO employees (name, department, salary)
VALUES ('王小明', 'Engineering', 65000);

-- 插入多筆資料
INSERT INTO employees (name, department, salary)
VALUES 
    ('王小明', 'Engineering', 65000),
    ('李小華', 'Design', 55000),
    ('張大偉', 'Marketing', 50000);

-- 從另一張表插入
INSERT INTO employees_archive (name, department, salary)
SELECT name, department, salary
FROM employees
WHERE resign_date IS NOT NULL;
```

### UPDATE — 更新資料

```sql
-- 更新特定條件的資料
UPDATE employees
SET salary = 70000
WHERE name = '王小明';

-- 更新多個欄位
UPDATE employees
SET salary = salary * 1.1,
    updated_at = GETDATE()  -- SQL Server; MySQL 用 NOW()
WHERE department = 'Engineering';
```

> **警告**: `UPDATE` 不加 `WHERE` 會更新整張表的所有資料！執行前務必確認條件。

### DELETE — 刪除資料

```sql
-- 刪除特定條件的資料
DELETE FROM employees
WHERE resign_date < '2025-01-01';

-- 刪除整張表的資料（保留表結構）
DELETE FROM temp_logs;

-- TRUNCATE: 更快速地清空表（不可 rollback，不觸發 trigger）
TRUNCATE TABLE temp_logs;
```

> **警告**: `DELETE` 不加 `WHERE` 會刪除整張表的所有資料！

---

## 表結構操作 (DDL)

### CREATE TABLE — 建表

```sql
CREATE TABLE employees (
    id INT PRIMARY KEY IDENTITY(1,1),  -- SQL Server 自動遞增
    name NVARCHAR(100) NOT NULL,
    department NVARCHAR(50),
    salary DECIMAL(10, 2) DEFAULT 0,
    email VARCHAR(255) UNIQUE,
    created_at DATETIME DEFAULT GETDATE()
);
```

```sql
-- MySQL 版本
CREATE TABLE employees (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    department VARCHAR(50),
    salary DECIMAL(10, 2) DEFAULT 0,
    email VARCHAR(255) UNIQUE,
    created_at DATETIME DEFAULT NOW()
);
```

### ALTER TABLE — 修改表結構

```sql
-- 新增欄位
ALTER TABLE employees ADD phone VARCHAR(20);

-- 刪除欄位
ALTER TABLE employees DROP COLUMN phone;

-- 修改欄位型別（SQL Server）
ALTER TABLE employees ALTER COLUMN name NVARCHAR(200);

-- 修改欄位型別（MySQL）
ALTER TABLE employees MODIFY COLUMN name VARCHAR(200);
```

### DROP TABLE — 刪表

```sql
-- 刪除表（連同結構和資料）
DROP TABLE IF EXISTS temp_logs;
```

---

## 常見陷阱與注意事項

### 1. NULL 的比較

```sql
-- ❌ 錯誤：永遠不會成立
SELECT * FROM employees WHERE email = NULL;

-- ✅ 正確
SELECT * FROM employees WHERE email IS NULL;
```

### 2. LIKE 的萬用字元 `_`

```sql
-- ❌ 搜尋 CP_ 開頭，但 _ 會匹配任意字元
SELECT * FROM types WHERE [SETUP-TYPE] LIKE 'CP_%';
-- 會匹配: CP_MOUNT, CP-MOUNT, CP1MOUNT ...

-- ✅ 正確：跳脫底線
SELECT * FROM types WHERE [SETUP-TYPE] LIKE 'CP\_%' ESCAPE '\';
-- 只匹配: CP_MOUNT, CP_DRILL ...
```

### 3. 欄位名含特殊字元

```sql
-- 欄位名有連字號時，各資料庫處理方式不同
SELECT [SETUP-TYPE] FROM types;         -- SQL Server（方括號）
SELECT `SETUP-TYPE` FROM types;         -- MySQL（反引號）
SELECT "SETUP-TYPE" FROM types;         -- PostgreSQL / Oracle（雙引號）
```

### 4. UPDATE / DELETE 忘記 WHERE

```sql
-- ⚠️ 這會更新整張表！
UPDATE employees SET salary = 0;

-- ✅ 安全做法：先用 SELECT 確認影響範圍
SELECT * FROM employees WHERE department = 'Temp';
-- 確認結果正確後，再執行
DELETE FROM employees WHERE department = 'Temp';
```

### 5. GROUP BY 的欄位限制

```sql
-- ❌ 錯誤：SELECT 的非聚合欄位必須在 GROUP BY 中
SELECT name, department, COUNT(*) FROM employees GROUP BY department;

-- ✅ 正確
SELECT department, COUNT(*) FROM employees GROUP BY department;
```

---

## 最佳實踐

1. **永遠先 SELECT 再 UPDATE/DELETE** — 用 SELECT 確認影響範圍後再執行修改操作
2. **使用交易 (Transaction)** — 重要操作包在 `BEGIN TRAN ... COMMIT` 中，出錯可 `ROLLBACK`
3. **避免 SELECT \*** — 明確列出需要的欄位，提升效能和可讀性
4. **加上 WHERE 條件** — UPDATE 和 DELETE 務必確認有 WHERE 子句
5. **使用參數化查詢** — 不要直接拼接使用者輸入到 SQL 字串中，防止 SQL Injection
6. **適當建立索引** — 常用於 WHERE、JOIN、ORDER BY 的欄位考慮建立索引
7. **用有意義的別名** — `e` 代表 employees、`d` 代表 departments，提升可讀性

---

## 延伸閱讀

- **窗口函數 (Window Functions)**: `ROW_NUMBER()`, `RANK()`, `PARTITION BY` — 進階分析用
- **CTE (Common Table Expression)**: `WITH ... AS` — 讓複雜查詢更易讀
- **索引 (Index)**: 資料庫效能優化的核心
- **交易 (Transaction)**: `BEGIN`, `COMMIT`, `ROLLBACK` — 資料一致性保證
- **預存程序 (Stored Procedure)**: 將常用邏輯封裝在資料庫端
- **觸發器 (Trigger)**: 自動在 INSERT/UPDATE/DELETE 時執行邏輯
