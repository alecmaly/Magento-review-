# Task 034 Context: XML Parsing / XXE Evaluation

## Pre-analysis matches
- simplexml_load_string/DOMDocument/xml_parse: 15 files
- libxml_disable_entity_loader/LIBXML_NOENT: 1 file (XXE config)

## Key files
- app/code/Magento/AdminNotification/Model/Feed.php - new SimpleXMLElement($data) from external feed
- app/code/Magento/Dhl/Model/Carrier.php - simplexml_load_string($response) from DHL API
- app/code/Magento/Dhl/Model/Validator/XmlValidator.php
- app/code/Magento/MediaGalleryMetadata/Model/GetXmpMetadata.php - XMP metadata parsing
- app/code/Magento/Rule/Model/Condition/AbstractCondition.php
- Check: lib/internal/Magento/Framework/Xml/Security.php for XXE protection

## Critical question
Does Magento have a global XXE protection mechanism, or is it per-file?
