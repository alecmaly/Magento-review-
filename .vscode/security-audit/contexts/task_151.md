# Task 151: API Token Revocation Completeness
M-021: password change/reset do not revoke API tokens.
Key files: AccountManagement.php (changePasswordForCustomer line 1072, resetPassword line 712), CustomerEmailChangedObserver.php, Integration/Plugin/Model/CustomerUser.php, CustomerTokenService.php, JwtUserToken/Model/Revoker.php
