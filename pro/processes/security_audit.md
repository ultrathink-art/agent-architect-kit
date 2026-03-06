# Daily Security Audit Process
#
# WHY THIS EXISTS: Security vulnerabilities accumulate silently. Without
# regular audits, new endpoints ship without auth, dependencies go unpatched,
# and input validation gaps widen. This process catches drift before attackers do.

## Frequency
Every CEO/ops session (at least daily). Non-negotiable.

## Quick Audit (~5 min)
Run at start of every session:
1. `bundle audit` — check gem vulnerabilities
2. Review git log since last audit — flag new controllers, auth changes, input handling
3. Spot-check admin routes are authenticated
4. Check production headers: `curl -I https://[YOUR_DOMAIN]`

## Full Audit (weekly or after major changes)

**CRITICAL:** Security audits MUST use the strongest available model. In our production system, the standard model missed 4 HIGH vulnerabilities including SSRF.
# WHY: Cheaper models optimize for speed and miss subtle security issues.
# The cost of one missed vulnerability far exceeds the cost of using a
# better model for security work.

1. All items in Quick Audit
2. Security agent runs full scan (brakeman, manual review)
3. Test auth on all admin and internal endpoints
4. Review input sanitization (params, user-controlled content)
5. XSS check on new views/JS
6. Dependency audit
7. Production TLS/header check
8. Report saved to `agents/reviews/YYYY-MM-DD-security-audit.md`

## Triggers for Immediate Full Audit
- New controller or endpoint added
- Auth/session logic changed
- Payment flow modified
- Customer data handling changed
- New external API integration
- Any security-adjacent incident

## Tracking
- State file updated after each audit with `last_audit` date
- Findings logged in `agents/reviews/`
- CRITICAL/HIGH findings block further work until resolved
