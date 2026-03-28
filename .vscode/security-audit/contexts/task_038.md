# Task 038 Context: SSRF Evaluation

## Pre-analysis matches
- curl_init/file_get_contents http: 3 files
- GuzzleHttp: 3 files
- URL from request: 34 files
- ImageMagick: 7-110 files
- SVG external references: 27 files

## Key targets
1. DHL carrier - makes outbound HTTP requests with shipping data
2. PayPal integration - OAuth callbacks, IPN
3. Import URLs for downloadable products
4. ImageMagick processing (ImageTragick CVE-2016-3714)
5. SVG file uploads with xlink:href (SSRF)
6. Media URL parameters (92 files)
7. Webhook/callback URLs
