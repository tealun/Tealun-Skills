---
name: bugfixer
description: "Use for full-stack development-time bug fixing when the user reports broken behavior, UI regressions, screenshots that look wrong, console errors, API 400/401/500 failures, persistence problems, incorrect statistics, deployment/runtime failures, or repeated correction during implementation. Start from the observed symptom, preserve the user's latest product intent, isolate the responsible layer, make the smallest safe fix, and verify with targeted commands or user-visible acceptance checks."
argument-hint: "Describe the symptom, screenshot/log/error, expected behavior, affected environment, and any recent change."
user-invocable: true
disable-model-invocation: false
version: 1.3.0
---

# Bugfixer

Repair concrete development defects from the user-visible symptom to the smallest proven cause. Preserve the latest product intent, change only the causal chain, and verify that the reported symptom is gone.

When the newest user message corrects the direction, treat the mismatch with that corrected intent as the current bug. Stop extending the rejected direction and protect everything the user already approved.

## Conditional References

Load only the detail required by the symptom:

- Read [references/full-stack-debugging.md](references/full-stack-debugging.md) when the failure may cross layers, the responsible layer is unclear, or a previous fix regressed.
- Read [references/frontend.md](references/frontend.md) for screenshots, layout, interaction, theming, role/view, or client-state defects.
- Read [references/backend-data.md](references/backend-data.md) for API, auth, persistence, storage, metrics, database, or migration defects.
- Read [references/runtime-deploy.md](references/runtime-deploy.md) for production-only behavior, configuration boundaries, CI, deploy sync, process managers, reverse proxies, or stale versions.

Load multiple references only when the observed causal path actually crosses those boundaries.

## Repair Contract

### 1. Capture the symptom

- Record what the user observes, what should happen, where it happens, and what changed recently.
- Treat screenshots, exact logs, HTTP responses, stack traces, and backend errors as evidence.
- Prefer runtime sources over examples, docs, comments, or assumptions.
- If the user corrects the target, restate the corrected outcome and rejected direction before editing.

### 2. Define acceptance

Use an observable result such as “the drawer no longer blocks content,” “the value persists after reload,” or “the route is registered in the running service.” Add the narrowest executable check that can prove it: syntax, typecheck, targeted test, request, log observation, migration inspection, or visual comparison.

### 3. Localize before editing

Identify the first layer that can explain the evidence:

- UI/layout — markup, styles, safe areas, conditional rendering, design tokens.
- Client — handlers, state, cache, navigation, request construction, response mapping.
- Contract — route, method, auth boundary, DTO/schema, status and response shape.
- Backend/data — service, repository, transaction, ownership, database/storage, metrics.
- Runtime — environment, build artifact, migration order, process, proxy, deployed version.
- Product intent — accepted structure, forbidden controls, role-specific behavior, wording.

Trace only far enough to prove the causal chain. If a link is assumed, mark it unverified.

### 4. Patch the smallest causal chain

- Preserve user-confirmed behavior and unrelated dirty-worktree changes.
- Do not redesign, audit, rename, refactor, or add features unless the repair requires it.
- Respect explicit protected surfaces such as “change A, do not change C.”
- Keep database assets in the database boundary and private/runtime values out of tracked examples.
- If the required repair materially expands scope, explain why before proceeding.

### 5. Verify the reported outcome

- Run the narrowest check that exercises the symptom, then broaden with blast radius.
- Read the first real failing command, line, and exit reason before naming a cause.
- A green build proves buildability, not visual, auth, metric, persistence, or deployment correctness.
- Report exact unverified gaps and required restart, migration, deploy, or user visual confirmation.
- Do not say “fixed” until evidence matches the original or corrected symptom.

## Fast Triage

Use status codes as evidence:

- `400` — compare request shape, content type, enums, and validation schema.
- `401` — check missing/expired auth and public/private route boundaries.
- `403` — check authenticated identity, owner/tenant role, and permission rules.
- `404` — distinguish wrong method/path, missing resource, absent route, stale build, and wrong proxy target.
- `500` — read server logs; inspect nulls, constraints, migrations, storage, and unhandled branches.

When an old protected route returns `401` but a new related route returns `404`, the service and auth layer are live while the new route is absent from the running target. Check deployment version, route registration, build output, and proxy target before changing the client.

## User Corrections

When the user says a fix is wrong or incomplete:

1. Stop defending the prior implementation.
2. Classify the divergence: intent, visual fidelity, data flow, persistence, contract, runtime, or verification.
3. Restate the corrected target and protected accepted behavior.
4. Remove the rejected direction before adding anything new.
5. Re-check code and runtime facts instead of defending the prior explanation.
6. Search for stale rejected labels, paths, controls, keys, endpoints, or private values after editing.

If a narrow edit caused encoding, line-ending, or whole-file churn, restore the prior content and reapply only the intended change. Stay calm and evidence-led when the user is frustrated.

## Verification Depth

- Small UI change — syntax plus targeted component/page inspection and visual acceptance.
- Client/contract change — client check plus affected server contract test or typecheck.
- Persistence/metrics change — exercise write, readback, reload, identity rules, and affected tests.
- Database/migration change — inspect schema authority, migration state, build/tests, and safe-target checks.
- Runtime/deploy change — verify external behavior after build/restart and compare expected running version.
- User-correction change — scan for the rejected variant and prove only the corrected behavior remains.

## Closeout

Report concisely:

1. Cause and repair.
2. Files or modules changed.
3. Checks and observed results.
4. Remaining restart, migration, deployment, or user confirmation.

Commit or push only when explicitly requested.
