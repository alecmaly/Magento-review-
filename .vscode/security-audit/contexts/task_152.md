# Task 152: UI Component Render ACL Bypass
AbstractAction._isAllowed() returns true. Render checks aclResource from DataProvider but only 42/113 components define it.
Key: Ui/Controller/Adminhtml/AbstractAction.php, Render.php validateAclResource()
