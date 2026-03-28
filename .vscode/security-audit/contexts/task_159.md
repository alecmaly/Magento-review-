# Validation Context: H-007 IP Spoofing Bypasses Rate Limiting

## Finding to Validate
- ID: H-007, Severity: high, Confidence: 0.95, Discovered by: task_157

## Key Claims to Verify
1. RemoteAddress::getRemoteAddress() reads X-Forwarded-For by default
2. CAPTCHA uses RemoteAddress for per-IP counting
3. RequestThrottler uses RemoteAddress for backpressure
4. No WAF/proxy header stripping in default config

## Files to Read
- lib/internal/Magento/Framework/HTTP/PhpEnvironment/RemoteAddress.php
- nginx.conf.sample - check X-Forwarded-For handling

## Critical Question
Does nginx.conf.sample set proxy_set_header X-Forwarded-For? If yes, severity should be downgraded.
