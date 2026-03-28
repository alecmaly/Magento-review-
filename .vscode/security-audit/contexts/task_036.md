# Task 036 Context: SQL Injection Evaluation

## Pre-analysis matches
- SQL query patterns: 17 files
- Taint correlations (CRITICAL):
  - setup/src/Magento/Setup/Validator/DbValidator.php:145 - $dbName in checkDatabaseName
  - setup/src/Magento/Setup/Validator/DbValidator.php:189,196,198 - checkDatabasePrivileges

## Key areas
1. DbValidator.php - uses sprintf for SQL with $dbName (potential injection)
2. CatalogRule/Model/Indexer/IndexBuilder.php - uses sprintf with quoted identifiers
3. Any raw query construction outside the ORM
4. parse_str() usage (13 files) - can inject variables used in queries

## Note
Magento uses parameterized queries via database abstraction layer, but
setup/ code and some legacy paths may use raw SQL construction.
