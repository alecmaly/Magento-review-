# Task 125: File Content-Type Validation Gaps

## Investigation Points
1. Which upload paths validate file content (magic bytes) vs just extension?
2. Can polyglot files (GIF89a + PHP) pass validation?
3. X-Content-Type-Options: nosniff prevents MIME sniffing
4. media/ files served directly by web server
