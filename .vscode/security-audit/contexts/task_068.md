# Context: Admin Backup & Encryption Key Management

## Entry Points (Admin - auth-by-default)
### Backup
- Backup/Controller/Adminhtml/Index/Create.php, Download.php, Rollback.php, MassDelete.php

### EncryptionKey
- EncryptionKey/Controller/Adminhtml/Crypt/Key/Save.php

## Security Concerns
1. Backup download path traversal (filename manipulation)
2. Backup contains secrets (password hashes, API keys, encryption keys)
3. Backup files accessible via web server directly?
4. Backup ACL scope (which admin roles?)
5. Encryption key rotation: old encrypted data handling
6. Rollback to insecure state
