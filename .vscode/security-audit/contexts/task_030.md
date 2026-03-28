# Hotspot Walk Batch 1: Top Tainted Functions (1-15)
Based on taint analysis (T-1 through T-9) plus high-risk unauthenticated controllers:
1. Wishlist/Plugin (T-1), 2. FormData::unserialize() (T-2), 3. BundleImportExport SQL (T-3)
4. Quote/Order item options (T-4), 5. CURL adapter (T-5), 6. CatalogUrlRewrite (T-6)
7. MediaGalleryUi REGEXP (T-7), 8. Layout/Merge simplexml (T-8), 9. Framework/Shell.php
10. Customer/Account/CreatePost, 11. Checkout/Onepage/SaveOrder, 12. Quote/Model/Quote
13. Compare/Add, 14. Review/Product/Post, 15. Contact/Index/Post
