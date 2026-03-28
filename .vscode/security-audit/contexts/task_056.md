# Trace Taint: CatalogUrlRewrite Column Name Injection

## Overview
`CatalogUrlRewrite\Model\Storage\DbStorage::prepareSelect()` concatenates column names directly without `quoteIdentifier()`, unlike parent class.

## Comparison
- Parent (safe) line 90: `$select->where($this->connection->quoteIdentifier($column) . ' IN (?)', $value);`
- Child (unsafe) line 43: `$select->where('url_rewrite.' . $column . ' IN (?)', $value);`

## Key Files
- `app/code/Magento/CatalogUrlRewrite/Model/Storage/DbStorage.php` (line 42-43)
- `app/code/Magento/UrlRewrite/Model/Storage/DbStorage.php` (line 89-90)
