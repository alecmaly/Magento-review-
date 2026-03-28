# Task 123: Verify Customer Address File Upload Auth Bypass (M-017)

## Key Files
- `app/code/Magento/Customer/Controller/Address/File/Upload.php` - extends Action, NOT AccountInterface
- `app/code/Magento/Customer/Controller/Plugin/Account.php` - Auth plugin for AccountInterface only

## Investigation Points
1. Is CSRF CsrfValidator applied to this POST endpoint?
2. Other plugins adding auth to non-AccountInterface customer controllers?
3. Does addressMetadataService->getAttributeMetadata() throw for non-existent attributes?
4. Check Customer/Controller/File/Upload.php for same gap
5. Enumerate ALL Customer controllers extending Action without AccountInterface
