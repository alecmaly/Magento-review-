# Task 040 Context: Crypto, Secrets, Weak Hashing Evaluation

## Pre-analysis matches
- Weak hashing md5/sha1/crypt: 104 files
- Predictable PRNG rand/mt_rand/uniqid: 49 files
- Potential hardcoded secrets: 627 files
- Weak ciphers DES/Blowfish: 10 files
- ECB mode: 5 files

## Key areas
1. Where is md5/sha1 used for security purposes vs checksums?
2. Are rand/mt_rand used for tokens, nonces, or session IDs?
3. Hardcoded API keys, passwords, or secrets in code
4. Legacy Blowfish/ECB encryption still active or decrypt-only?
5. Argon2ID13 parameter strength
