---
name: project-audit
description: >
  Universal automated project audit skill — code review, security scan, architecture health check,
  and document management. Works with any tech stack (React/Vue/Node/Go/Python/DB/etc).
  Audit phase is fully automated; fix phase is separate and requires explicit confirmation.
argument-hint: "Describe the project or path to audit, the concerns to prioritize, and the desired report depth."
user-invocable: true
disable-model-invocation: false
version: 2.5.0
---

# Universal Project Audit

A methodology for auditing any codebase: identifying risks, verifying findings, and maintaining code health over time.

**Core principle:** The audit phase (discover + judge + report) runs automatically without user confirmation. The fix phase (modify code) is a separate workflow and always requires explicit approval.

**Positioning:** **12-dimensional coverage × critical-path penetration × evidence-closed verification.** The 12 dimensions remain the coverage and communication backbone. Critical paths connect them across real system behavior; the evidence protocol makes every reported conclusion reviewable.

## When to Use

- User says "audit this project" / "review the code" / "check for bugs"
- User pushes fixes and says "verify" / "继续审计" / "修好了"
- User asks to "梳理文档" / "check doc status" / "sync documentation"
- Any task involving code quality, security, or architecture review

## Operating Mode

Default mode is **auto**.

In auto mode the agent:
1. Identifies the project type and tech stack
2. Scans risk signals
3. Selects audit depth automatically
4. Executes the audit
5. Writes the report
6. Presents findings

No interactive confirmation is required during the audit phase.

Switch to **interactive** mode only when the user explicitly asks for step-by-step control.

## Automation Configuration

Use `.audit-config.yml` in the project root to control automation boundaries:

```yaml
audit:
  mode: auto                  # auto | interactive
  max_depth: deep             # quick | standard | deep
  max_duration_minutes: 20    # hard cap for a single audit run
  output_dir: docs/99_audits   # where reports are written automatically
  push_report: false          # audit phase never pushes; set true only for fix workflow
```

If the file is missing, use these defaults:
- mode: auto
- max_depth: deep
- max_duration_minutes: 20
- output_dir: docs/99_audits
- push_report: false

---

## Section 1: Auto-Scoping & Risk Calibration

Before any audit, automatically fingerprint the project and compute a risk score. The score determines audit depth without asking the user.

### 1.1 Project Fingerprinting

Read these files to identify the project:

```bash
# Dependency and runtime
ls package.json go.mod pyproject.toml requirements.txt Cargo.toml pom.xml build.gradle 2>/dev/null

# Infrastructure and deployment
ls Dockerfile docker-compose.yml .github/workflows .gitlab-ci.yml 2>/dev/null
find . -maxdepth 2 -type d \( -name terraform -o -name k8s -o -name helm -o -name .serverless \) 2>/dev/null

# Basic structure
find . -maxdepth 2 -type d | head -30
```

Extract:
- Language and framework
- Database / ORM
- Auth library
- Payment processor
- Deployment target
- Cloud provider

### 1.2 Risk Signal Scan

Run keyword scans and accumulate a score.

**High-risk signals (+3 each):**
- Payment: `stripe`, `paypal`, `square`, `adyen`, `alipay`, `wechatpay`, `braintree`
- Auth: `passport`, `next-auth`, `jwt`, `clerk`, `auth0`, `oauth`, `oidc`, `keycloak`
- PII fields: `ssn`, `password`, `credit_card`, `phone`, `dob`, `date_of_birth`, `address`, `national_id`, `id_number`, `passport_number`
- File upload: `multer`, `upload`, `multipart`, `formidable`, `busboy`
- Admin surface: `admin`, `superuser`, `role`, `permission`
- Webhook receivers: `/webhook`, `stripe webhook`, `github webhook`
- Production deployment: `prod`, `production`, `aws`, `gcp`, `azure` in infra files

> False positives: words like `admin`, `role`, or `upload` appear in non-risk contexts. A signal counts only if it appears in code that actually implements the corresponding feature. Use file path and surrounding code to confirm.

**Medium-risk signals (+1 each):**
- User-facing API routes
- Third-party HTTP clients
- Email/SMS sending
- Scheduled jobs / cron
- Database write operations
- Caching layer

**Low-risk signals (0):**
- Static site generators
- CLI tools with no network
- Documentation-only projects

### 1.3 Depth Selection

Select depth automatically based on score:

| Score | Auto-selected depth |
|-------|---------------------|
| ≥ 6   | Deep audit |
| 3–5   | Standard audit |
| < 3   | Quick scan |

Also respect `max_depth` from config: if auto selection exceeds `max_depth`, cap it.

Commit count does not override depth. A single commit adding payment code can trigger a deep audit. Commit count only helps narrow the file range to inspect.

### 1.4 Mandatory Output

After scoping, record internally:
- Detected tech stack
- Risk score and signals
- Selected depth
- Estimated duration

Present this in the final report header. Do **not** stop to ask the user.

---

## Section 2: Audit Pipeline

### 2.1 Establish a Stable Audit Baseline

```bash
cd <project-path>
git status --short
git branch --show-current
git rev-parse HEAD
git log --oneline -15
```

Auditing is read-only by default. Do **not** run `git pull`, checkout another branch, clean files, install packages, or otherwise change the worktree merely to start an audit. Record the branch, HEAD, dirty state, and whether uncommitted changes are included. Synchronize from a remote only when the user explicitly requests it.

### 2.2 Load Context

Gather from project docs or prior audit files:
- Tech stack and architecture
- Conventions
- Deferred items from previous audits

If unclear, infer from fingerprinting. Never block the audit to ask.

### 2.3 Execute Audit

The selected depth runs automatically.

#### Quick Scan (score < 3)

Use `execute_code` to run 6–10 verification commands covering:
- Security: auth checks, input validation, exposed secrets
- Health: TODO count, dead code, unused imports, console.log residue
- Types: compilation errors, type mismatches
- Maintainability: boundary leakage, over-engineering, hardcoded config (see Section 5)

Reference `references/deep-audit-checklist.md` for command templates.

#### Standard Audit (score 3–5)

Cover these 5 specialist roles. When multi-agent work is available and explicitly allowed, they may run in two batches (max 3 concurrent). Otherwise the primary agent performs the same roles sequentially; coverage must not depend on delegation.

**Batch 1 — Core Risks:**
1. **Security Agent** — Auth, injection, XSS, IDOR, data exposure, race conditions, rate limiting; **tenant/role isolation (multi-tenant, RLS, cross-account access), log redaction of PII** (dims 3/6)
2. **Backend Agent** — API semantics, error handling, transactions, N+1, idempotency, DB health; **third-party integration reliability (SDK, callbacks, timeout/retry/circuit-breaker, graceful degradation), data accuracy (metric definitions, attribution, aggregation), parameter-passing boundaries (internal vs public ID, URL/body/header/token)** (dims 2/7/8)
3. **Frontend Agent** — Controlled components, render perf, memory leaks, error boundaries, a11y; **runtime smoothness (cache/concurrency/timeout/resource + wait experience), UX states (empty / loading / error-degradation / key-path flow)** (dims 5/9)

**Batch 2 — Code Quality:**
4. **Architecture Agent** — Module boundaries, naming, typing, spec↔code alignment, duplication, **and maintainability (see Section 5): boundary/scope leakage, over-engineering, upgradability; coding-standard consistency (response envelope, error codes, directory/lint conventions)** (dims 1/10)
5. **Health Agent** — Debug residue, TODO inventory, dead code, unused deps, vulnerabilities

Agent context template:
```
Project: <name>
Tech stack: <stack>
Audit range: <commit-old>..<commit-new> (<N> commits, <M> files)
Focus areas: <specific concerns from user or previous audit>
Known issues: <deferred items from last audit>
Conventions: <naming, file structure, patterns>
```

#### Deep Audit (score ≥ 6)

In addition to standard audit:
- Run business-logic focused checks on payment, auth, and state-machine paths
- Scan infrastructure and configuration files
- Run supply-chain vulnerability checks
- Allow follow-up rounds if agents surface complex issues
- **Run a 6th Test & Ops Agent** (Deep only — do not run in Quick/Standard):
  - **Test coverage (dim 11):** presence and adequacy of unit / integration / contract tests; authorization (越权) tests on protected routes; migration tests; whether CI actually enforces them (required checks, not skippable).
  - **Deploy & Ops (dim 12):** environment config hygiene, structured logging, monitoring/alerting, health checks, rollback path, backup, and secret rotation.
  - Report gaps here as **P1 by default** (missing safety net), escalate to P0 only when a live production path has zero coverage/rollback.

Use the time cap from config. If the cap is reached, stop and report findings so far, noting the partial coverage.

#### 12-Dimension Coverage Map

The 12 dimensions are the skill's **coverage backbone and primary communication advantage**. Specialist roles are possible executors, not the product model. No execution strategy may rename, collapse, replace, or silently drop the 12 dimensions. Use the map to prove breadth before writing the report.

| # | Dimension | Owner agent | Must-check (one line) |
|---|-----------|-------------|-----------------------|
| 1 | 架构 Architecture | Architecture | Module boundaries, tech-choice fit, extensibility, complexity (see Section 5) |
| 2 | 平台对接 Platform integration | Backend | SDK/callback correctness, external-call timeout/retry/circuit-breaker, degradation on outage |
| 3 | 安全防护 Security | Security | Auth/authz, secrets, encryption, log redaction, anti-abuse, anti-injection |
| 4 | 代码高效 Code efficiency | Architecture | Simple, low-duplication, low-complexity; no needless compute/queries (see Section 5.3) |
| 5 | 运行流畅 Runtime smoothness | Frontend + Backend | Perf, cache, concurrency, timeout/retry, resource use, wait experience |
| 6 | 信息隔离 Info isolation | Security | Multi-tenant / role / data-permission / RLS; no cross-tenant/account access |
| 7 | 数据准确 Data accuracy | Backend | Data model, metric definitions, attribution, idempotency, transaction consistency |
| 8 | 参数传递 Parameter passing | Backend | URL/body/header/token + internal vs public ID boundaries are clear and safe |
| 9 | 用户体验 UX | Frontend | Flow, status hints, error degradation, empty/loading states, key-path smoothness |
| 10 | 编码规范 Coding standards | Architecture + Health | Format/naming/dir/lint/comments/types + consistent response envelope & error codes |
| 11 | 测试验证 Testing | Test & Ops (Deep) | Unit/integration/contract/authz(越权)/migration tests + CI enforces them |
| 12 | 部署运维 Deploy & Ops | Test & Ops (Deep) | Env config, logs, monitoring, alerting, health checks, rollback, backup, secret rotation |

Depth note: dims 1–10 run in Standard and Deep; dims 11–12 run in Deep only. Quick scan spot-checks dims 3/4/10 (security, efficiency, standards) as the minimal safety floor.

#### Applicability Rule (works for any project, not just SaaS)

The 12 dimensions are a superset. **A dimension applies only when the project's shape (from Section 1 fingerprinting) actually has that surface.** If the surface is absent, mark the dimension **`N/A — <one-line reason>`** in the report and move on. **Never fabricate a finding for an absent surface** (e.g. "no multi-tenant isolation" on a CLI tool is noise, not a finding). This is the same anti-false-positive discipline as Section 2.4.

**Always-on (any codebase that has code / runs / ships):** 1 架构, 3 安全, 4 代码高效, 5 运行流畅, 7 数据准确, 10 编码规范, 11 测试, 12 部署运维. (Their *scope* adapts — e.g. "安全" for a CLI is input/arg validation and secret handling, not web auth.)

**Conditional (only if the surface exists):**
- **2 平台对接** — only if the project integrates external platforms/SDKs/callbacks.
- **6 信息隔离** — only if multi-tenant or multi-user with data-permission boundaries.
- **8 参数传递** — only if there is a request/entry surface (HTTP/RPC/CLI args/public API).
- **9 用户体验** — only if there is a UI (web/mobile/desktop/TUI).

**Default dimension set by project shape:**

| Project shape | Applies | Typically N/A |
|---------------|---------|---------------|
| SaaS / Web service | all 12 | — |
| CLI tool | 1,3,4,5,7,10,11,12 (+8 as arg-parsing) | 2,6,9 (unless it calls external APIs) |
| Library / SDK | 1,3,4,5,7,10,11 (+8 = its public API surface) | 6,9,12 |
| Data pipeline / ETL | 1,4,5,**7 (primary)**,11,12 (+6 if data tenancy) | 9 |
| Mobile / desktop app | 1,3,5,8,9,10,11 (+2 if backend) | 6 (usually) |
| Firmware / embedded / ML training | 1,3,4,5,7,10,11 (ops/test model differs — adapt 11/12) | 2,6,8,9 |

When the shape is ambiguous, include the conditional dimension but flag it `N/A?` and let evidence confirm or drop it. Do not block the audit to ask.

#### Critical-Path Penetration

Dimensions describe **what** is covered; critical paths show **how risks cross boundaries**. For Standard and Deep audits, identify the system's most consequential paths from available code and documentation. Deep audits must trace every high-risk path; Standard audits trace at least the highest-risk path. Quick scans may omit path tracing but must say so.

Typical paths include authentication, password recovery, payment/refund, entitlement, file upload/processing, role or tenant changes, webhook handling, import/export, and AI input → generation → persistence → re-injection.

Trace each selected path through the applicable stages:

```text
entry → validation → identity/authz → business rules → data write
      → external call/async work → user-visible result → logging/recovery
```

For every path, record:
- System/user goal and protected property
- Steps and code locations
- Applicable dimensions
- Confirmed controls (strengths)
- Findings and likely risks
- Verification gaps or blockers
- Overall health: `Healthy | At risk | Broken | Not verified`

Critical paths are **not a 13th dimension**. They are the cross-dimensional analysis method.

### 2.4 Evidence Protocol & Finding Verification (CRITICAL)

**Never trust keyword hits, tool output, or sub-agent reports blindly.** Every candidate finding must pass this evidence state machine before entering the final report:

```text
Candidate → Context Inspected → Reproduced or Statically Proven
          → Severity Calibrated → Accepted or Rejected → Reported
```

Verification process:
1. Inspect sufficient surrounding code and the reachable call/data path.
2. Reproduce the behavior when safe and feasible; otherwise construct a concrete static proof.
3. Check that file, line, commit, runtime/config applicability, impact, and severity are accurate.
4. Record the validation command or inspection method and its actual result.
5. Classify confidence and conclusion type.
6. Mark the candidate `Accepted` or `Rejected` with a reason. Only accepted findings enter the findings table.

Every accepted finding must contain:
- Trigger and relevant context
- Reproduction or static proof
- Expected invariant and actual behavior
- Impact and affected scope
- Evidence location and validation method
- Severity, confidence, and unverified assumptions

#### Conclusion and Confidence Types

| Type | Meaning |
|------|---------|
| `Confirmed` | Reproduced or directly proven through a reachable code/config path |
| `Likely` | Strong static evidence exists, but runtime confirmation is unavailable |
| `Exposure` | A dangerous surface exists, but no exploitable path has been established |
| `Verification gap` | An important property could not be checked with available evidence |
| `N/A` | The relevant system surface does not exist |

Confidence (`High | Medium | Low`) is separate from severity (`P0 | P1 | P2`). A high-impact hypothesis may be `P0 / Low confidence`; a confirmed minor issue may be `P2 / High confidence`.

#### Evidence Rejection Rules

Reject or downgrade evidence when:
- It is only a keyword hit without surrounding context or reachability.
- A dangerous function exists but no production call path reaches it.
- Missing tests are used to claim the underlying behavior is broken.
- A dependency advisory is reported without checking the resolved version and reachable usage.
- The line number or content belongs to another commit.
- Generated code, examples, fixtures, vendored files, or inactive configuration are mistaken for production behavior.
- Tool or agent output cannot be reproduced in the current audit baseline.
- Severity is inferred from a label rather than impact and exploitability.

Batch verification pattern:
```python
from hermes_tools import terminal, read_file

checks = {
    "S-P0-1": "grep -n 'vulnerable_pattern' src/routes/auth.ts",
    "B-P1-1": "grep -n 'missing_transaction' src/services/payment.ts",
    "F-P2-1": "grep -n 'uncontrolled_input' src/components/form.tsx",
}
for key, cmd in checks.items():
    r = terminal(cmd, timeout=10)
    out = r.get("output", "").strip()
    print(f"{key}: {'✅' if out else '❌ not found'}")
```

Common false positive patterns:
- Guard clause misjudgment
- Severity inflation
- `process.env.XXX` mistaken for hardcoded secret
- Dead code labeled P0

### 2.5 Write Report Automatically

Write the report to `docs/99_audits/` without asking. Create the directory if it does not exist.

#### Naming Convention

All audit files use the `99_` prefix so they sort at the end of `docs/`:

```
docs/99_audits/
├── 99_00_security.md
├── 99_01_backend_health.md
├── 99_02_shell_health.md
└── 99_9999_deferred.md
```

Rules:
- Sequential number starting at `99_00`
- Format: `99_NN_<aspect>.md`
- `<aspect>` = main focus of the audit, 1–3 words max, keep filename short
- Do not use full dates or long descriptions in the filename
- Example: `99_03_deps.md`, `99_04_auth.md`, `99_05_config.md`

#### Deferred File

There is exactly one deferred file per project:

```
docs/99_audits/99_9999_deferred.md
```

All deferred items must be moved there. Do not keep deferred items inside individual audit files.

Each deferred entry must include:
- Original audit file (e.g., `99_00_security.md`)
- Audit item ID (e.g., `S-P0-1`)
- Issue summary
- Why deferred
- Planned fix date or condition

#### Status Tracking

Every finding in an audit file has a **Status** column. Allowed values:

| Status | Meaning |
|--------|---------|
| `Open` | Not fixed yet |
| `Fixed` | Fix verified |
| `Deferred` | Moved to `99_9999_deferred.md` |
| `Declined` | User chose not to fix |

When an item is fixed or deferred, update its status in the audit file immediately. Do not leave fixed items as `Open`.

#### Report Format

```markdown
# 99_NN — <aspect> — <date>
## Scope
- Range: <commit-old>..<commit-new>
- Files: <N> changed
- Baseline: <branch>@<HEAD>; worktree <clean|dirty>; uncommitted changes <included|excluded>
- Auto-selected depth: <quick|standard|deep>
- Risk score: <N> (<signals>)

## System Goal & Critical Paths
- Goal / protected properties: ...
- Path health: ...

## Confirmed Strengths
- <verified control worth preserving>

## Verification Gaps
- <property not checked, why, and what evidence is needed>

## Findings

### P0 — Must Fix
| ID | Type | Confidence | Status | Title | Path/Dimension | File | Line | Evidence | Fix |
|----|------|------------|--------|-------|----------------|------|------|----------|-----|
| S-P0-1 | Confirmed | High | Open | SQL injection | Search / Security | routes/query.ts | 45 | Reachable unparameterized query; validation command... | Use parameterized query |

### P1 — Should Fix Soon
...

### P2 — Nice to Have
...

## Fix Guide
1. S-P0-1: ...
2. B-P1-1: ...

## Doc Updates Needed
- <specs/schemas to update>

## Evidence Log
- <candidate → validation → accepted/rejected>
```

#### Audit Acceptance Checks

Before presenting the report, verify all of the following:
- Every applicable dimension has a result; absent surfaces are explicitly `N/A — reason`.
- Every required critical path has a health result or a named blocker.
- Every accepted finding has reproducible evidence or a concrete static proof.
- All file/line references match the recorded baseline.
- Severity and confidence were calibrated separately.
- Candidate findings were accepted or rejected; raw scanner output is not presented as fact.
- Confirmed controls/strengths that should be preserved are recorded.
- Unrun tests, unavailable environments, credentials, external systems, and other evidence limits are explicit.
- Audit tools did not leave unintended worktree changes.

### 2.6 Present Findings

Output a concise summary to the user:
- Audit number and scope
- Risk score and selected depth
- Count of P0 / P1 / P2 issues
- Location of the full report
- Top 3 issues with one-line impact

Do not ask "What do you want to do next?" unless the user is entering the fix workflow.

---

## Section 3: Verification Audit (Fix Verification)

When user says "已修复" / "修好了" / "verify fixes" after a previous audit.

Process:
1. Record current HEAD and compare it with the baseline stored in the previous audit. Fetch/pull only if the user explicitly requested remote synchronization.
2. `git diff <old>..<new>` — see what changed
3. Batch verify each previous finding
4. **Update status** in the original audit file for every fixed/deferred item
5. Scan for new issues — fixes may introduce regressions
6. Write concise verification report automatically

Key: Don't redo full audit. Only cover previous findings + fix-induced issues.

**Critical:** After verification, no finding in any audit file may remain `Open` if it has been fixed. Update the status column to `Fixed` and include the verification commit hash.

---

## Section 4: AI / Prompt Security Audit

When code passes user input through LLM and stores/writes output.

### Threat Model

| Dimension | Risk |
|-----------|------|
| Prompt injection | User input manipulates LLM output |
| DB tampering | LLM output written to DB without validation |
| Data exfiltration | LLM output leaks to other users |
| Command execution | LLM output used in eval/exec/SQL |
| Tool calling abuse | LLM invokes functions/tools outside intended scope |
| RAG isolation failure | Retrieved context contains other users' private data |

### Audit Chain

1. **Input entry** — grep all routes accepting free text → AI
2. **Sanitization** — find `sanitizeForPrompt` or equivalent:
   - Control character stripping
   - Template injection prevention (`{{var}}` substitution)
   - Prompt injection keyword filtering
   - Length truncation
3. **Prompt assembly** — user input in system prompt or user message?
4. **Output validation** — Zod/JSON schema on AI response:
   - `z.enum([...])` = hard wall (safe)
   - `z.string()` = open surface (dangerous)
   - Numeric ranges validated?
5. **DB write** — raw AI output or filtered subset stored?
6. **Re-injection** — stored data read back into future prompts?
   - Same sanitization as input entry point
7. **Execution surface** — AI output → eval/exec/SQL/template?
8. **Tool/function calling** — which tools can the LLM invoke? Are parameters validated?
9. **RAG retrieval** — is retrieved context scoped to the current user/tenant?

### Key Principle

**Zod enums are the hard wall.** If every field is `z.enum([...])`, prompt injection can only produce valid enum values. Danger is in `z.string()` fields and missing sanitization on re-injection paths.

---

## Section 5: Maintainability & Boundary Audit

The audit above catches what *breaks*. This section catches what *rots*: unclear boundaries, over-engineering, and code that is hard to change or upgrade. These rarely cause an immediate crash, so they default to **P1** (structural risk) — never inflate them to P0.

Guiding principle (the audit's own north star): **keep boundaries clear, don't overreach, stay easy to maintain and upgrade, and don't make simple things complex.** Apply it to the code under audit — and to any fix you propose.

### 5.1 Boundary Clarity & No Overreach（边界清晰·不越权）

A module should do one job and reach only where it is allowed to. Flag:

- **Cross-layer reach-in** — UI/component code touching the DB or ORM directly; a route handler embedding business rules; a "util" function that mutates global state, writes files, or makes network calls.
- **Responsibility leakage** — one module doing work that belongs to another (e.g., a formatter that also validates and persists).
- **Hidden coupling** — modules communicating through global variables, singletons, or side effects instead of explicit inputs/outputs.
- **Scope creep in a single unit** — a function/class that grew to own unrelated concerns (auth + logging + business logic in one place).

Verification anchors:
```bash
# UI/components reaching directly into DB/ORM (should go through a service layer)
grep -rn "prisma\.\|db\.\|knex(\|mongoose\.\|sequelize\." src/components src/pages src/app --include="*.tsx" --include="*.jsx" 2>/dev/null | head -20
# "util/helper" files with side effects (network, fs, global mutation) — utils should be pure
grep -rn "fetch(\|axios\|fs\.\|process\.env\|globalThis\|window\." src/utils src/lib/helpers --include="*.ts" 2>/dev/null | head -20
```

### 5.2 Maintainability & Upgradability（好维护·好升级）

Can the next person change this safely, and can dependencies move forward without a rewrite? Flag:

- **Hardcoded config** — magic values, URLs, keys, limits that should be config/env; the same constant duplicated across files.
- **Shotgun surgery** — adding one feature forces edits in many scattered places (missing a single extension point / registry / factory-of-last-resort).
- **Upgrade traps** — unpinned or wildcard dependency versions, deep imports into a library's internals, forked/patched vendor code with no migration note, deprecated APIs still in use.
- **Contract drift** — public interface / API / schema no longer matches its docs or callers (ties into spec↔code alignment).

Verification anchors:
```bash
# Wildcard / unpinned deps (upgrade risk)
grep -rn "\"\\^\\|\"~\\|\"\\*\"\|latest" package.json 2>/dev/null | head -20
# Deep imports into library internals (breaks on upgrade)
grep -rn "from '.*/node_modules/\|/dist/\|/lib/internal" src/ --include="*.ts*" 2>/dev/null | head -20
# Deprecated markers still referenced
grep -rn "@deprecated\|DEPRECATED" src/ --include="*.ts*" 2>/dev/null | head -20
```

### 5.3 Anti-Over-Engineering / KISS（别把简单事做复杂）

Complexity must be earned by a real, present requirement — not a hypothetical one. Flag:

- **Speculative generality (YAGNI)** — abstractions, config flags, or plugin points built for needs that do not exist yet.
- **Needless indirection** — factory/strategy/wrapper layers, single-implementation interfaces, or one-line "manager" classes where a plain function would do.
- **Accidental complexity** — deep nesting, long parameter lists, high cyclomatic complexity, or a design pattern applied where three lines suffice.
- **Premature optimization** — caching/pooling/micro-tuning with no measured bottleneck, at the cost of readability.

Verification anchors:
```bash
# Single-implementation interfaces / abstract classes (candidate over-abstraction)
grep -rn "interface \|abstract class " src/ --include="*.ts" 2>/dev/null | head -20
# Deep nesting (rough complexity proxy: 6+ levels of indentation)
grep -rnE "^( {24,}|\t{6,})\S" src/ --include="*.ts*" 2>/dev/null | head -20
# "Manager/Factory/Wrapper/Helper" proliferation
grep -rln "Manager\|Factory\|Wrapper\|Abstract" src/ --include="*.ts*" 2>/dev/null | head -20
```

### 5.4 Reporting

Report these findings in the normal audit file (a dedicated `99_NN_maintainability.md` when they are the audit's main focus, otherwise inline). Each finding still needs concrete evidence and a location — the same verify-before-report rule from Section 2.4 applies. A "this could be simpler" claim with no file:line is a false positive.

When proposing a fix, the fix itself must obey the north star: prefer the smallest change that clarifies the boundary or removes the excess complexity. Do not fix over-engineering by adding more abstraction.

---

## Section 6: Document Management

### 6.1 Status Sync

When user asks to "梳理文档" / "check doc status":

Critical: Don't trust document header status markers. They often lag behind code.

Process:
1. List all docs: `find docs/ -name '*.md' | sort`
2. Read header 10-15 lines, collect status markers
3. For non-complete docs, verify against code:
   - Specs/tasks → delegate subagent to check each feature point against code
   - Execution plans → `git log --grep` search related commits
   - "Pending migration" → check database/server for actual status
4. Update document headers with `patch`
5. Write next-steps summary
6. If the user explicitly requested document updates, apply them; commit only with separate explicit authorization

### 6.2 Document Decomposition

When a doc becomes a "junk drawer" mixing bugs, features, branding, tech specs:

1. Overlap analysis — compare against all existing docs
2. Classify each block — duplicate / outdated / unique
3. Redistribute — unique content to correct destinations
4. Delete original — commit with itemized list

Pitfall: Version conflicts — bloated docs often have outdated values. Keep the more recent/authoritative version.

---

## Section 7: Priority Levels

| Level | Meaning | Examples |
|-------|---------|----------|
| **P0** | Must fix immediately | Data loss, security breach, algorithm bugs, crashes |
| **P1** | Fix soon | Hardcoded values, type mismatches, missing cleanup, perf issues |
| **P2** | Nice to have | DRY improvements, dead code, style issues, minor refactors |
| **⊘** | Declined | User chose not to fix — record reason, don't re-raise |

---

## Section 8: Fix Mode

**Fixing is separate from auditing.** The audit phase ends when the report is written and findings are presented.

Enter fix mode only when the user explicitly says:
- "修一下"
- "你自己修复"
- "fix these"
- "apply the recommendations"

### Can Fix Autonomously
- Hardcoded colors → CSS variables
- Missing cleanup (console.log, dead imports)
- Obvious bugs (missing null check, wrong variable name)
- Simple refactors (extract duplicate code)

### Must Ask User First
- Architecture decisions
- Database schema changes
- New features or behavior changes
- Any fix requiring domain judgment
- Any P0 security fix

### Fix Process
1. Present the proposed fixes
2. Get explicit confirmation
3. Apply fixes with `patch` or equivalent
4. Verify fixes with grep/tests
5. **Update the audit file status** for every fixed item: change `Open` → `Fixed`, add verification commit hash
6. If an item is deferred, change its status to `Deferred` and move it to `docs/99_audits/99_9999_deferred.md`
7. Write a verification note
8. Only push if user confirms (`push_report: true` or explicit approval)

**Critical rule:** After any fix, scan all audit files in `docs/99_audits/`. No item may remain `Open` if it has already been fixed or deferred.

---

## Section 9: Pitfalls & Recovery

### Agent Timeout
Large changes may timeout subagents. Accept partial results, use `execute_code` to manually cover remaining areas.

### Push Conflicts
User may push during audit. Always `git pull --rebase` before push in fix mode.

### Wrong File Path
`write_file` resolves `~/projects/X` to a different directory than `terminal` (`/home/hermes/` vs `/root/`). Always use `terminal` heredoc for file writes:
```bash
cd ~/projects/<PROJECT> && cat > docs/99_audits/99_00_security.md << 'EOF'
...content...
EOF
```

### Memory Pressure
Memory often near limit. Before saving audit results, compress old entries. Keep only: latest hash, fix rate, top unresolved issues.

### Don't Audit Prematurely
Wait for user's "改完了/已提交" signal before pulling for verification. If they say "先等下，我还在改" — wait.

### Multi-Project Confusion
When user mentions "two projects" without naming:
1. `git log` check all known projects for recent commits
2. If ambiguous, ask once: "X and Y have new commits, is it these two?"
3. Never guess — wrong audit wastes time and tokens

### Tool Side Effects
Some static-analysis tools write cache files. Run them in read-only mode or clean up artifacts after the audit so the repo is not polluted.

---

## Section 10: Quick Reference

### Auto-Scoping Commands

```bash
# Tech stack
ls package.json go.mod pyproject.toml requirements.txt Cargo.toml pom.xml build.gradle 2>/dev/null

# Payment signals
grep -Rin "stripe\|paypal\|square\|adyen\|alipay\|wechatpay\|braintree" . --include="*.json" --include="*.ts" --include="*.js" --include="*.tsx" --include="*.jsx" --include="*.py" --include="*.go" --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist --exclude-dir=build --exclude-dir=.next 2>/dev/null | head -20

# Auth signals
grep -Rin "passport\|next-auth\|jwt\|clerk\|auth0\|oauth\|oidc\|keycloak" . --include="*.json" --include="*.ts" --include="*.js" --include="*.tsx" --include="*.jsx" --include="*.py" --include="*.go" --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist --exclude-dir=build --exclude-dir=.next 2>/dev/null | head -20

# PII signals
grep -Rin "ssn\|password\|credit_card\|phone\|dob\|date_of_birth\|address\|national_id\|id_number\|passport_number" . --include="*.prisma" --include="*.sql" --include="*.ts" --include="*.js" --include="*.py" --include="*.go" --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist --exclude-dir=build --exclude-dir=.next 2>/dev/null | head -20

# Infra / deployment
ls Dockerfile docker-compose.yml .github/workflows .gitlab-ci.yml 2>/dev/null
find . -maxdepth 2 -type d \( -name terraform -o -name k8s -o -name helm \) 2>/dev/null
```

### Verification Command Templates

```bash
# Security
grep -rn "eval\|exec\|Function(" src/ --include="*.ts" | head -20
grep -rn "innerHTML\|dangerouslySetInnerHTML" src/ --include="*.tsx" | head -20
grep -rn "SELECT.*+\|INSERT.*+" src/ --include="*.ts" | head -20

# Health
grep -rn "console.log\|console.warn" src/ --include="*.ts*" | wc -l
grep -rn "TODO\|FIXME\|HACK" src/ --include="*.ts*" | wc -l
find src/ -name "*.ts*" -type f | wc -l

# Types
npx tsc --noEmit 2>&1 | grep "error TS" | wc -l
```

### Report Template

```markdown
# 99_NN — <aspect> — <Date>
## Scope
- Commits: <old>..<new> (<N> commits)
- Files: <M> changed
- Baseline: <branch>@<HEAD>; worktree <clean|dirty>; uncommitted changes <included|excluded>
- Auto-selected depth: <quick|standard|deep>
- Risk score: <N>

## Summary
- P0: <N> | P1: <N> | P2: <N>
- New issues: <N> | Fixed from previous: <N>

## System Goal & Critical Paths
- Goal / protected properties: <...>
- <path>: <Healthy|At risk|Broken|Not verified> — dimensions <...>

## Confirmed Strengths
- <verified control worth preserving>

## Verification Gaps
- <what could not be checked, why, and evidence needed>

## P0 — Must Fix
| ID | Type | Confidence | Status | Title | Path/Dimension | File | Line | Evidence | Fix |
|----|------|------------|--------|-------|----------------|------|------|----------|-----|
| S-P0-1 | Confirmed | High | Open | SQL injection | Search / Security | routes/query.ts | 45 | Reachable query + validation result | Use parameterized query |

## P1 — Should Fix
...

## P2 — Nice to Have
...

## Verification Log
- Accepted: S-P0-1 — <reproduction/static proof>
- Rejected: B-P1-1 — <false-positive reason>

## 12-Dimension Coverage
- 1 Architecture: <result>
- ...
- 12 Deploy & Ops: <result>

## Doc Updates Needed
- <specs/schemas to update>

## Next Steps
1. Fix P0-1: ...
2. Fix P0-2: ...
```

### Deferred File Template

```markdown
# 99_9999 — Deferred

| Audit File | ID | Summary | Reason | Planned Fix |
|------------|----|---------|--------|-------------|
| 99_00_security.md | S-P0-1 | SQL injection | Waiting for ORM migration | 2026-06-30 |
```
