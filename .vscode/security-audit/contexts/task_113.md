# Task 113: StompClient Jolokia Credential Exposure
## Finding: M-012
## Key: lib/internal/Magento/Framework/Stomp/StompClient.php:511-549
- Line 513: HTTP hardcoded, Line 523: Basic auth, Lines 527-528: TLS disabled
## Investigate: All CURLOPT_SSL_VERIFYPEER usage, Jolokia JMX impact, other internal service TLS
