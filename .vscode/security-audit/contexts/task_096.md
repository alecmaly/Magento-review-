# Task 096: DownloadCustomOption Secret Key IDOR

## Background
Sales/Controller/Download/DownloadCustomOption.php provides file downloads protected only by:
1. quote_item_option_id (integer, sequential)
2. secret_key (from serialized option value)
3. NO customer session check

Line 107 uses loose comparison: $this->getRequest()->getParam('key') != $info['secret_key']

## Key Questions
1. How is secret_key generated? Check product option file upload flow.
2. Is it CSPRNG or predictable?
3. Can quote_item_option IDs be enumerated?
4. Loose != comparison - any bypass on PHP 8.3+?
5. What types of files are downloadable via this endpoint?
6. Also check Wishlist/Controller/Index/DownloadCustomOption.php for same pattern.
