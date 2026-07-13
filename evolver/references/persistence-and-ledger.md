# Persistence and Evolution Ledger

Use this reference when writing durable evolution artifacts or updating related audit/planning records.

## Persistence Boundary

Prefer existing repository conventions. Direct-mode persistence (explicit `$evolver`, a clear persistence request, or confirmation of an advisory proposal) is limited to directly relevant local, non-production artifacts such as:

- an established retrospective or continuous-improvement record;
- a focused regression test or check when the requested evolution includes implementation;
- authoritative documentation, project instructions, checklists, or planning gates;
- `docs/98_evolution/` only when no existing convention fits.

Implicit activation alone is not write authorization. In advisory mode, propose one artifact and guard, then wait for confirmation. Do not silently apply architecture, schema, permission, production, deployment, broad workflow, or external-system changes. Record the proposed action and route its execution through `$tasker` when it exceeds the request.

If one material uncertainty, write restriction, missing workspace, or source-of-truth conflict blocks persistence, do not write a speculative record. Return that single blocker; after confirmation, persist without repeating the retrospective.

## Placement Priority

1. Update an existing authoritative test, rule, checklist, gate, or evolution ledger.
2. Otherwise append one concise entry to `docs/98_evolution/evolution-ledger.md`.
3. Create a cycle detail file only for multi-cause, high-risk, or cross-component learning.

Suggested fallback:

```text
docs/98_evolution/
  evolution-ledger.md
  cycles/
    <date-or-cycle>-<topic>.md
```

Keep evolution records separate from audit reports. Link the source audit item rather than copying it.

## Minimum Ledger Schema

```markdown
| ID | Trigger/Evidence | Root Cause | Local Fix | Systemic Action | Guard Verification | Closure Level | Next Planning Input |
|---|---|---|---|---|---|---|---|
```

Entries must distinguish confirmed evidence from inference, link their source where practical, and remain concise. Avoid empty directory scaffolding for one low-risk lesson.

## Audit and Status Coordination

When an audit finding triggered evolution:

- update its status only after the relevant action is verified and document edits are in scope;
- distinguish `Fixed locally` from `Guarded against recurrence`;
- link deferred systemic work to the original finding and evidence;
- do not rewrite the audit's original observation to make the later action appear inevitable.

## Write Verification

After persistence:

1. read back the exact changed artifact;
2. confirm links and referenced IDs resolve;
3. ensure the statement matches the verified baseline and does not promote inference to fact;
4. run the guard or the narrowest relevant validation;
5. inspect the worktree for unintended changes;
6. report the actual path and proven closure level.

No write/read-back evidence means `未落盘`. No guard execution or proof means closure cannot exceed `Corrected` unless the evolution is purely a planning feed-forward with independently verified ownership and gate placement.
