# Context: Guest Order Access & Order Management Security

## Key Entry Points (Frontend - OPEN by default)
### Guest (UNAUTHENTICATED)
- Sales/Controller/Guest/Form.php, View.php, Reorder.php
- Sales/Controller/Guest/Invoice.php, Shipment.php, Creditmemo.php, Print*.php
- Sales/Controller/Guest/OrderLoader.php - Guest order authentication

### Customer (AUTHENTICATED)
- Sales/Controller/Order/View.php, Reorder.php, History.php
- Sales/Controller/Order/Plugin/Authentication.php
- Sales/Controller/Download/DownloadCustomOption.php

### Order Cancellation: OrderCancellation/ module with GraphQL

## Security Concerns
1. Guest order enumeration (sequential IDs + email)
2. Guest auth bypass (email + increment ID + last name verification)
3. IDOR in order view (customer A sees customer B's order)
4. Custom option download path traversal
5. Order cancellation race conditions
6. XSS via order data in print views
