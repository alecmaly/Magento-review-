# Trace Taint: Wishlist Token Cache Poisoning → Request Param Override

## Overview
The Wishlist Plugin (`app/code/Magento/Wishlist/Controller/Index/Plugin.php`) deserializes a user-supplied `token` parameter to override ALL request parameters, including bypassing CSRF (form_key).

## Flow
1. User hits any wishlist controller action with `?token=<value>` while authenticated
2. `Plugin::beforeDispatch()` line 136-144 calls `$this->dataSerializer->unserialize($request->getParam('token'))`
3. `DataSerializer::unserialize()` validates token is 32 chars, looks up `wishlist_<token>` in cache (Redis/file)
4. If cache hit: JSON-deserializes the value, returns array
5. Plugin clears ALL request params and sets them to the deserialized data
6. `$data['form_key'] = $this->formKey->getFormKey()` - bypasses CSRF!

## Security Concerns
1. Cache poisoning: If Redis is accessible without auth (common misconfiguration), attacker can write to `wishlist_<known_token>` key with malicious JSON data
2. Request param injection: The deserialized data replaces ALL request params
3. CSRF bypass: Form key is auto-set from current session
4. Token is 32 random chars (via `Random::getRandomString`), good entropy. But cache TTL is 7 days.
5. Log injection: `"Invalid Token '$token' supplied."` (line 122)

## Key Files
- `app/code/Magento/Wishlist/Controller/Index/Plugin.php` (lines 108-150)
- `app/code/Magento/Wishlist/Model/DataSerializer.php` (full file)
- `lib/internal/Magento/Framework/Math/Random.php` (getRandomString)
