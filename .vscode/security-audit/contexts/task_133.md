# Task 133: ATO Chain - REST Email Change + Password Reset

## Chain
1. Attacker obtains bearer token
2. PUT /V1/customers/me with new email - NO re-auth (M-013)
3. POST /V1/customers/password triggers reset to new email
4. Attacker resets password via token

## Key Files
- Customer/Controller/Account/EditPost.php:430 - web requires password
- CustomerGraphQl/Model/Resolver/UpdateCustomerEmail.php:95 - GraphQL requires password
- Customer/Model/AccountManagement.php:653 - initiatePasswordReset loads by email
- Customer/Model/EmailNotification.php:164 - credentialsChanged sends to OLD+NEW email

## Investigate
1. Does REST CustomerRepositoryInterface::save() check password?
2. Does credentialsChanged() fire on REST path?
3. Is email confirmation required? Check AccountConfirmation::isCustomerEmailChangedConfirmRequired()
4. Check webapi.xml for /V1/customers/me service method
