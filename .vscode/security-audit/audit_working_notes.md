# Security Audit - Working Notes

> Investigation details, coverage tracking, and security questions.
> Read this file only for meta or report tasks.

## Active Prospect Queue

> Track active investigations. Each confirmed finding can spawn new prospects.
> Prospects are validated before becoming findings (prevents false positives).

| ID | Type | Source | Target | Depth | Status | Notes |
|----|------|--------|--------|-------|--------|-------|
<!-- P-001 | injection | H-001 | FunctionName | 1 | investigating | reason -->

**Status values:** `pending`, `investigating`, `validating`, `confirmed`, `dismissed`, `deferred`, `gadget`

### Queue Statistics

- Seeds processed: 0
- Total prospects: 0
- Confirmed: 0
- Dismissed: 0
- Current depth: 0
- Max depth limit: 3

## Investigation Threads

> Ongoing lines of investigation. Each thread tracks a family of related findings.

### Thread 1:
**Seed:**
**Spawned:**
**Depth:**
**Status:**

## Vulnerability Coverage Matrix

> Track what has been searched. Every class should be marked before audit completion.
> See `coverage-assurance` skill for full checklist with 65 vulnerability classes.

| Category | Total | Searched | Found | Not Found | N/A | Pending |
|----------|-------|----------|-------|-----------|-----|---------|
| Injection | 9 | 0 | 0 | 0 | 0 | 9 |
| XSS | 4 | 0 | 0 | 0 | 0 | 4 |
| Authentication | 7 | 0 | 0 | 0 | 0 | 7 |
| Authorization | 5 | 0 | 0 | 0 | 0 | 5 |
| Cryptography | 6 | 0 | 0 | 0 | 0 | 6 |
| SSRF | 4 | 0 | 0 | 0 | 0 | 4 |
| Deserialization | 3 | 0 | 0 | 0 | 0 | 3 |
| XML | 3 | 0 | 0 | 0 | 0 | 3 |
| File Operations | 5 | 0 | 0 | 0 | 0 | 5 |
| Race Conditions | 3 | 0 | 0 | 0 | 0 | 3 |
| Business Logic | 4 | 0 | 0 | 0 | 0 | 4 |
| Info Disclosure | 4 | 0 | 0 | 0 | 0 | 4 |
| Client-Side | 4 | 0 | 0 | 0 | 0 | 4 |
| Infrastructure | 4 | 0 | 0 | 0 | 0 | 4 |
| **TOTAL** | **65** | **0** | **0** | **0** | **0** | **65** |

## Audit Completeness Checklist

### Mandatory
- [ ] All 65 vulnerability classes marked (searched/n/a)
- [ ] All critical/high detector findings validated
- [ ] All critical call graph patterns reviewed
- [ ] Coverage matrix totals verified

### Recommended
- [ ] All entry points documented
- [ ] Idea generation rules applied for each finding
- [ ] Gadgets checked for chain potential
- [ ] Investigation threads closed or documented

### Security Questions
- [ ] All high-priority questions answered or converted to prospects
- [ ] Questions that led to findings linked to finding IDs
- [ ] Open questions documented with rationale for deferral
- [ ] Question statistics: ____ generated, ____ answered, ____ led to findings

### Tooling Gaps
- [ ] Missing relationships added to manual_function_relationship_map.json
- [ ] Missing decorators added to function_overrides.json
- [ ] Taint analysis gaps documented
- [ ] Tool improvement suggestions captured

### Sign-off
- Auditor:
- Date:
- Coverage: __/65 classes addressed
- Questions: ____ open (0 high priority)

## Security Questions Backlog

> Track investigative questions as they arise. These are "What if?" hypotheses that spawn from observations during the audit.
> Questions should be continuously generated based on context and checked off as investigated.

### Question Categories

| Tag | Meaning | Example |
|-----|---------|---------|
| `hypothesis` | "What if an attacker could X?" | What if the redirect URL validation is bypassable? |
| `verification` | "Does Y actually validate Z?" | Does this auth decorator actually check permissions? |
| `edge-case` | "What happens when input is X?" | What if the ID parameter is negative? |
| `trust-boundary` | "Is this caller actually trusted?" | Can this internal API be reached externally? |
| `race` | "Can these operations interleave?" | Can balance check and deduction race? |
| `data-flow` | "Where else does this data go?" | Does this tainted value reach other sinks? |
| `chain` | "Can X + Y combine for impact?" | Can SSRF + redirect chain to internal access? |

### Active Questions

| ID | Tag | Question | Context/Trigger | Priority | Status | Answer/Notes |
|----|-----|----------|-----------------|----------|--------|--------------|
<!-- Q-001 | hypothesis | What if X? | Found Y in file.py:123 | high | open | -->

**Status values:** `open` → `investigating` → `answered` (confirmed | false-lead | needs-context)

### Question Generation Triggers

As you audit, generate questions when you observe:

| Observation | Question to Ask |
|-------------|-----------------|
| Entry point with minimal validation | "What happens if I send malformed/malicious input here?" |
| Auth check only at controller level | "Are there other paths that bypass this controller?" |
| User-controlled data in file path | "Can I traverse to sensitive files?" |
| Multiple functions write same state | "Is there a race condition between these?" |
| Short path from entry to sink | "What validation exists between these?" |
| Hardcoded value that looks like a secret | "Is this actually sensitive? Is it used in prod?" |
| Error handler returns detailed info | "Can I trigger this error with controlled input?" |
| Commented-out security check | "Why was this disabled? Is it still needed?" |
| Dynamic dispatch/reflection | "What methods can actually be invoked here?" |
| Assumption in comments ("X is always Y") | "Can I violate this assumption?" |

### Answered Questions Archive

<!-- Move answered questions here for reference -->

| ID | Question | Answer | Finding (if any) |
|----|----------|--------|------------------|

---

## Tooling Gaps & Improvements

> Track issues with static analysis tooling discovered during the audit.
> These feed back into improving analysis for current and future audits.

### Missing Relationships (Dynamic Dispatch)

| Location | Pattern | Missing Link | Added to manual_function_relationship_map.json? |
|----------|---------|--------------|------------------------------------------------|
<!-- api/handler.py:45 | call_user_func | should link to actual_handler | yes -->

### Missing Decorators

| Function | Should Have | Reason | Added to function_overrides.json? |
|----------|-------------|--------|-----------------------------------|
<!-- handleRequest | 💥 | HTTP entry point | yes -->

### Taint Analysis Gaps

| Issue | Location | Description | Workaround |
|-------|----------|-------------|------------|
<!-- Missed flow through closure | utils.py:89 | Lambda captures tainted var | Manual trace -->

### Call Graph Gaps

| Issue | Description | Impact on Audit |
|-------|-------------|-----------------|
<!-- Missing edges for callbacks | Async callbacks not traced | May miss entry points -->

### Suggested Tooling Improvements

| Category | Suggestion | Rationale |
|----------|------------|-----------|
<!-- Detection | Add decorator for message handlers | Would auto-detect entry points in message-based systems -->

---

## Notes and Observations

<!-- Miscellaneous notes that don't fit elsewhere -->

---
*Last updated: [timestamp]*
