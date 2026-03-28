# Architecture Overview

## Tech Stack

| Component | Technology | Version |
|-----------|-----------|---------|
| Language | PHP | ~8.3/~8.4/~8.5 |
| Framework | Magento 2 CE | 2.4-develop |
| Database | MySQL (PDO) | ext-pdo_mysql |
| Auth | Session, Bearer Token, JWT, OAuth | multi-layer |
| Cache | Redis, File | |
| Queue | RabbitMQ, MySQL MQ, Stomp | |
| Search | Elasticsearch 8, OpenSearch 2 | |
| Encryption | ChaCha20-Poly1305 + legacy | sodium |
| Password Hash | Argon2ID13 + legacy | sodium |
| HTTP Client | Guzzle 7, Laminas HTTP | |
| GraphQL | webonyx/graphql-php 15 | 403 resolvers |
| JWT | web-token/jwt-framework 4 | |

## Auth Architecture

### Auth Layers

| # | Layer | Base Class | Mechanism | Posture |
|---|-------|-----------|-----------|---------|
| 1 | Admin controllers | Backend App AbstractAction | ACL (_isAllowed) + FormKey (POST) + SecretKey (GET) | Auth-by-default |
| 2 | Frontend controllers | Framework App Action Action | NONE at base level | **OPEN-by-default** |
| 3 | REST API | Webapi Controller Rest | Resource ACL via webapi.xml per endpoint | Resource-declared |
| 4 | GraphQL | **OPEN-by-default** (~370/402 no auth) | **HIGH** |

### Auth Details

**Admin (Backend App AbstractAction):**
- dispatch() calls _isAllowed() before action execution
- _isAllowed() checks authorization->isAllowed(ADMIN_RESOURCE)
- _processUrlKeys() validates FormKey (POST) and SecretKey (GET) via constant-time comparison
- SecretKey is MD5-based hash of formKey + route/controller/action

**Frontend (Framework App Action Action):**
- Base class provides NO authentication
- CSRF validation via CsrfValidator middleware (FormKey on POST, skips AJAX/XHR)
- Individual controllers must implement their own auth checks

**REST API (webapi.xml):**
- anonymous = no auth required (41 endpoints)
- self = customer-scoped (38 endpoints)
- Named resource = ACL check
- TokenUserContext extracts Bearer token; OauthUserContext validates OAuth 1.0a
- RequestThrottler rate-limits token generation

**GraphQL:**
- No framework-level auth; per-resolver check via getIsCustomer()
- Cart operations validated via GetCartForUser (ownership check)
- Query depth: 20, complexity: 1000; introspection enabled by default
- No visible rate limiting at GraphQL layer

### Auth Risk Matrix

| Area | Posture | Risk Level |
|------|---------|------------|
| Adminhtml | Auth-by-default | Lower |
| Frontend | **OPEN-by-default** | **HIGH** |
| REST API (anonymous) | Open (41 endpoints) | **HIGH** |
| REST API (self) | Customer-scoped | Medium |
| REST API (ACL) | Auth-by-default | Lower |
| GraphQL | **OPEN-by-default** (~370/402 no auth) | **HIGH** |

## Entry Points

| Type | Count |
|------|-------|
| Frontend routes.xml | 37 files |
| Admin routes.xml | 61 files |
| Controller PHP classes | ~1,240 |
| REST API webapi.xml | 22 files |
| REST Anonymous endpoints | 42 |
| REST Self-scoped endpoints | 38 |
| GraphQL schema files | 40 |
| GraphQL mutation modules | 17 |
| Custom routers | 4 (Cms, Robots, UrlRewrite, REST Route) |
| CLI commands | 97 |
| Cron jobs (crontab.xml) | 26 files |
| Message queue consumers | 10 queue_consumer.xml |
| SOAP endpoint | 1 (Webapi/Controller/Soap.php) |
| DI/Plugin interceptors | 288 across 89 di.xml |

### Critical Anonymous REST Endpoints

| Endpoint | Method | Risk |
|----------|--------|------|
| /V1/integration/admin/token | POST | Admin brute-force |
| /V1/integration/customer/token | POST | Customer brute-force |
| /V1/customers | POST | Registration abuse |
| /V1/customers/isEmailAvailable | POST | Email enumeration |
| /V1/customers/password | PUT | Password reset |
| /V1/search | GET | DoS potential |
| /V1/guest-carts/* | Multiple | 19+ guest cart ops |

### GraphQL Mutations Without Auth

| Mutation | Module | Risk |
|----------|--------|------|
| createCustomerV2 | CustomerGraphQl | Registration abuse |
| createGuestCart | QuoteGraphQl | Cart abuse |
| subscribeEmailToNewsletter | NewsletterGraphQl | Email spam |
| contactUs | ContactGraphQl | Spam |
| createProductReview | ReviewGraphQl | Spam (optional auth) |

## Sinks

| Type | Count | Key Files |
|------|-------|-----------|
| SQL query() | ~145 files | CatalogImportExport, UrlRewrite/DbStorage, Setup/DbValidator |
| Deserialization | ~202 files | Framework Serialize (allowed_classes=false) |
| PHP magic methods | ~107 files | Gadget chain surface |
| XML parsing (XXE) | ~41 files | Shipping carriers, Rule conditions |
| File uploads | ~16 files | Framework/File/Uploader |
| Shell execution | ~2 files | Framework/Shell.php (with escaping) |
| Variable includes | ~324 files | Needs investigation |
| Weak hashing | ~104 files | Legacy md5/sha1 |
| extract() | ~39 files | EAV/AbstractEntity |

## Network Topology
- PHP-FPM behind Nginx; Varnish/CDN in PageCache module
- HSTS available but NOT enabled by default (requires both front+admin HTTPS)
- Swagger API docs enabled only in developer mode (disabled in production)
- X-Frame-Options: SAMEORIGIN set in both .htaccess and PHP HeaderProvider
- X-Content-Type-Options: nosniff set by PHP HeaderProvider
- X-XSS-Protection: 1; mode=block (disabled for IE8)
- TRACE/TRACK HTTP methods blocked in .htaccess
- CSP: report-only mode default, allows unsafe-inline and unsafe-eval
- upgrade-insecure-requests CSP directive available when HTTPS enabled
- Static files cached with max-age=31536000 (1 year)
- app/ directory fully denied via .htaccess (deny all)
- setup/ directory denied by default with IP whitelist option
- Standalone pub/ files: index.php, get.php, static.php, health_check.php, cron.php
- Error pages: pub/errors/ (404.php, 503.php, report.php, processor.php)

## Server Security Headers Summary
| Header | Value | Source | Default Enabled |
|--------|-------|--------|----------------|
| X-Frame-Options | SAMEORIGIN | .htaccess + PHP | Yes |
| X-Content-Type-Options | nosniff | PHP HeaderProvider | Yes |
| X-XSS-Protection | 1; mode=block | PHP HeaderProvider | Yes |
| Strict-Transport-Security | max-age=31536000 | PHP HeaderProvider | No (requires HTTPS) |
| Content-Security-Policy | report-only + permissive | PHP Csp module | Yes (report-only) |
| upgrade-insecure-requests | via CSP | PHP HeaderProvider | No (requires HTTPS) |

## Cookie Security
| Setting | Default | Source |
|---------|---------|--------|
| HTTPOnly | true | Cookie/etc/config.xml |
| SameSite | Lax | PhpCookieManager default |
| Secure | Not forced by default | Requires HTTPS config |
| Lifetime | 3600s (1hr) | Cookie/etc/config.xml |

## Session Security
| Setting | Default | Source |
|---------|---------|--------|
| Validate Remote Address | Disabled | Store/etc/config.xml |
| Validate HTTP Via | Disabled | Store/etc/config.xml |
| Validate X-Forwarded-For | Disabled | Store/etc/config.xml |
| Validate User Agent | Disabled | Store/etc/config.xml |
| Use SID in URL | Disabled | Store/etc/config.xml |
| Admin Session Timeout | 900s | Security/etc/config.xml |
| Admin Session Max Size | 256KB | Security/etc/config.xml |

## Missing Security Modules
- No ReCaptcha modules found (only basic CAPTCHA)
- No TwoFactorAuth module found
- These are typically in Adobe Commerce (paid) or separate packages

## Known Stack Vulnerabilities
- Setup DbValidator: SQL injection via dbName (H-001)
- Version endpoint: unauthenticated disclosure (H-002)
- Admin token API: anonymous brute-force endpoint (H-004)
- GraphQL introspection enabled by default
- Legacy encryption modes (ECB, Blowfish) still supported
- CSP not enforced (report-only mode) with unsafe-inline/eval allowed
