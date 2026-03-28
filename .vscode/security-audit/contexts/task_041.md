# Context: Admin Token Brute-Force Investigation

## Related Finding: H-004

## Key Files to Read
- app/code/Magento/Integration/Model/Oauth/Token/RequestThrottler.php
- app/code/Magento/Integration/Model/Oauth/Token/RequestLog/Reader.php
- app/code/Magento/Integration/Model/Oauth/Token/RequestLog/Writer.php
- app/code/Magento/Integration/Model/Oauth/Token/RequestLog/Config.php
- app/code/Magento/Integration/Model/AdminTokenService.php
- app/code/Magento/Integration/etc/webapi.xml

## Questions to Answer
1. What is the max failure threshold before lockout?
2. How long is the lockout duration?
3. Is the lockout per-IP, per-username, or per-session?
4. Can the lockout be bypassed via IP rotation?
5. Is there a timing difference between valid/invalid usernames?
6. Does endpoint return different error messages for invalid username vs password?
7. Is there account lockout (admin account disabled after N failures)?
8. What happens when RequestThrottler is bypassed?
