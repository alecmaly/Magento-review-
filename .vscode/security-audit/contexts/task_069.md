# Context: Multishipping Checkout & InstantPurchase Security

## Entry Points (Frontend - OPEN by default)
### Multishipping (30 controllers)
- Full checkout flow: Addresses -> Shipping -> Billing -> Overview -> Place Order
- Multiple back/forward navigation controllers
- Address management (add, edit, select, save)

### InstantPurchase
- InstantPurchase/Controller/Button/PlaceOrder.php - One-click order

## Security Concerns
1. Step skipping in multi-step checkout
2. State manipulation between steps
3. Address IDOR (use another customer's address)
4. Quantity changes after shipping calculation
5. InstantPurchase token replay / CSRF
6. Race conditions in concurrent multishipping
