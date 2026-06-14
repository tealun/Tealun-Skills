---
name: project-audit
description: >
  Universal automated project audit skill — code review, security scan, architecture health check,
  and document management. Works with any tech stack (React/Vue/Node/Go/Python/DB/etc).
  Audit phase is fully automated; fix phase is separate and requires explicit confirmation.
version: 2.1.0
---

# Universal Project Audit

A methodology for auditing any codebase: identifying risks, verifying findings, and maintaining code health over time.

**Core principle:** The audit phase (discover + judge + report) runs automatically without user confirmation. The fix phase (modify code) is a separate workflow and always requires explicit approval.

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
  output_dir: docs/audits     # where reports are written automatically
  push_report: false          # audit phase never pushes; set true only for fix workflow
```

If the file is missing, use these defaults:
- mode: auto
- max_depth: deep
- max_duration_minutes: 20
- output_dir: docs/audits
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

### 2.1 Pull Latest Code

```bash
cd <project-path>
git pull
git log --oneline -15
```

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

Reference `references/deep-audit-checklist.md` for command templates.

#### Standard Audit (score 3–5)

Run 5 specialist agents in two batches (max 3 concurrent):

**Batch 1 — Core Risks:**
1. **Security Agent** — Auth, injection, XSS, IDOR, data exposure, race conditions, rate limiting
2. **Backend Agent** — API semantics, error handling, transactions, N+1, idempotency, DB health
3. **Frontend Agent** — Controlled components, render perf, memory leaks, error boundaries, a11y

**Batch 2 — Code Quality:**
4. **Architecture Agent** — Module boundaries, naming, typing, spec↔code alignment, duplication
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

Use the time cap from config. If the cap is reached, stop and report findings so far, noting the partial coverage.

### 2.4 Verify Agent Reports (CRITICAL)

**Never trust sub-agent reports blindly.** Every finding must be manually verified before entering the final report.

Verification process:
1. For each reported issue, `read_file` or `grep` to confirm it exists
2. Check: file path correct? Line number accurate? Severity appropriate?
3. Mark each finding: ✅ Verified / ❌ False positive (explain why)
4. Only verified findings enter the final report

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

Write the report to `output_dir` without asking.

Report format:
```markdown
# Audit #NN — <date>
## Scope
- Range: <commit-old>..<commit-new>
- Files: <N> changed
- Auto-selected depth: <quick|standard|deep>
- Risk score: <N> (<signals>)

## Findings

### P0 — Must Fix
| ID | Title | File | Line | Evidence | Fix |
|----|-------|------|------|----------|-----|
| S-P0-1 | SQL injection | routes/query.ts | 45 | Unparameterized query | Use parameterized query |

### P1 — Should Fix Soon
...

### P2 — Nice to Have
...

## Fix Guide
1. S-P0-1: ...
2. B-P1-1: ...

## Deferred
- <items moved to deferred list>

## Doc Updates Needed
- <specs/schemas to update>
```

Naming:
- `audit_NN_<short-desc>.md` or project-specific convention
- NN = sequential number (01, 02, ...)

Deferred items:
- Maintain one `deferred.md` or `99_deferred.md` per project
- Include: original audit ID, issue summary, why deferred, planned fix date

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
1. `git pull` → identify new range (last audit commit → new HEAD)
2. `git diff <old>..<new>` — see what changed
3. Batch verify each previous finding
4. Scan for new issues — fixes may introduce regressions
5. Write concise verification report automatically

Key: Don't redo full audit. Only cover previous findings + fix-induced issues.

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

## Section 5: Document Management

### 5.1 Status Sync

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
6. Commit all updates in one commit

### 5.2 Document Decomposition

When a doc becomes a "junk drawer" mixing bugs, features, branding, tech specs:

1. Overlap analysis — compare against all existing docs
2. Classify each block — duplicate / outdated / unique
3. Redistribute — unique content to correct destinations
4. Delete original — commit with itemized list

Pitfall: Version conflicts — bloated docs often have outdated values. Keep the more recent/authoritative version.

---

## Section 6: Priority Levels

| Level | Meaning | Examples |
|-------|---------|----------|
| **P0** | Must fix immediately | Data loss, security breach, algorithm bugs, crashes |
| **P1** | Fix soon | Hardcoded values, type mismatches, missing cleanup, perf issues |
| **P2** | Nice to have | DRY improvements, dead code, style issues, minor refactors |
| **⊘** | Declined | User chose not to fix — record reason, don't re-raise |

---

## Section 7: Fix Mode

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
5. Write a verification note
6. Only push if user confirms (`push_report: true` or explicit approval)

---

## Section 8: Pitfalls & Recovery

### Agent Timeout
Large changes may timeout subagents. Accept partial results, use `execute_code` to manually cover remaining areas.

### Push Conflicts
User may push during audit. Always `git pull --rebase` before push in fix mode.

### Wrong File Path
`write_file` resolves `~/projects/X` to a different directory than `terminal` (`/home/hermes/` vs `/root/`). Always use `terminal` heredoc for file writes:
```bash
cd ~/projects/<PROJECT> && cat > docs/audit.md << 'EOF'
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

## Section 9: Quick Reference

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
# Audit #NN — <Date>
## Scope
- Commits: <old>..<new> (<N> commits)
- Files: <M> changed
- Auto-selected depth: <quick|standard|deep>
- Risk score: <N>

## Summary
- P0: <N> | P1: <N> | P2: <N>
- New issues: <N> | Fixed from previous: <N>

## P0 — Must Fix
...

## P1 — Should Fix
...

## P2 — Nice to Have
...

## Verification Log
- ✅ <finding> — confirmed at file:line
- ❌ <finding> — false positive (reason)

## Deferred
- <item> (from audit #NN)

## Next Steps
1. Fix P0-1: ...
2. Fix P0-2: ...
```
