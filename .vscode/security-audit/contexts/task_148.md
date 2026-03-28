# Task 148: Locale Number Parsing Edge Cases in Financial Operations

## Key File
- `lib/internal/Magento/Framework/Locale/Format.php:77` - getNumber() method

## Regex Analysis
The regex `/[^0-9^\^.,-]/m` preserves: digits, carets, dots, commas, hyphens (negatives).

## Key Edge Cases to Verify
1. **Negative numbers pass through** - `-100` becomes `-100.0`. Check ALL 20+ callers of getNumber() for negative handling
2. **null input returns null** (line 79-81) - arithmetic on null coerces to 0 in PHP, but verify
3. **Arabic locale path** (line 88-90) - normalizeArabicLocale() transforms what characters?
4. **Japan locale hardcode** (line 112) - comma treated as group separator only for ja_JP
5. **Locale switch mid-session** - if store locale changes, same string "1,000" could parse as 1.0 or 1000.0

## Callers (20+ files)
Key financial callers: Quote/Item.php (_prepareQty), Quote/Item/Updater.php (parseCustomPrice), Sales/CreditmemoFactory.php (parseNumber), SalesRule conditions, Directory/Currency, Eav/AttributePersistor
