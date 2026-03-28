# Task 032 Context: PHP Deserialization Evaluation

## Pre-analysis matches
- unserialize(): 202 files (using Magento Serializer abstraction, but verify all paths)
- __wakeup/__destruct/__toString: 107 files (gadget chain surface)

## Key files to examine
- app/code/Magento/Webapi/Model/Config.php - unserialize for service config caching
- app/code/Magento/Config/Model/Config/Backend/Serialized.php - config value unserialization
- app/code/Magento/Ui/Model/Bookmark.php - bookmark data unserialization
- app/code/Magento/Ui/Model/Manager.php - UI component data unserialization

## Questions
1. Does any unserialize path use native PHP unserialize() vs Magento's Json serializer?
2. Can user-controlled data reach any unserialize call?
3. What gadget classes exist with __wakeup/__destruct that could be chained?
4. Is the Serializer interface always Json, or can it be configured to use native PHP?
