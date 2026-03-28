# Validation Context: H-006 Email Enumeration + Brute-Force ATO Chain

## Finding to Validate
- ID: H-006, Severity: high, Confidence: 0.92, Discovered by: task_107

## Key Claims to Verify
1. /V1/customers/isEmailAvailable returns distinct boolean - no auth required
2. /V1/integration/customer/token allows brute-force - lockout after 10 fails, no CAPTCHA on API
3. Chain: enumerate emails -> brute-force -> ATO via H-005

## Files to Read
- app/code/Magento/Customer/Model/AccountManagement.php - isEmailAvailable()
- app/code/Magento/Integration/Model/CustomerTokenService.php - createCustomerAccessToken()
- app/code/Magento/Customer/etc/config.xml - lockout settings

## Chain Components
M-005, M-006, H-005, M-022, M-023, H-007
