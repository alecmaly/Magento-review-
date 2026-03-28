# Auth Matrix - Magento 2

## Auth Posture Summary
- Admin: Auth-by-default (AbstractAction, ~250 controllers)
- Frontend: OPEN-by-default (~337 controllers, self-protect)  
- REST: Resource-declared (webapi.xml), self-scoped uses force=true
- GraphQL: OPEN-by-default (~370/402 no auth)

## Ownership Validation Results
- Customer/Address Delete: SAFE (customerId check)
- Wishlist: SAFE (customerId check via WishlistProvider)
- Downloadable Link: SAFE (hash + customerId)
- Sales/Guest: SAFE (cookie/form + orderAuth)
- Checkout/Sidebar: SAFE (session-scoped quote)
- Store SwitchRequest: SAFE (HMAC with crypt key)
- CompareListGraphQl AssignCompareList: VULN M-007 missing customer_id param

## Negative-Space Controls
- CSRF: ~100% POST via CsrfValidator middleware (XHR exempted)
- Admin ACL: ~100% via AbstractAction dispatch
- Customer auth: Opt-in, ~15/40 frontend groups require it
- Ownership: 1 gap found in GraphQL M-007
