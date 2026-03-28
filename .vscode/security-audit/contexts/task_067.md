# Context: Downloadable Products & Product Alert Security

## Entry Points
### Downloadable (Mixed auth)
- Downloadable/Controller/Download/Link.php - Download purchased link (auth)
- Downloadable/Controller/Download/LinkSample.php - Sample (may be public)
- Downloadable/Controller/Download/Sample.php - Product sample (public)

### ProductAlert (Auth)
- ProductAlert/Controller/Add/Price.php, Stock.php
- ProductAlert/Controller/Unsubscribe/Price.php, Stock.php, PriceAll.php, StockAll.php

## Security Concerns
1. Download link auth bypass (non-purchasers access)
2. Path traversal in download file serving (LFI)
3. Sample download no auth - file serving from disk
4. Download link token security
5. Unsubscribe without proper auth (CSRF)
