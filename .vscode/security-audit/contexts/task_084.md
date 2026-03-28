# Investigate: CSV Formula Injection in Export Module

## Overview
Magento's CSV export functionality writes user-controlled data (product names, customer names, etc.)
directly to CSV files without sanitizing formula injection characters.

## Vulnerable Code
`app/code/Magento/ImportExport/Model/Export/Adapter/Csv.php`:
- Line 141-145: `writeRow()` calls `$this->_fileHandler->writeCsv()` without any formula sanitization
- `lib/internal/Magento/Framework/Filesystem/Driver/File.php:884` calls `fputcsv()` directly

No sanitization of formula characters (`=`, `+`, `-`, `@`, `\t`, `\r`) found anywhere in the export path.

## Attack Scenario
1. Attacker creates product/customer with name like `=cmd|'/C calc'!A1` or `=HYPERLINK("https://evil.com","Click")`
2. Admin exports products/customers to CSV
3. Admin opens CSV in Excel/LibreOffice → formula executes

## Key Files to Examine
- `app/code/Magento/ImportExport/Model/Export/Adapter/Csv.php` (writeRow)
- `lib/internal/Magento/Framework/Filesystem/File/Write.php` (writeCsv)
- `lib/internal/Magento/Framework/Filesystem/Driver/File.php:884` (fputcsv)
- Product export: `app/code/Magento/CatalogImportExport/Model/Export/Product.php`
- Customer export: `app/code/Magento/CustomerImportExport/Model/Export/Customer.php`

## Severity Considerations
- Requires admin to export AND open in spreadsheet
- Modern spreadsheets warn about external formulas
- But this is a well-documented attack class (CWE-1236)
- Data injection possible via unauthenticated paths (product reviews, newsletter, customer registration)
