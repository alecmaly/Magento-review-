# Context: Import/Export & CSV Processing Security

## Modules: ImportExport, CatalogImportExport, CustomerImportExport, BundleImportExport, etc. (9 total)

## Key Files (Admin-only)
- ImportExport/Controller/Adminhtml/Import/Start.php, Validate.php
- ImportExport/Controller/Adminhtml/Export/Export.php
- ImportExport/Controller/Adminhtml/History/Download.php
- ImportExport/Model/Import/Source/Csv.php, Zip.php

## Known: T-3 BundleImportExport SQL injection via CSV (task_053)

## Security Concerns
1. SQL injection via CSV data fields (beyond bundle - check all importers)
2. CSV injection (formula injection in exports)
3. ZIP extraction path traversal (zip slip)
4. Import file type/content validation bypass
5. DoS via large import files
6. Image import SSRF (product image URLs fetched server-side?)
7. Export data exfiltration (all customer PII, order data)
8. History file access without proper auth
