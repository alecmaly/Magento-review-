# Context: User Content Features (Wishlist, Review, Contact, SendFriend)

## Entry Points
### Wishlist (Auth + Shared NO AUTH)
- Wishlist/Controller/Index/Send.php, Share.php - Share wishlist
- Wishlist/Controller/Shared/Index.php, Cart.php - View/add shared (NO AUTH)

### Review (Partially auth)
- Review/Controller/Product/Post.php - Submit review

### Contact (UNAUTHENTICATED)
- Contact/Controller/Index/Post.php - Contact form

### SendFriend (Auth)
- SendFriend/Controller/Product/Sendmail.php

## Known: T-1 Wishlist token cache poisoning (task_051)

## Security Concerns
1. Wishlist sharing token predictability/enumeration
2. Review XSS (title/detail/nickname sanitization)
3. Contact form email header injection
4. SendFriend spam/email injection
5. Wishlist IDOR
6. Review/contact rate limiting
