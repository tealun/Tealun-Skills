---
name: evolver
description: "Turn verified fixes, audit findings, delivery lessons, repeated user corrections, releases, incidents, and project retrospectives into durable regression guards, planning gates, documentation or engineering rules, skill refinements, and next-cycle inputs. Use automatically after a completed work cycle when credible recurrence risk or a systemic lesson may justify follow-up, or when the user invokes $evolver, asks to close the PDCA loop, prevent recurrence, institutionalize a lesson, or improve future work. On implicit activation, silently exit when no durable action is worthwhile; when one is worthwhile, present a compact persistence proposal and wait for the user's choice. Persist safe local evolution records directly when the user explicitly invokes or requests persistence. Do not use for unresolved symptoms or broad discovery audits."
---

# Evolver

Close the Act stage of PDCA. Convert verified evidence from a completed cycle into the smallest durable guard that would prevent or expose the same failure class earlier.

A local fix removes today's symptom; evolution changes tomorrow's default. Do not manufacture process for a one-off issue or institutionalize an unproven diagnosis.

## Conditional References

- Read [references/evolution-method.md](references/evolution-method.md) when classifying failed controls, selecting systemic actions, maintaining evolution ledgers, or handling multi-cause lessons.
- Read [references/persistence-and-ledger.md](references/persistence-and-ledger.md) before creating or updating evolution artifacts, planning gates, audit statuses, project rules, or detailed cycle records.

For a small lesson with one obvious guard, use the core workflow without loading both references.

## Invocation Modes

Determine the mode from the user's message, not merely from the fact that the skill was loaded.

### Direct mode

Use direct mode when the user:

- invokes `$evolver`;
- explicitly asks to close and persist the loop;
- asks to固化、落盘、沉淀、更新规则/测试/文档/技能, or otherwise clearly requests the durable action.

Direct mode authorizes safe local persistence within the boundary below. Execute without another confirmation unless the selected action changes architecture, schema, permissions, production/deployment state, external systems, or other material product behavior.

### Advisory mode

Use advisory mode when Evolver was selected implicitly after completed work and the user did not request persistence.

Evaluate internally whether all are true:

1. the lesson and local outcome have concrete evidence;
2. recurrence is credible, not merely imaginable;
3. a specific guard can catch the failure earlier;
4. an authoritative artifact or owner exists;
5. the expected value exceeds the maintenance and process cost.

If any condition fails, exit silently: do not write, ask, or add an Evolver section to the user's response.

If all conditions pass, do not write yet. Present only:

```text
闭环建议：<verified lesson and recurrence risk>
落盘建议：<one guard + intended artifact/path>
确认：是否执行？（是 / 否）
```

Treat “是” or an equivalent confirmation as direct mode and persist immediately. Treat refusal as final; do not re-raise the same proposal unless new evidence materially changes it.

## Operating Boundary

Use only after concrete evidence exists from a verified fix, audit, release, incident, accepted user correction, or completed delivery cycle.

Do:

- identify the ineffective control that allowed the issue to survive;
- choose the earliest reliable and proportionate prevention or detection point;
- update a directly relevant test, gate, authoritative document, rule, or skill when authorized;
- verify that the new guard catches the target failure class;
- feed unresolved or generalizable constraints into `$planner`.

Do not:

- diagnose an unresolved symptom—route it to `$bugfixer`;
- perform broad risk discovery—route it to `$auditor`;
- replace bounded implementation—use `$tasker`;
- auto-apply architecture, schema, permission, production, deployment, or broad code changes;
- claim closure merely because a retrospective document exists.

## Entry Gate

Establish:

- `trigger` — completed fix, finding, release, incident, correction, or workflow failure;
- `evidence` — diff, test, audit item, log, screenshot, acceptance result, or outcome;
- `local_fix_status` — verified, partially verified, unresolved, or not applicable;
- `affected_path` — product or engineering path that failed;
- `recurrence_risk` — credible condition under which the failure could recur.

Separate `Confirmed`, `Inference`, and `Unknown`. Never persist an inference as a confirmed root cause. If the local symptom should be fixed but is not verified, stop evolution and route the work to `$bugfixer` or `$tasker`.

The newest user correction invalidates affected learning and downstream actions. Replace any persisted wrong statement before continuing.

## Core Workflow

### 1. Reconstruct the lesson

State internally:

```text
Expected control or behavior:
Observed failure:
Verified local change:
Failed earlier control:
Credible recurrence condition:
```

Reject “test more,” “communicate better,” “be careful,” “human error,” or “AI error” as root causes. Name the missing or ineffective control.

### 2. Select one primary systemic action

Choose the lowest-cost action at the earliest reliable point:

1. **Prevent** invalid state through types, schema, permissions, constraints, or simpler architecture.
2. **Detect automatically** with regression/contract tests, CI checks, static rules, monitors, or migration checks.
3. **Gate explicitly** with a planning decision, acceptance rule, review gate, deploy checklist, or audit scope.
4. **Teach the system** through authoritative docs, project instructions, or a reusable skill.
5. **Track consciously** with owner, reason, evidence needed, and revisit condition when stronger action is disproportionate.

Prefer prevention and automatic detection over reminders. Add multiple layers only when consequence and recurrence risk justify them.

### 3. Define the action contract

For every action identify:

- authoritative artifact or execution surface;
- owner;
- protected invariant;
- observable guard verification;
- rollback/removal condition when relevant.

Preserve existing repository conventions and one source of truth. Ask for a decision only when evidence cannot safely determine architecture, schema, permissions, production behavior, or domain intent.

### 4. Apply within authorization

In direct mode, safe local persistence is limited to directly relevant non-production tests, documentation, checklists, planning gates, project rules, skills, or the established evolution ledger. Advisory mode must receive confirmation first. Use `$tasker` for broader implementation.

Every persistence claim requires an actual write and read-back verification. No verified write means `待确认` or `未落盘`, never `已落盘`. Do not commit, push, deploy, migrate, or contact external systems unless separately requested.

### 5. Prove both paths

Verify:

```text
original trigger → local fix → symptom no longer present
same failure class → new guard → prevented or detected earlier
```

Use a realistic regression case when possible. A document edit alone does not prove prevention, and a green build does not prove the guard detects the target failure.

Assign the highest proven level:

- `Corrected` — local symptom is verified fixed.
- `Guarded` — a repeatable control catches the same failure class.
- `Institutionalized` — guard, source of truth, and ownership align.
- `Fed forward` — the lesson is also linked into the next planning cycle.

The PDCA loop is closed only at `Institutionalized` or `Fed forward`.

### 6. Feed the next cycle

Route unresolved or generalizable lessons to `$planner` as a confirmed decision, assumption to verify, M0 spike, M1 acceptance gate, non-goal, protected invariant, or architecture/data/security/operations/compliance constraint. Do not leave durable lessons only in chat.

## Cross-Skill Loop

```text
planner → tasker → auditor → bugfixer → evolver
   ↑                                      |
   └──────────────────────────────────────┘
```

`evolver` may follow a successful release or process review directly when no defect exists.

## Output Contract

After persistence or a direct-mode closeout, return no more than five short lines:

```text
闭环：<Corrected | Guarded | Institutionalized | Fed forward>
结论：<one verified lesson>
改进：<highest-value systemic action or applied guard>
落盘：<已落盘 + path | 待确认 + one blocker | 未落盘 + reason>
待办：<only when a material action remains>
```

Omit `待办` when empty. In advisory mode, use only the three-line proposal from Invocation Modes; when evolution is not worthwhile, emit nothing. Keep detailed cards, taxonomies, and evidence walkthroughs internal or in the persisted artifact unless the user requests detail. Never claim closure without guard verification.
