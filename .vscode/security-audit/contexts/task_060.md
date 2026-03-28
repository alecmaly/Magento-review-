# Context: PayPal Payment Integration Security

## Feature Overview
PayPal is Magento's largest payment integration with 73 frontend controller files.

## Key Entry Points (Frontend - OPEN by default)
- Paypal/Controller/Express/ - Express checkout flow
- Paypal/Controller/Ipn/Index.php - IPN webhook receiver (unauthenticated POST)
- Paypal/Controller/Payflow/ - Payflow gateway callbacks
- Paypal/Controller/Payflowadvanced/ - Payflow Advanced callbacks
- Paypal/Controller/Hostedpro/ - Hosted Pro callbacks
- Paypal/Controller/Billing/Agreement/ - Customer billing agreements

## Security Concerns
1. IPN Verification: Does IPN handler verify messages with PayPal? Spoofed IPN to mark orders paid?
2. Price Manipulation: Can Express Checkout amounts be modified between redirect and return?
3. Return URL Tampering: Are return/cancel URLs validated? Open redirect?
4. Billing Agreement Abuse: Created/charged without consent?
5. PayPal CSRF Exemption: Express checkout bypasses CSRF (redirects)
6. Payflow Silent Post: Unauthenticated callback - signature verification?
7. Race Condition: Concurrent PayPal return callbacks?

## Related: CardinalCommerce (3D Secure), Vault (stored payments), PaypalCaptcha, PaypalGraphQl
