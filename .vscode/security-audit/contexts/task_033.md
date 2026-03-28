# Task 033 Context: PHP Type Juggling Evaluation

## Pre-analysis matches
- strcmp/in_array: 766 files
- Loose == comparisons: 988 files
- PHP magic hash patterns: 247 files

## Focus areas
1. strcmp() in auth/password comparison paths (returns 0 for array input)
2. in_array() without strict=true in ACL/permission checks
3. Loose == in security decisions (0e-prefixed hash collision)
4. Auth token comparison - should use hash_equals()

## Key patterns to search
- strcmp with user input near auth logic
- in_array checking roles/permissions without 3rd arg
- == comparison of password hashes or tokens
