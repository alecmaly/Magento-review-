# Task 095: CSRF XHR Bypass Investigation

## Background
CsrfValidator skips CSRF validation for XHR/AJAX requests. This is IQ-1 in audit_context.md.

## Key File
lib/internal/Magento/Framework/App/Request/CsrfValidator.php (line ~75)

## Questions
1. How is isAjax() determined? Check Request class.
2. Can attacker set X-Requested-With header cross-origin?
3. What state-changing POST endpoints are reachable via AJAX?
4. Does SameSite=Lax prevent cross-site AJAX CSRF?
5. For same-site scenarios (subdomain takeover), is CSRF possible?
