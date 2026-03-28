# Trace Taint: BundleImportExport SQL Injection via Import CSV Data

## Overview
`BundleImportExport/Model/Import/Product/Type/Bundle.php` line 534-536 concatenates `$item[0]` directly into SQL WHERE clause without parameterization.

## Vulnerable Code
```php
$select->where('parent_id = ' . $item[0] . ' AND title = ?', $item[1]);
$select->orWhere('parent_id = ' . $item[0] . ' AND title = ?', $item[1]);
```
Only `$item[1]` (title) uses parameter binding. `$item[0]` (parent_id) is concatenated directly.

## Data Source
`_cachedOptionSelectQuery` populated from import data. Need to trace CSV → array → SQL path.

## Key Files
- `app/code/Magento/BundleImportExport/Model/Import/Product/Type/Bundle.php` (lines 530-549)
## Pre-evaluation Note (task_036)
Line 227: `(int)$entityId` cast means $item[0] is always integer. Likely SAFE.
Verify this is the ONLY place _cachedOptionSelectQuery is populated (lines 227, 921, 952).
