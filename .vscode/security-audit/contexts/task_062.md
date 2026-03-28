# Context: Customer Account Security

## Key Entry Points (Frontend - OPEN by default)
### Unauthenticated
- Customer/Controller/Account/LoginPost.php, CreatePost.php
- Customer/Controller/Ajax/Login.php
- Customer/Controller/Account/ForgotPasswordPost.php, CreatePassword.php, ResetPasswordPost.php
- Customer/Controller/Account/Confirm.php, Confirmation.php

### Authenticated
- Customer/Controller/Account/EditPost.php
- Customer/Controller/Address/FormPost.php, Delete.php
- Customer/Controller/Address/File/Upload.php
- Customer/Controller/Section/Load.php - Customer data sections (AJAX)

## REST/GraphQL (Anonymous)
- POST /V1/customers, /V1/customers/isEmailAvailable, /V1/customers/password
- createCustomerV2, generateCustomerToken, requestPasswordResetEmail mutations

## Security Concerns
1. Password reset token prediction/timing/reuse
2. Email enumeration (isEmailAvailable, registration, password reset)
3. AJAX login CSRF bypass
4. Address file upload: types, path traversal, XSS
5. Section/Load data exposure (other users?)
6. Account confirmation bypass
7. Customer token security (generation, expiry, revocation)
