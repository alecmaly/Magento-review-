# Task 120: JS Escaper data: URI Bypass Investigation

## Key Finding
JS escaper.js _checkHrefValue only checks startsWith('javascript'). Missing data: URI check.

## Code Paths to Check
1. product/name.js - allowedTags includes 'a'
2. Theme/messages.js - allowedTags includes 'a'
3. summary/item/details.js - allowedTags without 'a' (safe)
4. Ui grid/cells/sanitizedHtml.js - check allowedTags
5. MediaGalleryUi grid/messages.js - check allowedTags
