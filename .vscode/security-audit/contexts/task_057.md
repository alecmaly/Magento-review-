# Trace Taint: MediaGalleryUi REGEXP Pattern Injection

## Overview
`MediaGalleryUi\Model\SearchCriteria\CollectionProcessor\FilterProcessor\Directory::apply()` concatenates user-controlled directory path into MySQL REGEXP.

## Vulnerable Code
```php
$collection->getSelect()->where('BINARY path REGEXP ? ', '^' . $value . '/[^\/]*$');
```
Only `%` is stripped. MySQL REGEXP metacharacters `.`, `*`, `+`, `(`, `)`, `[`, `|` are NOT stripped.

## Key Files
- `app/code/Magento/MediaGalleryUi/Model/SearchCriteria/CollectionProcessor/FilterProcessor/Directory.php`
