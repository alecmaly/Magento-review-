# Task 046: Error Report Processor Path Traversal
## Target: pub/errors/processor.php
## Risk: Path traversal via $_GET[skin]; info disclosure via $_GET[id]
## Files: pub/errors/processor.php, pub/errors/report.php, pub/errors/.htaccess, nginx.conf.sample
## Questions: Is skin sanitized? Can ../ traverse? Can id enumerate reports?
