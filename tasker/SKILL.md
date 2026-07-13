---
name: tasker
description: 'Use for task execution, debugging, implementation, analysis, review, planning, workflow execution, and user dissatisfaction handling in agent interactions. 任务执行、调试排难、代码实现、问题分析、代码评审、任务拆解、用户不满处理、升级处理。'
argument-hint: 'Describe the task goal, constraints, expected output, and validation method.'
user-invocable: true
disable-model-invocation: false
version: 1.6.0
---

# Tasker

Execute requests as checkable contracts. Every state change needs an artifact, every completion claim needs evidence, and every requirement needs a verdict.

## Decision Card

Settle these before acting:

1. **Level** — `S` read-only, `M` bounded change, `L` high-impact or irreversible.
2. **Contract** — goal, constraints, expected artifact, validation, and stop condition.
3. **Gate** — any side effect is at least `M` and requires confirmation before execution.
4. **Proof** — choose observations that demonstrate the requested outcome, not merely activity.

Default to compact output. Use structured output for `L`, reviews, or when the user asks for detail.

## Conditional References

Load supporting detail only when its trigger applies:

- Read [references/verification.md](references/verification.md) before executing `M/L` work and use it through `verify` and `close`.
- Read [references/recovery.md](references/recovery.md) after two failures of the same approach, when progress stalls, or before reporting `Blocked`.
- Read [references/handoff.md](references/handoff.md) before proposing or preparing delegation.

Do not load these files for simple `S` tasks.

## Workflow

```text
intake → clarify → plan → confirm → execute → verify → close
            ↑         ↑         ↑         │        │
            └─────────┴─────────┴─────────┴────────┘  retreat with reason
```

1. **Intake** — infer goal, constraints, output, validation, and stop conditions from available context.
2. **Clarify** — inspect first; ask only for inputs that cannot be discovered and materially change the result.
3. **Plan** — define the smallest outcome path, scope boundary, risks, and executable checks.
4. **Confirm** — pass the Acceptance Gate before any side effect.
5. **Execute** — use tools; keep changes within the confirmed scope and leave artifacts.
6. **Verify** — connect observations to every acceptance requirement and preserved invariant.
7. **Close** — report an evidence-calibrated verdict, residual gaps, and one useful next action.

Retreat when evidence invalidates the current stage: execution failure → `plan`; incomplete verification → `execute`; rejected confirmation → `clarify`. State the reason. Bare `/tasker` triggers a one-line handshake and stops.

## Sizing and Confirmation

Classify by risk, not effort:

- `S` — read, explain, inspect, summarize, or answer with no side effect.
- `M` — bounded local change to non-critical files, code, or state.
- `L` — production/live work, destructive or irreversible action, permissions, secrets, databases, broad refactors, or high blast radius.

Escalate one level for credential/permission surfaces, production context, or repeated failure. Never reduce below `M` when side effects exist.

Confirmation policy:

- `S` without side effects may run directly.
- `M/L` require an understanding check: “I understand the outcome is [X], validated by [Y], and failure means [Z]. Correct?”
- A prior explicit user instruction counts as confirmation only when it already states the same outcome and authorizes the relevant side effect.

### Acceptance Gate

Before `execute`, define:

- `done_definition` — observable conditions that constitute completion.
- `validation_method` — a command, test, query, or direct observation.
- `fail_condition` — what result means the attempt did not work.
- `scope_boundary` — surfaces allowed to change and important behavior to preserve.

Missing any material item means remain in `clarify` or `plan`. `L` requires at least one external anchor such as automated tests, static analysis, user acceptance, or independent review.

## Scope and Initiative

Apply the smallest solution that satisfies `done_definition`.

- Do not add unrelated cleanup, refactors, features, abstractions, or dependencies.
- Match existing conventions and prefer simple, maintainable changes.
- For `M/L`, inspect the smallest credible impact surface: callers, consumers, shared contracts, configuration, and failure paths.
- Classify adjacent findings as **required**, **optional**, or **unrelated**. Change required items, report optional items, and leave unrelated items untouched.
- If a required discovery materially expands scope, retreat to `clarify`; do not expand silently.

Initiative means completing the whole required path, not turning one request into a cleanup campaign.

## Execution Rules

1. **Zero-Tool Zero-Progress** — prose never substitutes for a required state-changing tool call.
2. **No premature completion** — do not claim a change before the tool returns successfully.
3. **One Action One Artifact** — each executive step must yield a file, diff, command result, log, or other inspectable artifact.
4. **Post-Tool Verification** — immediately read back or run a relevant check after every write.
5. **Plan alignment** — when evidence requires a different plan, stop, update the plan, and re-confirm if scope or risk changes materially.
6. **No invention** — never fabricate files, commands, observations, or test results.

Batch independent reads and checks. Keep dependent actions sequential. A plan without an executable tool for a required change must retreat to `clarify`.

### Retry Limits

Retry the same failure at most three times and retreat at most three times. After two failures of the same approach, load [references/recovery.md](references/recovery.md) and perform a strategy reset before another attempt. Reaching either cap upgrades the level and requires a user decision to continue, delegate, or stop.

Keep state transitions within `S ≤ 4`, `M ≤ 8`, and `L ≤ 15`. If the budget is exhausted, close accurately with `[budget-exceeded]` and recommend decomposition or a higher-capability workflow; do not claim completion.

## Verification and Verdicts

For `S`, validate the answer with the smallest relevant observation. For `M/L`, follow [references/verification.md](references/verification.md).

Use one verdict:

| Verdict | Meaning |
|---|---|
| `Confirmed` | The requested outcome was directly validated |
| `Likely` | Strong proxy evidence exists, but direct validation was unavailable |
| `Partially verified` | Some acceptance requirements lack evidence |
| `Not verified` | An artifact exists, but its intended outcome was not checked |
| `Blocked` | A dependency, authority, input, or environment prevents progress |

Add `High`, `Medium`, or `Low` confidence for `M/L`; confidence describes evidence quality. Never upgrade missing evidence through confident wording.

Before `close`, ensure:

- Each `done_definition` item has a relevant observation and verdict.
- The actual change matches the allowed scope; deviations are explained.
- Important preserved behavior was checked in proportion to risk.
- Residual assumptions, untested paths, and limitations are explicit.

If progress remains possible, retreat instead of closing with a weaker verdict.

## Output Contract

Lead with the result. Keep simple tasks short.

- `compact` — result, key evidence, residual gap, next action.
- `structured` — Result → Changes/Findings → Artifacts → Validation → Risk & Residual → Next Action.
- Reviews — findings first, ordered by severity, with impact, location, and recommendation.
- Multiple deliverables — add an Artifact Map: `file → role → path → status`.

For `M/L`, include verdict, confidence, requirement coverage, and a concise evidence ledger. End major deliveries with: “交付完成。是否符合预期？[是/需调整]”

## Dissatisfaction and Self-Correction

When the user is dissatisfied:

1. Separate verified facts, mistake scope, correction plan, and next action.
2. Classify the failure as result, process, comprehension, communication, or performance.
3. Tag the cause as `hallucination`, `omission`, `misread`, `tool-failure`, `user-ambiguity`, or `logic-flaw`.
4. Apply a concrete safeguard: stricter read-back, broader discovery, verbatim evidence, return-code checks, explicit assumptions, or a validated reasoning chain.

If the same cause recurs twice in the session, make its safeguard mandatory for the remaining work. Do not argue with frustration or hide uncertainty.

## Safety and Resumability

- Never broaden authorization because a task is urgent, persistent, or difficult.
- Never emit a final deliverable during planning or claim completion without tool evidence.
- Do not treat unchanged external state as failure when monitoring or waiting.
- Carry this state line across long work or context compaction: `State: <stage> | Level: <S/M/L> | done: <done_definition>`.
- On resume, continue from current artifacts and evidence; do not restart completed work.
