# Context: Checkout & Cart Manipulation Security

## Key Entry Points (Frontend - OPEN by default)
- Checkout/Controller/Cart/Add.php, Addgroup.php, Delete.php, UpdatePost.php
- Checkout/Controller/Cart/CouponPost.php - Apply/remove coupons
- Checkout/Controller/Cart/EstimatePost.php - Shipping estimation
- Checkout/Controller/Onepage/SaveOrder.php - Place order
- Checkout/Controller/Sidebar/RemoveItem.php, UpdateItemQty.php - AJAX sidebar

## REST API (Anonymous): 19+ guest cart endpoints
- POST /V1/guest-carts, /V1/guest-carts/:cartId/items, payment-information, shipping-information

## Security Concerns
1. Price Manipulation via API or parameter tampering
2. Coupon brute force (rate limiting?)
3. Cart hijacking (masked ID predictability - task_044 already exists)
4. Negative quantities for credit
5. Race conditions during checkout (double-spend)
6. Step skipping (payment without shipping)
7. Currency manipulation mid-checkout
8. Sidebar AJAX CSRF protection
