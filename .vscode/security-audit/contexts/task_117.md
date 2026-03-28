# Task 117: OrderMutex Coverage Gap
## Finding M-015
Operations WITH mutex: cancel, RefundInvoice, InvoiceOrder, ShipOrder, RefundOrder
Operations WITHOUT mutex: hold(), unHold(), addComment()
Key file: app/code/Magento/Sales/Model/Service/OrderService.php
Race: hold reads state=processing, cancel acquires mutex sets canceled, hold overwrites with holded.
