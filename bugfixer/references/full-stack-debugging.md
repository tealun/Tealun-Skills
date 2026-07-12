# Full-Stack Debugging Reference

Use this reference when a bug may cross UI, client state, API, backend, database, storage, auth, deployment, or metrics boundaries.

## Symptom Routing

| Symptom | First checks | Common root causes |
|---|---|---|
| UI looks wrong | screenshot, WXML/HTML, CSS/WXSS, theme tokens, safe areas, conditional rendering | changed the wrong visual layer, hardcoded color, missing responsive constraint, optional data displayed as placeholder |
| Click does nothing | event binding, method name, component/page scope, disabled state, overlay hit area | handler missing, name mismatch, wrong component, stale build |
| Wrong page role or CTA | latest user feedback, screenshot, route type, tab bar config, owner/visitor state | mixing public visitor page with internal tab page, showing owner-only actions to visitors, retaining rejected product actions |
| Save succeeds visually but reload loses data | request payload, API response, repository write, storage URL, reload mapper | field omitted, contract rejects field, stored under wrong key, response mapper drops it |
| API 400 | body shape, DTO/schema, enum, content type, validation errors | unknown field, invalid enum, empty JSON body, client/server contract drift |
| API 401/403 | route privacy, token, visitor token, current user, owner rules | public page calling private route, expired token, owner/visitor confusion |
| API 404 | exact method/path, route registration, deployed version, reverse proxy target, resource id | frontend path typo, route not implemented in running backend, stale production build, proxy points to old service |
| API 500 | backend log, stack trace, DB constraint, null/length, migration status | column too short, missing migration, null dereference, unhandled storage failure |
| Data count wrong | metric definition, event creation, dedupe key, owner exclusion, time window | counting visits as users, repeat anonymous identity, owner included, cache stale |
| Config ignored | which process reads the file, gitignored private config, runtime config loader, environment override | writing the value into the wrong config plane, committing secrets, expecting runtime JS config to affect IDE/tool metadata |
| Example config becomes active | runtime import path, ignored/private config precedence, sample file references | app reads `.example` or sample config, sample contains realistic values, public repo leaks live settings |
| Demo mode or stale banner remains | feature flag source, ext config/global data, backend response, cached build, local storage | flag set in wrong plane, stale compiled mini program, UI hardcoded fallback, server still returns demo data |
| Migration pending or DB shape wrong | migration files, `pgmigrations`, `DATABASE_URL`, `DATABASE_DIR`, deploy working directory, DB user permission | migration not run, backend points to different DB, database package missing on server, assets moved into wrong layer |
| Admin operation says success but no effect | admin role, endpoint response, command stdout/stderr, server logs, working directory, reload status | operation ran in wrong directory, no pending items, missing server env, command output hidden, response mapper not refreshed |
| Production only failure | build output, env vars, module resolution, migration order, runtime path | local-only import, missing env, dist path mismatch, production DB schema lag |
| Deploy sync missing files | workflow run, sync step logs, auth, target path, source path, include/exclude rules, server permissions | workflow did not run, path trigger missed, auth failed, wrong target, exclude pattern removed intended files |
| CI failure unclear | full log around first failure, command exit code, coverage/audit/test summary | step label is broad, but actual failure is coverage threshold, test assertion, install, lint, typecheck, or audit tooling |
| Server panel/runtime mismatch | run directory, start command, port, reverse proxy target, `.env` location, build output | panel runs from wrong folder, build not run, port mismatch, real env absent, proxy points to old process |
| Platform/SaaS config confusion | provider app config, tenant auth table, callback URL, platform console, public examples | provider-level app config confused with tenant credentials, real customer/platform values leaked into examples |
| User says "still wrong" | newest correction, previously approved constraints, exact rejected behavior, screenshot/log delta | solving the wrong product problem, preserving old assumption, expanding scope instead of correcting |

## Layer Walk

Use the shortest path that explains the symptom:

1. Reproduce or identify the user-visible failure.
2. Find the UI component/page that renders or triggers it.
3. Trace state and event handlers.
4. Trace network request and response mapping.
5. Trace backend route, service, repository, and transaction.
6. Trace database/storage schema and migration.
7. Trace reload/read path back to the UI.

Stop when the causal chain is proven. Do not keep expanding the investigation unless the verification fails.

For persistence and display bugs, explicitly walk this chain:

`frontend display -> user action -> request payload -> API contract -> controller -> service -> repository -> database/storage -> response mapping -> reload/display`

The bug can live in either direction. A value may be saved correctly but dropped by the response mapper; a value may render locally but never enter the payload; an uploaded file may return a URL but not be persisted; a statistics event may be recorded but filtered incorrectly on reload.

Use this chain as a checklist, not a slogan:

- Frontend display: what the user sees, including empty/demo/fallback text and role-specific controls.
- User action: click/tap/submit handler, disabled state, confirmation dialog, double-submit protection.
- Request payload: method, path, headers, token, content type, body fields, enum names, file metadata.
- API contract: route registration, global prefix, DTO/schema, status code, validation errors, response envelope.
- Service/repository: authorization, tenant/account ownership, transaction, idempotency, retry/dead-letter state.
- Database/storage: migration applied, column exists, nullable/default/length, unique indexes, object path, public URL.
- Config/tenant boundary: public placeholders, server-local `.env`, platform console values, provider-level SaaS config, per-tenant authorization rows, and encrypted tenant secrets.
- Response mapping: field names, null handling, redaction, aggregate/stat calculation, stale cache invalidation.
- Reload display: refresh, reopen edit view, revisit public/consumer page, switch identity/role if relevant.

If any link is assumed rather than observed, mark it as unverified and do not close the bug yet.

## Intent and Feedback Triage

When the user corrects the direction, classify the failure before editing:

- Product intent mismatch: the feature idea itself is wrong, such as proposing "contact admin" when the user cannot know who the admin is.
- Role/view mismatch: owner view, visitor view, public page, tab page, and admin page are mixed together.
- Visual mismatch: layout, copy, spacing, CTA, or hierarchy differs from the provided screenshot/description.
- Data-flow mismatch: UI changed but persistence/API/readback was not updated.
- Deployment mismatch: code exists locally/remotely but production behavior proves an older or different runtime.
- Repository/process mismatch: the user is correcting where work belongs, such as audit directory naming, database assets under `database/`, or secrets outside public repo files.

Correction protocol:

1. Treat the newest feedback as authoritative.
2. Restate the corrected target in concrete UI/data terms.
3. Stop changing the rejected direction.
4. List what must be protected because the user already accepted it.
5. Re-run the layer walk from the symptom, not from the previous assumption.
6. Verify the exact corrected behavior, not just nearby code.
7. Search for stale variants of the rejected thing: old directory name, old label, old endpoint, old config key, old demo fallback, or old product action.
8. If your previous change caused noise such as whole-file rewrites, encoding churn, or unrelated diffs, recover to the prior content and reapply only the intended string/logic change.

## Frontend Checks

- Search with `rg` for displayed text, event names, route names, and API method names.
- Inspect adjacent markup, styles, and state initialization before editing.
- For design bugs, identify the object the user wants preserved and the layer they want changed.
- For mini programs, check status bar/capsule/safe-area behavior, bottom tab overlap, popup z-index, unsupported WXSS selectors, and page-vs-component event scope.
- For theming, verify selected color propagates through icons, buttons, tabs, badges, empty states, and edit pages without hardcoding.
- For custom images/files, check file type/size restrictions, upload result, storage category, persisted URL, and reload display.
- For public visitor pages, check whether a tab bar, owner-only footer, management CTA, or self-action is leaking into the public route.
- For mini program fixed panels, verify bottom safe area, content padding, and whether the panel should hide for owner/self view.
- For role-specific CTAs, prove the condition with actual state: current identity public id, owner flag from response, route query, or auth state.
- For optional business content, hide empty/unconfigured sections rather than showing demo company data on real cards.
- For "interaction does nothing", inspect overlays and fixed panels before assuming the handler is missing; a visible button may be covered by another element.
- For "still showing demo/state banner", search rendered text, feature flag checks, cached local storage, runtime config, and backend-provided flags.
- For UI corrections after screenshots, compare the exact changed layer: spacing, position, text, role, data source, or interaction. Do not rework the whole page to satisfy one visual complaint.

## Backend Checks

- Read the route/controller, DTO or contract, service, repository, and affected tests together.
- For database writes, inspect column type, nullability, length, defaults, JSON shape, and migration presence.
- For public/visitor flows, separate anonymous visitor, logged-in visitor, and owner.
- For owner behavior, exclude self-views from analytics when product intent requires it.
- For sharing or visit tokens, avoid deriving private actions from a public page unless the route is designed for it.
- For file storage, verify the category, allowed MIME types, max size, returned public URL, and cleanup behavior.
- For `404`, compare method and route against the controller decorator and global prefix. If related routes return `401`, the module and auth guard are live; focus on the missing route/version/proxy target.
- For `401` on an authenticated flow, inspect whether the client actually has the token in memory/storage and whether the request helper attaches it.
- For public pages, do not call employee/admin private endpoints unless the product explicitly requires a logged-in owner mode.
- For request helpers with retries, remember one user action can create multiple console errors; distinguish retry noise from multiple root causes.
- For admin mutation endpoints, verify required role, throttling, idempotency/concurrency handling, error shape, and logs that identify the actor without leaking secrets.
- For configuration bugs, prefer validated env/config getters over ad hoc `process.env` reads spread through business logic.
- For output that includes command results, redact connection strings, tokens, and full secret-bearing env values before returning or logging.

## Database and Migration Checks

Treat database bugs as a separate lifecycle, not as generic backend bugs:

- Locate migration files and schema authority first. Do not create or move migrations into backend code when the project has a dedicated database boundary.
- Check applied state against the migration table, commonly `pgmigrations` for `node-pg-migrate`.
- Compare migration file names to applied names both with and without `.js` when tooling stores basenames.
- Verify the server process knows the database asset directory through an explicit env/config value such as `DATABASE_DIR`; never let a browser submit arbitrary filesystem paths.
- Confirm the migration command runs from the database package working directory, not from the backend package.
- Confirm production has database package dependencies installed before exposing a manual run button.
- Add concurrency protection for manual migration execution so repeated clicks do not launch overlapping runs.
- Require high-privilege admin/owner role for destructive or schema-changing operations, even if lower roles can view status.
- Before and after migration, re-check pending/applied state and surface errors rather than just returning raw stdout.

Database verification options:

- Static: inspect migration SQL/JS, run syntax checks on migration files, and run typecheck/build if backend contracts changed.
- Non-destructive live check: query expected tables/indexes/RLS posture or a project-provided `db-check` command.
- Migration execution: only on a safe target or explicitly intended production window; confirm backup/rollback expectations.
- UI admin operation: click "detect", verify pending list, click "run" only after confirmation, then reload status and inspect server logs.

## Deployment and Runtime Checks

Production can be "alive" but not current. Use this path when local code and production behavior disagree:

1. Verify the failing URL from an external client, not only the app console.
2. Compare a known old route and the new failing route.
   - Old route returns `401`, new route returns `404`: production likely runs a version before the new route.
   - Both return `404`: wrong service, wrong prefix, or proxy target.
   - Route returns `500`: route exists; inspect logs, env, DB, or migration.
3. Check deploy commit/build id if available. Add or use a version/health endpoint when possible.
4. Confirm the build directory and start command match the actual backend.
5. Confirm process/container restart, not just file upload or build success.
6. Confirm reverse proxy target points to the updated process and port.
7. After redeploy, re-run the external URL. For protected endpoints, `401` can be the correct proof that the route is now registered.
8. If the bug depends on a filesystem path, verify the runtime working directory. A path that works locally from `backend/` may be wrong when production starts from the deploy root.
9. If a deployment syncs multiple subprojects, confirm protected runtime files such as `.env`, `node_modules`, uploads, logs, and certificates are not deleted by `rsync --delete` or equivalent.
10. Compare deploy workflow comments to executable include/exclude rules. Trust the shell commands over comments when they disagree.
11. For source-only deployments, confirm generated outputs such as `dist/` are rebuilt by the server panel or restart command after files sync.

### CI Log Triage

When a user asks why a pipeline step failed, do not infer from the step title. Read the failing command and the first non-zero exit.

Common distinctions:

- Typecheck failure: TypeScript compiler reports file/line/type errors.
- Lint failure: ESLint reports rule ids and file/line positions.
- Test failure: Jest/Vitest/etc. reports failed test names, assertion diffs, or thrown errors.
- Coverage failure: tests pass, but coverage thresholds fail. Report the metric and threshold, such as statements/branches/functions/lines.
- Install failure: package manager exits before project commands run.
- Audit failure: vulnerability/audit tooling exits after install/test may have passed.

If the log says a project command passed and a later coverage/audit threshold failed, explain that the named step was broad but the actual failure was the later subcommand. Fix the failing subcommand, not the whole pipeline blindly.

### Server Panel Runtime Checks

For BaoTa, PM2 panels, cloud app runners, or similar Node process managers, verify:

- Project path is the synced deploy root that contains `package.json`.
- Run directory matches the project path unless the project intentionally starts from a subdirectory.
- Install command matches the lockfile, commonly `npm ci` for npm projects.
- Build command exists and produces the runtime entry, commonly `npm run build` then `dist/main.js`.
- Start command matches `package.json`, commonly `npm run start`.
- Panel port, reverse proxy target, and `.env` `PORT` match.
- Real `.env` exists on the server and is protected from deploy overwrite.
- Only one owner restarts the service: either the panel or the deploy workflow, not both.
- Database assets required by migrations are present in the deployed working tree when migrations read files from disk.

If the server project directory is empty or lacks `package.json`, debug deployment/sync first. A panel cannot install or start source that has not arrived.

PowerShell note: `curl` may be an alias for `Invoke-WebRequest`; use `curl.exe -i <url>` or `Invoke-WebRequest -Uri "<url>"` when checking HTTP status on Windows.

Useful status-only PowerShell pattern:

```powershell
try {
  $r = Invoke-WebRequest -Uri "https://example.com/api/v1/path" -ErrorAction Stop
  $r.StatusCode
} catch {
  $_.Exception.Response.StatusCode.value__
}
```

## Metrics Rules

Before editing analytics code, name the metric:

- `unique visitors`: distinct people or identities that viewed the card.
- `display count`: every non-owner view event, including repeats.
- `interactions`: explicit actions such as phone, email, location, copy, like, exchange.
- `likes/reliable`: one positive vote per identity per card.

Anonymous identity may be based on a stored client id plus IP/user-agent hints. If the product wants a temporary anonymous identity, use a clear expiry window such as 24 hours and document it in the code or tests.

Metrics verification checklist:

- Define whether owner/self visits are excluded.
- Define whether repeat visits count toward display count but not unique visitors.
- Define whether anonymous and logged-in visitors use separate identity keys.
- Trace event write, dedupe/query, response field names, and frontend display labels.
- Check stale demo values are cleared after login or real data load.
- When multiple identities or companies exist, decide whether metrics are per personal card, per enterprise card, per tenant, or per selected sending identity before changing queries.
- For admin dashboards, confirm filters and role scope match the user's expectation: platform-wide, tenant-wide, member-specific, or current identity only.

## Verification Menu

Pick the smallest credible set:

- JavaScript page change: `node --check <file>`.
- Mini program page scripts: `node -e "new Function(require('fs').readFileSync('<page>.js','utf8'))"`.
- Mini program config/page JSON: `node -e "JSON.parse(require('fs').readFileSync('<file>.json','utf8'))"`.
- TypeScript backend: `npm run typecheck`.
- Affected backend behavior: targeted test file or test name.
- Build/runtime import issue: production build command.
- Contract change: one client request construction check plus server DTO/service test.
- Migration/schema issue: inspect migration and run build/typecheck; if possible, run migration in a safe environment.
- Database boundary issue: scan that migration tooling and schema assets remain in the database package, not duplicated into backend or frontend.
- Visual fix: screenshot or user-visible acceptance description, plus syntax checks for touched files.
- Public/protected route check: unauthenticated request should return the expected `401`, `404`, or public `200` depending on route privacy.
- Persistence fix: save, reload, re-open edit page, and view the public/consumer page that reads the saved value.
- Deployment fix: external request to the production domain after restart, with old/new route comparison when version drift was suspected.
- Deploy-sync fix: inspect include/exclude rules, run a dry mental trace of source path to target path, and verify protected runtime files stay protected while intended templates/assets are not excluded.
- CI fix: rerun or inspect the exact failing command and confirm the failure mode changed from failing to passing, not merely that an earlier subcommand passes.
- Server-panel fix: confirm `package.json` exists in the configured path, run install/build/start commands from that path, and verify the public health URL through the reverse proxy.
- Repo hygiene/naming fix: rename with VCS-aware commands, update all references, then run a full-text scan for old and new variants.
- User-correction fix: search for rejected copy/control/path and verify it no longer appears in active surfaces.

Suggested search checks before closeout:

```powershell
rg -n "rejected copy|old button label|forbidden field|secret value" <touched paths>
rg -n "old-directory-name|old_config_key|old_endpoint" . --glob "!node_modules/**" --glob "!.git/**"
git diff --stat
git status --short --branch
```

Do not treat broad audit output as bugfix verification. Verification must prove the reported symptom is gone.

## Anti-Patterns

- Changing UI by personal preference when the user supplied a screenshot or explicit product intent.
- Reintroducing a button, footer, tab bar, module, or copy that the user explicitly rejected.
- Fixing only the frontend when the symptom involves request payload, API contract, persistence, or response mapping.
- Ignoring production logs or external HTTP checks for a production-only issue.
- Declaring a save fixed without reload/readback proof.
- Treating a green build as proof of a visual, metric, auth, or deployment bug.
- Expanding into unrelated refactors or "while here" cleanup during a bugfix.
- Overwriting or reverting user changes in a dirty worktree.
- Confusing tool configuration with runtime configuration.
- Reading sample/example files as live runtime config, or making examples look like real deployed secrets.
- Putting a user's real domain, path, token, or private platform setting into a tracked example file when the correct answer is "put this in your server `.env`."
- Trusting workflow comments over the actual shell include/exclude patterns.
- Treating "files uploaded" as "service deployed" when dependencies, build output, migration, or process restart still has not happened.
- Letting both a deploy script and a server panel restart the same Node process without a clear owner.
- Moving database lifecycle into backend just because the backend exposes an admin trigger.
- Letting frontend/browser input decide server filesystem paths or shell commands.
- Treating an audit workflow as the fix itself. Audit can find risk; bugfix must change and verify the failing symptom.
- Leaving stale references after a directory or config key rename.
- Creating whole-file encoding/line-ending churn for a one-string fix; recover and apply a narrower edit.

## Closeout Wording

Report in this shape:

1. Fixed cause in one sentence.
2. Files/modules changed.
3. Checks run.
4. Remaining action: restart, migrate, deploy, or user visual confirmation.
