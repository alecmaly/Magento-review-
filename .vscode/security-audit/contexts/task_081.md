# Task 081: Customer Viewfile Path Traversal
Check: Adminhtml/Index/Viewfile.php, Adminhtml/Address/Viewfile.php
Key: mb_strpos($path, ..) check, urlDecoder->decode(), no frontend viewfile found
