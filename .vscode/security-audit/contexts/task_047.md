# Task 047: HTTP Cron Trigger Security
## Target: pub/cron.php
## Risk: Remote cron via HTTP GET without auth
## Key: escapeshellarg on GET params, .htaccess blocks access, check nginx too
## Questions: Is blocking effective? Can params influence cron jobs?
