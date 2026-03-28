# Task 124: Symlink Handling in Magento File Operations

## Key Insight
getRealPathSafety() does NOT call PHP realpath(). It normalizes paths but does NOT resolve symlinks.
A symlink in media/ pointing to /etc/passwd would pass PathValidator checks.

## Investigation Points
1. Can TAR archives create symlink entries?
2. Does image resize follow symlinks?
3. Media sync symlink handling?
