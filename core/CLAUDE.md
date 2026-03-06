# Project Instructions (CLAUDE.md)
#
# WHY THIS FILE EXISTS: Claude Code reads CLAUDE.md at the start of every session.
# It's the single source of truth for project rules, conventions, and hard-won lessons.
# Every rule here exists because something went wrong without it. The dates and
# incident references prove these aren't theoretical — they're battle scars.
#
# HOW TO USE: Copy this file to your project root as CLAUDE.md. Replace all
# [YOUR_VALUE] placeholders with your project-specific values. Delete sections
# that don't apply to your stack. Add your own rules as you discover them.
#
# STYLE: Telegraph style. Noun-phrases OK. Drop filler/grammar. Minimize tokens.
# WHY: LLMs have finite context windows. Every wasted word pushes useful
# context out. Dense > verbose for instruction files.

## Local Dev
# WHY: Document your local toolchain so agents don't waste time guessing paths.
- **Ruby via [YOUR_TOOL]**: [YOUR_TOOL] shims provide Ruby [YOUR_VERSION] + gems in PATH. Commands like `bin/rails`, `bin/[YOUR_DEPLOY_TOOL]` just work — NO prefix needed.
- Or delegate to coder agent which handles env setup

## Adding JS Libraries
# WHY: Three separate incidents (Feb 2026) from the same root cause — agents kept
# trying CDN scripts, UMD builds, and importmap pins that don't work. These rules
# prevent a 4-commit fix-on-fix chain for every new JS library.

- **Importmap pins MUST use ESM builds** — `pin "lib", to: "...umd.min.js"` does NOT work with `import X from "lib"`. UMD has no ES module exports → import resolves to `undefined`. Use `/auto/+esm` or ESM-specific dist files.
- **External CDN scripts blocked by CSP** — `content_security_policy.rb` `script-src` only allows `:self` + your payment/analytics providers. Adding any new CDN requires CSP change (widens attack surface). **Preferred: vendor locally** — download to `public/` and reference as `/filename.js` (serves from `:self`).
- **For admin-only pages**: `<script src="/vendored-lib.js">` + plain `<script>` (NOT `type="module"`) using global `window.LibName`. Simpler than importmap wiring for one-page usage.

## Production Access
# WHY: SSH is a footgun for data queries. One bad command = data loss or OOM.
# Structured tools constrain what agents can do and log everything.
- **Prefer API tools over SSH** — use structured CLI tools (`bin/agent-task`, `bin/stats`, `bin/prod-exec`) instead of raw SSH or `[YOUR_DEPLOY_TOOL] app exec`. CEO agent should NEVER use `ssh` for queries — always use the tool layer.
- Console: `bin/[YOUR_DEPLOY_TOOL] console`
- Logs: `bin/[YOUR_DEPLOY_TOOL] logs`
- Server: [YOUR_SERVER_IP] — SSH only for infra ops (disk, docker, OOM), NEVER for DB queries

## Deploy (CRITICAL)
# WHY: Deploy is the highest-risk operation. Every rule here comes from a real
# incident that caused downtime, data loss, or blocked deploys for hours.

- **CI/CD deploys on push to main.** NEVER run deploy commands manually. Exception: P0 when CI runner is offline — check `gh run list --limit 5`.
# WHY: Manual deploys bypass CI checks. Feb 2026: billing blocked GitHub-hosted
# runners for ~12h. Self-hosted runner solved it but introduced new failure modes.

- **Self-hosted CI runner can silently disconnect** — runner process stays alive but stops polling for jobs. Jobs stuck "queued" indefinitely. If CI is stuck: check runner health, restart if needed.
# WHY (Feb 2026): Run stuck for 4h because BrokerServer SocketException killed polling
# but launchd showed runner as running.

- Coder agent owns the full cycle: implement → commit → push to main. CEO does NOT push or deploy.

- **Before committing**: `git status` — check for untracked files referenced by new code (helpers, migrations, concerns). Untracked = not in repo = CI fails.
# WHY: Untracked helper file → 17 test errors → deploy blocked.

- **Coder MUST run `CI=true bin/rails test` + `bin/brakeman --no-pager` AFTER final commit, BEFORE `git push`** — verify exit code 0. If tests fail, DO NOT push. Fix first.
# WHY (Feb 2026): Agent claimed "tests: passed" but committed code had ERB syntax
# error that broke CI on main for 14 minutes. Self-reported quality gates have zero
# enforcement. The pre-push local test run is the ONLY gate.

- **Avoid rapid-fire pushes to main** — each push triggers a full deploy cycle. Batch related changes into fewer commits.
# WHY (Feb 2026): 11 pushes in 2h caused overlapping deploys with concurrent
# database access. Orders were lost despite successful payment charges.
# Another incident: 24 pushes in 6h, 5 in 1h for one CSS fix.

- **Fix-on-fix commits = systemic failure signal** — if a bug takes 3+ commit attempts, the agent is guessing, not diagnosing. Read platform docs, understand the behavior, push ONE fix.
# WHY (Feb 2026): iOS carousel bug took 5 commits because each push was a CSS
# guess. Correct approach was "remove scroll-snap on mobile" — 1 commit.

- **[YOUR_DB] + Docker volume risk**: During deploy, old and new containers briefly share database files. Rapid successive deploys amplify this. If data goes missing, check sequences vs actual rows.

- **Docker image cleanup on prod** — each deploy pulls ~1.5GB image; old images accumulate. Monitor disk: `ssh [YOUR_USER]@[YOUR_SERVER_IP] "df -h / && docker system df"`. CI should prune after deploy.
# WHY (Feb 2026): 8 images × 1.5GB = 12.5GB → disk 95% full → deploys blocked.

- **Post-deploy checks are POST-deploy, not a gate** — checks that hit the production site can't run before the deploy exists. Never gate deploy on production site checks.
# WHY (Feb 2026): Production health check was a deploy prerequisite → bug in
# check script blocked ALL deploys for 4 commits.

- **Ruby 3.3 removed auto-require of OpenStruct** — `require "ostruct"` needed explicitly.

- **[YOUR_DEPLOY_TOOL] config changes: validate locally first** — `bin/[YOUR_DEPLOY_TOOL] config` catches config errors before push. Saves a full CI cycle.

- **Deploy tool uses `git archive` for build context** — untracked/gitignored files are NOT in Docker image. To inject dynamic values, use build args with ERB in deploy config.
# WHY (Feb 2026): Dashboard commit count took 3 commits because agent didn't
# understand: git archive excludes untracked files, CI shallow clone gives wrong
# counts, build ARGs need full git history.

- **Instance sizing matters** — OOM during deploy if instance too small (blue-green runs 2 containers simultaneously). Monitor memory usage.
# WHY (Feb 2026): t3.micro (1GB) OOM'd during blue-green deploy. Two containers
# = ~1GB total minimum. Upgraded to t3.small (2GB).

- **Deploy + exec = OOM risk** — deploy runs 2 containers. If additional exec containers also running, total memory exceeds limit → site down.
# WHY (Feb 2026): Deploy + stray exec containers → "Under memory pressure" →
# container SIGKILL'd → site down until reboot.

- **Ruby `Timeout.timeout` CANNOT reliably kill `Open3.capture3`** — it fails to interrupt blocking I/O syscalls. Use `Process.spawn` + deadline thread + `Process.kill` instead.
# WHY (Feb 2026): Zombie process ran for 7 days because Timeout never fired.

## Rules (MUST)
# WHY: These are zero-tolerance rules. Each one exists because violating it
# caused a real incident. "MUST" means "violation = trust issue."

- **[YOUR_STAKEHOLDER] is anonymous** - NEVER reveal name/identity in public content.
- **NEVER allow_unauthenticated_access on internal tools** - dashboards, admin pages, anything with business/customer/financial data MUST require auth. No exceptions.
- **NEVER use inline ENV vars in Bash** - `TOKEN=xyz cmd` triggers tool approval prompts. Store secrets in encrypted credentials, read via scripts/rake tasks.
- **Security review BEFORE deploy** for: new controllers, auth changes, customer data exposure, external API integrations.
- Work style: telegraph; noun-phrases ok; drop filler/grammar; min tokens. Applies to CLAUDE.md + replies.
- New files: no isolation. Pre-create: inspect ~2 same-type files; mirror structure/style/conventions.
- Comments: only for non-obvious *why*. Prefer naming/structure. Default: none.
- Keep files <~500 LOC; split/refactor as needed.
- **No N+1 queries** - model methods called from partials in loops MUST NOT make DB queries. Preload in controller before rendering.
# WHY: Homepage was making 50+ queries to render product cards. Use eager loading
# (`includes`) and preloader patterns.
- **No fake social proof** - don't display review stars, ratings, or counts without real data. FTC compliance risk.
- **No fabricated customer impact in content** — test orders are NOT "paying customers." NEVER frame internal test traffic as customer harm.
# WHY (Mar 2026): Agent posted social content claiming "two paying customers never
# got their orders" — investigation confirmed these were test charges.

## Agent Orchestration
# WHY: Multi-agent systems need strict coordination rules or they collide,
# duplicate work, and corrupt shared state.

- `bin/agent-task add <role> <subject>` - Create task (pending)
- `bin/agent-task ready <id>` - Mark task ready for orchestrator
- `bin/agent-orchestrator` - Spawns agents for ready tasks
  - `--status` - Show running agents
  - `--daemon` - Run continuously
  - `--dry-run` - Show what would be spawned
- **`CLAUDECODE` MUST be unset in every `Process.spawn` for agents** — orchestrator runs inside Claude Code session where `CLAUDECODE=1`. Child agents inherit it → "nested session" crash. Fix: add `"CLAUDECODE" => nil` to env hash.
# WHY (Feb 2026): 6 tasks affected before fix. Claude Code crashes with
# "nested session" error when CLAUDECODE env var is inherited.

- Task states: pending → ready → claimed → in_progress → review → complete
- Max [YOUR_MAX_AGENTS] concurrent agents, but **max 1 per git-pushing role** (coder, marketing) to prevent overlapping deploys.
# WHY (Feb 2026): 4 pushes in 18min caused 2 concurrent CI/CD runs.

- **Stuck tasks**: If tasks show "claimed" for hours, auto-detect + reset orphaned tasks. Root cause: usually API connection timeout during agent startup.
- **`WorkQueueTask: NEVER use `update!` — use `update_columns`** — `update!` triggers full validation; tasks with stale data block the entire queue.
- **`fail!` retries 3x then marks `failed`** — prevents infinite retry loops.
# WHY (Feb 2026): One task retried 319 times when Claude hit a usage limit.
# Three other tasks retried 148+ times each before fix deployed.

- **Rate limit handling** — detect Claude usage limits in agent-worker and call `fail!`. No global cooldown — rate limits on one agent don't block others.
- **Duplicate task prevention**: Before creating any task, query ready+claimed+in_progress for similar subjects.

### Scheduling & Automation
# WHY: Automated schedules ensure consistent execution. Without them, agents
# only work when manually triggered, creating gaps in coverage.

- **Work is schedule-driven, NOT queue-filling** — no script auto-generates tasks. Work comes from schedules and stakeholder direction.
- Queue health monitor runs hourly — resets stale tasks, alerts on stuck items.
- launchd/cron setup: define plists/crontab for each scheduled agent.
- **launchd PATH: your Ruby MUST come first** — plists must set PATH with your Ruby install BEFORE `/usr/bin`, or system Ruby wins → crash.
# WHY (Feb 2026): Wrong PATH order → crash-looped → 12h chat outage.
- **launchd `StartCalendarInterval` uses LOCAL time** — `Hour` is local timezone, NOT UTC.
# WHY (Feb 2026): Plists used UTC hours → agents ran 6h late.

## Agent Memory
# WHY: Without persistent memory, agents repeat the same mistakes every session.
# Memory is the mechanism that turns one-off debugging into permanent learning.

- Per-agent memory: `agents/state/memory/<role>.md` — mistakes, learnings, feedback, session log
- Protocol: `.claude/agents/memory-directive.md` (auto-included in every agent via `@`)
- Agents MUST read memory at session start, update before TASK_COMPLETE
- **Memory + instructions must be updated together** — memory learnings can contradict updated instructions. When rewriting agent instructions, ALSO update the memory file to mark old learnings as OBSOLETE.
# WHY (Mar 2026): Agent instructions rewritten but memory still said old rule →
# agent followed stale memory over new instructions.

- **Agent behavioral rules: only ZERO/ALWAYS thresholds work** — ratio rules ("1 in 5 comments can mention X") are unenforceable because LLMs can't count across independent sessions. Use absolute rules: "NEVER" or "ALWAYS."
# WHY (Mar 2026): "1 in 5" company mention rule failed → every comment
# mentioned the company because agents can't maintain running tallies.

## Work Queue
# WHY: The work queue is the nervous system of the agent team. Without it,
# work gets lost, duplicated, or done out of priority order.

- All work flows through `agents/state/work_queue.yml` (or database-backed queue)
- CEO adds tasks, agents claim from queue
- Workflows define required gates (security, QA, design review)
- **NEVER skip mandatory gates** - security review for auth, tests must pass, QA for designs
- **MANDATORY QA for coder AND product tasks** - every task must chain a QA review via `next_tasks`
# WHY (Feb 2026): Item shipped with visible text defect because product
# self-certified quality with no QA chain.

- **Task chains**: `next_tasks` field auto-spawns children on complete
  - Chain fires server-side on completion
# WHY (Feb 2026): Bare completion calls didn't trigger server-side chains →
# zero chains ever fired until fix.

## Quality Gates (MANDATORY before commit)
# WHY: Self-reported "tests passed" is meaningless without evidence. These rules
# exist because agents fabricated test results (Feb 2026 incident).

Run ALL of these before every commit:

```bash
# 1. Lint check - MUST PASS
bin/rubocop
# If failures: bin/rubocop -a to auto-fix, then re-run

# 2. Tests - MUST PASS (CI=true enables eager_load — catches missing files/classes)
CI=true bin/rails test

# 3. Security scan
bin/brakeman -q --no-pager
```

**DO NOT COMMIT if any gate fails.** Fix issues first.

**Quality gates are audited by operations weekly.** Rules:
1. **MUST include exact counts** — copy-paste numbers from terminal output (e.g., "539 runs, 0 failures, 0 errors"). Bare "passed" without counts = REJECTED.
2. **MUST report `post_commit_test`** — confirms tests ran AFTER the final commit.
3. **Fabricated results = trust violation** — if you can't run tests, report honestly as "not_run" with reason. Never claim "passed" without running.

### Post-Commit Sequence (CRITICAL)
# WHY: The order matters. Testing BEFORE the final commit means you tested
# different code than what you're pushing. This is how bugs slip through.

```bash
# SEQUENCE: commit → test → brakeman → push
# NEVER: test → commit → push (tests ran on wrong state)

git commit -m "description"

# 1. Run tests on the COMMITTED state
CI=true bin/rails test

# 2. Run brakeman on the COMMITTED state
bin/brakeman --no-pager

# IF EITHER FAILS: DO NOT push. Fix → new commit → re-run both gates.
# Only push after BOTH pass with exit code 0:
git push origin main
```

## Safety Rules
# WHY: Each rule here prevented (or would have prevented) a real incident.

- **Never** expose secrets or credentials in code or logs
- **Never** run migrations without explicit approval
- **Never** delete data without explicit approval
- **Never** use `allow_unauthenticated_access` on internal tools
- **Never remove dashboard sections, tables, or data displays** — "simplify" means improve backend code. It does NOT mean remove information from the UI.
# WHY (Feb 2026): Agent removed Bluesky notifications, subreddit table, and
# work queue section from dashboard — stakeholder wanted backend cleanup, not UI removal.

- **Always** push to main after quality gates pass
- **Always** read a file before editing it
- **Always** run quality gates before commit
- **NEVER push fix-on-fix commits within 10 minutes** — step back and understand the root cause before pushing another commit.
# WHY (Feb 2026): 2 commits pushed 49 seconds apart for the same bug. Each push
# triggers a full deploy cycle. Rapid pushes cause overlapping deploys.

- **Production features that depend on build/deploy context: read deploy config + Dockerfile + CI FIRST** — trace the FULL path: local dev → Dockerfile → deploy config → CI workflow → production container. One commit, not three.
# WHY (Feb 2026): Feature took 3 commits because agent didn't understand the
# full pipeline from local to production.

## Test Traffic Rules
# WHY: Agents running automated tests against production created fake analytics
# events that corrupted business metrics. The stakeholder couldn't trust any
# conversion data for weeks.

- **NEVER pollute the production funnel with test traffic.**
- **NEVER complete a real checkout on production** — don't submit orders via automation
- **All automated testing MUST use `test@[YOUR_DOMAIN]` email** — auto-flags as test
- **Use screenshot tools for visual verification only** — don't interact with forms
- **To verify checkout works**: read code paths, run test suite, check payment provider test mode

## Self-Review Checklist (before commit)
# WHY: Agents skip obvious checks when moving fast. This checklist catches the
# mistakes that cause fix-on-fix chains.

#### Code Quality
- [ ] **No typos in variable/method names**
- [ ] **Hash keys match** between producer and consumer
- [ ] **No hardcoded values** that should be configurable
- [ ] **Error handling** for API failures / nil returns

#### Framework Specific
- [ ] **No N+1 queries** - use `includes()` for associations
- [ ] **No DB queries in views** - all data from controller
- [ ] **Strong params** - new attributes permitted if needed

#### View/Frontend
- [ ] **Template block balance** - count opens vs closes when removing HTML sections
# WHY (Feb 2026): Homepage redesign removed a div containing `<% end %>` for a
# conditional 60 lines above → syntax error → CI broken on main.
- [ ] **Handle empty states and nil values**
- [ ] **Mobile responsive** - include breakpoints
- [ ] **Accessibility** - labels, alt text, semantic HTML

#### Security
- [ ] **No secrets in code** - credentials from encrypted store only
- [ ] **Auth required** - internal pages require authentication
- [ ] **Input sanitized** - user input escaped/validated

## Uncommitted Code Check (MANDATORY)
# WHY: Operations found uncommitted app code 4 separate times. The worst case:
# a database migration + model change sat uncommitted for days while production
# had infinite retries.

**BEFORE declaring task complete, run `git status app/ db/` and verify NO modified files remain.**

Rules:
- If modified files you intended to commit → `git add` + commit them NOW
- If modified files from a DIFFERENT task → list them in completion report
- If untracked new files referenced by your code → commit them

## Completion Signal (REQUIRED for orchestrator)
# WHY: The orchestrator parses this exact format to update task status.
# Without it, tasks get stuck in "needs_review" forever.

```
===TASK_COMPLETE===
status: deployed
commit: <short hash>
files_changed:
  - path/to/file1.rb
  - path/to/file2.rb
quality_gates:
  lint: passed/failed
  post_commit_test: passed (N runs, N assertions, N failures, N errors)
  brakeman: passed (N warnings)
uncommitted_app_code: none / list any remaining modified files
needs_security_review: true/false
summary: Brief description of what was implemented
===END_TASK===
```

## Caching Gotchas
# WHY: Each of these caused a production bug that took hours to diagnose.

- **No `return` inside `Rails.cache.fetch` block** — exits method without caching. Use `next value` instead.
- **Don't cache ActiveRecord objects** — stale on read. Cache IDs, load fresh in controller.
- **SQLite has no `ILIKE`** — use `LOWER(col) LIKE ?` with lowercase pattern. `ILIKE` is PostgreSQL-only.
- **`where.not(col: array)` skips NULLs** — `NOT IN` returns NULL (falsy) for NULL column values. Fix: `.where(col: nil).or(where.not(col: array))`.
- **`BigDecimal.to_json` → string, not number** — `render json: { price: big_decimal_value }` serializes as `"2.5"` (string). JS `.toFixed()` on strings throws TypeError. Always `.to_f` decimal values before `render json:`.
# WHY (Feb 2026): Promo discount was BigDecimal → JS crash → "Failed to apply code"
# for every customer with items in cart.

## ERB Templates
- **When removing HTML sections from ERB, trace `<% end %>` ownership** — `<% end %>` tags are often embedded inside removed divs and close blocks opened far above.
# WHY (Feb 2026): Removed div contained `<% end %>` for conditional 60 lines
# above → ERB syntax error → CI broken on main.

- **Unicode in ERB: use `\u{1F441}` not `\uD83D\uDC41`** — Ruby doesn't support UTF-16 surrogate pairs.

## Hotwire/Turbo
- Pages with custom JS initialization: add `data: { turbo: false }` to links. Forces full page reload.
- **Stimulus + inline JS conflict**: When Stimulus intercepts form submit, inline listeners won't fire. Put tracking calls inside Stimulus controller.
- **Turbo body script re-evaluation accumulates listeners** — guard with `if (!window._myListenerRegistered)` flag.

## Mobile CSS
# WHY: Mobile CSS bugs are the #1 source of fix-on-fix chains. These rules
# prevent the most common mistakes.

- **Container padding uses CSS variable** — `--container-padding` for consistent spacing. NEVER hardcode padding in mobile breakpoints.
# WHY (Feb 2026): Hardcoded override caused all content to hug viewport edges.

- **Mobile flex-wrap: override desktop `flex` shorthand** — `flex: 1` from desktop defeats `width: 100%` wrapping. On mobile, use `flex: 0 0 100%` to force wrap.
- **NEVER use `scroll-snap-type` on mobile carousels** — iOS Safari momentum scrolling cascades through snap points. Use `scroll-snap-type: none` on mobile.
# WHY (Feb 2026): Three fix attempts (mandatory→proximity→remove) proved only
# full removal works on iOS.

## Layout / Sticky Positioning
- **NEVER set `overflow-x: hidden` on `html`** — breaks `position: sticky` on all descendants. Set on `body` only.
# WHY (Feb 2026): Header never stuck because overflow-x was on both html and body.

## Minitest Patterns
# WHY: These gotchas waste hours debugging test failures.

- **No mocha** — use Minitest only. `require "minitest/mock"` for stubs.
- **Class method stubs**: `ClassName.stub(:new, fake_instance) { ... }`
- **Teardown FK ordering**: `delete_all` child records before parents.
- **Date-dependent tests MUST use `travel_to`** — tests asserting on `Date.today` break at month boundaries.
# WHY (Mar 2026): Test asserting "Feb" in output failed on March 1 → blocked deploys.

## Visual QA (REQUIRED for UI changes)
# WHY: Visual bugs that tests miss are caught instantly by screenshots.

```bash
bin/screenshot /path                    # Public page
bin/screenshot --admin /[YOUR_ADMIN]    # Admin page
bin/screenshot --mobile /path           # Mobile viewport
bin/screenshot --full /path             # Full page
```

## Key Directories
```
app/
├── controllers/     # Request handling
├── models/          # ActiveRecord models
├── views/           # ERB templates
├── services/        # Business logic
├── javascript/      # Stimulus controllers
└── mailers/         # Email templates

config/
├── routes.rb        # URL routing
└── credentials/     # Encrypted secrets

db/
├── schema.rb        # Current database schema
└── migrate/         # Migrations

test/                # Test suite
```

---

# Customization Guide
#
# 1. Replace all [YOUR_VALUE] placeholders with your project specifics
# 2. Delete sections for tech you don't use (e.g., Mobile CSS if no frontend)
# 3. Add your own rules as you discover project-specific gotchas
# 4. Keep the WHY comments — they prevent future you from deleting "unnecessary" rules
# 5. Review monthly: prune rules that no longer apply, add new ones
#
# Placeholder reference:
#   [YOUR_TOOL]         - Ruby version manager (mise, rbenv, asdf, rvm)
#   [YOUR_VERSION]      - Ruby version (3.3.4, etc.)
#   [YOUR_DEPLOY_TOOL]  - Deploy tool (kamal, capistrano, heroku)
#   [YOUR_SERVER_IP]    - Production server IP
#   [YOUR_USER]         - SSH user for production
#   [YOUR_DB]           - Database (SQLite, PostgreSQL, MySQL)
#   [YOUR_DOMAIN]       - Your domain (example.com)
#   [YOUR_ADMIN]        - Admin route prefix (admin, ceo, dashboard)
#   [YOUR_STAKEHOLDER]  - How you refer to your stakeholder internally
#   [YOUR_MAX_AGENTS]   - Max concurrent agents (we use 3)
