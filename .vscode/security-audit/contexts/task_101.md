# Task 101: GraphQL Resolver IDOR Investigation
GraphQL resolvers open-by-default. Check customer/wishlist/order resolvers for ownership. Guest cart uses masked_quote_id only.
Key: GetCartForUser.php:109-120, CustomerGraphQl resolvers, OrderGraphQl resolvers.
