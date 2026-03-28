# Task 149: Creditmemo Adjustment Edge Cases

## Key Files
- Sales/Model/Order/Creditmemo.php:542-555 - setAdjustmentAmount()
- Sales/Model/Order/CreditmemoFactory.php:350-369 - parseAdjustmentAmount()
- Sales/Model/Order/Creditmemo/Total/Grand.php:14-35 - Grand total calc

## Flow
1. Admin POST creditmemo adjustment_positive and adjustment_negative
2. CreditmemoFactory parseAdjustmentAmount -> parseNumber -> preserves percent sign
3. setAdjustmentAmount checks substr percent then multiplies by order GrandTotal/100
4. Grand.php adds positive and subtracts negative from grandTotal
5. isValidGrandTotal rejects grandTotal <= 0

## Questions
1. Can percentage > 100 inflate refund above order value?
2. Can negative adjustment_positive reduce refund below items+shipping?
3. REST API creditmemo path - different validation?
4. BaseToOrderRate at line 552 - zero or negative rate?
