# Context: Coupon Per-Customer Usage Race Condition (task_118)

## Parent Finding: M-014

TOCTOU between validation and increment. Validation in Utility::canProcessRule() reads
ruleCustomer.times_used WITHOUT lock. Increment in Processor::updateCustomerRuleUsages()
does read-modify-write WITHOUT lock. Coupon-level lock exists but only covers coupon.times_used.

Key files: SalesRule/Model/Utility.php, Coupon/Usage/Processor.php, ValidateCoupon.php,
CouponUsagesIncrement.php, CouponUsagesDecrement.php, CouponUsagePublisher.php.
Check: async publisher races, LockManager implementation, cartMutex scope.
