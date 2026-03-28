# Task 037 Context: Shell/Code Execution Evaluation

## Pre-analysis matches
- eval/exec/system/passthru: 45 files
- shell_exec/popen/proc_open: 35 files
- PHP file inclusion with variables: 324 files
- preg_replace /e modifier: 1 file (code execution)
- assert() with variable: 1 file

## Key areas
1. Template includes - are any user-influenced?
2. Deploy/Developer commands with shell execution
3. Extract() with user input: 1 file (variable overwrite)
4. preg_replace /e usage (deprecated, code execution)
