# Task 114: PageCache Cookie Cache Poisoning
## Finding: L-010
## Key: lib/internal/Magento/Framework/App/PageCache/Version.php:59
- md5(rand() . time()), HttpOnly=false, SameSite=Lax
## Investigate: Varnish cache keying, cache poisoning via prediction, AJAX usage
