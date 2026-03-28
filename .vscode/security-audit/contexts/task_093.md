# Task 093: REST API Customer Self-Update Mass Assignment

## Background
PUT /V1/customers/me uses webapi.xml force=true for 4 fields:
- customer.id -> %customer_id%
- customer.group_id -> %customer_group_id% 
- customer.website_id -> %customer_website_id%
- customer.store_id -> %customer_store_id%

Source: app/code/Magento/Customer/etc/webapi.xml lines 137-148

## Key Questions
1. What other fields does CustomerRepositoryInterface::save() accept?
2. Can extension_attributes or custom_attributes be used to modify protected fields?
3. Is is_active, disable_auto_group_change, or other sensitive fields writable?
4. Does the service contract layer have field-level write protection beyond force params?

## Files to Read
- app/code/Magento/Customer/Model/ResourceModel/CustomerRepository.php (save method)
- app/code/Magento/Customer/Api/Data/CustomerInterface.php (data contract)
- lib/internal/Magento/Framework/Webapi/ServiceInputProcessor.php (force param handling)
