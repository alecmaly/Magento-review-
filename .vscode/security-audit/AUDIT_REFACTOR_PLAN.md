# Audit Loop Refactor Plan
Last updated: 2026-03-28

---

## Problems This Fixes

From the Magento 2 audit post-mortem:

| # | Problem | Impact |
|---|---------|--------|
| 1 | Framework detection is hardcoded — Magento not in pattern catalog | Grep found 4 of ~1000+ entry points |
| 2 | Entry points and sinks bulk-accepted without validating data flow | 502 unvalidated candidates written; paths may be meaningless |
| 3 | `function_overrides.json` silently drops IDs not in scanned index | Decorated functions that don't exist in scan produce empty path results with no error |
| 4 | Architecture scanning was prescriptive — told which files to read | LLM applies generic checklist instead of understanding the specific codebase |
| 5 | Chain tracking relies on LLM memory across context windows | 9 broken chain references, retroactive chains missed, no re-sweep on new findings |
| 6 | Chain checks only covered HIGH/CRITICAL | Multiple LOW/INFO gadgets can chain to CRITICAL — severity is not a valid filter |

---

## Phase 0 — Architecture and Framework Reconnaissance

### Task 0.1 — Free-Form Codebase Exploration

The LLM explores the codebase to understand it. **No prescribed files, no prescribed tools.** The LLM decides what to look at — directory structure, dependency manifests, routing config, base classes, framework source, examples — whatever it needs to answer:

- What technology stack and framework is this?
- How does an external request (HTTP, CLI, queue, cron) get dispatched to application code?
- What does an entry point look like in this specific codebase? (class hierarchy, interface, naming convention, registration mechanism)
- What does each type of sink look like in this codebase's idiom? (DB queries via ORM vs raw adapter, deserialization via framework wrapper vs native, command execution, file writes, outbound HTTP)
- How is authentication enforced — at what layer, via what mechanism?
- How does dependency injection / service resolution work?
- Are there any codebase-specific patterns worth flagging as security surface? (eval, dynamic include, custom serializers, magic method chains, etc.)

**Required output — written to `architecture_overview.md` before any vulnerability task runs:**

```
Framework: <name and version>
Language: <language and runtime version>

Entry point pattern:
  <How requests reach code — base class/interface, method name convention,
   registration mechanism (XML, annotations, decorators, routing file, etc.)>

Sink patterns:
  Database:          <what executing a query looks like here>
  Deserialization:   <what deserializing untrusted data looks like here>
  Command execution: <what running a shell command looks like here>
  File write:        <what writing attacker-influenced files looks like here>
  Network (SSRF):    <what making outbound HTTP requests looks like here>
  Template/eval:     <what dynamic code evaluation looks like here>

Routing mechanism:  <how URLs map to entry point classes/functions>
Auth mechanism:     <how the framework enforces authentication>
DI/IoC pattern:     <how dependencies are resolved at runtime>

Notable security surface:
  <Any codebase-specific patterns that don't fit standard categories but
   are worth scanning — custom magic method usage, plugin/observer hooks,
   dynamic dispatch patterns, etc.>

Coverage gaps:
  <Anything the LLM could not determine — note it here and spawn a follow-up task>
```

If any field cannot be determined, write "unknown — investigation needed" and spawn a follow-up task. Do not leave it blank or skip it.

---

## Phase 1 — Entry Point and Sink Enumeration

### Task 1.1 — Entry Point Discovery (LLM-driven, framework-aware)

Using the architecture understanding from Phase 0, search for actual entry points in this codebase. The search strategy comes from what was learned — not from a pre-baked catalog.

For each candidate:
1. Read the function body
2. Confirm: does untrusted external input (HTTP param, request body, header, CLI arg, queue message, uploaded file, environment variable) arrive at this function without sanitization applied before it?
3. **Yes → validated entry point.** Record the exact function ID (`name,/abs/path#line`).
4. **No → reject.** Note why (input is always sanitized before here, function is internal-only, etc.)

### Task 1.2 — Sink Enumeration (LLM-driven, framework-aware)

Using the architecture understanding from Phase 0, search for dangerous operations in this codebase's specific idiom.

For each candidate:
1. Read the function body
2. Confirm: does this function execute the dangerous operation (SQL execution, deserialization, shell command, file write, outbound network call, eval)?
3. Confirm: is at least one parameter to that dangerous operation a function parameter or accessible property that is not always sanitized at the point of call?
4. **Both yes → validated sink.** Record the exact function ID.
5. **Either no → reject.** Note why.

### What "Validated" Means — The Standard

> **Entry point validated** = LLM has read the function body and confirmed: (1) the function is reachable from an external trigger, AND (2) at least one parameter or accessible property at execution time contains data from the external request without sanitization applied before this function.
>
> **Sink validated** = LLM has read the function body and confirmed: (1) the function executes a dangerous operation, AND (2) at least one argument to that operation is a function parameter or property that is not always sanitized.
>
> A grep match, a pattern catalog match, or a pre-analysis suggestion is a **lead, not a confirmation.** Do not confirm until both criteria are met.

---

## Phase 2 — Registering Validated Entries and Sinks

### The Index-Match Check (mandatory before every `confirm`)

Before calling `discover_attack_surface(confirm={...})` for any function:

```
Step 1: Call search(query="<function_name>") to check if the function
        exists in the scanned index.

Step 2a — FOUND:
  Record the exact function_id returned.
  Proceed to confirm.

Step 2b — NOT FOUND (scanner did not index this function):
  Read the source file to confirm the function exists, its exact path, and line number.
  Call add_function(name=..., file=..., line=..., parameters=[...])
  For each caller of this function (find via grep in source):
    Call add_relationship(caller_id, this_function_id)
  For each sink this function directly calls:
    Call add_relationship(this_function_id, sink_id)
  NOW proceed to confirm.
```

**Why this matters:** `reapplyOverridesToMerged` silently skips any function ID not in the in-memory map — no error, no warning, no count. The confirm response says "502 applied" even if 200 don't exist. `paths_to_sinks` and `paths_from_entries` will return empty results for those functions with no indication of why. The index-match check eliminates this class of silent failure.

---

## Phase 3 — Chain Detection

### Core Design Principle

**LLM memory cannot be the enforcement mechanism for chain completeness.** The LLM is stateless between context windows. If chain detection depends on the LLM remembering to check chains when a new finding is added, chains will be missed — this is not a reliability concern, it is a certainty.

The design removes LLM memory as a dependency by making chain detection event-driven.

### The Attack Primitives Index

Every finding, when first written, must also populate a compact entry in `attack_primitives.json`:

```json
{
  "id": "M-017",
  "severity": "medium",
  "title": "Unauthenticated Address File Upload",
  "gives": "unauthenticated file write to pub/media/customer_address/ if store has file-type address attribute",
  "requires": "store has at least one file-type custom address attribute configured"
}
```

- `gives` — what capability or information the attacker gains if they exploit this finding
- `requires` — what precondition must be true (attacker role, prior exploitation step, configuration state, etc.)

This is the same mental model a human attacker uses: *"what does this give me, and what do I need to use it?"*

**Scale:** ~30-40 tokens per finding. All 155 current findings as primitives = ~12,000 tokens — fits in a single context alongside a new finding's full detail. The index stays compact as finding count grows.

### On-Write Chain-Check Trigger (deterministic, not a reminder)

Every time a finding is written at **any severity**, the audit loop immediately spawns a dedicated chain-check subtask:

```
chain_check_task(
  new_finding        = <full detail of the new finding including its gives/requires>,
  all_primitives     = <complete attack_primitives.json — id, severity, title, gives, requires
                        for ALL existing findings>
)
```

The task:
1. Scans all primitives: does any existing finding's `gives` satisfy the new finding's `requires`? Does the new finding's `gives` satisfy any existing finding's `requires`?
2. For each matched pair: reads full detail of both findings, reasons about exploitability
3. Writes confirmed chains to `chains.json`

Severity is **not** a filter. A LOW gadget chains with another LOW gadget chains with an INFO finding to produce a CRITICAL chain — checking only HIGH/CRITICAL misses this entirely.

### Call Graph Validation — Corroborating Evidence, Not a Gate

For chains where both findings have known function IDs:
- Call `find_path(A_entry_function, B_sink_function)`
- Path found → strong corroboration, record `call_graph_path_found: true`
- Path not found → does not invalidate the chain — inter-process chains (A writes to session/Redis/DB/queue, B reads it in a separate request lifecycle) have no call graph path by design. Record the inter-process mechanism explicitly.

A chain is valid when the LLM can explain the mechanism. Call graph agreement is supporting evidence; its absence is not a rejection.

### chains.json — Authoritative Chain Record

The main audit loop **never writes to chains.json directly.** Only the chain-check subtask appends to it. This ensures every chain has a traceable origin.

```json
{
  "chains": [
    {
      "id": "CHAIN-001",
      "title": "Account Takeover via Email Change + Password Reset",
      "severity": "high",
      "steps": ["M-013", "H-005"],
      "step_descriptions": [
        "M-013: unauthenticated email change sets victim email to attacker-controlled value",
        "H-005: password reset link sent to the now-attacker-controlled email"
      ],
      "preconditions": "attacker knows victim email address",
      "severity_upgrade": "M-013 alone is MEDIUM; chain with H-005 enables full ATO — HIGH",
      "call_graph_path_found": false,
      "inter_process_mechanism": "database — email change persisted, reset reads persisted value",
      "detected_by": "chain_check_subtask at finding H-005",
      "confidence": "high",
      "llm_reasoning": "M-013 gives the ability to change a victim's email without auth. H-005 requires the attacker to receive a password reset link. M-013's gives satisfies H-005's requires directly.",
      "dynamically_confirmed": true
    }
  ]
}
```

### chains_with Field on Findings

The `chains_with` field on individual findings is kept for display and backward compatibility but is **not the authoritative record**. `chains.json` is. The field may be derived/populated from chains.json at report time.

### End-of-Audit Full Cross-Check

Before writing the final report, a dedicated task:
1. Reads `attack_primitives.json` in full
2. Does an exhaustive pairwise comparison across all findings
3. For any pair not already in `chains.json`: checks if a chain exists
4. Also checks for broken `chains_with` references (IDs that don't exist in findings.json)
5. Updates chains.json with anything the per-finding triggers missed

This is the completeness backstop. It catches chains that were missed because a finding's primitive was initially written too narrowly and later revised, or because both findings in a chain were added before the trigger system was in place.

---

## Audit Loop Prompt Instructions

These must be in the audit loop system prompt, not config:

### Architecture exploration:
> At the start of every new project audit, explore the codebase to understand it. You decide what to look at. Do not rely on assumptions about the framework or apply a generic checklist. Write your findings to `architecture_overview.md` — including what you could not determine — before writing any vulnerability findings.

### Entry point and sink discovery:
> Use your architecture understanding to search for entry points and sinks as they exist in this specific codebase. After identifying a candidate, read its code before marking it confirmed. A grep match or pattern catalog suggestion is a lead, not a confirmation. Do not confirm until you have verified data flow.

### Registering with MCP:
> Before calling `discover_attack_surface(confirm={...})` for any function:
> 1. Call `search()` to verify the function exists in the scanned index
> 2. If not found: call `add_function()` then `add_relationship()` for callers and callees, then confirm
> Silent failures in function_overrides.json are not reported. Skipping this check means path-tracing returns empty results for that function with no error.

### Chain detection:
> When you write any finding, also write its attack primitive (gives/requires) to `attack_primitives.json`. You do not decide whether to check for chains — the chain-check subtask is spawned automatically and handles it. Do not write directly to `chains.json`. Your job is to write accurate gives/requires fields so the chain-check task has the information it needs.

---

## New Files in Audit Directory

| File | Purpose |
|------|---------|
| `architecture_overview.md` | Framework, entry point pattern, sink patterns — written in Phase 0 |
| `attack_primitives.json` | Compact gives/requires per finding — one entry per finding at any severity |
| `chains.json` | Authoritative chain records — written only by chain-check subtask |

---

## MCP Tool Improvements Needed (claude-context-helper repo)

| Item | Why |
|------|-----|
| Add Magento to `PACKAGE_FRAMEWORK_MAP` | Framework detection phase currently misses it entirely |
| Add Magento `execute()` controller pattern to `ENTRY_POINT_PATTERNS` | ~1000 controllers invisible to pattern-based discovery |
| `reapplyOverridesToMerged` should return unmatched IDs | Silent drops make debugging impossible |
| `discover_attack_surface(confirm=...)` should report unmatched count | Currently reports "502 applied" even if many don't exist in function map |
| Add `find_chains(finding_a_id, finding_b_id)` tool | Wraps find_path with chain-specific output including inter-process gap detection |
