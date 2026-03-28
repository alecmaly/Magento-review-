# Task 097: Template Directive SSTI

Key: Filter/Template.php, LegacyDirective.php (reflection dispatch), VarDirective.php, TemplateDirective.php

Investigate: Can non-admin users inject directives? What methods does reflection expose? Can {{template}} load arbitrary files? Can VariableResolver traverse to sensitive objects?