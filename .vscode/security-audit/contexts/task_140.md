# Task 140: RemoteAddress IP Spoofing Consumer Analysis
RemoteAddress trusts X-Forwarded-For without proxy validation. Finding M-018.
Key files: RemoteAddress.php, app/etc/di.xml:2043-2049.
Investigate all DI injections of RemoteAddress for security-relevant IP decisions.
