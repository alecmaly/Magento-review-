# Task 116: Admin SecretKey MD5 Investigation
## Key: app/code/Magento/Backend/Model/Url.php:245-272
- SecretKey = HMAC(route+controller+action+formKey, crypt_key)
- BackendValidator:111 uses ===, AbstractAction:390 uses Security::compareStrings
## Investigate: FormKey leak via XSS/logs, SecretKey in Referer, timing safety of ===
