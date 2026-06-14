# Deep Audit Checklist

Reference checklist for deep-dive verification commands. Adapt patterns to your project's file extensions and directory structure.

## Auto-Scoping & Risk Calibration

Run these commands before selecting audit depth. Count matches and sum the score. Do not ask the user — use the score to choose depth automatically.

### Project Fingerprinting

```bash
# Runtime / dependency manifests
ls package.json go.mod pyproject.toml requirements.txt Cargo.toml pom.xml build.gradle 2>/dev/null

# Infrastructure and deployment
ls Dockerfile docker-compose.yml .github/workflows .gitlab-ci.yml 2>/dev/null
find . -maxdepth 2 -type d \( -name terraform -o -name k8s -o -name helm -o -name .serverless \) 2>/dev/null

# Directory shape
find . -maxdepth 2 -type d | head -30
```

### High-Risk Signals (+3 each)

Count non-zero matches in each category. Use project-appropriate extensions.

```bash
# Payment processing
find . -type f \( -name "*.json" -o -name "*.ts" -o -name "*.js" -o -name "*.tsx" -o -name "*.jsx" -o -name "*.py" -o -name "*.go" \) \
  -not -path "*/node_modules/*" -not -path "*/.git/*" -not -path "*/dist/*" -not -path "*/build/*" -not -path "*/.next/*" \
  -exec grep -Rin "stripe\|paypal\|square\|adyen\|alipay\|wechatpay\|braintree" {} + 2>/dev/null | wc -l

# Authentication / authorization
find . -type f \( -name "*.json" -o -name "*.ts" -o -name "*.js" -o -name "*.tsx" -o -name "*.jsx" -o -name "*.py" -o -name "*.go" \) \
  -not -path "*/node_modules/*" -not -path "*/.git/*" -not -path "*/dist/*" -not -path "*/build/*" -not -path "*/.next/*" \
  -exec grep -Rin "passport\|next-auth\|jwt\|clerk\|auth0\|oauth\|oidc\|keycloak" {} + 2>/dev/null | wc -l

# PII fields in schemas and models
find . -type f \( -name "*.prisma" -o -name "*.sql" -o -name "*.ts" -o -name "*.js" -o -name "*.py" -o -name "*.go" \) \
  -not -path "*/node_modules/*" -not -path "*/.git/*" -not -path "*/dist/*" -not -path "*/build/*" -not -path "*/.next/*" \
  -exec grep -Rin "ssn\|password\|credit_card\|phone\|dob\|date_of_birth\|address\|national_id\|id_number\|passport_number" {} + 2>/dev/null | wc -l

# File upload handlers
find . -type f \( -name "*.ts" -o -name "*.js" -o -name "*.py" -o -name "*.go" \) \
  -not -path "*/node_modules/*" -not -path "*/.git/*" -not -path "*/dist/*" -not -path "*/build/*" -not -path "*/.next/*" \
  -exec grep -Rin "multer\|upload\|multipart\|formidable\|busboy" {} + 2>/dev/null | wc -l

# Admin / role surface
find . -type f \( -name "*.ts" -o -name "*.js" -o -name "*.tsx" -o -name "*.jsx" -o -name "*.py" -o -name "*.go" \) \
  -not -path "*/node_modules/*" -not -path "*/.git/*" -not -path "*/dist/*" -not -path "*/build/*" -not -path "*/.next/*" \
  -exec grep -Rin "admin\|superuser\|role\|permission" {} + 2>/dev/null | wc -l

# Webhook receivers
find . -type f \( -name "*.ts" -o -name "*.js" -o -name "*.py" -o -name "*.go" \) \
  -not -path "*/node_modules/*" -not -path "*/.git/*" -not -path "*/dist/*" -not -path "*/build/*" -not -path "*/.next/*" \
  -exec grep -Rin "webhook\|/hooks" {} + 2>/dev/null | wc -l

# Production deployment markers
find . -type f \( -name "Dockerfile" -o -name "docker-compose.yml" -o -name "*.tf" -o -name "*.yaml" -o -name "*.yml" \) \
  -not -path "*/node_modules/*" -not -path "*/.git/*" \
  -exec grep -Rin "prod\|production\|aws\|gcp\|azure" {} + 2>/dev/null | wc -l
```

Score each high-risk signal as **+3** if its count is > 0.

### Medium-Risk Signals (+1 each)

```bash
# User-facing API routes
find . -type f \( -name "*.ts" -o -name "*.js" -o -name "*.py" -o -name "*.go" \) \
  -not -path "*/node_modules/*" -not -path "*/.git/*" -not -path "*/dist/*" -not -path "*/build/*" -not -path "*/.next/*" \
  -exec grep -Rin "router\.\(get\|post\|put\|delete\|patch\)" {} + 2>/dev/null | wc -l

# Third-party HTTP clients
find . -type f \( -name "*.json" -o -name "*.ts" -o -name "*.js" -o -name "*.py" -o -name "*.go" \) \
  -not -path "*/node_modules/*" -not -path "*/.git/*" -not -path "*/dist/*" -not -path "*/build/*" -not -path "*/.next/*" \
  -exec grep -Rin "axios\|fetch\|requests\|httpx\|got(" {} + 2>/dev/null | wc -l

# Email / SMS sending
find . -type f \( -name "*.ts" -o -name "*.js" -o -name "*.py" -o -name "*.go" \) \
  -not -path "*/node_modules/*" -not -path "*/.git/*" -not -path "*/dist/*" -not -path "*/build/*" -not -path "*/.next/*" \
  -exec grep -Rin "sendMail\|sendgrid\|twilio\|nodemailer\|ses" {} + 2>/dev/null | wc -l

# Scheduled jobs
find . -type f \( -name "*.ts" -o -name "*.js" -o -name "*.py" -o -name "*.go" \) \
  -not -path "*/node_modules/*" -not -path "*/.git/*" -not -path "*/dist/*" -not -path "*/build/*" -not -path "*/.next/*" \
  -exec grep -Rin "cron\|schedule\|setInterval" {} + 2>/dev/null | wc -l

# Database writes
find . -type f \( -name "*.ts" -o -name "*.js" -o -name "*.py" -o -name "*.go" \) \
  -not -path "*/node_modules/*" -not -path "*/.git/*" -not -path "*/dist/*" -not -path "*/build/*" -not -path "*/.next/*" \
  -exec grep -Rin "\.create\|\.insert\|\.update\|\.delete\|\.save(" {} + 2>/dev/null | wc -l
```

Score each medium-risk signal as **+1** if its count is > 0.

### Depth Selection Rule

| Total Score | Selected Depth |
|-------------|----------------|
| ≥ 6         | Deep           |
| 3 – 5       | Standard       |
| < 3         | Quick          |

Respect `max_depth` from `.audit-config.yml`. If auto-selected depth exceeds `max_depth`, cap it.

### Low-Risk Project Markers

If the project matches any of these, score stays at 0:
- Only static files (HTML/CSS/MD) and no backend
- CLI tool with no network or file-server code
- Documentation-only repository

## Security

```bash
# Injection vectors
grep -rn "eval\|exec\|Function(" src/ --include="*.ts" --include="*.js" | head -20
grep -rn "innerHTML\|dangerouslySetInnerHTML" src/ --include="*.tsx" --include="*.jsx" | head -20
grep -rn "SELECT.*+\|INSERT.*+\|UPDATE.*+\|DELETE.*+" src/ --include="*.ts" --include="*.js" | head -20

# Auth & session
grep -rn "req\.body\|req\.query" src/routes/ --include="*.ts" | grep -v "z\." | head -20
grep -rn "jwt\.verify\|jsonwebtoken" src/ --include="*.ts" | head -10
grep -rn "cors\|helmet\|rateLimit" src/ --include="*.ts" | head -10

# Secrets exposure
grep -rn "api_key\|secret\|token\|password" src/ --include="*.ts" | grep -v "process\.env" | grep -v "// " | head -20
```

## Backend Health

```bash
# Error handling
grep -rn "catch (" src/ --include="*.ts" | grep -v "console\." | grep -v "logger\." | head -20
grep -rn "throw new" src/ --include="*.ts" | wc -l

# Transactions
grep -rn "BEGIN\|COMMIT\|ROLLBACK" src/ --include="*.ts" | head -20
grep -rn "\.transaction(" src/ --include="*.ts" | head -20

# N+1 queries
grep -rn "for.*await\|for.*\.map\|for.*\.forEach" src/services/ --include="*.ts" | head -20

# Idempotency
grep -rn "ON CONFLICT\|UPSERT\|INSERT.*IGNORE" src/ --include="*.ts" | head -20
```

## Frontend Health

```bash
# Uncontrolled inputs
grep -rn "value={\|onChange={" src/ --include="*.tsx" | grep -v "useState" | head -20

# Memory leaks
grep -rn "setInterval\|setTimeout" src/ --include="*.tsx" | grep -v "clear" | head -20
grep -rn "addEventListener\|removeEventListener" src/ --include="*.tsx" | head -20

# Error boundaries
grep -rn "componentDidCatch\|ErrorBoundary" src/ --include="*.tsx" | head -10
```

## Architecture

```bash
# Circular dependencies
cd src && npx madge --circular . 2>/dev/null || echo "madge not installed"

# Duplicate code
grep -rn "function.*similar\|const.*similar" src/ --include="*.ts" | sort | uniq -d | head -20

# Type coverage
npx tsc --noEmit 2>&1 | grep "error TS" | wc -l
npx tsc --noEmit 2>&1 | grep "implicitly has an 'any' type" | wc -l
```

## General Health

```bash
# Debug residue
grep -rn "console.log\|console.warn\|console.error" src/ --include="*.ts*" | wc -l
grep -rn "TODO\|FIXME\|HACK\|XXX" src/ --include="*.ts*" | wc -l

# Dead code
grep -rn "export.*function\|export.*const" src/ --include="*.ts" | while read line; do
  name=$(echo "$line" | sed 's/.*export //' | sed 's/function //' | sed 's/const //' | sed 's/:.*//' | sed 's/(.*//')
  count=$(grep -rn "$name" src/ --include="*.ts" | grep -v "export" | wc -l)
  if [ "$count" -eq 0 ]; then echo "$line"; fi
done | head -20

# Unused dependencies
npx depcheck 2>/dev/null || echo "depcheck not installed"
```

## Verification Patterns

### Confirm a fix exists
```bash
grep -n "fixed_pattern" src/file.ts | head -5
```

### Confirm a bug is gone
```bash
grep -n "old_bug_pattern" src/file.ts || echo "✅ Not found — likely fixed"
```

### Check adjacent code for similar issues
```bash
grep -n "pattern" src/module/*.ts | head -20
```

### TypeScript compilation after fix
```bash
npx tsc --noEmit 2>&1 | grep "error TS" | wc -l
```
