# Auth Gap Hunter Context

## Auth Architecture Summary
- Admin: Auth-by-default via Backend\App\AbstractAction (ACL + FormKey + SecretKey)
- Frontend: OPEN-by-default via Framework\App\Action\Action
- REST API: Resource-based ACL via webapi.xml routes
- GraphQL: OPEN-by-default, per-resolver auth

## Highest Priority
1. Frontend controllers (~337) - OPEN-by-default, must self-protect
2. GraphQL resolvers (~403) - OPEN-by-default, per-resolver auth
3. REST API endpoints with 'anonymous' resource in webapi.xml

## Route files
- 98 routes.xml files (frontend + adminhtml)
- 73 webapi.xml files
- Frontend routes use 'standard' router
- Admin routes use 'admin' router

## Key question
Which frontend controllers handle sensitive operations without requiring auth?
Which GraphQL mutations allow unauthenticated access?
