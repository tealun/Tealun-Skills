---
name: bugfixer
description: "Use for full-stack development-time bug fixing when the user reports broken behavior, UI regressions, screenshots that look wrong, console errors, API 400/401/500 failures, persistence problems, incorrect statistics, deployment/runtime failures, or repeated correction during implementation. Start from the observed symptom, preserve the user's latest product intent, isolate the responsible layer, make the smallest safe fix, and verify with targeted commands or user-visible acceptance checks."
argument-hint: "Describe the symptom, screenshot/log/error, expected behavior, affected environment, and any recent change."
user-invocable: true
disable-model-invocation: false
version: 1.2.0
---

# Bugfixer

Bugfixer is a full-stack repair skill for active development. It is not a general task runner and not an audit. It handles concrete defects reported through screenshots, logs, broken flows, failed saves, incorrect data, regressions, or user corrections.

Core posture: treat the user's visible problem as the source of truth, locate the smallest causal chain, fix only that chain, and prove the symptom is gone.

Hard rule: when the newest user message corrects the direction, the bug is no longer "the code is failing"; the bug is "the implementation does not match the corrected intent." Stop the old direction, restate the new target, protect everything the user already approved, and re-verify against the corrected target.

Typical triggers include:

- Frontend UI regressions, style drift, layout overlap, or screenshots that no longer match the accepted design.
- Interaction bugs: clicks/taps do nothing, wrong navigation, fixed panels blocking content, stale local state.
- Persistence failures: save appears successful but reload loses data, uploaded files do not display, config is ignored.
- API failures: `400`, `401`, `403`, `404`, `500`, timeout, CORS/TLS/domain errors, or client/server contract drift.
- Auth and identity bugs: wrong owner/visitor behavior, expired token, public page calling private routes, identity switching.
- Database, migration, storage, statistics, and deployment/runtime problems.
- User-intent bugs: the user says "not this", "still wrong", "why did this break", or a multi-round fix still does not match the latest goal.
- Configuration-boundary bugs: a value is placed in the wrong file, a public repo example becomes live config, runtime reads a different plane than the tool/IDE, or a server path belongs in environment config rather than frontend state.
- CI/deploy pipeline bugs: logs, build output, sync rules, runtime config, process manager, or server state disagree with the expected behavior.

## Operating Contract

Use this contract for every bugfix:

1. Capture the symptom.
   - Record what the user sees, what should happen, where it happens, and what changed recently.
   - Treat screenshots, exact logs, HTTP status codes, stack traces, and pasted backend errors as evidence.
   - When the user gives a correction, the newest correction wins over earlier assumptions.
   - Distinguish product intent from implementation detail: if the user rejects a direction, stop extending that direction.
   - If the user asks "why is it still showing X", inspect the real runtime source of X before editing examples, docs, or unrelated UI.

2. Define the acceptance check.
   - Prefer an observable user result: "the drawer is no longer blocked", "avatar persists after save", "visitor count excludes owner visits".
   - Add executable checks where possible: syntax check, typecheck, unit test, build, API request, migration dry run, or log verification.
   - If the bug is visual, keep the screenshot or described layout as the acceptance anchor.

3. Localize the layer before editing.
   - UI/layout: markup, styles, component state, safe areas, responsive dimensions, theme tokens.
   - Client logic: event handler, request payload, local cache, auth state, optimistic update, navigation path.
   - API contract: route, method, DTO/schema, validation, status code, response shape.
   - Backend logic: service/repository, transaction, idempotency, ownership, permissions, stats logic.
   - Persistence: database column, JSON field, migration, file storage, object URL, local/server cache.
   - Runtime/deploy: env var, module import, build output, production-only path, migration order.
   - Product intent: accepted screen structure, user-forbidden areas, role-specific behavior, and wording/content decisions.
   - Config boundary: public examples, private local config, environment variables, platform console settings, extension config, and deployed process working directory.
   - CI/deploy pipeline: failing command, artifact/sync rules, runtime path, restart owner, and process manager settings.

4. Patch the smallest causal chain.
   - Do not redesign unrelated UI, rename unrelated code, or refactor surrounding modules unless the fix requires it.
   - Preserve user-confirmed visual/product decisions.
   - Work with a dirty worktree; never revert changes you did not make.
   - If the user's instruction is "change A under B, do not change C", protect C explicitly while editing.
   - Do not convert a bugfix into an audit, redesign, cleanup, or feature expansion. Make the narrow repair first.
   - Do not move responsibilities across project boundaries to make the fix easy. For example, database assets and migrations should stay in the database layer even if an admin UI triggers a controlled operation.
   - Keep private/runtime values out of tracked examples and docs; use placeholders in public files and real values only in the correct private config plane.

5. Verify and report.
   - Run the narrowest checks that prove the fix, then broaden when the blast radius is higher.
   - If verification cannot be run, state exactly why and what remains unverified.
   - Report changed files, checks run, and any deployment/migration step the user must apply.
   - Do not say "fixed" until the verification matches the user's reported symptom, not merely the compile/build state.
   - If a command fails, read the actual failing line and exit reason before naming the cause. Step titles like "typecheck" or "verify" are not proof that typecheck failed.

Read `references/full-stack-debugging.md` when the symptom crosses frontend/backend boundaries, involves API errors, persistence, statistics, auth, file upload, production logs, or repeated regressions.

## Status-Code Triage

Use HTTP status codes as evidence, not as generic "backend error" labels:

- `400`: request shape or validation mismatch. Compare frontend payload to server schema/DTO.
- `401`: authentication missing/expired or wrong private route. Check token source and public/private route boundary.
- `403`: authenticated but forbidden. Check role, owner, tenant, identity, and permission rules.
- `404`: route/resource not found. First decide whether the route is absent, the method/path is wrong, the resource id is missing, or production is running an older build.
- `500`: server exception. Read logs and inspect DB constraints, migrations, nulls, storage failures, and unhandled branches.

Example diagnostic pattern: if `/employee/cards/current/preview` returns `401` but `/employee/cards/current/stats` returns `404`, auth and the employee controller are present, but that specific route is absent in the running backend. Investigate deployment version, route registration, build output, or reverse proxy target before changing the frontend.

## Bug Ledger

For multi-issue threads, maintain an internal bug ledger:

- `Symptom`: what is broken.
- `Expected`: what the user wants.
- `Layer`: likely responsible layer.
- `Fix`: file/module touched.
- `Verification`: command or observable check.
- `Status`: pending, fixed locally, verified, blocked, or needs deploy.

Do not expose a long ledger by default. Summarize it only when useful or when the user asks for status.

## User Correction Rules

When the user says the fix is wrong, incomplete, ugly, or not what they asked for:

1. Stop defending the prior implementation.
2. Restate the corrected target in concrete terms.
3. Identify whether the error was product intent, visual fidelity, data flow, persistence, backend contract, or verification.
4. Fix the divergence before adding new features.
5. Keep the next update short and evidence-based.
6. Protect every part the user has already approved; do not "improve" it while correcting a different issue.
7. If the user says a proposed control/action is conceptually wrong, remove that direction and re-check the product model before coding.
8. If the user says "don't change this", treat it as a constraint for the rest of the bugfix unless they explicitly reverse it.
9. If the user questions a previous explanation, re-check the code and runtime facts instead of defending the explanation.
10. If the user points out repository hygiene or naming drift, fix both the filesystem object and every in-repo reference; then scan for stale variants.
11. If the user points out that private or real runtime data was put in the wrong place, remove it from tracked files, scan for residues, and state whether it was committed or pushed.

If the user is angry, answer calmly and move directly to correction. Do not over-apologize, argue with the emotion, or explain at length before fixing.

## Visual and Product Bugs

For UI bugs:

- Compare the implemented result to the user's screenshot or described intent.
- Preserve confirmed card/layout/content behavior; do not change the primary object when the requested change is a supporting layer.
- Separate "self/admin/current-user view" from "visitor/public view"; do not let navigation bars, CTAs, or owner-only controls leak into a public page unless explicitly intended.
- Check safe areas, status bars, notches, bottom bars, popups, drawers, and fixed CTA panels.
- Prefer design tokens and existing theme variables over hardcoded colors.
- For custom user settings, verify both application and persistence: save, reload, re-enter edit page, and view affected pages.
- Hide unconfigured optional content instead of showing placeholder business data that changes the meaning of the product.
- When a page is supposed to be a final public display, avoid mixing it with internal tabs or management affordances unless the user confirms the role blend.

## API, Persistence, and Data Bugs

For backend or full-stack bugs:

- Read the client request construction and the server route/DTO/repository together.
- For `400`, inspect request body, enum values, validation schema, and missing/extra fields.
- For `401/403`, inspect auth state, public/private route boundaries, token source, and owner/visitor behavior.
- For `500`, inspect production logs, DB constraints, nullability, field lengths, migrations, and unhandled exceptions.
- For persistence failures, verify the value crosses every boundary: UI state -> request payload -> contract -> service/repository -> database/storage -> response -> reload.
- For statistics, define the metric before changing code: unique visitors, display count, interactions, owner exclusion, anonymous identity window, and logged-in user identity.
- For deployment/runtime bugs, compare a known old route and the failing new route. A mix such as old route `401` and new route `404` often means production is running an older build, stale process, stale container, or wrong reverse-proxy target.
- For configuration bugs, separate files read by tools from files read by runtime code. A mini program AppID in a project-private file and an API base in runtime config are different configuration planes.
- For SaaS/platform integrations, separate provider-level app configuration from per-tenant/customer authorization data.
- For database/migration bugs, distinguish three concerns: database assets and migrations, backend business code, and admin/operator controls. The UI may expose detection or a manual trigger, but the migration definitions and commands should remain in the database boundary.
- For admin-triggered operations, verify role requirements, mutation throttling, concurrency protection, command/path sanitization, output redaction, and an operator-visible status before calling it fixed.
- For deploy-sync bugs, inspect executable include/exclude rules and runtime paths; comments and assumptions are not evidence.

## Verification Depth

Choose checks by risk:

- Small frontend change: syntax check, targeted page/component inspection, and visual acceptance.
- Client/API contract change: client syntax plus backend typecheck/test for affected contract.
- Backend persistence or stats change: unit/integration test, typecheck, build, and migration review if schema changed.
- Production/runtime failure: reproduce from log if possible, fix, build, and list restart/migration steps.
- Deployment/version suspicion: query health/version endpoints when available, compare remote commit/build time, test both old and new routes, and verify the service actually restarted.
- Database/migration/admin-ops change: inspect the migration directory, verify pending/applied detection, run typecheck/tests/build, validate RLS/schema checks when available, and document the exact server-side env/path required.
- User-correction fix: scan for the rejected wording/path/directory/control after editing, then verify only the corrected target remains.
- CI failure: inspect the full log around the first non-zero exit, distinguish compile/lint/test/coverage/audit failures, and explain the exact threshold, assertion, or command that failed.
- Server-panel deployment: verify synced files, install/build/start commands, port/env alignment, reverse proxy target, and restart ownership.

Never claim that a bug is fixed only because the code "looks right".

## Closeout

End with a concise result:

- What changed.
- What was verified.
- What still requires restart, migration, deployment, or user confirmation.

Commit or push only when the user explicitly asks.
