# Task 115: Encryption Key Management
## Key: lib/internal/Magento/Framework/Encryption/Encryptor.php
- Line 148: Keys from crypt/key. Lines 489-494: setNewKey(). Lines 419-461: decrypt() with legacy ciphers
- Current: ChaCha20-Poly1305. Legacy: Blowfish-ECB, Rijndael-128-ECB, Rijndael-256-CBC
## Investigate: Initial key generation entropy, re-encryption mechanism, keyVersion manipulation, env.php permissions
