# Task 086: Carrier Config URL SSRF

## Files
- Ups/Config/Backend/UpsUrl.php validates ups.com. Others?
- StompClient.php:513 Jolokia, SSL verify disabled. Admin panel or env.php?
- PayPal transaction_url: arbitrary configurable?
