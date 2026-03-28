# Task 087 Context: Legacy Encrypted Data Investigation

## Background
Encryptor.php supports 4 cipher versions for decrypt:
- 0: Blowfish-ECB (weakest - pattern leaking, 64-bit block)
- 1: Rijndael-128-ECB (pattern leaking)
- 2: Rijndael-256-CBC (acceptable but deprecated)
- 3: ChaCha20-Poly1305 AEAD (current, modern)

New encrypt() always uses version 3 (ChaCha20).
decrypt() auto-detects version from prefix format: keyVersion:cipherVersion:base64data

## Key Questions
1. What database fields store encrypted values? Search for encrypt( and decrypt( calls.
2. Is there a key rotation / re-encryption mechanism?
3. Do old installations retain version 0/1 encrypted data indefinitely?
4. Could payment-related data still be ECB-encrypted?
5. Is there a migration path to re-encrypt all data with ChaCha20?

## Key Files
- lib/internal/Magento/Framework/Encryption/Encryptor.php (lines 418-461 decrypt)
- lib/internal/Magento/Framework/Encryption/Adapter/Mcrypt.php (legacy adapter)
- setup/src/ - check for key rotation commands
