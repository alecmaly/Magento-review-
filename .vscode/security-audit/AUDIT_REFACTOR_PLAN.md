# Audit Loop Refactor Plan

Last updated: 2026-03-28

## Problems This Fixes

1. **Framework detection is hardcoded** — audit tool has no Magento support; grep-based pre-analysis found only 4 of ~1000+ entry points
2. **Entry points and sinks were never validated** — all 502 were bulk-accepted from unvalidated grep candidates; actual data flow never confirmed
3. **function_overrides.json silently drops unmatched IDs** — no warning when a confirmed function isn't in the scanned index; `add_function` must be called first for those
4. **Chain tracking is lossy** — chains embedded as fields on findings, decided on partial context, never verified computationally, broken references exist, no re-sweep when new findings are added
5. **Architecture scanning was prescriptive** — instructions told the LLM which files to read instead of letting it explore and reason independently

---

## Phase 0 — Architecture and Framework Reconnaissance (NEW, runs first)

### Task 0.1 — Codebase Exploration and Framework Identification

**The LLM explores the codebase freely.** No prescribed files, no prescribed tools. The LLM looks at whatever it needs to understand:

- What technology stack is this?
- How does an HTTP request get dispatched to code?
- What does an entry point look like in this codebase?
- What does a sink (database, command, deserialization, file write) look like in this codebase's idiom?
- What does the dependency injection / service container look like?
- What ORM or query layer is used?

**Required output** (written to `architecture_overview.md`):
```
Framework: <name and version>
Entry point pattern: <how HTTP/CLI/queue requests reach code — class hierarchy, interface, convention>
Sink patterns:
  - Database: <what SQL execution looks like in this codebase>
  - Deserialization: <what deserialization looks like>
  - Command execution: <what shell calls look like>
  - File write: <what file writes look like>
  - Network: <what outbound HTTP looks like>
Routing mechanism: <how routes map to code>
Auth mechanism: <how authentication is enforced>
DI/IoC pattern: <how dependencies are resolved>
Interesting security surface: <any codebase-specific patterns worth scanning>
```

The LLM must write this before any vulnerability analysis task runs. If it cannot determine something, it writes "unknown — needs investigation" and spawns a follow-up task.

### Task 0.2 — Entry Point Enumeration (LLM-driven, framework-aware)

Using the understanding from 0.1, the LLM searches for actual entry points. It knows what they look like in this specific codebase, so it searches for those patterns — not patterns from a pre-baked catalog.

For each candidate entry point found:
1. Read the function body
2. Confirm: does untrusted external input arrive at this function? (HTTP request body, query param, header, CLI arg, queue message body — whatever is external for this framework)
3. If yes → validated entry point
4. If no → reject it, note why

### Task 0.3 — Sink Enumeration (LLM-driven, framework-aware)

Using the understanding from 0.1, the LLM searches for dangerous operations in this codebase's specific idiom.

For each candidate sink found:
1. Read the function body
2. Confirm: does this function execute the dangerous operation (SQL, command, deserialization, file write, etc.)?
3. Confirm: is at least one parameter to the dangerous operation not sanitized/escaped at the point of call?
4. If both yes → validated sink
5. If no → reject, note why

---

## Phase 1 — Registering Validated Entry Points and Sinks

### The Index-Match Check (mandatory before every confirm)

Before calling `discover_attack_surface(confirm={...})` for any function:

```
1. Call search(query="<function_name>") to check if it exists in the scanned index
2. IF FOUND:
     - Record the exact function_id from the result
     - Proceed to confirm
3. IF NOT FOUND:
     - The scanner did not index this function
     - Read the source file to confirm name, file path, line number
     - Call add_function(name, file, line, parameters=[...])
     - For each caller of this function (find via grep):
         Call add_relationship(caller_id, this_function_id)
     - For each sink this function calls:
         Call add_relationship(this_function_id, sink_id)
     - NOW confirm — the function is in the index
```

Never write a function ID to `function_overrides.json` that hasn't been verified to exist in-memory first. The silence in `reapplyOverridesToMerged` when a function is missing means bad IDs are invisible.

### What "Validated" Means — The Standard

**Entry point validated** = LLM has read the function body and confirmed:
- The function is reachable from an external trigger (HTTP, CLI, queue, cron)
- At least one parameter or accessible property at execution time contains data from the external request without sanitization applied before this function

**Sink validated** = LLM has read the function body and confirmed:
- The function executes a dangerous operation
- At least one argument to that dangerous operation is a function parameter or property that static analysis shows as tainted OR that the LLM confirms is not always sanitized

Do not call `discover_attack_surface(confirm=...)` until both checks pass per entry.

---

## Phase 2 — Chain Tracking Refactor

### Problem with Current Approach

`chains_with` is a field on each finding, populated by the LLM during whatever iteration it happened to have both findings in context. Issues:
- Broken references exist (9 confirmed: IDs referencing non-existent strings like "session_hijacking")
- LLM never reads all 155 findings at once (~141K tokens total)
- No re-sweep when new findings are added
- No computational validation — chains are asserted, not verified

### New Structure: `chains.json`

Separate file. Each chain is a first-class object:

```json
{
  "chains": [
    {
      "id": "CHAIN-001",
      "title": "Account Takeover via Email Change + Password Reset",
      "severity": "high",
      "steps": ["M-013", "H-005"],
      "step_descriptions": [
        "M-013: unauthenticated email change request",
        "H-005: password reset to changed email completes takeover"
      ],
      "preconditions": "attacker knows victim email address",
      "call_graph_path_validated": false,
      "path_trace": null,
      "notes": "Confirmed via dynamic test"
    }
  ]
}
```

The `chains_with` field on individual findings stays for display but is not the authoritative record.

### Mandatory Chain Re-Sweep Task

Triggers after: every 15 new findings added, or at start of final report phase.

Task reads a **summary-only view** of all findings (id, severity, title — ~10K tokens, not 140K) and:
1. Checks every HIGH/CRITICAL for missing chain coverage
2. Checks all findings added since last sweep against all HIGH/CRITICAL for new chain potential
3. Checks for broken references in existing `chains_with` fields
4. Writes new chains to `chains.json`

### Call Graph Chain Validation

For any chain where both findings have known function IDs:
- Call `find_path(from=entry_function_of_A, to=sink_function_of_B)` via MCP
- If path exists: set `call_graph_path_validated: true` in `chains.json`
- If no path: note explicitly — inter-process chains (A writes to Redis, B reads from Redis in a separate request) will legitimately have no single call graph path

---

## Phase 3 — Audit Loop Prompt Instructions to Add

### On architecture exploration:
> At the start of every new project audit, explore the codebase to understand it. You decide what to look at — use whatever files, patterns, and tools help you understand how this specific codebase works. Do not rely on assumptions about the framework or apply a generic checklist. Write what you find to `architecture_overview.md` before writing any findings.

### On entry point and sink discovery:
> When identifying entry points and sinks, use your understanding of this specific codebase from the architecture exploration phase. After identifying a candidate, read its code before marking it confirmed. A grep match is a lead, not a confirmation.

### On confirming via MCP:
> Before calling `discover_attack_surface(confirm={...})` for any function:
> 1. Call `search()` to verify the function exists in the scanned index
> 2. If not found, call `add_function()` first, then `add_relationship()` for its callers and callees
> 3. Only then confirm the decorator
> Silent failures in `function_overrides.json` are not reported — skipping this check means path-tracing will silently return empty results for that function.

### On chain tracking:
> When two findings chain, write the chain to `chains.json` as a named chain object with both finding IDs, preconditions, and whether the call graph path was validated. At the start of the final report task, read the summary view of all findings and do a complete chain re-sweep before writing conclusions.

---

## Open Items for MCP Tool Improvements (tracked separately in claude-context-helper)

- Add Magento to `PACKAGE_FRAMEWORK_MAP` in `framework-detection.ts`
- Add Magento controller `execute()` entry point pattern to `ENTRY_POINT_PATTERNS`
- Add `find_chains(finding_a_id, finding_b_id)` tool that uses call graph to validate a chain
- `reapplyOverridesToMerged` should return unmatched IDs instead of silently dropping them
- `discover_attack_surface(confirm=...)` response should report count of IDs not found in function map

---

## Amendment: Chain Detection Reliability (added 2026-03-28)

The plan above is insufficient. Both `find_chains` call graph validation and LLM-remembered re-sweeps are unreliable:

### Why find_chains is not trustworthy as a gate
- Path exists ≠ exploitable (taint must flow)
- Path missing ≠ no chain (inter-process chains via Redis/session/DB/queue have no call graph path)
- Call graph is already incomplete due to dynamic dispatch and framework routing

### Why LLM-remembered chain updates fail
- LLM is stateless between context windows — finding #150 doesn't trigger re-reading the 149 prior findings
- Rolling audit_context.md summary is lossy — each meta-reprioritization compresses prior chain knowledge
- No enforcement: a finding can be written without any chain check happening

### Reliable Design: Remove LLM Memory as a Dependency

**Rule: the main audit task never writes to chains.json. Only the chain-check subtask does.**

**Trigger (deterministic, not a reminder):**
Every time a finding is written with severity >= medium, the audit loop immediately spawns:

```
chain_check_task(
  new_finding = <full detail>,
  compare_against = <full detail of all HIGH/CRITICAL findings>
                  + <id + title + one-line summary of all MEDIUM findings>
)
```

The chain-check task asks: does this new finding enable any of those, or do any of those enable this? It writes any new chains to chains.json as named objects. It does not rely on prior audit context.

**find_path is corroborating evidence, not a gate:**
The chain-check task calls find_path as one input. A chain with no call graph path is still valid if the LLM explains the inter-process mechanism (session, Redis, DB row, queue). A chain with a call graph path but no clear taint flow is flagged unconfirmed. Both pieces of evidence are recorded in chains.json.

**End-of-audit NxM cross-check:**
Before writing the final report, a dedicated task reads ALL HIGH/CRITICAL findings in full (small enough to fit — typically <10 findings), plus titles+summaries of all MEDIUMs, and does an exhaustive pairwise check. This is the only complete sweep; it catches anything the per-finding triggers missed.

**chains.json schema addition:**
```json
{
  "id": "CHAIN-001",
  "detected_by": "chain_check_subtask",       // or "end_of_audit_sweep"
  "call_graph_path_found": true,               // find_path result
  "inter_process_mechanism": null,             // "session" / "redis" / "db" / null
  "llm_reasoning": "M-013 changes email; H-005 sends reset to new email...",
  "confidence": "high"                         // high/medium/low
}
```
