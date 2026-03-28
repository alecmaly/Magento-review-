# Trace Taint: CURL FTP Protocol and User Options SSRF Amplification

## Finding 1: FTP Protocol Enabled
- File: `lib/internal/Magento/Framework/HTTP/Adapter/Curl.php`
- Code: `CURLOPT_PROTOCOLS, CURLPROTO_HTTP | CURLPROTO_HTTPS | CURLPROTO_FTP | CURLPROTO_FTPS`
- FTP can reach internal file servers and enable CRLF injection

## Finding 2: Arbitrary Curl Options
- File: `lib/internal/Magento/Framework/HTTP/Client/Curl.php`
- `setOptions()` accepts any array of curl options without validation

## Key Files
- `lib/internal/Magento/Framework/HTTP/Adapter/Curl.php`
- `lib/internal/Magento/Framework/HTTP/Client/Curl.php`
