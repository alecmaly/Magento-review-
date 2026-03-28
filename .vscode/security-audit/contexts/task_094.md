# Task 094: Systematic GraphQL Resolver IDOR Check

## Background  
M-007 found missing customer_id param in AssignCompareListToCustomer. Similar patterns may exist in other resolvers.

## Pattern to Check
Any resolver that: (1) accepts an ID/UID from args, (2) resolves it to an internal ID, (3) performs an operation. The ownership check must happen BEFORE the operation.

## Known Safe Resolvers (verified in task_028)
- CustomerGraphQl: DeleteCustomer, UpdateCustomer, DeleteAddress, UpdateAddress - all check getIsCustomer()
- QuoteGraphQl: All cart operations use GetCartForUser which validates cart ownership
- WishlistGraphQl: ClearWishlist, UpdateProducts validate customer ID
- OrderCancellationGraphQl: CancelOrder checks order customer_id !== context userId

## Focus Areas
- SalesGraphQl: Order queries by order_number - does it verify customer ownership?
- QuoteGraphQl: GetCartForUser edge case - guest cart customer_id=0 vs logged-in customer_id=0
- RequisitionListGraphQl if exists
- GiftCardGraphQl if exists
- Any resolver using MaskedQuoteIdToQuoteId without customer check
