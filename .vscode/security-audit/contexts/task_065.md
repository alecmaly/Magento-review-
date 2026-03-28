# Context: CMS, Email Templates & Template Directive Injection

## Modules: Cms, CmsGraphQl, Widget, Newsletter, Variable, Email

## Entry Points
### Frontend: Cms/Controller/Page/View.php, Router.php, Noroute/Index.php
### Admin: Cms/Controller/Adminhtml/Page/Save.php, Block/Save.php, Wysiwyg/Directive.php

## Security Concerns
1. Template directive injection: {{config path="..."}} reads config; {{block class="..."}} instantiates classes
2. WYSIWYG directive processing: server-side image/link directives
3. Email template injection: user data (name, address) in transactional emails
4. Newsletter template SSTI: user-supplied data reaching template processor
5. Widget configuration injection: widget params from DB rendered in HTML
6. CMS Router open redirect
