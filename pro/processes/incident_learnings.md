# Incident Learnings Database
#
# WHY THIS EXISTS: Every rule in CLAUDE.md started as an incident. This database
# captures the pattern: what went wrong, why, and what rule was added to prevent
# recurrence. Use this as a template for your own incident tracking.
#
# FORMAT: Each entry follows the pattern:
#   Date → What Happened → Root Cause → Fix → Rule Added

## Deploy Incidents

### Rapid-fire pushes causing data loss (Feb 2026)
**What:** 11 pushes in 2h caused overlapping deploys with concurrent database access. Customer orders were lost despite successful payment charges.
**Root cause:** Each push triggered a full deploy. Old and new containers shared database files during blue-green switchover. Rapid deploys amplified race conditions.
**Fix:** Added deploy pacing rules. Batched related changes into fewer commits.
**Rule:** "Avoid rapid-fire pushes to main. Batch related changes."

### Fix-on-fix chain for CSS bug (Feb 2026)
**What:** iOS carousel bug took 5 commits over several hours. Each push was a CSS guess that didn't work.
**Root cause:** Agent was guessing instead of diagnosing. iOS has specific behaviors (momentum scrolling, snap cascades) that require reading docs.
**Fix:** "Remove scroll-snap entirely on mobile" — 1 commit if diagnosed correctly.
**Rule:** "Fix-on-fix commits = systemic failure signal. If a bug takes 3+ attempts, the agent is guessing."

### Disk full blocking deploys (Feb 2026)
**What:** 8 Docker images × 1.5GB = 12.5GB. Disk at 95% → deploys blocked.
**Root cause:** No automated image cleanup. Stopped containers held refs to old images.
**Fix:** CI pipeline runs `docker prune` after deploy.
**Rule:** "Docker image cleanup on prod after each deploy."

### OOM during blue-green deploy (Feb 2026)
**What:** Instance had 1GB RAM. Blue-green runs 2 containers (~500MB each). Deploy triggered OOM kill → site down.
**Root cause:** Instance undersized for deploy strategy.
**Fix:** Upgraded to 2GB instance.
**Rule:** "Instance must handle 2× normal container memory for blue-green deploys."

### Deploy config error blocking all deploys (Feb 2026)
**What:** Unknown key in deploy config caused immediate validation error. No deploy attempted.
**Root cause:** Config key was nested wrong (should be top-level, was under proxy section).
**Fix:** Always validate config locally before pushing: `bin/[YOUR_DEPLOY_TOOL] config`.
**Rule:** "Validate deploy config locally first."

## Agent Quality Incidents

### Fabricated test results (Feb 2026)
**What:** Agent reported "tests: passed" in completion signal. Committed code had ERB syntax error. CI broke on main for 14 minutes.
**Root cause:** Agent ran tests BEFORE final edit, then reported the pre-edit result.
**Fix:** Post-commit test run is now mandatory. Must copy exact counts from terminal.
**Rule:** "SEQUENCE: commit → test → push. NEVER: test → commit → push."

### Uncommitted code sitting for days (Feb 2026)
**What:** Database migration + model change sat uncommitted on dev machine. Production had infinite retries because the fix wasn't deployed.
**Root cause:** Agent made the change but forgot to commit/push. No one checked.
**Fix:** Mandatory `git status` check before declaring task complete.
**Rule:** "Run git status app/ db/ before TASK_COMPLETE. Report uncommitted files."

### Agent instructions uncommitted (Feb 2026)
**What:** 9 agent instruction files edited but never committed/pushed. Changes to quality gates, blog publishing rules, rate limits — all unenforced.
**Root cause:** Operations edits agent files but doesn't own the commit cycle.
**Fix:** Operations chains a coder task to commit+push after editing agent files.
**Rule:** "Agent instructions are production config — uncommitted = unenforced."

## Product/Design Incidents

### Invisible product for 5+ hours (Feb 2026)
**What:** Hoodie and mug created in fulfillment provider but never made visible on site. Stakeholder asked multiple times.
**Root cause:** Creating agent completed step 1 (create) and declared done. Steps 2-4 (sync, set visible, verify) never happened.
**Fix:** Hard gate: task NOT complete until product visible or follow-up chained.
**Rule:** "Product launch is 4 steps, not 1. HARD GATE on visibility."

### 9 out of 10 sticker designs were slop (Feb 2026)
**What:** AI generated 10 stickers. 9 were text on colored circles — no illustration, no humor, no reason to buy.
**Root cause:** No taste filter. Only technical checks (dimensions, transparency).
**Fix:** Added taste gate, rejection targets (70-90%), specific rejection criteria.
**Rule:** "Quality > quantity. 60-70% rejection target."

### Item shipped with text defect (Feb 2026)
**What:** Product had badly placed text. Shipped to customers.
**Root cause:** Product agent self-certified quality. No QA chain existed.
**Fix:** Mandatory QA chain for all product tasks. Product must NOT self-certify.
**Rule:** "Product agents must NOT self-certify quality. QA is separate."

## Content/Social Incidents

### 5 blog episodes in 24 hours (Feb 2026)
**What:** Series meant to publish weekly was dumped all at once.
**Root cause:** Agent optimized for completion, not pacing. Brief said "1/week over months."
**Fix:** `bin/blog-publish check` enforces max 1 post/week via content calendar.
**Rule:** "Maximum 1 blog post per week. NEVER publish multiple in one session."

### Fake customer impact in social posts (Mar 2026)
**What:** Agent posted claiming "two paying customers never got their orders." Investigation confirmed these were test charges from internal IP.
**Root cause:** Agent dramatized internal test failures as customer harm.
**Fix:** Added rule against fabricating customer impact.
**Rule:** "NEVER frame internal test traffic as customer harm."

## Infrastructure Incidents

### CI runner silently disconnected (Feb 2026)
**What:** CI jobs stuck "queued" for 4+ hours. Runner process alive but not polling.
**Root cause:** BrokerServer SocketException killed polling but process stayed alive.
**Fix:** Health monitor auto-detects queued jobs >30min and restarts runner.
**Rule:** "If CI is stuck, check runner health first."

### Chat outage for 12 hours (Feb 2026)
**What:** CEO chat processor crash-looped for 12 hours.
**Root cause:** launchd plist had wrong PATH order. System Ruby (2.6) won instead of project Ruby (3.3.4).
**Fix:** All plists must set project Ruby first in PATH.
**Rule:** "launchd PATH: your Ruby MUST come first."

## Pattern: How to Add New Learnings

When an incident occurs:
1. Document: what happened, root cause, fix
2. Add rule to CLAUDE.md (with WHY comment + date)
3. Add check to relevant agent instructions
4. If applicable: add automated gate (script, pre-commit hook)
5. Add entry to this database
6. Review monthly: are the rules still relevant?
