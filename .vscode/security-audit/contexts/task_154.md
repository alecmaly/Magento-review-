# Task 154: Address IDOR Pattern Check Across Endpoints

## Background
M-026 confirmed that PUT /V1/customers/me allows address IDOR via CustomerRepository::save().
The root cause is AddressRepository::save() loading addresses by ID without ownership check.

## Key Files
- app/code/Magento/Customer/Model/ResourceModel/AddressRepository.php (save method, lines 107-145)
- app/code/Magento/Customer/Model/AddressRegistry.php (retrieve method, no ownership check)
- app/code/Magento/Customer/etc/webapi.xml (address endpoints)

## Endpoints to Check
1. PUT /V1/addresses/:addressId (direct address update)
2. PUT /V1/customers/:customerId (admin customer update)
3. GraphQL updateCustomerAddress mutation
4. POST /V1/customers/:customerId/addresses (create address)

## Root Cause
AddressRepository::save() at line 112 calls addressRegistry->retrieve($address->getId()) 
which loads ANY address without checking that it belongs to the calling customer.
