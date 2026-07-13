---
name: auditor
description: >
  Universal project audit skill for evidence-backed code review, security analysis, architecture
  health, maintainability, testing, deployment readiness, and documentation consistency across
  common tech stacks. Use for audit/review/check-for-bugs requests, verification of prior audit
  fixes, or documentation status reviews. Auditing is read-only by default; modifying product code
  requires an explicit fix request.
argument-hint: "Describe the project or path to audit, concerns to prioritize, and desired depth or report format."
user-invocable: true
disable-model-invocation: false
version: 4.0.0
---

# Auditor

Audit a real project baseline, trace consequential behavior across boundaries, and report only findings supported by reproducible evidence or a concrete static proof.

The audit phase is read-only by default. Record the baseline and inspect the existing worktree without pulling, installing, cleaning, switching branches, or changing project files. Enter fix mode only when the user explicitly asks to apply fixes. A request to verify previous fixes authorizes audit-status updates only when the user also asks to update the audit documents.

## Conditional References

Load only what the audit needs:

- Read [references/audit-method.md](references/audit-method.md) for depth selection, the 12-dimension model, project-shape applicability, specialist lenses, and critical-path tracing.
- Read [references/evidence-and-reporting.md](references/evidence-and-reporting.md) before accepting findings or producing a durable audit report.
- Read [references/specialized-audits.md](references/specialized-audits.md) for AI/prompt security, maintainability, or documentation-governance audits.
- Read [references/deep-audit-checklist.md](references/deep-audit-checklist.md) only when executable search/test command patterns are useful for the detected stack.

## Audit Contract

Before scanning, define internally:

- `scope` — repository/path, included uncommitted changes, and requested focus;
- `baseline` — branch, HEAD when Git exists, worktree state, and time of observation;
- `depth` — quick, standard, or deep, with the reason;
- `deliverable` — conversational findings or a repository report explicitly requested by the user;
- `limits` — unavailable runtimes, credentials, services, test data, or permissions.

Do not pause for ordinary scoping questions. Infer project shape from evidence and state material assumptions. Ask only when the target is ambiguous enough that auditing the wrong project is likely.

Honor `.audit-config.yml` when present, except where it conflicts with the user's request or higher-level safety constraints. Treat time/depth settings as caps, not permission to mutate the repository or contact external systems.

## Workflow

### 1. Stabilize the baseline

Inspect repository status, branch, HEAD, recent changes, project instructions, and existing audit reports. Preserve unrelated dirty-worktree changes. State whether uncommitted work is included. Remote synchronization happens only when explicitly requested.

### 2. Fingerprint the project

Identify languages, frameworks, dependency managers, database/ORM, auth, external integrations, UI surfaces, deployment model, CI, and high-value data. Confirm risk signals in surrounding production code; keywords alone do not count.

Select depth from actual consequences:

- **Quick** — narrow or low-risk project/request; spot-check the requested concern plus basic security, correctness, maintainability, and test health.
- **Standard** — multiple runtime layers, user-facing APIs/UI, persistence, or meaningful integration risk; cover all applicable dimensions and trace at least the highest-risk path.
- **Deep** — auth/payment/tenant boundaries, sensitive data, uploads/webhooks, production infrastructure, complex state machines, or an explicit deep audit; trace every identified high-risk path and include supply-chain, tests, and operations.

If time or access ends first, stop cleanly and report partial coverage rather than manufacturing completeness.

### 3. Build the coverage map

Use the 12 dimensions as the stable communication model:

1. Architecture
2. Platform integration
3. Security
4. Code efficiency
5. Runtime smoothness
6. Information isolation
7. Data accuracy
8. Parameter passing
9. User experience
10. Coding standards
11. Testing
12. Deploy and operations

Mark a conditional surface `N/A — reason` when absent. Never create a finding merely to fill a dimension. Quick audits may sample dimensions; standard/deep audits must state a result or gap for every applicable one.

### 4. Trace critical paths

For standard/deep audits, select paths whose failure would most harm users or protected properties: authentication/recovery, payment/refund/entitlement, role or tenant changes, upload/processing, webhooks, import/export, or AI input → generation → persistence → reuse.

Trace the applicable chain:

```text
entry → validation → identity/authz → business rules → data write
      → external/async work → user-visible result → logging/recovery
```

Record goal, code locations, confirmed controls, findings, verification gaps, applicable dimensions, and health: `Healthy | At risk | Broken | Not verified`. Critical paths connect dimensions; they are not a thirteenth dimension.

### 5. Generate and verify candidates

Use repository search, static tools already available, targeted tests, build/type checks, safe local requests, and configuration inspection. Start narrow, then expand according to blast radius. Do not install tools or run destructive/database/production checks without appropriate authorization.

Every candidate must pass:

```text
Candidate → Context inspected → Reproduced or statically proven
          → Severity calibrated → Accepted or rejected
```

Only accepted findings enter the findings table. Missing tests prove a verification gap, not the underlying bug. Scanner output, dependency advisories, keyword hits, and delegated analysis are leads until independently checked against the baseline.

### 6. Report the audit

Lead with the verdict and counts, then provide:

- scope, baseline, depth, and evidence limits;
- system goal and critical-path health;
- confirmed strengths worth preserving;
- P0/P1/P2 findings with type, confidence, status, impact, evidence, and smallest safe remediation;
- verification gaps and rejected high-signal candidates when useful;
- 12-dimension coverage for standard/deep audits;
- exact checks run and observed results.

Write into `docs/99_audits/` only when the user requested a durable report or the active task explicitly includes documentation updates. Follow the repository's existing naming and status conventions; otherwise use the compact template in the reporting reference. Do not commit or push unless explicitly requested.

## Verification Audit

When verifying fixes from a prior audit:

1. compare the recorded baseline with the current baseline;
2. inspect the actual diff for each prior finding;
3. re-run its reproduction or proof and relevant regression checks;
4. inspect adjacent code for the same defect class;
5. report fixed, still open, regressed, deferred, or not verified;
6. update original audit statuses only when document edits are in scope.

Do not redo the entire audit unless requested or the fixes materially changed the risk surface.

## Fix Boundary

An explicit “fix/apply the recommendations/修复” request enters fix mode. Apply the smallest causal changes, verify them, and preserve unrelated work. Architecture decisions, schema/data changes, production actions, or domain-dependent behavior may still require a user decision when the existing evidence does not determine a safe answer.

Fixing an issue does not authorize committing, pushing, deploying, migrating production data, or rewriting unrelated modules.
