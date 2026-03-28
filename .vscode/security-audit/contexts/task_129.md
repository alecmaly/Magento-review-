# Task 129 Context: Elasticsearch/OpenSearch TestConnection SSRF

## Finding: G-012

### Key Files
- AdvancedSearch/Controller/Adminhtml/Search/System/Config/TestConnection.php
- Elasticsearch8/Model/Client/Elasticsearch.php
- OpenSearch/Block/Adminhtml/System/Config/TestConnection.php

### Flow
1. Admin POST to search/system_config/testconnection
2. TestConnection::execute() line 72: options = getRequest()->getParams()
3. Line 80: clientResolver->create(options[engine], options)->testConnection()
4. Elasticsearch::buildESConfig() line 198-216: constructs URL from options
5. No IP/hostname validation

### Investigation Points
1. Verify ACL check: ADMIN_RESOURCE = Magento_Catalog::config_catalog
2. Check if error messages leak network info
3. Verify OpenSearch variant has same issue
4. Assess response: blind vs partial SSRF?
