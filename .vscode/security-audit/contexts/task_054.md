# Trace Taint: Quote/Order Item Options Deserialization Chain

## Overview
Quote and Order items store serialized option data in database. Data is user-influenced (add-to-cart) and unserialized during order display/reorder/admin operations.

## Key Deserialization Points
- `app/code/Magento/Sales/Model/AdminOrder/Create.php` lines 2055-2058
- `app/code/Magento/Catalog/Helper/Product/Configuration.php` lines 126-129

## Concerns
- Framework uses `allowed_classes => false` - blocks PHP objects
- But: Array contents used in rendering - potential XSS if option values contain HTML
- Can customer inject arbitrary option values via cart API/GraphQL?
- Legacy data may use PHP serialize format instead of JSON

## Key Files
- `app/code/Magento/Sales/Model/AdminOrder/Create.php`
- `app/code/Magento/Catalog/Helper/Product/Configuration.php`
- `app/code/Magento/Quote/Model/Quote/Item.php`
