# Security Audit - Global Context

## Scope Definition

### In Scope
- All PHP source code in app/code/Magento/ (221 modules, 10650+ files)
- Framework core in lib/internal/Magento/Framework/
- Setup code in setup/src/
- Configuration files (nginx, routes.xml, webapi.xml, di.xml)
- JavaScript/RequireJS frontend code
- GraphQL schema and resolvers

### Out of Scope
- Third-party vendor/ dependencies (beyond known CVEs)
- Test files (excluded per config)
- node_modules, dist, build directories

### Attack Surface Priority

| Priority | Description | Examples |
|----------|-------------|----------|
| Critical | Internet-facing, unauthenticated | GraphQL (open-by-default), Frontend controllers, REST anonymous endpoints |
| High | Internet-facing, authenticated | Customer dashboard, REST authenticated APIs |
| Medium | Internal, authenticated | Admin panel (auth-by-default), Admin REST APIs |
| Low | Admin-only, localhost | CLI commands, Cron jobs, Setup wizards |

## Project Overview

**Application Name:** Magento 2 (Open Source / Community Edition)
**Purpose:** Full-stack e-commerce platform for online retail
**Technology Stack:** PHP 8.3+, MySQL, Redis, Elasticsearch/OpenSearch, RabbitMQ, GraphQL
**Repository:** magento/magento2ce (2.4-develop branch)

## Architecture Summary

### Directory Structure
```
app/code/Magento/       # 221 modules (main application code)
lib/internal/Magento/   # Framework core (88+ subdirectories)
setup/src/              # Installation and setup code
pub/                    # Public web root
bin/                    # CLI entry point (bin/magento)
dev/                    # Development tools
phpserver/              # Built-in PHP server config
```

### Key Components
- **Entry Points:** Frontend controllers (~337), Admin controllers (~894), REST API (73 webapi.xml), GraphQL resolvers (~403), CLI commands, Cron jobs
- **Database Layer:** PDO/MySQL with ORM abstraction, QueryBuilder pattern
- **Authentication:** Multi-layer (Session + FormKey for web, Bearer Token + OAuth for API, JWT for modern API)
- **Authorization:** ACL-based RBAC with per-resource permissions

### Trust Boundaries
- Storefront <-> Frontend controllers (Session + CSRF FormKey)
- Admin panel <-> Adminhtml controllers (Admin session + ACL + SecretKey)
- API clients <-> REST/SOAP (Bearer Token/OAuth/Guest + ACL per webapi.xml resource)
- API clients <-> GraphQL (Bearer Token/Guest, per-resolver auth)

## Data Flow

### User Input Sources
- HTTP request parameters (GET/POST), headers, cookies
- REST API JSON/XML bodies
- GraphQL queries/mutations
- File uploads (images, CSV imports, theme files)
- SOAP requests
- CLI arguments (setup/admin commands)

### Sensitive Data Types
- Customer PII (name, email, address, phone)
- Payment information (credit card data via payment gateways)
- Admin credentials and tokens
- API keys and integration tokens
- Encryption keys (crypt/key config)
- Order data, pricing, inventory

### External Integrations
- Payment gateways (PayPal, CardinalCommerce/3DS)
- Shipping carriers (DHL, FedEx, UPS, USPS)
- Search engines (Elasticsearch, OpenSearch)
- Email (SMTP via Symfony Mailer)
- Analytics (Google Analytics/GTM, Adobe Analytics)
- AWS S3 (remote storage)
- RabbitMQ (async operations)
- Duo Security (2FA)

## Security-Relevant Patterns Observed

### Positive Patterns (Security Controls)
- ChaCha20-Poly1305 AEAD encryption (modern)
- Argon2ID13 password hashing (modern)
- CSP with nonce support (XSS prevention)
- Admin CSRF with FormKey + SecretKey
- Timing-safe comparison (Security::compareStrings)
- Session regeneration on login
- Rate limiting on password resets
- JWT token revocation mechanism
- SameSite=Lax cookies by default
- X-Frame-Options: SAMEORIGIN, X-Content-Type-Options: nosniff
- HTTPOnly cookies enabled
- TRACE/TRACK HTTP methods blocked in .htaccess
- Sensitive directories (app/, setup/) denied via .htaccess
- Swagger UI disabled in production mode

### Concerning Patterns (Potential Issues)
- Frontend controllers OPEN-by-default (no auth enforcement at base class level)
- GraphQL resolvers OPEN-by-default
- 265 files with deserialization (even though using Serializer abstraction)
- 107 files with PHP magic methods (__wakeup/__destruct) - gadget chain surface
- 324 files with variable-based includes
- 104 files with weak hashing (md5/sha1) - legacy compatibility
- 49 files with predictable PRNG (rand/mt_rand/uniqid)
- Legacy encryption modes (ECB, Blowfish) still supported
- HSTS missing from nginx sample config
- Critical SQL injection taint in setup/DbValidator
- Extract() with user input found (1 file)
- preg_replace /e modifier found (1 file)
- No ReCaptcha or 2FA modules present in this codebase
- CAPTCHA per-IP threshold=1000 (effectively no IP-based rate limit)
- Admin login is case-insensitive (simplifies brute-force)
- HSTS not enabled by default
- CSP in report-only mode with unsafe-inline and unsafe-eval

### Known Sinks
- unserialize (via Serializer) - 265 files
- simplexml_load_string/DOMDocument - 15 files (XXE)
- $_FILES/move_uploaded_file - 16 files
- shell_exec/proc_open - 35 files
- eval/exec/system/passthru - 45 files
- include/require with variables - 324 files
- fputcsv - CSV injection surface
- GuzzleHttp/curl - SSRF surface

## MCP Coverage Gaps
- Pre-analysis was run (summary.json exists with rich pattern data)
- Taint correlations available for critical/high severity
- Setup code has critical SQL injection taint signals
- No MCP project loaded (MCP tools not available in this task)

## REST API Anonymous Endpoint Inventory
- 42 anonymous REST endpoints across 22 webapi.xml files
- Critical: /V1/integration/admin/token (POST) - admin credential brute-force
- Critical: /V1/integration/customer/token (POST) - customer credential brute-force
- Email enumeration: /V1/customers/isEmailAvailable (POST)
- 19+ guest cart endpoints for unauthenticated checkout flow

## GraphQL Security Notes
- 17 modules define mutations; 40 schema files total
- Auth check: context->getExtensionAttributes()->getIsCustomer()
- Query depth: 20, complexity: 1000; introspection enabled by default
- No visible rate limiting at GraphQL layer
- Newsletter mutation subscribes any email without auth (H-003)
- Cart ownership: Most resolvers use GetCartForUser (ownership check). EstimateShippingMethods bypasses it (L-040). PayPal HostedProUrl/PayflowLinkToken use order collection with guest bypass (L-041).
- Systematic IDOR check (task_094): SalesGraphQl, CustomerGraphQl, WishlistGraphQl, CompareListGraphQl, VaultGraphQl, OrderCancellationGraphQl all properly verify customer_id ownership

## Documented Security Claims
| # | Claim | Source | Verified? | Verified By | Notes |
|---|-------|--------|-----------|-------------|-------|
| D-1 | All admin actions require ACL check | Auth code | partial | task_002 | AbstractAction._isAllowed() confirmed; subclass overrides need checking |
| D-2 | CSRF on state-changing requests | CsrfValidator | partial | task_002 | Skips AJAX/XHR |
| D-3 | Passwords hashed with Argon2ID13 | Encryptor.php | confirmed | task_040 | Legacy MD5/SHA256 compat for verification only |
| D-4 | Encryption uses ChaCha20-Poly1305 | Encryptor.php | confirmed | task_040 | New encrypt uses ChaCha20; legacy decrypt supports Blowfish/Rijndael |
| D-5 | Session regenerated on login | Customer Session | confirmed | task_005 | Both customer (Session.php:456,471) and admin (Auth/Session.php:264) |
| D-6 | Bug bounty via HackerOne | SECURITY.md | verified | task_001 | psirt@adobe.com |
| D-7 | Bearer token auth for REST API | TokenUserContext | partial | task_002 | Expiry/revocation needed |
| D-8 | Admin SecretKey constant-time compare | BackendValidator | confirmed | task_002 | Security::compareStrings() |
| D-9 | RequestThrottler rate-limits tokens | RequestThrottler | partial | task_002 | Limits need verification |
| D-10 | GraphQL depth/complexity limited | QueryComplexityLimiter | confirmed | task_002 | Depth=20 Complexity=1000 |
| D-11 | Admin locked after 6 failed logins (30min) | User/etc/config.xml | pending | | |
| D-12 | Customer locked after 10 failed logins (10min) | Customer/etc/config.xml | pending | | |
| D-13 | Admin password min 7 chars, 90-day forced change | User/etc/config.xml | pending | | |
| D-14 | Customer password min 8 chars, 3 char classes | Customer/etc/config.xml | pending | | |
| D-15 | CAPTCHA on admin login after 3 fails | Captcha/etc/config.xml | confirmed | task_050 | Per-IP threshold=1000 (M-022). No CAPTCHA on API/GraphQL. |
| D-16 | CAPTCHA on customer login after 3 fails | Captcha/etc/config.xml | confirmed | task_050 | Per-IP threshold=1000. GraphQL login has zero CAPTCHA (M-023). |
| D-17 | Cookies HTTPOnly=true, SameSite=Lax | Cookie+CookieMetadata | pending | | 1hr default lifetime |
| D-18 | X-Frame-Options: SAMEORIGIN | HeaderProvider | pending | | Configurable |
| D-19 | X-Content-Type-Options: nosniff | HeaderProvider | pending | | |
| D-20 | HSTS only when both front+admin HTTPS | Hsts HeaderProvider | pending | | Not default-enabled |
| D-21 | CSP report-only, unsafe-inline/eval | Csp/config.xml | pending | | |
| D-22 | Session validation disabled by default | Store/config.xml | confirmed | task_073 | No IP/UA binding - L-045 |
| D-23 | Admin session timeout 900s | Security/config.xml | pending | | |
| D-24 | Password reset max 5 requests, 10s apart | Security/config.xml | pending | | |
| D-25 | Swagger UI disabled in production | Swagger/Model/Config | confirmed | task_003 | Dev mode only |
| D-26 | API requires HTTPS | WebapiSecurity/config.xml | pending | | |
| D-27 | GraphQL alias limit: 10 | GraphQl/config.xml | pending | | |
| D-28 | Admin login case-insensitive | User/config.xml | pending | | Brute-force simpler |
| D-29 | 3DS credentials encrypted at rest | CardinalCommerce/config.xml | pending | | |
| D-30 | CAPTCHA per-IP threshold=1000 | Captcha/config.xml | confirmed | task_050 | M-022: 1000 attempts/IP, 30min reset window |

## Accepted Risks (Documented or Intentional)
| # | Risk | Source | Chain Potential |
|---|------|--------|----------------|
| AR-1 | health_check.php unauthenticated | pub/health_check.php | SSRF: reveals DB/cache status |
| AR-2 | cron.php accepts HTTP GET params | pub/cron.php | Remote cron via GET; uses escapeshellarg |
| AR-3 | Error processor accepts user input | pub/errors/processor.php | skin/id params - path traversal? |
| AR-4 | GraphQL introspection enabled | GraphQl config | Schema enumeration |
| AR-5 | Admin notification fetches external XML | AdminNotification/Feed.php | Feed URL NOT admin-configurable (hardcoded, not in system.xml). SSRF negligible. XXE mitigated by PHP 8.x. Covered by L-002. |
| AR-6 | LoginAsCustomer admin impersonation | LoginAsCustomer module | Insider threat |
| AR-7 | CSP report-only + unsafe-inline/eval | Csp/etc/config.xml | XSS not blocked by CSP |
| AR-8 | Session validation disabled by default | Store/etc/config.xml | Session hijacking easier |
| AR-9 | Dev template hints gated by IP only | Developer/Helper/Data.php | IP spoofing exposure |
| AR-10 | CAPTCHA per-IP threshold=1000 | Captcha/etc/config.xml | Effectively no IP rate limit |

## File Upload Security Architecture (task_035)

### Upload Framework Layers
1. **Base Framework Uploader** (lib/internal/Magento/Framework/File/Uploader.php): Extension allowlist (fail-open when empty), filename sanitization (getCorrectFileName strips dots/special chars), path traversal check in validateFileId
2. **MediaStorage Uploader** (app/code/Magento/MediaStorage/Model/File/Uploader.php): Extends Framework Uploader, adds NotProtectedExtension validator (blocks 23+ dangerous extensions from Store config), adds Image validator
3. **NotProtectedExtension** (general/file/protected_extensions): php, php3-7, phtml, pht, phpt, phar, htaccess, jsp, pl, py, asp, aspx, sh, cgi, htm, html, shtml, svg, svgz, xml, xhtml
4. **Product Option File Upload**: Uses Laminas FileTransfer (NOT Framework Uploader), only blocks php,exe via config denylist, saves with random 32-char name without extension, directory protected by htaccess/nginx deny

### Key Findings
- M-001: Product option file upload weak denylist (defense-in-depth gap)
- L-004: Framework Uploader fail-open on empty extensions (gadget)
- Multiple mitigations on product option path: random filename, no extension, directory denied
### Content-Type Validation Analysis (task_125)
- **Image uploads** (WYSIWYG, product, customer image): Use getimagesize()/GD2 for magic byte validation. Polyglot files (GIF89a+PHP) pass but can't execute due to web server protections.
- **Non-image file uploads** (customer file attributes): Extension-only validation, no content inspection. Stored in deny-all directories.
- **MediaStorage Image Validator**: Defaults to valid=true for non-image MIME types (G-031). Only validates claimed images via GD2.
- **MIME detection** (Filesystem/Driver/File/Mime.php): Uses mime_content_type() (magic bytes) but overrides with extension-based lookup for SVG/XML/HTML/text. All overrideable extensions are in protected list.
- **nosniff header**: Only on PHP-routed responses, NOT on direct static file serving. Static files get correct Content-Type via AddType directives in .htaccess.
- **PHP execution prevention**: pub/media/.htaccess disables PHP engine. Nginx sample config blocks .php. Sensitive dirs use deny-all.
- **Overall**: Multi-layer defense adequate. No exploitable content-type bypass found.


## Shell/Code Execution Evaluation (task_037)

### Shell Execution Patterns
- **Framework\Shell** and **Shell\Driver**: Both use CommandRenderer::render() which applies escapeshellarg() on all arguments before exec(). Safe.
- **Cron ProcessCronQueueObserver**: Shell::execute with %s placeholders + escapeshellarg. Group IDs from XML config. Safe.
- **Deploy/Model/Filesystem**: Shell execute with hardcoded commands + validated locales (whitelist). Safe.
- **DevTestsRunCommand**: passthru() with unsanitized CLI --command-arguments option. CLI-only, not web-accessible.
## KO html: Binding Investigation Results (task_121)
All core data paths to KO html: bindings have proper backend escaping. additional_options extension path (Configuration.php:190-191) bypasses escapeHtml when no option_id present. JS escaper allows style attribute on allowed tags. G-009 validated as informational.


### Code Execution Patterns
- **eval() in Filesystem.php:496**: Builds eval from internal _filters[] references. User values not interpolated. Admin-only. Recorded as G-002 gadget.
- **Redis eval()**: Lua scripts, hardcoded. Safe.
- **No preg_replace /e modifier, no create_function(), no assert() with variables** found in non-test code.
- **extract() with EXTR_SKIP**: Used in EAV AbstractEntity and template engines. Safe.

### TAR Path Traversal
- **M-003**: Tar::_unpackCurrentTar() has Zip Slip vulnerability. Admin-only (backup restore).
- Zip::unpack() used for import correctly renames to expected basename.

### Dismissed Patterns
- call_user_func: All callbacks from internal code, not user-controlled.
- Variable includes (324 files): All use framework-resolved template/config paths.

## Client-Side Security Evaluation (task_039)

### Redirect Validation
- **_isUrlInternal()** pattern used consistently: strpos($url, baseUrl) === 0
- Base URL always has trailing slash (Store::getBaseUrl line 667), preventing subdomain confusion bypass
- Store/App/Response/Redirect.php validates referer_url, uenc, r64 params through _isUrlInternal
- **No open redirect found** in redirect handling

### XSS Protection
- Template escaping: escapeHtml(), escapeUrl(), escapeJs() used consistently in phtml templates
- @noEscape annotations: ~300+ uses, all in safe contexts (numeric, pre-escaped, admin-generated)
- Review templates: All user content escaped with escapeHtml() before nl2br()
- escapeUrl(): Removes javascript:/data:/vbscript: protocols recursively

### CSP Configuration (L-005)
- Report-only mode for both storefront and admin
- unsafe-inline + unsafe-eval on script-src and default-src
- Effectively provides ZERO XSS protection

### HTML Sanitization
- MaliciousCode filter + HTMLPurifier for admin content (strong)

### JS Client-Side Patterns
- All JS files deleted from working tree - cannot evaluate innerHTML/postMessage/cookie/location patterns
- Client-side DOM XSS evaluation deferred to task_010

### No CORS Headers
- No Access-Control-Allow-Origin headers set anywhere in application code

## Shadow Functionality (Zero/Minimal Documentation)
| # | Feature | Location | Risk |
|---|---------|----------|------|
| SF-1 | Health check endpoint (no auth) | pub/health_check.php | Info disclosure (DB/cache status) |
| SF-2 | HTTP cron trigger | pub/cron.php | Remote cron execution via HTTP GET |
| SF-3 | Error report processor | pub/errors/processor.php | User input in skin/id params |
| SF-4 | Admin unlock via CLI | User/Console/UnlockAdminAccountCommand.php | Bypass lockout |
| SF-5 | Sensitive config set CLI | Deploy/Console/SensitiveConfigSetCommand.php | Credential manipulation |
| SF-6 | Dev profiler/query log toggles | Developer/Console/Command/ | Performance data exposure |
| SF-7 | Setup wizard web access | setup/index.php | Full installation reconfiguration |
| SF-8 | Backup download (admin) | Backup/Controller/Adminhtml/ | Full DB/filesystem access |
| SF-9 | Admin notification external feed | AdminNotification/Model/Feed.php | External XML fetch |
| SF-10 | No ReCaptcha/2FA modules present | (missing modules) | Basic CAPTCHA only |

## Application Features (task_016)

### Feature Map

| # | Feature | Modules | Frontend Controllers | Auth Posture | Risk | Investigation Task |
|---|---------|---------|---------------------|--------------|------|--------------------|
| F-1 | PayPal Payment | Paypal, PaypalCaptcha, PaypalGraphQl, CardinalCommerce | 73 (IPN, Express, Payflow, HostedPro, Billing) | OPEN | **CRITICAL** | task_060 |
| F-2 | Checkout/Cart | Checkout, Quote, QuoteGraphQl | 25+ cart/checkout + 19 REST anonymous | OPEN | **CRITICAL** | task_061 |
| F-3 | Customer Account | Customer, CustomerGraphQl | 30 (login, register, password, address, file upload) | OPEN | **CRITICAL** | task_062 |
| F-4 | Import/Export | ImportExport + 8 specialized modules | Admin-only | Auth-by-default | HIGH | task_063 |
| F-5 | Guest Order Access | Sales, OrderCancellation | 16 guest controllers | OPEN | HIGH | task_064 |
| F-6 | CMS/Templates | Cms, Widget, Email, Newsletter, Variable | 6 frontend + admin WYSIWYG | Mixed | HIGH | task_065 |
| F-7 | User Content | Wishlist, Review, Contact, SendFriend | 21 wishlist + 8 review + 3 contact + 3 sendfriend | OPEN | MEDIUM | task_066 |
| F-8 | Downloadable Products | Downloadable, ProductAlert | 5 download + 9 alert | Mixed | MEDIUM | task_067 |
| F-9 | Admin Backup/Encryption | Backup, EncryptionKey | Admin-only | Auth-by-default | MEDIUM | task_068 |
| F-10 | Multishipping/InstantPurchase | Multishipping, InstantPurchase | 30 multishipping + 1 instant | OPEN | MEDIUM | task_069 |
| F-11 | Search/Promotions | CatalogSearch, Search, SalesRule, CatalogRule | 6 search + coupon apply | OPEN | MEDIUM | task_070 |
| F-12 | REST API | Webapi, WebapiAsync, WebapiSecurity, Swagger | 14 frontend + 42 anonymous endpoints | OPEN | **CRITICAL** | task_022 (existing) |
| F-13 | GraphQL | GraphQl + 41 GraphQl modules | 403 resolvers, all open-by-default | OPEN | **CRITICAL** | task_022, task_043 (existing) |
| F-14 | Admin Panel | Backend + all Adminhtml controllers | ~894 admin controllers | Auth-by-default | HIGH | task_006, task_028 (existing) |
| F-15 | OAuth/Integration | Integration, JwtUserToken, JwtFrameworkAdapter | OAuth token flow | Mixed | HIGH | task_005 (existing) |
| F-16 | Shipping Carriers | Dhl, Fedex, Ups, Usps, OfflineShipping | Admin-only config, frontend rate calc | Mixed | MEDIUM | task_025 (SSRF) |
| F-17 | Catalog/Products | Catalog, ConfigurableProduct, Bundle, Grouped | 12 frontend controllers | OPEN | LOW | covered by search/injection audits |
| F-18 | LoginAsCustomer | LoginAsCustomer (8 sub-modules) | Admin-initiated | Auth-by-default | MEDIUM | task_049 (existing) |

### Feature Coverage Summary
- **11 new investigation tasks** spawned for uncovered features
- **7 features** already covered by existing audit/investigate tasks
- **Critical features** (F-1 through F-3, F-12, F-13): All internet-facing, open-by-default
- **Highest-risk feature**: PayPal (73 controllers, handles money, unauthenticated webhooks)

## Import/Export Security Summary (task_063)
- **SQL injection via CSV data**: SAFE — all importers use `insertOnDuplicate`/`insertMultiple` with parameterized values. Column names whitelisted against EAV attributes. `quoteIdentifier()` provides backtick quoting for identifiers.
- **ZIP extraction**: SAFE — `Zip::unpack()` renames entries to `basename($destination)` before extraction, preventing path traversal. Unlike `Tar::_unpackCurrentTar()` (M-003).
- **Export file path handling**: Download uses explicit `getRealPathSafety()`, Delete relies on framework `PathValidator` inside `delete()`. Both protected but inconsistent (G-019).
- **History Download**: Protected by `basename()` + `getRelativePath()` + `ValidatorException`.
- **Import upload**: Extension whitelist (csv/zip), random 32-char filenames, no MIME validation.
- **CSV formula injection (M-002)**, **SSRF via image import (M-004)**: Previously confirmed.

## Guest Order Access Security Summary (task_064)
- **Guest order form auth**: increment_id + billing_lastname + (email|zip), case-insensitive. No CAPTCHA. No rate limit. (L-036)
- **Guest cookie auth**: base64(protectCode:incrementId), hash_equals validation (timing-safe). 600s lifetime.
- **Customer order IDOR**: Authentication plugin enforces login on 10 Sales/Controller/Order/* controllers. OrderViewAuthorization checks order.customerId == session.customerId (loose ==, but both integer-like strings).
- **REST API order auth**: All endpoints require ACL (no anonymous). Authorization plugin returns true for non-customer types by design (admin/integration).
- **DownloadCustomOption**: Sales/Controller/Download/* NOT covered by Authentication plugin. Relies on secret_key only (loose != comparison -- L-011). (G-020)
- **Order cancellation keys**: 32-char random, stored plaintext, NEVER deleted after use. (L-035)
- **Order increment IDs**: Sequential via SalesSequence (pattern: %s%'.09d%s). Predictable.

## Template Directive Injection Summary (task_065)

### Directive Security Assessment
| Directive | Validated? | Finding |
|-----------|-----------|---------|
| {{config path=...}} | YES - allowlisted | Safe |
| {{widget type=...}} | YES - registered XML | Safe |
| {{var ...}} | YES - StrictResolver | Safe |
| {{block class=...}} | NO - any AbstractBlock | M-024 |
| {{layout handle=...}} | NO - any handle | M-025 |

- Customer data in email vars does NOT trigger second-order SSTI (directives matched before var replacement)
- All entry points admin-only (CMS, email templates, catalog WYSIWYG, newsletter)
- **Deep SSTI analysis (task_097):** Two-pass filter architecture with 32-char random signature prevents user-injected directives in template variables from re-processing. escapeHtml() does NOT strip curly brace syntax, but user data enters via setTemplateVars() not template content. LegacyDirective reflection limited to [a-z]{0,10}Directive methods. SendFriend email uses var message with raw modifier but message is escapeHtml before variable assignment. MessageValidator on Wishlist share blocks directive patterns as defense-in-depth. Config directive whitelist limited to non-sensitive paths.


## Host Header in API Schema Endpoints (task_141)
- REST Swagger schema (SchemaRequestProcessor, AsynchronousSchemaRequestProcessor) embeds raw Host header in JSON host field
- Schema cache key does NOT include Host - enables cache poisoning (L-063)
- BaseUrlChecker only in frontend/di.xml - NOT applied to webapi_rest/webapi_soap areas
- SOAP WSDL generator receives requestHost but does not use it (endpoint URLs from store config) - safe
- PageCache Server Host header in purge target already covered by L-019
- Developer helper Host header in IP allowlist check covered by AR-9

## UI Component ACL Bypass (M-028, task_152)
- Ui\Controller\Adminhtml\AbstractAction._isAllowed() returns true unconditionally
- Render, Handle, GridToCsv, GridToXml controllers all affected
- validateAclResource() is fail-open: returns true when aclResource not configured
- 20+ form components lack aclResource (customer_form, product_form, sales_rule_form, etc.)
- All listings have aclResource (protected)
- Impact: low-privilege admin can access form data for any module via /admin/mui/index/render?namespace=X


## Crypt/Key Exposure Analysis (task_135)

### Protection Mechanisms (Default)
- app/etc/env.php: Protected by app/.htaccess (deny all)
- Nginx whitelists only specific PHP files
- health_check.php returns only HTTP status codes
- Error report IDs: HMAC-SHA256 with crypt/key (unpredictable)
- var/ directory: .htaccess deny all

### Exposure Vectors
1. Developer mode (L-065): Full stack traces to unauthenticated clients
2. Error report files (G-030): var/report/ accessible via report.php viewer
3. MAGENTO_DC__OVERRIDE env var: Can override crypt/key via JSON
4. MAGE_DEBUG_SHOW_ARGS: Leaks 16-char truncated function arguments
5. JWT key derivation: crypt/key padded to 2048 chars (L-016)

## Framework Core Security Evaluation (task_076)

### Serialize Subsystem
- Serialize::unserialize() uses allowed_classes => false — safe
- All Framework unserialize goes through SerializerInterface

### Encryption Subsystem
- ChaCha20-Poly1305 AEAD for new encryption (modern, secure)
- L-047: encryptWithFastestAvailableAlgorithm() silently returns plaintext when key missing
- encrypt() throws on invalid key; asymmetric fail-safe behavior
- Security::compareStrings() uses hash_equals() correctly

### Session Subsystem
- Regeneration keeps old session alive 1hr as redirect mechanism (by design)
- Session Validator uses != (loose comparison) — not exploitable (both strings)
- **Redis Session Deserialization (G-011)**: PHP session engine uses native session.serialize_handler (default: php) which does NOT use allowed_classes=false. Cm\RedisSession compression is bypassable (uncompressed data passes through _decodeData() unchanged). Attacker with Redis access can write crafted PHP serialized payloads to sess_<id> hash field data to trigger RCE via gadget chains.
- **ACL Cache Not Encrypted (M-030)**: System config cache is encrypted before storing in Redis, but ACL authorization rules (authorization_rule_cached_data) are stored as plaintext serialized arrays. Redis access enables admin privilege escalation via cache poisoning.
- **Redis Default No Auth (L-046)**: All Redis connections (session DB 2, cache DB 0, page cache DB 1) default to empty password. Docker compose exposes on 0.0.0.0:6379.

### Escaper
- DOMDocument + htmlspecialchars — robust. escapeUrl strips protocols recursively.


## Sales Order State Machine Analysis (task_077)

### Mutex Coverage
| Operation | OrderMutex? | Finding |
|-----------|------------|---------|
| cancel (OrderService) | YES | - |
| hold/unHold (OrderService) | NO | M-015 |
| shipOrder (ShipOrder) | YES | - |
| refundOrder (RefundOrder) | YES | - |
| creditmemoRefund (CreditmemoService) | NO | M-020 |
| invoiceCapture/Void (InvoiceService) | NO | L-022 |

### InstantPurchase Address IDOR (M-029)
- InstantPurchase PlaceOrder controller accepts arbitrary address IDs without ownership validation
- InstantPurchaseOptionLoadingFactory::getAddress() calls addressRepository->getById() directly
- Payment token IS scoped to customer via getByPublicHash($hash, $customerId)
- Contrast: Multishipping uses isAddressIdApplicable() to validate address ownership correctly
- Chains with M-026 (REST address IDOR) — both exploit missing address ownership checks

### Multishipping Step-Skip (G-028)
- Overview/OverviewPost controllers don't check step completion like Shipping/Billing do
- Defense-in-depth only: _validate() in createOrders still checks payment/address data
- createOrders uses cartMutex for race condition protection

### Creditmemo Negative Adjustment (L-048)
- adjustment_positive/negative API fields accept negative values without validation
- Negative creditmemo grand total decreases order's total_refunded -> enables over-refund
- Admin-only (Magento_Sales::creditmemo ACL)

### Guest Order Cancellation
- Encrypted token + billing validation + confirmation key (never consumed: L-035)

## Confirmed Exploit Chains

### Chain: Full ATO via REST Email Change + Password Reset (H-005)
**Components:** M-013 (REST email change no re-auth) + anonymous password reset endpoint
**Attack:** Attacker with stolen bearer token changes email via PUT /V1/customers/me (no password needed), then triggers anonymous password reset to attacker email, resets password
**Combined Severity:** HIGH (M-013 alone is MEDIUM, but chain enables full ATO)
**Mitigations Present (insufficient):** Token revocation after save (too late), email notification to old email (detection only), email confirmation config (disabled by default)
**Amplifiers:** L-005 (CSP report-only) enables initial token theft via XSS; M-021 (tokens not revoked on password change) means stolen tokens remain valid

### Chain DISMISSED: Admin SSRF (G-012) -> Redis Session Injection (G-011) -> RCE
**Components:** G-012 (ES TestConnection SSRF) + G-011 (PHP session deser without allowed_classes) + L-046 (Redis no auth default)
**Hypothesis:** Admin uses TestConnection SSRF to reach Redis on 6379, injects serialized PHP objects into session store, PHP session engine deserializes with full object instantiation -> RCE via __destruct gadgets.
**Verdict: NOT EXPLOITABLE as single chain.** HTTP SSRF (Guzzle 7/cURL) cannot inject Redis RESP commands:
1. Modern cURL rejects CRLF injection in URLs (blocks HTTP request smuggling to Redis)
2. Non-HTTP schemes (gopher://) are blocked by buildESConfig URL construction (regex only strips http/https, causing scheme doubling)
3. SSRF provides discovery only (port scanning via error messages), not command injection
4. Direct Redis access requires separate network position not achievable from HTTP SSRF
**Remaining risk:** G-012 enables internal network topology mapping (service discovery gadget). G-011 remains valid if Redis is directly accessible (separate prerequisite). ~27 __destruct gadgets available in framework/app code.

## Skill Coverage (Updated Meta Task 10 - Iteration 100)
| Skill | Status | Task |
|-------|--------|------|
| auth-audit | **DONE** | task_005 |
| access-control-audit | **DONE** | task_006 |
| injection-audit | **DONE** | task_007 |
| client-side-audit | **DONE** | task_019 |
| request-handling-audit | **DONE** | task_020 |
| file-handling-audit | **DONE** | task_021 |
| infrastructure-audit | **DONE** | task_010 |
| api-audit | **DONE** | task_022 |
| data-protection-audit | **DONE** | task_008 |
| crypto-audit | **DONE** | task_040 |
| deserialization-audit | **DONE** | task_024 |
| ssrf-audit | **DONE** | task_025 |
| concurrency-audit | **DONE** | task_026 |
| business-logic-audit | **DONE** | task_009 |

All 14/14 core skills COMPLETED. N/A: memory-safety, smart-contract, cloud-native, llm-security.

## Reprioritization Log (Meta Task 15)
**Iteration 150 (150 tasks completed):**
- 155 findings total (3 HIGH, 33 MEDIUM, 92 LOW, 27 INFO), 63 gadgets
- 9 pending tasks (3 high, 4 low, 2 final) after reprioritization
- **2 unvalidated HIGHs remain**: H-006 (email enum chain), H-007 (IP spoofing rate limit bypass) -- validation tasks task_158, task_159 still high priority
- **New findings since meta 14**: L-074 through L-081, M-028, H-007. All properly chained.
- **Chain synthesis**: 155 findings reviewed. Only M-008 (CLI-only) unchained. No new CRITICAL/HIGH chains. 106 findings have chain links.
- **No tasks elevated, demoted, or spawned**: queue stable, final convergence
- **Absence checks verified**: all 6 controls present (unchanged)
- **All 14 core skills COMPLETED**, all 9 preanalysis categories DONE
- **Critical path**: task_158 -> task_159 -> task_014 -> task_012 (report)
- **Queue health**: 4 LOW investigate tasks are diminishing returns. No promotion warranted.

## Reprioritization Log (Meta Task 14)
**Iteration 140 (140 tasks completed):**
- 146 findings total (3 HIGH, 33 MEDIUM, 84 LOW, 26 INFO), 59 gadgets
- 19 pending tasks (3 high, 14 low, 2 final) after reprioritization
- **2 unvalidated HIGHs remain**: H-006 (email enum chain), H-007 (IP spoofing rate limit bypass) -- validation tasks task_158, task_159 still high priority
- **New findings since meta 13**: L-069 through L-073 (admin audit logging, refund race window, coupon usage race audit trail, checkout base_cost exposure, shipping carrier PII logging). All LOW severity.
- **Chain synthesis**: 146 findings reviewed. Only 1 unchained MEDIUM+: M-008 (CLI command injection, CLI-only, no meaningful chain). No new CRITICAL/HIGH chains identified. All existing chains valid.
- **No tasks elevated or demoted**: queue stable, all LOWs are diminishing returns
- **No new tasks spawned**: queue comprehensive, deep convergence phase
- **task_015 (debug eval) skippable**: debug_mode=false in config.json, task has requires_debug_mode=true
- **Absence checks verified**: all 6 controls present (verified meta 9-13, unchanged)
- **All 14 core skills COMPLETED**, all 9 preanalysis categories DONE
- **Analysis dimensions**: D-3, D-6, D-9 have tasks in queue (unchanged)
- **Audit convergence**: queue reduced from 29->19 in 10 iterations (10 tasks completed, 0 new spawned). Validation tasks (158, 159) and PoC gen (014) are the critical remaining HIGH-priority work. Report generation can proceed once validations complete.
- **Critical path**: task_158 -> task_159 -> task_014 -> task_012 (report)
- **HIGH-priority queue**: task_158, task_159, task_014
- **Queue health**: All 14 LOW-priority investigate tasks are diminishing-return deep-dives into admin-only or already-confirmed patterns. No promotion warranted. The audit has reached comprehensive coverage with 146 findings across all vulnerability classes.

## Reprioritization Log (Meta Task 13)
**Iteration 130 (130 tasks completed):**
- 140 findings total (3 HIGH, 33 MEDIUM, 79 LOW, 25 INFO), 57 gadgets
- 29 pending tasks (3 high, 24 low, 2 final) after reprioritization
- **2 unvalidated HIGHs remain**: H-006 (email enum chain), H-007 (IP spoofing rate limit bypass) -- validation tasks task_158, task_159 still high priority
- **New findings since meta 12**: M-031 (anonymous group_id mass assignment), L-066 (key rotation incomplete), L-067 (SearchCriteria REGEXP exposure), L-068 (order state no transition validation), G-032 (MQ RPC non-CSPRNG), G-034 (BackendValidator non-timing-safe fallback)
- **Chain synthesis**: 140 findings reviewed. Added chains: M-001<->L-004/G-031 (upload denylist + upload gadgets), M-007<->H-005 (GraphQL IDOR + ATO chain). M-031 chains with L-039 (already linked). L-067 chains with L-056/H-007 (already linked). L-068 chains with M-020/L-048 (already linked). No new CRITICAL/HIGH chains identified. M-008 (CLI injection) has no meaningful chain (CLI-only context).
- **No tasks elevated or demoted**: queue is stable, all LOWs are diminishing returns
- **No new tasks spawned**: queue already comprehensive, deep convergence phase
- **Absence checks verified**: all 6 controls present (verified in meta 9-12, unchanged)
- **All 14 core skills COMPLETED**, all 9 preanalysis categories DONE
- **Analysis dimensions**: D-3, D-6, D-9 have tasks in queue (unchanged)
- **Audit convergence**: queue reduced from 39->29 in 10 iterations (10 tasks completed, 0 new spawned). Validation tasks (158, 159) and PoC gen (014) are the critical remaining HIGH-priority work. Report generation can proceed once validations complete.
- **Critical path**: task_158 -> task_159 -> task_014 -> task_012 (report)
- **HIGH-priority queue**: task_158, task_159, task_014
- **Queue health**: All 24 LOW-priority investigate tasks are diminishing-return deep-dives into admin-only or already-confirmed patterns. No promotion warranted. The audit has reached comprehensive coverage.

## Reprioritization Log (Meta Task 12)
**Iteration 120 (120 tasks completed):**
- 136 findings total (3 HIGH, 32 MEDIUM, 77 LOW, 24 INFO), 56 gadgets
- 39 pending tasks (3 high, 34 low, 2 final) after reprioritization
- **2 unvalidated HIGHs remain**: H-006 (email enum chain), H-007 (IP spoofing rate limit bypass) -- validation tasks task_158, task_159 still high priority
- **New finding since meta 11**: G-033 (session max size write handler, informational)
- **Chain synthesis**: 136 findings reviewed. Added chain links for 6 previously unchained MEDIUMs: H-002<->G-001/G-025, M-003<->L-062/G-029/G-027, M-004<->G-003/G-010/L-046, M-009<->M-019, M-014<->M-016/L-060/L-061, M-020<->L-048/M-015. No new CRITICAL/HIGH chains identified.
- **No tasks elevated or demoted**: queue is stable, all LOWs are diminishing returns
- **No new tasks spawned**: queue already comprehensive, convergence phase
- **Absence checks verified**: all 6 controls present (verified in meta 9-11, unchanged)
- **All 14 core skills COMPLETED**, all 9 preanalysis categories DONE
- **Analysis dimensions**: D-3, D-6, D-9 have tasks in queue (unchanged from meta 11)
- **Audit convergence**: queue reduced from 49->39 in 10 iterations. Validation tasks (158, 159) and PoC gen (014) are the critical remaining HIGH-priority work. Report generation can proceed once validations complete.
- **Critical path**: task_158 -> task_159 -> task_014 -> task_012 (report)
- **HIGH-priority queue**: task_158, task_159, task_014

## Reprioritization Log (Meta Task 11)
**Iteration 110 (110 tasks completed):**
- 133 findings total (3 HIGH, 32 MEDIUM, 76 LOW, 22 INFO), 56 gadgets
- 49 pending tasks (3 high, 2 medium, 42 low, 2 final) after reprioritization
- **2 unvalidated HIGHs remain**: H-006 (email enum chain), H-007 (IP spoofing rate limit bypass) -- validation tasks task_158, task_159 still high priority
- **Demoted to LOW**: task_082 (CMS WYSIWYG, admin-only), task_085 (import SSRF callers, admin-only, M-004 already confirmed), task_086 (carrier config SSRF, admin-only)
- **3 subsumed tasks confirmed still subsumed**: task_042 (by task_107), task_101 (by task_094), task_117 (by task_133)
- **New findings since meta 10**: L-063 (host header cache poison), L-064 (admin tokens not revoked on pw change), L-065 (dev mode stack traces), G-030 (error report files), G-031 (image validator default-true)
- **Chain synthesis**: 133 findings reviewed. L-064 (admin tokens not revoked) chains with admin compromise scenarios but is defense-in-depth only (admin-only). No new CRITICAL/HIGH chains identified.
- **Absence checks verified**: all 6 controls present (verified in meta 9+10, unchanged)
- **All 14 core skills COMPLETED**, all 9 preanalysis categories DONE
- **Analysis dimensions**: same 3 pending as meta 10 (D-3, D-6, D-9 have tasks in queue)
- **Audit convergence**: queue reduced from 59->49 in 10 iterations. Validation tasks (158, 159) and PoC gen (014) are the critical remaining HIGH-priority work. Report generation can proceed once validations complete.
- **HIGH-priority queue**: task_158, task_159, task_014

## Reprioritization Log (Meta Task 10)
**Iteration 100 (100 tasks completed):**
- 128 findings total (3 HIGH, 32 MEDIUM, 73 LOW, 20 INFO), 53 gadgets
- 59 pending tasks (7 high, 11 medium, 39 low, 2 final) after reprioritization
- **2 unvalidated HIGHs remain**: H-006 (email enum chain), H-007 (IP spoofing rate limit bypass) -- validation tasks task_158, task_159 already high priority
- **Elevated to HIGH**: task_081 (customer file path traversal), task_141 (host header injection), task_151 (API token revocation completeness), task_135 (crypt/key exposure)
- **Demoted to LOW**: task_148 (locale parsing), task_149 (creditmemo adjustment), task_143 (checkout config exposure), task_144 (payment debug logging)
- **6 tasks confirmed subsumed**: task_042, task_101, task_103, task_117, task_119, task_137
- **Chain synthesis**: 128 findings reviewed. Existing chains comprehensive. No new CRITICAL/HIGH chains.
- **Absence checks verified**: all 6 controls present, findings exist for gaps
- **All 14 core skills COMPLETED**, all 9 preanalysis categories DONE
- **Analysis dimensions**: 6/9 completed, 3 pending with tasks in queue (D-3, D-6, D-9)
- **HIGH-priority queue**: task_158, task_159, task_014, task_081, task_135, task_141, task_151

## Reprioritization Log (Meta Task 9)
**Iteration 90 (90 tasks completed):**
- 121 findings total (3 HIGH, 30 MEDIUM, 69 LOW, 19 INFO), 49 gadgets
- 67 pending tasks (6 high, 26 medium, 35 low, 2 final) after reprioritization
- **2 unvalidated HIGHs**: H-006 (email enum chain), H-007 (IP spoofing rate limit bypass) -- spawned validation tasks task_158, task_159
- **Elevated to HIGH**: task_140 (IP spoofing consumers - H-007 blast radius), task_123 (customer address upload auth - M-017), task_126 (Redis session auth - G-011 chain)
- **Demoted to LOW**: task_083, task_084, task_100, task_104, task_119, task_134, task_120, task_108, task_138, task_092, task_075, task_078 (all substantially covered by completed tasks)
- **Chain synthesis**: 121 findings, 112 chain pairs. No new CRITICAL/HIGH chains. M-028 read-only, no viable chains.
- **Absence checks verified**: all 6 controls verified, findings exist for gaps
- **All 14 core skills COMPLETED**, all 9 preanalysis categories DONE
- **HIGH-priority queue**: task_014 (PoC gen), task_123 (address upload auth), task_126 (Redis auth), task_140 (IP spoofing consumers), task_158 (validate H-006), task_159 (validate H-007)

## Reprioritization Log (Meta Task 8)
**Iteration 81 (80 tasks completed):**
- 109 findings total (1 HIGH, 29 MEDIUM, 63 LOW, 16 INFO), 45 gadgets
- 75 non-run-last pending tasks (6 high, 51 medium, 18 low) after reprioritization
- All HIGH/CRITICAL findings validated (H-005 confirmed, H-001 downgraded to low)
- **Elevated to high**: task_157 (IP spoofing + CAPTCHA bypass chain), task_132 (cart checkout race), task_121 (KO html: binding XSS), task_107 (email enumeration chain), task_095 (CSRF XHR bypass)
- **Demoted to low**: task_089 (JWT overlap), task_114 (PageCache cookie), task_116 (admin SecretKey), task_090 (admin timing)
- **Chain synthesis**: 109 findings reviewed. Existing chains comprehensive. No new critical chains identified.
- **Absence checks verified**: all 6 controls searched, findings exist for gaps
- **All 14 core skills COMPLETED**, all 9 preanalysis categories DONE
- **HIGH-priority queue**: task_014, task_095, task_107, task_121, task_132, task_157

## Reprioritization Log (Meta Task 7)
**Iteration 71 (70 tasks completed):**
- 108 findings total (2 HIGH, 30 MEDIUM, 60 LOW, 16 INFO), 44 gadgets
- 83 non-run-last pending tasks (4 high, 60 medium, 19 low) after reprioritization
- 1 unvalidated HIGH: H-001 — spawned task_156 to validate it
- **Demoted to low**: task_099 (noEscape XSS, subsumed by task_106), task_102 (stored XSS rendering, subsumed by task_106), task_103 (REST mass assignment, overlaps completed task_093), task_147 (cron variable bug, likely dead code), task_150 (REST error dev mode, low exploitability)
- **Elevated to high**: task_139 (admin SSRF -> Redis session injection -> RCE chain) — highest-impact remaining chain, requires focused investigation
- **New task_156** (high): Validate H-001 setup DbValidator SQL injection — only unvalidated HIGH
- **New task_157** (medium): Chain investigation M-018 (IP spoofing via X-Forwarded-For) + M-022/M-023 (CAPTCHA per-IP threshold=1000) — if X-Forwarded-For resets per-IP counters, all per-IP rate limiting is defeated
- **Chain synthesis update**: New chain identified: M-018 + M-022 + M-023 = complete auth rate limiting bypass. Combined with H-004 (admin token brute-force) and M-011 (GraphQL no rate limit), creates comprehensive brute-force attack path.
- **Absence checks verified**: all 6 controls searched, findings exist for gaps
- **All 14 core skills COMPLETED**, all 9 preanalysis categories DONE
- **Current HIGH-priority queue**: task_014 (PoC gen), task_106 (XSS chain), task_139 (SSRF->Redis->RCE), task_156 (H-001 validation)

## Reprioritization Log (Meta Task 6)
**Iteration 61 (60 tasks completed):**
- Fixed duplicate G-008 finding ID -> renamed Variable Controller mass assignment to G-023
- Added M-026 (address IDOR) chain with H-005 (ATO)
- Demoted SSRF overlap tasks: task_055, task_130, task_131 -> low (covered by task_085, task_129)
- Demoted task_137 (OrderMutex gap) -> low (overlaps broader task_119)
- Demoted subsumed: task_042, task_101, task_117 -> low (already marked subsumed)
- Elevated task_152 (UI component ACL bypass) -> high (potential data access without proper ACL)
- Elevated task_073 (Redis session/cache) -> high (chains with G-011 session deser)
- Elevated task_112 (LoginAsCustomer escalation) -> high
- 95 findings total (2 HIGH, 28 MEDIUM, 51 LOW, 14 INFO), 37 gadgets
- 1 unvalidated HIGH: H-001 (setup DbValidator SQL injection) — needs_investigation
- All 14 core skills COMPLETED, all 9 preanalysis categories DONE
- 93 non-run-last pending tasks (12 high, 65 medium, 16 low)
- Key HIGH-priority queue: task_014 (PoC gen), task_073 (Redis), task_074 (REST/GraphQL consistency), task_076 (framework core), task_077 (sales state machine), task_080 (hotspot batch 3), task_106 (XSS chain), task_112 (LoginAsCustomer), task_115 (encryption key), task_152 (UI ACL bypass), task_154 (address IDOR follow-up)
- **Chain update**: M-026 (address IDOR via REST) + H-005 (ATO chain) = multi-vector customer data theft
- **No new tasks spawned** — queue already has 93 pending with comprehensive coverage
- **Absence checks verified**: all 6 controls searched, findings exist for gaps

## Reprioritization Log (Meta Task 5)
**Iteration 51 (50 tasks completed):**
- Demoted task_099 (noEscape XSS) HIGH->MEDIUM: subsumed by task_106 (XSS chain combines 099+102 scopes)
- Demoted task_102 (stored XSS rendering) HIGH->MEDIUM: subsumed by task_106
- Demoted task_103 (REST mass assignment) HIGH->MEDIUM: overlaps with task_093
- All 14 core skills COMPLETED, all 9 preanalysis categories DONE, all analysis dimensions covered
- 80+ findings, absence checks pass, negative-space analysis verified
- New credential stuffing mega-chain: M-023+M-022+M-005/M-006 (already linked in findings)
- No new tasks spawned -- queue comprehensive at 104 pending
- Highest-value remaining: task_065 (CMS SSTI), task_097 (template SSTI), task_073 (Redis), task_076 (Framework core), task_094 (GraphQL IDOR), task_106 (XSS chain)

## Reprioritization Log (Meta Task 4)
**Iteration 41 (40 tasks completed):**
- Fixed duplicate IDs: task_119->task_154, task_120->task_155
- Subsumed task_101 (by task_094), task_042 (by task_107), task_117 (by task_133)
- Noted overlaps: task_103/task_093, task_137/task_119, task_154/task_120
- Demoted task_045 (swagger, dev-only) to low; Reduced task_089 (JWT, core done) to medium

**Key Chains Identified:**
- CRITICAL: M-013 + M-005/M-006 + H-004 = ATO chain (task_133)
- HIGH: M-010 + L-005 + G-009 = Stored XSS chain (task_106)
- MEDIUM: G-012 + G-011 = Admin SSRF -> Redis session injection -> RCE (task_139)

**Coverage: 40/154 tasks done, 70 findings, all 14 skills completed, all 9 preanalysis categories done**

## Access Control Architecture (task_006)

### Ownership Verification Patterns
- Wishlist: WishlistProvider checks customerId != session customer (verified)
- Orders (customer): OrderViewAuthorization checks customerId match (verified)
- Orders (guest): Multi-factor verification or protectCode cookie with hash_equals (verified)
- Cart (GraphQL): GetCartForUser uses masked UUIDs + customer ownership check (verified)
- REST self-scoped: force=true overrides identity params from session (verified)
- Customer (GraphQL): Schema constrains input - no group_id/store_id in update input (verified)
- Multishipping: Auth enforced at dispatch() level (verified)
- Address (REST): AddressRepository::save() does NOT validate ownership when address ID is provided — IDOR confirmed (M-026)
- Customer mass assignment (REST): force=true protects id/group_id/website_id/store_id but NOT disable_auto_group_change (L-039)
- Issues: L-009 loose comparison type juggling, G-008 mass assignment gadget, M-026 address IDOR

## Gadgets Registry
| ID | Type | Location | Chain Potential |
|----|------|----------|----------------|
| G-001 | Info disclosure | Version/Controller/Index/Index.php | Version fingerprint -> CVE targeting |
| G-002 | Health check | pub/health_check.php | SSRF + health_check = infrastructure recon |
| G-008 | Mass assignment | Variable admin controller | Admin addData without allowlist |

## Business Logic Audit Summary (task_009)

### Security Control Coverage Gaps Found
| Control | Web Frontend | GraphQL | REST API | Gap |
|---------|-------------|---------|----------|-----|
| Email change re-auth | Yes (EditPost) | Yes (UpdateCustomerEmail) | NO | M-013 |
| Token revocation on pw change | Sessions only | Sessions only | Sessions only | M-021 |
| Token revocation on email change | Sessions only (no observer) | Tokens+Sessions | Tokens+Sessions | L-025 |
| Coupon per-customer lock | N/A | N/A | N/A | M-014 (only coupon locked) |
| Order rate limiting | N/A | N/A | Available but disabled | L-012 |
| XSS input validation | N/A (output escaping) | None | Weak (<script> only, M-010) | G-024 |
| Address IDOR | N/A | Proper ownership check | No ownership on save (M-026) | M-026 |
| Mass assignment (update) | N/A | Schema-restricted fields | Allows disable_auto_group_change (L-039) | L-039 |
| CAPTCHA on login | After 3 fails | None (M-023) | None | M-023 |
| Backpressure/rate limit | InstantPurchase | PlaceOrder only (M-011), disabled default | PlaceOrder only, disabled default | L-012 |

### REST vs GraphQL Auth Consistency Summary (task_074)
- **GraphQL is generally MORE secure** than REST for overlapping customer operations
- GraphQL schema-level input restriction prevents mass assignment
- GraphQL email change requires password, REST does not (M-013)
- GraphQL address operations verify customer ownership, REST has IDOR (M-026)
- Both share the same token service with identical lockout/throttling
- Batch GraphQL queries NOT supported at HTTP level (single query per request)
- Alias limit enforced at 10 (GraphQl/config.xml)
- CAPTCHA on account creation covers both REST and GraphQL equally

### Positive Controls Confirmed
- Quantity validation: CartItemPersister rejects qty<=0
- Custom price: admin-only (not REST/GraphQL for customers)
- Cart mutex: placeOrder uses CartMutexInterface
- ByPercent discount capped at min(100, amount)
- Guest cart uses masked UUID
- WebAPI forced params prevent IDOR on /V1/customers/me

## Message Queue Security Summary (task_078)

### MQ Consumer Inventory (12+ consumers)
| Consumer | Queue | Handler | Trust Level |
|----------|-------|---------|-------------|
| saveConfigProcessor | saveConfig | AsyncConfig\Consumer::process | CRITICAL — arbitrary config |
| async.operations.all | async.operations.all | MassConsumer (isSecureArea=true) | CRITICAL — all bulk API ops |
| exportProcessor | export | ImportExport\Export\Consumer::process | MEDIUM — file write |
| product_action_attribute.update | * | Catalog\Consumer::process | MEDIUM — product attrs |
| codegeneratorProcessor | codegenerator | SalesRule\Coupon\Consumer::process | LOW — coupon gen |

### Key Security Findings
- **No message-level auth** (G-036): All consumers trust any schema-valid message from broker
- **AMQP plaintext default** (L-080): Port 5672, SSL disabled by default
- **AsyncConfig ACL bypass** (L-079): Already documented
- **MassConsumer isSecureArea=true**: Blanket delete protection bypass for all async operations
- **Export filename**: Server-generated, path-validated — SAFE
- **Chain**: L-080 (plaintext) -> credential sniff -> G-036 (no msg auth) -> L-079 (config injection)

## Taint Analysis Summary (task_004)

### Input Handling Model
- All user input enters via getParam()/getPostValue() through Laminas Request wrapper
- No centralized input validation - each controller/module implements own sanitization
- Common pattern: getPostValue() -> model->addData() -> model->validate() -> model->save()
- Integer casting (int) is the most common sanitization for ID params
- No raw superglobal access in application code (good)

### Critical Taint Flows Identified
| # | Flow | Sink Type | Severity | Task |
|---|------|-----------|----------|------|
| T-1 | Wishlist token cache lookup -> request param override + CSRF bypass | Deser/CSRF | HIGH | task_051 |
| T-2 | FormData parse_str -> array_replace_recursive -> model data | Param inject | MEDIUM | task_052 |
| T-3 | BundleImportExport CSV item[0] concat in SQL WHERE | SQL inject | HIGH | task_053 |
| T-4 | Quote/Order item options -> user cart -> admin display unserialize | Deser/XSS | HIGH | task_054 |
| T-5 | CURL adapter enables FTP/FTPS + arbitrary curl options | SSRF amp | MEDIUM | task_055 |
| T-6 | CatalogUrlRewrite column name concat (no quoteIdentifier) | SQL inject | MEDIUM | task_056 |
| T-7 | MediaGalleryUi REGEXP with user path (no metachar strip) | ReDoS/enum | MEDIUM | task_057 |
| T-8 | simplexml_load_string in Layout/Merge without XXE protection | XXE | MEDIUM | task_058 |
| T-9 | __destruct/__wakeup gadget chain surface (107 magic methods) | Deser RCE | LOW | task_059 |

### SQL Injection Patterns
- Direct concat with intval(): Common safe pattern - SAFE
- Direct variable concat: BundleImportExport - has (int) cast at line 227, LIKELY SAFE (task_053 to verify)
- Column name concat: CatalogUrlRewrite - column names from UrlRewrite constants, NOT user input, LOW RISK (task_056)
- REGEXP/LIKE injection: MediaGalleryUi, Category/Flat
- Price filter: _getComparingValue() returns float - SAFE
- FIELD() expressions: integer arrays - generally SAFE

### Deserialization Safety (Evaluated task_032)
- **PRIMARY MITIGATION**: Framework Serialize.php uses allowed_classes=false - blocks PHP object instantiation (GOOD)
- **JSON everywhere**: Most paths now use Json serializer (no object creation possible)
- **NO raw unserialize()**: Zero native PHP unserialize() calls bypass the framework abstraction
- **NO phar:// vectors**: No phar:// wrapper usage found
- **6 native PHP Serialize users** (cache data only): ConfigLoader, ConfigCache, PluginList, ActionList, Flag, Interception CacheManager
- **Flag.php legacy fallback**: Tries JSON first, falls back to native PHP Serialize (still with allowed_classes=false)
- **~28 __wakeup + ~27 __destruct classes**: Moot as gadget targets because allowed_classes=false prevents object instantiation
- Main risk: Array content from deserialized cache data used without validation (data integrity, not RCE)
- **Cache poisoning concern**: If Redis has no auth, attacker could poison cache but allowed_classes=false blocks object injection
- **Existing coverage**: task_054 (order option deser), task_059 (gadget chain mapping), task_052 (FormData parse_str)

### Deserialization Deep Audit (task_024)
- **SerializerInterface default**: Maps to Json::class via app/etc/di.xml:170 - all components use JSON unless explicitly overridden
- **Only 2 di.xml overrides** use native PHP Serialize: Config/App/Config/Type/System (encrypted cache) and Csp/Model/BlockCache
- **Session deserialization gap (G-011)**: PHP native session handler does NOT use allowed_classes=false. If Redis session store is unauthenticated (default), attacker with network access could inject serialized objects. ~27 __destruct gadget candidates exist.
- **Dynamic class instantiation**: CatalogRule/SalesRule NewConditionHtml controllers accept class type from admin request, restricted to ConditionInterface. Admin-only.
- **No Serializable interface abuse**: Only JsonSerializable found (safe - JSON encoding only)
- **Spawned**: task_126 (Redis auth/session deser), task_127 (system config cache integrity), task_128 (rule condition class instantiation)

### PHP Type Juggling: NOT VULNERABLE (Evaluated task_033)
- **766 files with strcmp/in_array, 988 with loose ==** - all false positive or non-exploitable
- **PHP 8.3+ requirement** eliminates classic type juggling vectors
- **Security-critical comparisons use Security::compareStrings()** (hash_equals wrapper) consistently
- **No type juggling tasks spawned** - comprehensive evaluation found no exploitable patterns

### XML Parsing / XXE Evaluation (task_034)
- **PHP 8+ mitigates external entities by default** - dynamic test confirmed on PHP 8.4
- **libxml2 detects recursive entity loops** - billion laughs blocked
- **Flat entity expansion still works** but 1:1 (no amplification), limited DoS impact
- **Security::scan() used by**: Shipping carriers (AbstractCarrierOnline:659), DHL (XmlValidator:51), PayPal (FraudHandler:101) - GOOD
- **Security::scan() NOT used by**: REST XML Deserializer (L-001), AdminNotification Feed (L-002), MediaGallery XMP (L-003), SOAP Server (has DOCTYPE check after parse)
- **LIBXML_NOENT never used** anywhere in codebase - good, prevents entity substitution bypass
- **Overall**: Defense-in-depth gaps, not exploitable on PHP 8.3+. Would be critical on PHP <8.0.

### SSRF Surface (Evaluated task_038)

**No framework-level SSRF protection** - no IP blocklist, no internal network validation. G-003 gadget.

| # | SSRF Vector | Auth | URL Source | Severity | Finding |
|---|-------------|------|------------|----------|---------|
| S-1 | Product image import (CSV) | Admin | CSV column value | **Medium** | M-004 |
| S-2 | Downloadable product sample/link | Admin-set, customer-triggers | DB stored URL | Low | G-004 |
| S-3 | Admin notification feed | Admin-config | feed URL config | Low | L-002 (XXE) |
| S-4 | CURL adapter FTP/FTPS | N/A (framework) | Depends on caller | Info | T-5 |
| S-5 | StompClient Jolokia | Deployment config | env.php host | Info | task_086 |
| S-6 | Shipping carriers | Admin config | gateway_url config | Low | task_086 |
| S-7 | Dashboard Tunnel | Admin | Fixed URL (image-charts.com) | None | Hardcoded + HMAC |
| S-8 | Elasticsearch/OpenSearch TestConnection | Admin | Request params (hostname/port) | Low | G-012 |
| S-9 | Currency rate import | Admin config | Hardcoded service URLs | None | Safe |
| S-10 | Analytics signup/update | Admin config | Config path URLs | None | Safe |
| S-11 | Security file accessibility check | Auto | Store base URL | None | Config-derived |

**Key observations:**
- HTTP Client Curl has CURLOPT_PROTOCOLS (HTTP/HTTPS/FTP/FTPS)
- Filesystem Driver Http has NO protocol restrictions
- UPS validates ups.com domain; other carriers need checking (task_086)
- PayPal uses hardcoded endpoints; PayPal GraphQL validates paths correctly
- Checkout return_url validated against base store URL - redirect, not SSRF

### Command Execution: Mostly SAFE
- Framework Shell uses escapeshellarg() consistently
- **Exception: DevTestsRunCommand** (M-008) - passthru() with unsanitized CLI --command-arguments. CLI-only.

### Injection Audit Summary (task_007)

**SQL Injection:**
- G-007: Second-order SQL via trigger names in DDL (3 files, unquoted in DROP/SHOW CREATE TRIGGER)
- L-008: Bestsellers storeId concatenation mitigated by PHP ?int type hint
- Framework PDO adapter uses parameterized queries consistently for user data

**Command Injection:** M-008: CLI DevTestsRunCommand passthru without escapeshellarg (CLI-only)

**Template Injection:** Filter\Template processes directives in CMS/email. LegacyDirective uses reflection (task_097).

**XSS / Output Encoding:** @noEscape ~2800+ times. productAttribute() conditionally escapes. MaliciousCode filter NOT on WYSIWYG save (task_099).

**Not Found:** Open redirect, email injection, CRLF injection, LDAP, NoSQL injection.

**Negative Space Controls:**
- escapeshellarg: all framework Shell, 1 bypass (DevTestsRunCommand)
- quoteIdentifier: 3 DDL files lack it for trigger names
- MaliciousCode filter: 4 files only, not on product WYSIWYG save

### Crypto, Secrets, Weak Hashing Evaluation (task_040)

**Encryption Architecture:**
- Modern: ChaCha20-Poly1305 AEAD (Sodium) for new encryption - GOOD
- Legacy: Blowfish-ECB, Rijndael-128-ECB, Rijndael-256-CBC for decrypt backward compat
- Password hashing: Argon2ID13 with INTERACTIVE ops/mem limits - GOOD
- Admin SecretKey: uses Encryptor::getHash() (Argon2) with formKey salt - GOOD
- Security::compareStrings() (hash_equals wrapper) for security comparisons - GOOD
- Random class (Math/Random): uses random_int() (CSPRNG) - GOOD

**PRNG Findings:**
- PageCache Version.php: md5(rand() . time()) for cache cookie - WEAK but low impact (L-006)
- StoreSwitcher: uniqid() for same cookie - WEAK but low impact
- Payflowlink: md5(mathRandom->getRandomString(10)) for payment hash - suboptimal (G-005)
- MessageQueue: rand() for correlation_id - non-security
- ImageProcessor: md5(rand()) for temp filenames - non-security

**Weak Hashing (md5/sha1):**
- ~44 files md5 in app/code + 14 in framework. Mostly cache keys/checksums. NOT for passwords/tokens.
- ~21 files sha1. Used for cache keys. NOT for security tokens.
- All password hashing uses Argon2ID13 (confirmed)

**Legacy Cipher Risk (L-007):**
- Blowfish-ECB and Rijndael-128-ECB in decrypt path only
- No automatic re-encryption mechanism found (needs task_087)

**No hardcoded secrets, no TLS bypass, no embedded private keys found.**

**Verified claims:** D-3 (Argon2ID13) CONFIRMED, D-4 (ChaCha20) CONFIRMED for new data.

### JWT Token Security (task_072)

**Architecture:**
- JWT via web-token/jwt-framework v4 (JwtFrameworkAdapter module)
- Token issuance: Issuer.php creates JWS or JWE based on config
- Token reading: Reader.php -> JwtManager -> JwsManager/JweManager (signature verification via library)
- Validation: CompositeUserTokenValidator chains ExpirationValidator + RevokedValidator
- Token consumption: TokenUserContext (REST), AuthorizationRequestValidator (GraphQL)

**Default Config:** HS256, 60min admin TTL, 60min customer TTL, A128GCM for JWE content

**Key Derivation:** SecretBasedJwksFactory takes crypt/key, pads with & to 2048 bytes. CryptKeyGenerator produces 256-bit random key via random_bytes() (CSPRNG). Adequate entropy.

**Security Assessment:**
- Algorithm confusion: **SAFE** - server-side algorithm selection only, prepareAllAccepted() returns only configured algorithm
- alg:none: **SAFE** - UnsecuredJwtManager exists but unreachable for user tokens (NoEncryption never in accepted list)
- Signature verification: Delegated to jwt-framework library (loadAndVerifyWithKeySet)
- Expiry: Enforced by ExpirationValidator (skip for integration tokens by design)
- Revocation: Per-user timestamp-based (RevokedValidator checks iat <= beforeTimestamp), no per-token revocation
- Claims: Only uid, utypid, iat, exp - no iss/aud/jti (G-013)
- Key isolation: None - JWT key = padded crypt/key (L-016)
- Available algorithms: HS256/384/512, AES-KW variants, AES-GCM-KW - no asymmetric in default config, no none

**Findings:** L-016 (key derivation from master key, gadget), G-013 (missing iss/aud claims)

---
*Last updated: 2026-03-27 JWT security evaluation task_072*


## Discovery Validation Results (task_017)

### Validation Pass 1 - Corrections Applied

**Entry Point Count Corrections:**
- REST Self-scoped endpoints: 38 (was incorrectly 64)
- REST Anonymous endpoints: 41 (was 42 - minor)
- Custom routers: 4 (was 5 - CSP is a plugin, not a router)

**New Entry Points Documented:**
- CLI commands: 97 files
- Cron jobs: 26 crontab.xml files
- Message queue consumers: 10 queue_consumer.xml files
- SOAP endpoint: Webapi/Controller/Soap.php (FrontControllerInterface)
- Error handlers: 6 files in pub/errors/

**Auth Architecture Validated:**
- Admin AbstractAction._isAllowed() + ADMIN_RESOURCE confirmed at line 211/47
- No admin controllers bypass Backend AbstractAction (checked)
- CsrfValidator skips XHR (line 75) and non-POST (line 74) - confirmed
- GraphQL: only ~32/402 resolvers check getIsCustomer() - vast majority open

**Confidence Assessment:** Discovery data is trustworthy for analysis planning. Counts are validated against source. Auth model is confirmed. Ready to proceed.

### Validation Passes: 1 (clean after corrections - no structural gaps requiring re-pass)

---
*Last updated: 2026-03-27 validate_discovery task_017*

## Crown Jewels (task_071)
1. Admin account access - full store control, customer data, financial ops
2. Customer PII export - name, email, address, phone, order history
3. Payment manipulation - amount tampering, refund fraud, gateway credential theft
4. Encryption key (crypt/key) - decrypts all stored sensitive data
5. Integration tokens - long-lived API access equivalent to admin

## Feature Trust Map (task_071)
- Customer email change vs password reset (no re-auth?) -> task_062
- File upload vs admin display (stored XSS?) -> task_035
- Cart ops vs checkout validation (TOCTOU?) -> task_061
- GraphQL vs REST rate limiting (bypass?) -> task_074
- Import CSV vs product data (SQL injection?) -> task_053
- CMS directives vs config secrets (path traversal?) -> task_065
- LoginAsCustomer secret vs session isolation -> task_049
- AsyncConfig MQ vs admin session requirement -> task_078
- Redis sessions vs auth (default no password) -> task_073

## Implementation Quirks (task_071)
- IQ-1: CsrfValidator skips XHR/AJAX -> task_019
- IQ-2: GraphQL NO framework auth (~370/402 open) -> task_074
- IQ-3: REST/GraphQL different auth for same ops -> task_074
- IQ-4: parse_str() in FormData -> task_052
- IQ-5: Session validation disabled by default -> AR-8
- IQ-6: CSP report-only + unsafe-inline/eval -> AR-7
- IQ-7: 286 DI plugins modify method behavior -> task_079
- IQ-8: AsyncConfig MQ for config saves -> task_078

## File Handling Deep Audit (task_021)

### Path Traversal Protection Architecture
- **Framework PathValidator**: Comprehensive via getRealPathSafety() + directory prefix check. NOTE: does NOT resolve symlinks.
- **MediaStorage Request**: str_replace("..", "") on pub/get.php path
- **StaticResource**: getRealPathSafety() + theme allowlist + locale validation
- **Error Processor**: Skin [a-z0-9_]+ regex; report ID [a-fA-F0-9]{64}
- **Customer Viewfile**: mb_strpos(\$path, "..") check
- **Downloadable Helper**: preg_match for ../ LFI protection

### File Upload Coverage
| Path | Extension Check | Auth | Notes |
|------|----------------|------|-------|
| Customer address file | NotProtectedExtension | NONE (M-017) | Requires file attr config |
| Product option file | Weak denylist | None | Random filename + dir denied (M-001) |
| CMS WYSIWYG | MediaStorage | Admin | directoryResolver validates |

### Negative Space Controls
- PathValidator: ~100% coverage on filesystem ops
- NotProtectedExtension: ~10/15 upload paths
- Content-type validation: NOT consistent (extension only, not magic bytes)
- getRealPathSafety() does NOT resolve symlinks (task_124)

### New Findings: M-017 (no-auth upload), G-010 (SSRF via redirect following)

## Compound Class Signals (task_071)
- code_symmetry + state_invariants: Order create/cancel/refund + state machine
- parallel_data + check_use_non_atomicity: Cache+DB, check-then-act in checkout
- resource_exhaustion + state_invariants: GraphQL complexity + checkout steps

## Analysis Dimensions (task_071)
- D-1: REST vs GraphQL consistency -> task_074
- D-2: Default-path CsrfValidator + auth -> task_019, task_028
- D-3: Config attack surface -> task_075
- D-4: JWT security -> task_072
- D-5: Redis session/cache -> task_073
- D-6: RabbitMQ consumers -> task_078
- D-7: Framework core scope -> task_076
- D-8: Sales state machine -> task_077
- D-9: DI plugin interceptors -> task_079
- D-10 to D-15: Structural classes -> task_029

## Hotspot Walk Coverage (task_071)
- Batch 1 (task_030): Functions 1-15 (taint flows T-1 to T-8 + unauth controllers)
- Batch 2 (task_031): Functions 16-30 (payment, auth, API dispatchers)
- Batch 3 (task_080): Functions 31-50 (Eav, tax, files, CMS, import, backup, OAuth)

## Cross-Finding Chain Analysis (meta_reprioritize_2)

| Finding A | Finding B | Chain? | Combined Impact |
|-----------|-----------|--------|-----------------|
| G-001 (version) | H-004 (admin token) | YES | Version->CVE targeting->brute-force. INFO+HIGH = HIGH |
| H-004 (admin) | H-001 (setup SQLi) | CONDITIONAL | Admin->re-trigger setup->SQLi |
| G-001 (version) | L-001 (REST XML) | YES | Version reveals PHP ver->if <8 XXE=CRITICAL |
| H-004 (admin) | L-002 (feed XXE) | POSSIBLE | Admin->configure feed->SSRF |
| **M-010 (REST XSS filter)** | **L-005 (CSP disabled)** | **YES** | **Stored XSS: weak filter + no CSP = HIGH** |
| **M-005+M-006+G-008 (email enum)** | **H-004+M-011 (no rate limit)** | **YES** | **Full credential attack chain = HIGH** |
| M-004 (import SSRF) | G-003 (no SSRF prot) | YES | Cloud metadata theft. MEDIUM+INFO = HIGH |
| M-003 (TAR path traversal) | admin access | YES | Backup restore -> webshell -> RCE |
| G-004 (downloadable SSRF) | G-003 (no SSRF prot) | YES | Stored SSRF. LOW+INFO = MEDIUM |

**Chain tasks spawned:** task_106 (XSS chain), task_107 (email enum chain)


## Confirmed Exploit Chains

### Chain: Full ATO via REST Email Change + Password Reset (H-005)
**Components:** M-013 (REST email change no re-auth) + anonymous password reset endpoint
**Attack:** Attacker with stolen bearer token changes email via PUT /V1/customers/me (no password needed), then triggers anonymous password reset to attacker email, resets password
**Combined Severity:** HIGH (M-013 alone is MEDIUM, but chain enables full ATO)
**Mitigations Present (insufficient):** Token revocation after save (too late), email notification to old email (detection only), email confirmation config (disabled by default)
**Amplifiers:** L-005 (CSP report-only) enables initial token theft via XSS; M-021 (tokens not revoked on password change) means stolen tokens remain valid

## Skill Coverage (meta_reprioritize_3, updated meta_10)

All 14/14 core skills COMPLETED. See updated table at top of Reprioritization Log (Meta Task 10).

## Pre-Analysis Coverage (meta_reprioritize_2)

**9/9 categories complete.** All evaluated. No gaps.

## Absence = Finding Checks (meta_reprioritize_2)

All 6 controls verified present: password policy, session invalidation, account lockout, rate limiting (partial: M-011), security headers (partial: L-005). No new findings needed.

## Negative-Space Analysis (meta_reprioritize_2)

Verified: escapeshellarg (1 bypass: M-008), quoteIdentifier (3 DDL gaps: G-007), CSRF ~100% (XHR exempted: task_095), admin ACL ~100%, ownership 1 gap (M-007), rate limiting 2/41 anon endpoints (M-011).

## Task Overlap Registry (meta_reprioritize_2)

| Task A | Task B | Resolution |
|--------|--------|------------|
| task_089 | task_072 | Different JWT subsystems. Notes added. |
| task_094 | task_101 | High overlap. First covers both; second verifies. |
| task_042 | M-005/M-006/G-008 | Superseded by task_107 chain analysis. |
| task_099 | task_102 | Combined in task_106 chain analysis. |

## Data Integrity Fixes (meta_reprioritize_2)

- task_030 duplicate ID: Second entry reassigned to task_105 with correct content.

## Reprioritization Log (meta_reprioritize_2)

1. Fixed task_030 duplicate -> task_105, elevated to HIGH
2. Spawned task_106 (XSS chain M-010+L-005) HIGH, task_107 (email enum chain) MEDIUM
3. Noted 4 task overlaps for deduplication by executing agents
4. All absence checks PASSED, negative-space verified, pre-analysis 9/9 complete
5. 5/14 skill audits done, 9 pending with tasks, no orphans
6. All 15 analysis dimensions have tasks, auth matrix exists

**Priority order for next tasks:**
1. task_060 (PayPal - money, 73 controllers, unauthenticated webhooks)
2. task_097 (template SSTI - potential RCE)
3. task_106 (stored XSS chain)
4. task_061 (checkout manipulation)
5. task_062 (customer account security)
6. task_093 (REST mass assignment)
7. task_094 (GraphQL IDOR systematic)

---
*Last updated: 2026-03-27 meta_reprioritize_2 (20 tasks completed)*

### CSV Formula Injection (Evaluated task_036)
- **No formula sanitization** in any CSV export path
- ImportExport/Model/Export/Adapter/Csv.php writeRow() -> writeCsv() -> fputcsv() - no escaping of =, +, -, @
- No escapeFormula or equivalent function anywhere in codebase
- User-controlled data (product names, customer names, reviews) written directly
- Attack: inject formula via unauthenticated paths (registration, reviews), admin exports CSV, opens in spreadsheet
- **Finding M-002**: Medium severity (requires user interaction)
- **task_084**: Investigation spawned to trace all export paths and confirm injection vectors

## Authentication & Session Audit (task_005)

### Verified Security Controls (Positive)
- **Session regeneration**: Confirmed on customer login, admin login, account creation, checkout, LoginAsCustomer
- **Constant-time comparison**: Security::compareStrings (hash_equals) used for all token/secret comparisons (13 instances)
- **Session invalidation on password change**: SessionCleaner::clearFor() in both resetPassword() and changePasswordForCustomer()
- **Password hashing**: Argon2ID13 via sodium. Legacy MD5/SHA256 accepted for verification only
- **Token generation**: Math\Random uses random_int() (CSPRNG). Reset tokens 32-char random
- **Account lockout**: Customer 10 failures/10min, Admin 6 failures, API 6 failures/30min
- **Password reset protection**: ForgotPasswordPost catches NoSuchEntityException silently

### Email Enumeration Surface
- **M-005**: GraphQL requestPasswordResetEmail leaks email existence via different errors
- **M-006**: isEmailAvailable anonymous endpoint (REST + GraphQL) returns registration status
- **G-006**: Lockout messages differentiate locked from non-existent
- **Chain**: M-005 + M-006 + G-006 + H-004 = comprehensive user discovery + targeted attacks

### Spawned Investigations
- task_089: JWT token security (alg enforcement, key management, expiration)
- task_090: Admin auth timing enumeration (hash computation skipped for non-existent users)
- task_091: OAuth 1.0a implementation security (callback validation, token replay)
- task_092: Session validation weaknesses (disabled by default, cross-store, LoginAsCustomer)


## Access Control & IDOR Audit (task_028)

### Auth Model Summary
- Auth matrix: contexts/auth_matrix.md
- Admin: Auth-by-default. ~462 _isAllowed refs across ~250 controllers. Well-protected.
- Frontend: OPEN-by-default. Ownership validation verified in 6/6 key controllers.
- REST API: Self-scoped uses force=true params. Systemically safe.
- GraphQL: ~32/402 resolvers check auth. One IDOR found: M-007.

### Findings
- M-007: AssignCompareListToCustomer missing customer_id in maskedListIdToCompareListId call

### Negative-Space
- CSRF: ~100% POST via CsrfValidator (XHR exempted - task_095)
- Admin ACL: ~100% via framework dispatch
- Ownership: 1 gap in GraphQL (M-007)

### Spawned Tasks
- task_093: REST customer mass assignment
- task_094: Systematic GraphQL IDOR
- task_095: CSRF XHR bypass
- task_096: DownloadCustomOption secret key

---
*Last updated: 2026-03-27 task_028*

## API Security Audit (task_022)
- M-009: GraphQL complexity disabled in dev mode
- M-010: REST XSS filter only blocks script tags
- M-011: GraphQL rate limiting only on PlaceOrder
- G-008: Email enumeration via isEmailAvailable
- Rate limiting: 2/41 anonymous endpoints covered
- REST: 41 anonymous, 38 self, 269 ACL-protected


## Cryptography and Secrets Audit (task_008)

### Encryption Architecture
- Current: ChaCha20-Poly1305 (AEAD) via SodiumChachaIetf - STRONG
- Legacy: Blowfish-ECB, Rijndael-128-ECB, Rijndael-256-CBC - backward-compat only
- Key: 32-char from env.php crypt/key, versioned keys supported
- Password hashing: Argon2ID13 current, SHA256/MD5 upgrade path for legacy

### Secret Comparison: 9/12 use hash_equals. 3 file download endpoints use loose == (L-011)
### TLS: M-012 StompClient disables SSL verification + sends creds over HTTP
### Weak PRNG: PageCache cookie md5(rand().time()), MQ message IDs, export temp files - none auth-critical
### Key management: env.php plaintext, no HSM/KMS. Needs investigation (task_115)


## Code Symmetry, State Invariants, and Structural Heuristics (task_029)

### Paired Function Asymmetry: OrderMutex Coverage (M-015)
- Protected by OrderMutex: cancel(), RefundInvoice, InvoiceOrder, ShipOrder, RefundOrder
- NOT protected: hold(), unHold(), addComment()
- CreditmemoService.refund(): Uses own beginTransaction but NOT OrderMutex (task_119)

### SalesRule Usage Counters (M-016)
- Coupon.times_used: Properly locked via LockManager
- Rule.times_used: NO locking in updateRuleUsages() - TOCTOU

### Stock Management Asymmetry (L-013)
- registerProductsSale(): lockProductsStock() - SAFE
- revertProductsSale()/backItemQty(): No locking

### Negative-Space: OrderMutex 5/8 ops, Coupon lock 1/3 counters, Stock lock 1/3 ops
### No admin audit log module in CE
### Qty validation: CartItemPersister checks qty > 0 - negatives blocked


## Client-Side Security Audit (task_019)

### XSS Defense Architecture
- **PHP Escaper** (Framework/Escaper.php): blocks javascript:, data:, vbscript: URIs
- **JS Escaper** (Security/view/base/web/js/escaper.js): Only blocks javascript: -- MISSING data: URI (L-014)
- **CSP**: Report-only with unsafe-inline + unsafe-eval (L-005) -- zero XSS protection

### Output Encoding Coverage
- 774 files use escapeHtml/escapeHtmlAttr/escapeJs/escapeUrl
- 624 files use @noEscape (45% ratio of raw output)

### Knockout html: Binding Surface (G-009)
- 25+ frontend templates use data-bind="html: ..." rendering raw HTML
- cart-item-renderer.js returns productName/optionValue raw ("already escaped on backend")
- No client-side sanitization in most rendering paths

### CORS: No CORS headers found -- secure-by-default (same-origin only)
### Open Redirect: _isUrlInternal() validates URLs start with store base URL

### Negative-Space: Output encoding ~55%, @noEscape ~45%, CSP ineffective, REST XSS filter ~10% coverage

## Chain Verification Gate (task_027)

C1: ATO email+reset - YES - REST API missing re-auth (M-013) enables ATO chain
C2: OAuth redirect - NO - OAuth 1.0a only, no redirect_uri
C3: Upload+processing - NO - GD2 only, no exiftool/ImageMagick/ffmpeg
C4: Double-spend coupon - YES - TOCTOU M-014, M-016
C5: ATO cache deception - NO - cacheable=false on customer pages
C6: Session smuggling - PARTIAL - SameSite=Lax, proxy-dependent
C7: MFA bypass - YES - No MFA module present (SF-10)
C8: GraphQL IDOR - YES - Per-resolver auth, M-007 existing
CC1: No-trace substitution - YES - Coupon TOCTOU + no audit trail (M-014)
CC2: Double-spend diverged - YES - CartMutex vs QuoteMutex (L-015)
CC3: Asymmetric growth - PARTIAL - Cart limits configurable
CC4: Pipeline escalation - NO - No CI/CD in application code

Cross-Feature Trust Map: Cart/Payment divergent locks (L-015), Email/Reset no re-auth (M-013), Coupon/Order TOCTOU (M-014), Hold/Invoice OrderMutex gap (M-015), Config directives whitelist-gated (SAFE), Re-auth coverage 2/3 paths



## Cross-Finding Chain Analysis Update (meta_reprioritize_3)

New chains identified since meta_2:

| Finding A | Finding B | Chain? | Combined Impact |
|-----------|-----------|--------|-----------------|
| G-012 (ES SSRF) | G-011 (session deser) | YES | Admin SSRF scans for Redis -> injects session objects -> RCE. MEDIUM chain. |
| M-013 (REST email change) | password reset | YES | ATO chain: stolen token -> email change -> reset -> full takeover. Already in task_133. |
| L-016 (JWT key from crypt/key) | any env.php exposure | YES | Master key leak -> forge JWT for any user. Covered by task_135. |
| M-017 (unauth upload) | L-004 (fail-open ext) | POSSIBLE | Depends on attribute config + server misconfiguration. |
| M-015 + M-016 (order/coupon races) | L-015 (CartMutex divergence) | YES | Compound concurrency: multiple race conditions across sales flow. |

**New chain task spawned:** task_139 (admin SSRF -> Redis session chain)

## Data Integrity Fixes (meta_reprioritize_3)

- task_117 duplicate ID: Second entry (order_mutex_coverage_gap) reassigned to task_137
- task_118 duplicate ID: Second entry (admin_audit_logging_gaps) reassigned to task_138

## Reprioritization Log (meta_reprioritize_3)

**Elevations:**
1. task_060 (PayPal payment security) -> CRITICAL: Financial impact, 73 open-by-default controllers
2. task_061 (Checkout/cart manipulation) -> CRITICAL: Financial impact, price tampering
3. task_062 (Customer account security) -> CRITICAL: ATO risk, unauthenticated surface
4. task_133 (ATO chain: REST email change) -> CRITICAL: Confirmed chain to full account takeover
5. task_097 (Template directive SSTI) -> HIGH: Potential RCE via server-side template injection

**Demotions:**
1. task_030 (smart contract) -> FINAL: N/A for PHP project
2. task_013 (test coverage) -> LOW: Not direct security assessment
3. task_122 (prototype pollution jQuery) -> LOW: JS files deleted, unlikely for PHP app
4. task_136 (JWT replay session binding) -> LOW: Depth 3, low impact

**Queue summary (after 30 completed):**
- Completed: 30 tasks
- Pending HIGH/CRITICAL: ~25 investigate/trace tasks
- Pending MEDIUM: ~40 investigate/evaluate tasks
- Pending LOW: ~10 tasks
- Pending FINAL (run_last): 3 tasks (PoC gen, debug eval, report)
- Total findings: 40 (2 HIGH, 17 MEDIUM, 16 LOW, 5 INFO/gadgets)

**Coverage assessment:**
- Pre-analysis: 9/9 categories evaluated
- Core skills: 11/14 completed, 3 pending in queue
- Feature coverage: 18 features identified, all have investigation tasks
- Absence checks: All 6 controls verified present


## Infrastructure Audit Summary (task_010)

### Infrastructure Present
- docker-compose.yml (PHP-FPM, Nginx, MySQL, OpenSearch, Redis, Mailpit)
- docker/php.Dockerfile, docker/nginx.conf, docker/install.sh
- nginx.conf.sample (production reference)
- pub/.htaccess + multiple subdirectory .htaccess files
- phpserver/router.php (built-in PHP dev server)
- No Terraform, Kubernetes, CI/CD workflows

### Key Findings
- **L-017**: Docker dev stack exposes all services (MySQL/Redis/OpenSearch) on 0.0.0.0 without auth
- **L-018**: Docker nginx missing security headers on static file responses
- **G-014**: pub/.htaccess unconditionally disables mod_security WAF (chains with M-001, M-004, M-010)
- Redis has no auth in docker config (chains with G-011 session deserialization)
- HSTS opt-in disabled by default (D-20 confirmed)
- Swagger gated by developer mode (D-25 confirmed)
- Admin frontname auto-generated if not specified (good)
- Composer dependencies version-pinned with ^ (acceptable)
- No hardcoded production secrets found

### Negative-Space Gaps
| Control | Coverage | Gap |
|---------|----------|-----|
| HSTS | Opt-in, off by default | All HTTP deployments vulnerable to downgrade |
| Security headers (static) | 0% on nginx-served static files | MIME-sniffing possible |
| WAF (mod_security) | 0% - unconditionally disabled | No Apache WAF protection |

## HTTP Request Handling Audit (task_020)

### Host Header Handling
- URL Construction: Framework Url uses config-based base URLs, NOT Host header. Safe.
- BaseUrlChecker: Validates Host vs configured base URL, but only on redirect-to-base flow.
- getHttpHost() in SOAP/REST Schema: Used for WSDL/schema URLs (needs investigation - task_141)
- Cache purge target: Server::getUris() uses Host header when no cache hosts configured (L-019)

### IP Address Handling
- RemoteAddress: di.xml configures X-Forwarded-For but NO trusted proxies. IP spoofable (M-018).
- All IP-based controls (CAPTCHA, throttling) bypassable via X-Forwarded-For header.

### Cache Architecture
- Varnish cache key: URL + X-Magento-Vary cookie + SSL offload header + design exceptions
- GraphQL adds X-Magento-Cache-Id, Store, Content-Currency (client-controlled, G-015)
- PURGE ACL restricted to configured IPs

### CSRF Protection
- CsrfValidator skips XHR (isXmlHttpRequest), but no CORS config = restrictive by default
## Persistent Blockers

| Blocker | Times seen | Last recovery task |
|---------|-----------|-------------------|
| (none currently) | | |

### Data Protection and Information Disclosure (task_023)
- L-020: Checkout config exposes all quote DB columns (remote_ip, applied_rule_ids) to frontend JS
- L-021: Payment Logger debugReplaceKeys defaults empty, CardinalCommerce logs full JWT
- M-019: GraphQL validation disabled in developer mode (compounds M-009)
- Error reports stored var/report/ with 64-char hex IDs. Production mode masks exceptions.
- Customer DataProvider excludes password_hash/rp_token (GOOD). REST API interface-constrained (GOOD).
- Sensitive config: 30+ fields use Backend Encrypted (GOOD coverage).


## Concurrency Audit Summary (task_026)

### OrderMutex Coverage: 5/11 state-changing order REST endpoints use OrderMutex (45%)
- SAFE: cancel, invoiceOrder, refundOrder, refundInvoice, shipOrder
- MISSING: creditmemoRefund (M-020), hold/unhold/addComment (M-015), setCapture/setVoid (L-022)

### New Findings: M-020 (CreditmemoService double refund), L-022 (InvoiceService race)
### Spawned: task_146 (invoice capture/void race), task_147 (cron variable bug)


## Edge Cases and Boundary Conditions Audit (task_011)

### Numeric Boundary Handling
- Qty validation: CartItemPersister checks is_numeric + qty<=0. _prepareQty defaults negatives to 1.
- Price validation: parseCustomPrice defaults negatives to 0. Catalog price APIs check price<0.
- Creditmemo grand total: isValidGrandTotal rejects <=0. Percentage adjustments not capped at 100%.
- Weee division by zero: Renderer divides by qty without guard (L-024).

### Password Length Asymmetry (L-023)
- Customer: MAX_PASSWORD_LENGTH=256. Admin: NO max length check.

### Security Controls Verified Safe
- compareStrings: callers guard against empty strings
- PathValidator + getRealPathSafety: comprehensive
- REST ServiceInputProcessor: blocks XMLElement, validates types

### Spawned: task_148 (locale parsing), task_149 (creditmemo adjustment), task_150 (error disclosure)


## PayPal Payment Security Audit (task_060)

### IPN (Instant Payment Notification)
- **Postback verification**: Solid - _postBack() sends IPN data back to PayPal, requires "VERIFIED" response
- **Merchant email verification**: _getConfig() checks business/receiver_email against configured merchant email
- **CSRF exempt**: Correctly marked as CsrfAwareActionInterface (server-to-server)
- **OrderMutex**: Only used for refund, NOT for capture/auth/void (L-027)

### Express Checkout
- **Price manipulation prevention**: AMT sent to PayPal in DoExpressCheckoutPayment - PayPal verifies server-side
- **Return URL**: No open redirect - redirects to hardcoded checkout paths

### Payflow Silent Post
- **Hash verification inconsistency**: _getOrderFromResponse() uses != (loose), ReturnUrl uses hash_equals (L-026)
- **Hash generation**: md5(CSPRNG 10-char string) = ~59 bits entropy (G-005)

### Billing Agreement
- **Auth enforced**: dispatch() calls authenticate() - session required
- **IDOR check**: Loose == comparison for customer ownership - mitigated by auth requirement

## Customer Account Security Investigation (task_062)

### Password Reset Token Security - SOLID
- Token: 32-char alphanumeric via Random::getRandomString(32), uses random_int() (CSPRNG)
- Comparison: hash_equals() via Security::compareStrings() (timing-safe)
- Expiry: 2 hours (configurable), token cleared after use (single-use)
- Token renewal: timestamp refreshed when reset form is loaded (prevents expiry mid-fill)

### AJAX Login CSRF - MITIGATED BY DESIGN
- CsrfValidator (line 75) skips CSRF for XHR requests ($request->isXmlHttpRequest())
- X-Requested-With is a custom header that triggers CORS preflight
- No CORS headers set in Magento (confirmed: no Access-Control-Allow-Origin anywhere)
- SameSite=Lax cookies provide additional defense layer
- Result: Cross-origin XHR with custom headers blocked by browser SOP

### Session Fixation - MITIGATED
- session_regenerate_id() called in Customer/Model/Session::setCustomerDataAsLoggedIn()
- Regeneration happens BEFORE customer data is set (line 471)
- Cookie flags: HttpOnly, SameSite=Lax, Secure (when HTTPS)

### Section/Load Endpoint - BY DESIGN
- Returns data scoped to current PHP session only
- No cross-user IDOR: all section sources use session-based customer ID
- Cache-Control: no-store headers prevent browser caching

### Account Confirmation Key - INCONSISTENCY (L-029)
- Key generation: Same CSPRNG as password reset (32-char random_int based)
- Comparison: Uses !== (NOT timing-safe) vs password reset which uses hash_equals()
- Low practical risk due to ~190-bit entropy, but inconsistent security control

### Confirmation Email Resend - NO ENUMERATION LEAK
- Both invalid email and already-confirmed cases return "Wrong email." (same message)

## Recovered from stalled attempt (iter 41, task task_133)
<!-- Stream stalled after 20m no output. Partial work recovered. -->
### Tools called before stall
```
Read {"file_path":"/home/ubuntu/Desktop/projects/magento2/app/code/Magento/Customer/M
Grep {"pattern":"class AccountManagementApi","path":"/home/ubuntu/Desktop/projects/ma
Bash {"command":"jq --arg id \"M-013\" '.findings[] | select(.id == $id) | {id, title
Bash {"command":"jq --arg id \"M-021\" '.findings[] | select(.id == $id) | {id, title
Bash {"command":"python3 -c \"\nimport json, datetime\n\nwith open('findings.json') a
Bash {"command":"cat /tmp/claude-1000/-home-ubuntu-Desktop-projects-magento2/1e76adfb
Bash {"command":"python3 << 'PYEOF'\nimport json, datetime\n\nwith open('findings.jso
Bash {"command":"python3 << 'PYEOF'\nimport json\n\nwith open('findings.json') as f:\
Write {"file_path":"/home/ubuntu/Desktop/projects/magento2/.vscode/security-audit/cont
Bash {"command":"cat > /home/ubuntu/Desktop/projects/magento2/.vscode/security-audit/
Bash {"command":"python3 -c \"\nimport json\ndata = {\n    'task_id': 'task_133',\n  
Read {"file_path":"/home/ubuntu/Desktop/projects/magento2/.vscode/security-audit/audi
Bash {"command":"cat >> /home/ubuntu/Desktop/projects/magento2/.vscode/security-audit
Bash {"command":"python3 << 'PYEOF'\nentry = \"\"\"\n## Iteration 41 - 2026-03-27T23:
Grep {"pattern":"Potential Exploit Chains","path":"/home/ubuntu/Desktop/projects/mage
Read {"file_path":"/home/ubuntu/Desktop/projects/magento2/.vscode/security-audit/audi
Read {"file_path":"/home/ubuntu/Desktop/projects/magento2/.vscode/security-audit/audi
Read {"file_path":"/home/ubuntu/Desktop/projects/magento2/.vscode/security-audit/audi
Bash {"command":"python3 << 'PYEOF'\n# Append chain info to audit_context.md\nchain_e
Bash {"command":"python3 << 'PYEOF'\nimport json\n\nentry = {\n    \"iteration\": 41,
```
### Analysis output before stall
Now let me investigate the full ATO chain. I'll start by examining the REST API path for customer email change and the password reset flow.
Key finding: `initiatePasswordReset` loads customer by email at line 659. Now let me check the CustomerRepositoryInterface::save() method to see if it validates password on the REST path.
Now let me check the critical parts: the `customer_email_changed` event observer and whether `credentialsChanged` is actually called on the REST path.
Now let me check the critical question: is this observer registered for the webapi/REST area, or only for frontend?
Important findings so far:

1. The `customer_email_changed` event IS registered for `webapi_rest` area — so the observer DOES fire on REST API email changes
2. The observer clears sessions AND revokes tokens (line 72) — this is a mitigation
3. `credentialsChanged()` sends notification to BOTH old and new email (lines 177-178)

But wait — the observer **revokes the token** at line 72. This means the attacker's own token gets revoked right after changing the email! Let me think about the race condition: the token revocation happens in the same request as the email change. The save completes, the event fires, tokens are revoked. But what about the email confirmation requirement?
Now let me check the default value of this config setting and what happens to the account when confirmation is required:
**Critical finding:** `<confirm>0</confirm>` — email change confirmation is **disabled by default**. This means:

1. Email changes via REST API take effect immediately
2. No confirmation email is sent to the new address before activation
3. The account email is immediately changed

Now let me verify the key question: Does the token revocation at line 72 actually prevent the ATO chain? The issue is that the attacker's token is revoked AFTER the email is already changed. But the password reset is a separate request...

Let me check: after the email is changed and token revoked, can the attacker still use the anonymous password reset endpoint?
The password reset endpoint (`/V1/customers/password`) is **anonymous** — no token needed. So:

1. Attacker has stolen bearer token
2. Attacker calls `PUT /V1/customers/me` to change email to `attacker@evil.com` — this succeeds, email changes, then token is revoked
3. Token revocation doesn't matter — attacker calls anonymous `PUT /V1/customers/password` with `attacker@evil.com`
4. Password reset token is sent to `attacker@evil.com`
5. Attacker calls anonymous `POST /V1/customers/resetPassword` to set new password
6. Attacker now has full control of the account

But there's a mitigation: `credentialsChanged()` sends email notification to the OLD email (line 177). The victim gets an alert. However, this is a **detection** control, not a **prevention** control.

Also, the `CustomerEmailChangedObserver` at line 72 revokes the token — but the attacker only needs one successful request. After email change completes (in same request), the email is already changed. The token revocation happens after.

Let me also check: does `CustomerRepository::save()` have any password validation when called via REST?
Confirmed: `CustomerRepository::save()` has **no password validation**. It just saves whatever customer data is provided. The password check is only in the web controller (`EditPost.php`) and the GraphQL resolver.

Now let me verify the full chain is viable by checking the M-013 finding and then the `EditPost.php` for comparison:
This confirms the asymmetry:
- **Web (EditPost.php)**: Requires `current_password` for email change (line 437)
- **REST API**: No password required — just `PUT /V1/customers/me` with new email

Now let me verify the GraphQL path too:
Confirmed: GraphQL **requires password** for email change (line 99-103). REST API does not.

Now let me also check if there are existing mitigations like plugins that intercept the REST save:
There's a plugin `UpdateCustomer` registered specifically fo


## XSS Chain Investigation Results (task_106)
- M-010+L-005 chain: Output encoding mitigates stored XSS across all verified paths. M-010 downgraded to LOW.
- Key rendering paths verified: admin grid Address column, admin order view, address renderer, email templates, gift messages, reviews
- Escaper with allowed tags uses DOM parsing, strips event handlers, escapeUrl blocks javascript:/data:/vbscript:


## Email Enumeration -> Credential Attack Chain (task_107)

**Chain: H-006 - Unauthenticated Email Enumeration + API Credential Brute-Force -> Scalable ATO**

Components: M-005 + M-006 + G-006 + G-008 (email enum) -> H-004 + M-011 + M-022 + M-023 (weak auth) -> H-005 + M-013 + M-021 (post-auth escalation)

Key defaults: OAuth lockout=6 failures/30min, Customer lockout=10 failures/10min, no per-IP limiting, no CAPTCHA on API, no ReCaptcha modules in codebase. Combined severity: HIGH.

## Confirmed Exploit Chains

### Chain: IP Spoofing Bypasses All IP-Based Rate Limiting (H-007)
**Components:** M-018 (X-Forwarded-For IP spoofing) + M-022 (CAPTCHA per-IP threshold 1000) + M-023 (no CAPTCHA on GraphQL) + Backpressure IdentityProvider
**Attack:** Attacker rotates X-Forwarded-For header per request. Each value gets a fresh CAPTCHA counter and fresh backpressure identity. Per-IP CAPTCHA (threshold 1000) never triggers. Backpressure rate limits never apply to guests.
**Combined Severity:** HIGH (individual findings are MEDIUM)
**Remaining Defense:** Per-account lockout only (RequestThrottler: 6 failures per account). No IP-based protection survives.
**Discovery:** IdentityProvider.php (Authorization/Model/) uses RemoteAddress for guest identity in Backpressure system - not just CAPTCHA.

### Chain: CSV Formula Injection + ACL Bypass = Admin Workstation RCE (Meta Task 10)
**Components:** M-002 (CSV formula injection in fputcsv) + M-028 (UI Component ACL bypass on gridToCsv)
**Attack:** Unauthenticated attacker registers customer with formula payload in firstname. Low-privilege admin exports customer grid via /admin/mui/export/gridToCsv (no ACL required per M-028). CSV opened in Excel executes payload.
**Combined Severity:** HIGH (unauthenticated write + no ACL export + RCE on admin workstation)

### Chain: ACL Cache Poisoning via Unauthenticated Redis = Full Admin (Meta Task 10)
**Components:** M-030 (ACL rules cached unencrypted in Redis) + L-046 (Redis default no auth)
**Attack:** Attacker with internal network access writes to Redis cache key authorization_rule_cached_data_<role_id>, grants Magento_Backend::all. Any restricted admin immediately becomes full admin.
**Combined Severity:** HIGH (no deserialization needed, pure data poisoning, persistent until cache flush)

### Chain: Mass ATO + Address IDOR = Full Customer PII Harvest (Meta Task 10)
**Components:** H-006 (credential brute-force) + M-026 (REST address IDOR) + M-029 (InstantPurchase address IDOR)
**Attack:** One compromised account + sequential address ID enumeration via REST API = all customer addresses exposed
**Combined Severity:** CRITICAL blast radius extension of H-006

### Chain: LoginAsCustomer Persistent Backdoor (Meta Task 10)
**Components:** M-027 (GraphQL loginAsCustomer bypasses consent + no audit log) + M-021 (tokens not revoked on password change)
**Attack:** Malicious admin creates customer token via GraphQL (no consent/audit), token survives customer password change
**Combined Severity:** HIGH (persistent unauthorized access, zero forensic trail)

