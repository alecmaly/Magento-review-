# Context: Catalog Search & Promotions/SalesRule Security

## Entry Points
### Search (Frontend - OPEN by default)
- CatalogSearch/Controller/Result/Index.php, Advanced/Result.php
- CatalogSearch/Controller/Ajax/Suggest.php
- GET /V1/search (anonymous REST API)

### Promotions
- Checkout/Controller/Cart/CouponPost.php - Apply coupon (frontend)
- SalesRule admin controllers - Coupon management
- CatalogRule admin controllers - Price rules

## Security Concerns
1. Search injection (Elasticsearch/OpenSearch queries)
2. Search DoS (wildcards, complex queries)
3. Coupon brute force / enumeration
4. Price rule scope bypass
5. Popular search terms info disclosure
