# Task 085: HTTP Driver SSRF - All Callers

## Sinks
- Http.php:86 file_get_contents, Http.php:251 fsockopen, Http.php:31 get_headers

## Tasks
1. Search all callers of ReadFactory->create() with HTTP/HTTPS driver
2. Check if product import can be triggered via REST API
3. Check for non-admin paths to HTTP driver
