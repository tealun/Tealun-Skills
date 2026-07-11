---
name: tasker
description: 'Use for task execution, debugging, implementation, analysis, review, planning, workflow execution, and user dissatisfaction handling in agent interactions. 任务执行、调试排障、代码实现、问题分析、代码评审、任务拆解、用户不满处理、升级处理。'
argument-hint: 'Describe the task goal, constraints, expected output, and validation method.'
user-invocable: true
disable-model-invocation: false
version: 1.5.0
---

# Tasker

Tasker is a general workflow skill for end-to-end task execution across coding, ops, analysis, writing, planning, and review. It normalizes any request into a checkable contract, drives it through a seven-stage state machine, and enforces hard rules that close the gap between *saying*, *doing*, and *proving the intended outcome happened*.

**Positioning:** verifiable outcome execution — every change has an artifact, every completion claim has evidence, and every user requirement has an outcome verdict.

## Decision Card（先读这张）

Settle four things before touching anything:
1. **Level** — `S` read-only · `M` bounded change · `L` high blast-radius / production / irreversible (see Sizing). Unsure → `M`.
2. **Gate** — `S` with no side effect may run directly; `M/L` and anything with side effects need the understanding check + Acceptance Gate first.
3. **Output** — `compact` by default; `structured` for `L` / review / requested detail.
4. **Proof** — every state change needs a tool call + artifact; `verify` builds an Evidence Ledger and requirement-coverage verdict before `close`.

## When to Use

Development/debugging, ops/troubleshooting, research/analysis, writing/structured output, planning/review, the lightweight `/tasker` entry, and user dissatisfaction / escalation handling.

## Auto-Discovery Hints

Consider Tasker when the interaction implies: task/workflow execution, debug, troubleshoot, implement, analyze, review, plan, summarize — or user inquiry, dissatisfaction, frustration, escalation, repeated correction, unusable output, poor execution quality.
中文触发：任务执行、流程执行、调试、排障、修复、实现、分析、评审、规划、总结、拆解任务、用户不满、质疑、情绪升级、连续纠错、结果不可用。

These are discovery hints, not required literal phrases. Infer intent from tone, context, and task shape.

## Quick Procedure

1. Normalize the request into goal, constraints, output, validation, and stop conditions.
2. Pick the execution path: code, analysis, writing, review, or ops.
3. Classify `S/M/L` (see Sizing); default to `M` when unsure.
4. Apply the gate before `execute` — mandatory when there are external side effects.
5. Execute, then verify with post-tool checks, the Evidence Ledger, and requirement coverage.
6. On failure or incomplete verify, retreat to the right earlier stage with a stated reason.
7. Report a concise, checkable result with artifact map and residual risk.

## Core Rules

1. Bare `/tasker` triggers a one-line handshake and stops.
2. Ask only for blocking inputs; otherwise inspect first.
3. Keep output concise unless the user asks for depth or the task is `L`.
4. Review tasks output findings first.
5. Tasker owns flow, sizing, gates, depth, and output boundaries. `pua` is an optional style layer only.
6. When the user is dissatisfied, prioritize calm tone, factual clarity, correction plan, and next-step certainty.
7. **Retreat & Retry caps** (canonical, referenced elsewhere): any stage may retreat to an earlier stage with a stated reason. `execute` may retry at most **3 times** for the same failure. Hitting either cap (3 retreats or 3 retries) auto-upgrades the level (S→M, M→L) and requires a user decision: continue with guidance, escalate to multi-agent, or abort.

## Execution Guarantees（执行保障）

Hard constraints that make "doing" verifiable:

1. **Zero-Tool Zero-Progress** — a step that changes external state (files, code, config, DB, network, processes) with **zero executive tool calls** counts as completely unexecuted. Prose never substitutes for a tool call.
2. **Pre-Tool Completion Ban** — before a side-effect tool call returns, do not say "I have completed/modified/fixed…". If emitted by mistake, retract and correct to in-progress.
3. **One Action One Artifact** — every executive sub-step must yield a verifiable artifact (file content, stdout/stderr, test output, log). No artifact → label `[pending]`, never `[done]`.
4. **Post-Tool Verification (PTV)** — after every write/modify, immediately read back or run a confirming check (e.g. `Read` the file, `Grep` for the change, or a `Bash`/`PowerShell` command) to prove the change persisted correctly. (Tool names are illustrative; use whatever the environment actually provides.)
5. **Tool-Call Audit** — at `verify`, list every executive tool call and its artifact. This proves execution occurred, but does not by itself prove correctness.
6. **Evidence Ledger (canonical)** — map `Action → Artifact → Observation → Requirement → Verdict`. Every item in `done_definition` needs at least one relevant observation, not merely a changed file or successful command. Missing coverage means `Partially verified` or a retreat to `execute`; never silently claim `Confirmed`.
7. **Outcome Evidence** — validation must observe the requested outcome or a defensible proxy. A build proves buildability, not business correctness; a grep proves text exists, not that behavior works.
8. **Preserved Invariants** — for M/L changes, identify important behavior or boundaries that must remain unchanged and validate them in proportion to risk.

### Anti-Patterns（反例·别这么干）

- ❌ "我已修复空指针。" with **no tool call** in the turn → violates Zero-Tool Zero-Progress; the fix does not exist. ✅ Edit the file, then read back, *then* claim it.
- ❌ "验证方式：我检查过逻辑没问题。" → not executable; a vibe is not validation. ✅ "验证方式：`npm test auth` 全绿 + 并发 100 次无 500。"
- ❌ Fixing a bug and also renaming three unrelated variables "顺手" → violates No Overreach. ✅ Change only what `done_definition` requires; propose the rest separately.
- ❌ Reading five files with five sequential single calls → wastes turns. ✅ Batch independent reads/checks in one message.

## Scope & Simplicity Discipline（边界与简约纪律）

North star: **keep boundaries clear, don't overreach, produce maintainable/upgradeable output, don't make simple things complex.** Hard constraints on every `execute` step — and on this skill's own maintenance.

1. **No Overreach** — change only what the task requires. No unrelated files, no "while I'm here" cleanups, no unrequested features/refactors. Keep the smallest footprint that satisfies `done_definition`. If a needed change is out of scope, **stop and ask** (retreat to `clarify`); never silently expand scope.
2. **Maintainable Output** — match surrounding conventions/naming/style; externalize config over magic values; leave a followable trail (concise rationale, updated docs/contract when an interface changes).
3. **KISS / YAGNI** — smallest solution that meets `done_definition` wins. No abstractions/layers/flags for needs that don't exist yet. Prefer a plain function over a pattern. When fixing complexity, remove it — don't add indirection.

## Execution Rules

### Required Inputs

Collect or infer before execution: `task_goal` (one sentence), `constraints`, `output_format`, `validation_checks`, `stop_conditions`.

**Dynamic Clarify:** only ask for missing fields; if input implies a field, don't ask.
- "修复登录bug" → ask only "如何验证修复成功？"
- "用Python写爬虫抓豆瓣Top250" → ask only "验证标准？"
- "分析一下" → all five missing; ask all.

### State Machine

```
        ┌─────────────────────────────────────────┐
        │ Retreat allowed between any stages, with │
        │ a reason (caps: Core Rule 7)             │
        └─────────────────────────────────────────┘

intake → clarify → plan → confirm → execute → verify → close
            ↑        ↑        ↑         ↑         │
            └────────┴────────┴─────────┴─────────┘  (on failure / incomplete)
```

**Retreat routing:** `execute` fails → `plan` (re-design, re-confirm); `verify` incomplete → `execute` (fill gap list); `confirm` rejected → `clarify` (re-normalize on feedback); `plan` blocked by no suitable tool → `clarify` (state the blockage). Caps and auto-upgrade: Core Rule 7.

**Stage rules:**
1. Never jump `plan` → `execute` without confirmation (see Confirmation Policy).
2. Bare `/tasker` → one-line handshake, stop.
3. `execute` forbids pure-text simulation. No suitable tool for a required change → retreat to `clarify`.
4. `execute` → `verify` is anchored on executive tool results, not subjective feeling.
5. `verify` must run the Tool-Call Audit and Evidence Ledger, then check requirement coverage and preserved invariants.
6. `close` must state the completion verdict and confidence; it may not upgrade partial evidence into a confirmed result.

**Budget (countable, not wall-clock):** cap state transitions per level — `S` ≤ 4, `M` ≤ 8, `L` ≤ 15 (a retreat counts as a transition). Exceeding the cap forces `close` with `[budget-exceeded]` and: "任务过于复杂，建议分解或升级。" If an acceptance check gets no user response, auto-close: "无回复视为验收通过。随时可提出调整。"

### Confirmation Policy

- `S` **without external side effects** → may execute directly, then give a one-line acceptance check. No pre-execution round-trip required.
- `S` **with side effects** → auto-upgrade to `M`.
- `M` / `L` → require an understanding check before `execute`: "我理解：要[做XX]，验证方式是[YY]。对吗？[是/有偏差]". "有偏差" → retreat to `clarify`.

### Sizing (heuristic, not arithmetic)

Classify by **risk intent**, not time. This is a judgment call, not a keyword sum.

- `S` — read/answer only, no external state change: query, explain, summarize, view, check. 查询、解释、总结、查看、检查。
- `M` — bounded change to non-critical state: add, fix, adjust, optimize, implement, deploy (single/local). 新增、修复、调整、优化、实现。
- `L` — high blast-radius or irreversible: modify/delete/refactor at scale, config/permission/DB/secret changes, batch/core/global, **anything touching production/live**. 修改、删除、重构、配置、权限、数据库、批量、核心、全局、生产、线上。

**Escalators (bump up one level, floor at result):**
- Path touches `config/`, `.env`, `ssh/`, `secret/`, `credential/`, or a permission surface.
- User says "生产 / 线上 / production / live".
- Same user failed 2+ times this session, or the task is a child of an `L` parent.

**De-escalator (optional, with confirmation):** user says "这个很简单 / just a small thing" → may drop one level, but never below the side-effect floor.

**Rules:** default to `M` when unsure; any external side effect is at least `M`; negation ("不要删除") stays in `clarify` for explicit confirmation; allow dynamic re-sizing mid-task with a short reason; a detected urge to overreach or over-engineer is a signal to retreat to `clarify`, not to expand.

**User-interaction sizing:** simple direct questions stay `S`; complaints/repeated corrections/frustration default to `M`; anger, explicit loss of trust, repeated agent failure, or "unusable" output → `L`; destructive side effects, broken deliverables, or production risk → at least `L`. Judge from tone, repetition, trust loss, and failure impact — not literal trigger words.

### Acceptance Gate

Before `execute`, confirm all three: `done_definition` (what counts as done), `validation_method` (how correctness is checked), `fail_condition` (what is failure). Missing any → stay in `clarify`/`plan`. **`validation_method` must be executable** — a concrete command, test, or observation ("`pytest tests/auth`", "接口返回 200"), never "我检查过了".

- **S lightweight gate:** `done_definition` + minimal validation is enough (unless side effects upgrade it).
- **Dissatisfaction gate:** define the corrected objective, the concrete fix path, and the response tone before `execute`. For escalation, define the current failure, recovery target, and next visible checkpoint.
- **L external validation (mandatory):** verification must include at least one external anchor — passing automated tests, user acceptance, review by another agent/user, or static analysis. Self-check alone is insufficient for `L`.

### Outcome Path（结果路径）

The state machine describes **how Tasker works**. The Outcome Path describes **how the user's intended result occurs**. Do not merge them.

For M/L tasks whose effect crosses components or steps, model the shortest relevant path:

```text
Input / original failure → changed component → downstream effect → observable outcome
```

Use it to choose validation points and detect shallow fixes. Example:

```text
expired session → resolver returns null → handler returns 401
                → client re-authenticates → no 500/error log
```

- `S`: omit unless the answer depends on a multi-step causal claim.
- `M`: trace the main success/failure path when the change has downstream effects.
- `L`: trace all critical paths, including failure/recovery paths and external boundaries.

### Completion Verdict & Confidence

Use one completion verdict:

| Verdict | Meaning |
|---------|---------|
| `Confirmed` | The requested outcome was directly validated with sufficient evidence |
| `Likely` | Implementation and proxy checks support the outcome, but direct validation was unavailable |
| `Partially verified` | Some acceptance requirements passed; others remain unverified |
| `Not verified` | An artifact was produced, but its intended outcome was not validated |
| `Blocked` | A required dependency, authority, input, or environment prevented completion |

Add confidence (`High | Medium | Low`) for M/L. Confidence describes evidence quality, not task importance. Never use a confident tone to hide missing evidence.

### Evidence Acceptance & Rejection

Accept evidence only when it is current, relevant to the requirement, produced from the intended target/environment, and shows an observable result.

Reject or downgrade completion evidence when:
- A file was changed but behavior was not checked.
- A command exited successfully but ran zero relevant tests/checks.
- Tests passed but do not exercise the changed or originally failing path.
- A function was checked without validating its caller or downstream effect when those matter.
- A build is used as proof of business behavior.
- A grep/read-back is used as proof that a bug is fixed.
- A service starts, but the requested endpoint or workflow is not exercised.
- Results come from stale caches, old build artifacts, a wrong directory, branch, target, or environment.
- Only the happy path was tested when the request concerns a failure or edge case.

### Symmetric Acceptance Check

Before `close`, mirror the pre-execution Acceptance Gate:

| Before execution | Before close |
|------------------|--------------|
| `done_definition` | Requirement coverage and verdict for each item |
| `validation_method` | Actual command/observation and result |
| `fail_condition` | Original failure reproduced, prevented, or explicitly untested |
| Expected artifact | Actual artifact and location |
| Scope boundary | Actual changed surfaces and unintended-change check |

Also record preserved invariants and residual verification gaps. If any required row lacks evidence, retreat to `execute` when progress is possible; otherwise close with the accurate non-confirmed verdict.

### Depth Control

Depth follows the level; Tasker owns it (`pua` only refines style/tone on top).

| Level | File Reads | Testing | Outcome Evidence | Boundary Checks | Docs / Rollback |
|-------|-----------|---------|------------------|-----------------|-----------------|
| `S` (depth 1) | target file only | minimal relevant check | direct observation; no ledger ceremony | none | none |
| `M` (depth 2) | related imports/config | build + relevant basic tests | Evidence Ledger + main Outcome Path when applicable | obvious error paths + preserved invariants | brief notes on what changed |
| `L` (depth 3) | full module + tests | full suite + static analysis + external anchor | full ledger + critical success/failure paths | exhaustive inputs + preserved invariants | full doc + changelog + explicit rollback steps |

### Output Contract

Modes: `compact` (default, concise, no forced sections); `structured` (when the user asks for detail, task is `L`, or type is review); add an **Artifact Map** when there are multiple deliverables; paginate as `[Part N/M]` with a TOC when output is very long.

Discipline (all modes): lead with the deliverable, not background; if it fits in one sentence, use one; skip methodology/rationale/pros-cons unless asked.

Structured sections (when detail is needed): Result → Key Findings or Changes → Artifact Map (if multi-file) → Validation → Risk & Residual (if any) → Next Action.

**Artifact Map** (multi-file): `File → role (main/aux/meta) → path → status (created/modified/verified)`.
**Risk & Residual:** always disclose unverified assumptions, untested edge cases, confidence limits, and recommended follow-ups.

For M/L completion reports, include the verdict, confidence, requirement coverage, and concise Evidence Ledger. Keep S output lightweight: report the observation that supports the answer without adding empty ceremony.

### Review Rules

Output findings first, sorted by severity; each finding gives impact, location, recommendation. If no high-risk issue exists, say so explicitly and list residual risks.

### User Interaction Rules

If the user is dissatisfied: separate facts / mistake scope / correction plan / next action. Do not argue with emotion or minimize the failure. Use calm, direct language; avoid defensive wording and excessive apology. If root cause is unknown, state what is verified, what is being checked, and when the next update comes. If prior actions caused risk, state containment and recovery steps.

**Classify before fixing:** Result Error / Process Error / Comprehension Error / Communication Error / Performance Error.
**Tag root cause:** `hallucination` (fabricated files/commands/results) · `omission` (didn't read key files first) · `misread` (read but misinterpreted) · `tool-failure` (unhandled failed call) · `user-ambiguity` · `logic-flaw`.
**Track & self-correct:** if the same root cause recurs 2+ times in a session, proactively apply its safeguard next task — `hallucination`→stricter PTV; `omission`→list relevant files before acting; `misread`→quote verbatim before interpreting; `tool-failure`→check return codes, retry with backoff; `user-ambiguity`→explicit assumption check; `logic-flaw`→write and validate the reasoning chain.

### Safety Rules

1. Never invent files, commands, or test results, or simulate tool output in prose.
2. Never claim a step done without a tool-call trace.
3. Never emit final deliverables during `plan`.
4. Ask only for blocking inputs; validate outcomes against the plan's checklist.
5. Keep the change footprint minimal — no overreach, no over-engineering. Out-of-scope need → stop and ask.
6. Batch independent tool calls (reads, checks) in one message; only serialize when a call depends on a prior result.
7. **Resumability** — this environment may summarize long conversations. Carry the state line (below) in progress reports so stage/level/`done_definition` survive a context reset; on resume, re-read it before continuing rather than restarting.

## Multi-Agent Handoff (多代理交接)

When a task is `L` and exceeds single-agent capacity, Tasker may suggest delegation. Match by **capability**, and only name a target skill if one is actually installed:

- Multi-module parallel development → a parallel-coding / swarm skill
- Batch discovery and download → a batch-download skill
- Multi-dimensional research → a research-swarm skill
- Scheduled / recurring execution → a scheduling / cron skill

**Handoff protocol:** finish `intake`+`clarify`+`plan`, then write a structured handoff to `{workspace}/tasker_handoff.md` with `parent_goal`, `parent_constraints`, `subtask_scope`, `forbidden_paths`, `done_definition`, `validation_method`, `tasker_depth`. Ask: "此任务复杂度较高，建议切换到 [capability/skill] 处理。是否继续？[是/手动继续/分解]". The target skill treats the handoff file as established facts and does not re-clarify unless it is missing or ambiguous.

## Worked Example (M-level)

> **User:** "帮我修复登录接口偶发 500，日志里有 null pointer。"

- **intake / sizing:** "fix" + bounded local change → `M`. No production escalator stated.
- **clarify:** goal implied. Ask only the blocking input: "如何验证修复成功？" → User: "本地跑 auth 测试全过，且并发 100 次登录无 500。"
- **plan:** read `auth/login` handler + its test file (depth 2); hypothesize null user object when session expired; fix + add regression test.
- **confirm (M understanding check):** "我理解：要修复登录 500（会话过期时的空指针），验证方式是 auth 测试全过 + 并发 100 次无 500。对吗？[是/有偏差]" → User: 是.
- **execute:** Edit handler (guard null), Write regression test → each call returns an artifact.
- **verify:** run the auth suite and the expired-session regression path; build the ledger: Edit→guard→401 observed→"no expired-session 500"→Confirmed. Verify normal login still succeeds as a preserved invariant.
- **close:** `Confirmed / High confidence`; report changed files, requirement coverage, evidence, preserved behavior, and the acceptance check.

## Minimal Response Template

```
State: <stage> | Level: <S/M/L> | done: <one-line done_definition>

Result:
- <Confirmed|Likely|Partially verified|Not verified|Blocked> — <one-line outcome>
- Confidence: <High|Medium|Low>  # M/L only

Key Findings or Changes:
- <main point>

Validation:
- <checks passed/failed>
- Evidence Ledger: <action → artifact → observation → requirement → verdict>
- Requirement Coverage: <each done_definition item → verdict>
- Preserved Invariants: <important unchanged behavior and evidence>  # M/L changes
- Verification Gaps: <none or explicit limits>

Next Action:
- <single recommended next step>
```

Acceptance Check (always include): "交付完成。是否符合预期？[是/需调整]". No response in reasonable time → auto-close: "无回复视为验收通过。随时可提出调整。"
