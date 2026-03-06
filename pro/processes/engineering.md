# Engineering Process
#
# WHY THIS EXISTS: Small team. No bureaucracy. Move fast with guardrails.
# Every section here exists because skipping it caused a production incident.

## Code Review Requirements

### All Changes
- [ ] Code review before merge to main
- [ ] Self-review for low-risk changes (typos, small styling, docs)
- [ ] Full review for: features, refactoring, dependencies

### Security Review Required For
- [ ] Authentication logic (login, signup, sessions)
- [ ] Payment handling (integration, transactions)
- [ ] User data access (authorization checks)
- [ ] New endpoints (verify routes protected)
- [ ] Database queries (no raw SQL)

### Review Checklist
- Does it work? (Tests pass)
- Is it safe? (No security holes)
- Does it follow patterns? (Matches existing code style)
- Can it break things? (Review migration/config changes)

## Testing Requirements

### Before Commit
```bash
bin/rails test              # All unit + integration tests
```

### Manual Testing
- [ ] UI changes: test in browser
- [ ] Mobile changes: verify on mobile viewport (375px, 768px, 1024px)
- [ ] Forms: test success and error states
- [ ] Edge cases: null/empty values, long text, special characters

### When to Skip Tests
Never. Always run tests.

## Deploy Process

### Automatic via CI/CD
- [ ] All commits to `main` trigger CI/CD pipeline
- [ ] **NEVER run deploy commands manually**
# WHY: Manual deploys bypass CI checks. Automated deploys ensure every push
# gets the same quality gates.
- [ ] Check deploy status in CI dashboard
- [ ] Production updates ~2-5 minutes after push

### After Deploy
```bash
bin/[YOUR_DEPLOY_TOOL] logs    # Monitor logs for errors
```

Watch for:
- [ ] No exceptions in logs
- [ ] Background jobs processing
- [ ] Database queries normal
- [ ] External integrations responding

### If Something Breaks
1. Rollback immediately (don't investigate first):
   ```bash
   bin/[YOUR_DEPLOY_TOOL] rollback
   ```
2. Then investigate offline
3. Document incident in `agents/decisions/incident-[YYYY-MM-DD].md`

## Security Checklist

### Code
- [ ] No raw SQL queries (use ActiveRecord/ORM)
- [ ] All user input escaped in views
- [ ] New endpoints have authorization
- [ ] No secrets hardcoded (all in encrypted credentials)
- [ ] Dependencies reviewed

### Database
- [ ] Migrations are safe for data
- [ ] Indexes added for slow queries
- [ ] No N+1 queries in critical paths

### External APIs
- [ ] API keys from credentials, not code
- [ ] Rate limits handled
- [ ] Error responses don't leak sensitive data
- [ ] Logging doesn't expose auth tokens

## Incident Response

**If production is broken:**

1. **Rollback immediately** — get the site back up. Investigation comes after.
2. **Verify it worked** — check logs
3. **Document what happened** — incident report
4. **Fix root cause** — add test coverage, improve checks
5. **Share learning** — update CLAUDE.md if process needs tweaking

## Common Patterns

### Adding a New Feature
1. Create migration (if needed)
2. Write test first
3. Implement model/controller/view
4. Add security review (auth, input validation)
5. Manual test (UI + edge cases)
6. Commit with clear message
7. Push to main (auto-deploys)
8. Monitor logs

### Fixing a Bug
1. Write test that reproduces bug
2. Fix the code
3. Verify test passes
4. Check no other tests broke
5. Commit with issue context
6. Deploy and verify

### Database Migration
- **Never** delete columns without discussion
- Always test rollback locally
- For large tables, migrate in phases
- Write idempotent migrations (safe to run twice)

## Who Does What

**Coder:** Implementation, bug fixes, commits, pushes
**Product:** Feature specs, acceptance criteria
**Designer:** Visual design, mockups, brand
**Marketing:** Launch coordination, content
**Security:** Code review for auth/payments/data
**CEO:** Orchestrates, delegates, reviews — does NOT write code or deploy
# WHY: Mixing execution and oversight creates conflicts. The CEO who deploys
# their own code can't objectively audit deployment quality.

## Visual QA Tools
```bash
bin/screenshot /path                    # Screenshot public page
bin/screenshot --admin /[YOUR_ADMIN]    # Admin page
bin/screenshot --mobile /path           # Mobile viewport (375x812)
bin/screenshot --full /path             # Full page screenshot
```

**Always screenshot after UI changes** — visual QA catches issues tests miss.
