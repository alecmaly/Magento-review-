# Task 099: @noEscape Stored XSS

attribute.phtml:53 uses @noEscape. productAttribute() escapes only when is_html_allowed_on_front=false. Default HTML-allowed: description, short_description.

Investigate: Admin-only? MaliciousCode filter gap. compare/list.phtml:132 same. Customer-controlled paths.