# Task 132: Cart Checkout Race - Mutex Divergence

## Background
CartMutex uses LockManagerInterface (cart_lock_<id>).
QuoteMutex uses SELECT FOR UPDATE on quote_id_mask table.
Different lock mechanisms - don't synchronize.

## Key Files
- Quote/Model/CartMutex.php - placeOrder lock
- Quote/Model/QuoteMutex.php - item save lock
- Quote/Model/QuoteManagement.php:420 - placeOrderRun
- Quote/Model/Quote/Item/Repository.php:122 - item save
- Quote/etc/di.xml:47-48 - DI preferences

## Key Question
submitQuote() does NOT call collectTotals(). Check if concurrent item save can modify cart while placeOrder runs.
