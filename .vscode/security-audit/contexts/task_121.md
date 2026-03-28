# Task 121: KO html: Binding Stored XSS Surface Audit

## Templates Using html: Binding (Frontend)
1. minicart/content.html - getCartParamUnsanitizedHtml('extra_actions')
2. minicart/item/default.html - getProductNameUnsanitizedHtml(product_name)
3. minicart/item/default.html - getOptionValueUnsanitizedHtml(option.value)
4. summary/item/details.html - getNameUnsanitizedHtml, full_viewUnsanitizedHtml
5. OfflinePayments banktransfer/cashondelivery - getInstructions()
6. checkout-agreements.html - checkboxText, modalContent
7. shipping-policy.html - config.shippingPolicyContent

## Key Question
Customer custom option text -> DB -> PHP API -> JSON -> JS -> html: binding
Is this path always HTML-encoded by PHP before JSON serialization?
