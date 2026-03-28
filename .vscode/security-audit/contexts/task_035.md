# Task 035 Context: File Upload Handling Evaluation

## Pre-analysis matches
- move_uploaded_file/$_FILES: 16 files
- original filename preserved: 25 files

## Key files
- app/code/Magento/Theme/Controller/Adminhtml/Design/Config/FileUploader/Save.php
- app/code/Magento/Customer/Controller/Adminhtml/File/Address/Upload.php
- app/code/Magento/Customer/Controller/Adminhtml/File/Customer/Upload.php
- app/code/Magento/Customer/Model/FileUploader.php
- app/code/Magento/Catalog/Model/Product/Option/Type/File.php
- app/code/Magento/ImportExport/Controller/Adminhtml/Import/Validate.php

## Check for
1. File type validation (MIME vs extension)
2. Path traversal in filename
3. Upload to web-accessible directory
4. Double extension bypass (file.php.jpg)
5. SVG upload allowing XSS/SSRF
