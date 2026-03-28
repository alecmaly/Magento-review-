# Trace Taint: FormData parse_str Parameter Injection in Admin Forms

## Overview
`Magento\Framework\Serialize\Serializer\FormData::unserialize()` uses `parse_str()` + `array_replace_recursive()` which enables parameter injection.

## Flow
1. Admin submits form with `serialized_options` POST parameter
2. Controller calls `formDataSerializer->unserialize(getParam('serialized_options', '[]'))`
3. FormData JSON-decodes to get array of URL-encoded field strings
4. Each string is passed through `parse_str($item, $decodedFieldData)`
5. Results merged with `array_replace_recursive($formData, $decodedFieldData)`

## Known Callers
- `app/code/Magento/Catalog/Controller/Adminhtml/Product/Attribute/Save.php` line 140-143

## Key Files
- `lib/internal/Magento/Framework/Serialize/Serializer/FormData.php` (lines 36-52)
