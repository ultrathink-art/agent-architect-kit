# Changelog

All notable changes to the Agent Architect Kit are documented here.
This project follows [Semantic Versioning](https://semver.org/).

## [1.4.0] — 2026-08-17

### Added

- **First-class Codex setup** — `core/codex/AGENTS.md`, project
  `.codex/config.toml`, and six project-scoped `.codex/agents/*.toml` roles use
  Codex-native instruction and custom-agent conventions without Claude
  frontmatter, tool lists, imports, or model aliases.
- **Dual-harness worker adapter** — `AGENT_HARNESS=claude|codex` selects an
  argument-array command while keeping Claude as the default. Task and brief
  context is delivered through a protected stdin file; Codex defaults to the
  workspace-write sandbox without an approval bypass.
- **Pre-claim harness validation** — the orchestrator now checks executable,
  project instructions, role config, and sandbox/permission configuration
  before claiming a queued task. `agent-worker --check` provides the same
  no-write preflight for setup.
- **Auditable mandatory QA contract** — coder/product `--no-chain` now requires
  `--no-chain-reason`, forwards both fields, and surfaces the reason. The
  executable framework-neutral server reference rejects raw empty-chain
  bypasses, persists an audit note, and idempotently guarantees one QA child at
  completion while preserving origin and keeping untrusted children pending.
- **Hermetic product test suite** — fake harnesses and a local fake API cover
  command construction, protected prompt delivery, configuration failures,
  completion normalization, heartbeat and timeout cleanup, client QA defaults,
  opt-out persistence, and completion-time idempotency.

### Changed

- README compatibility claims now distinguish supported/tested Claude and Codex
  paths from merely portable Markdown patterns, with fresh setup and no-write
  smoke commands for both harnesses.
- Orchestrator and work-queue docs now define the authoritative server-side QA
  handoff and provenance contract.

## [1.3.0] — 2026-07-15

### Added
- **Untrusted-origin task controls in the shipped scripts** — v1.2.0's
  `untrusted_content.md` described origin tagging and the
  `--confirm-untrusted` human gate, but `full/scripts` didn't implement any
  of it. Now they do (client side): `agent-task add` stamps
  `origin: internal|untrusted` from `AGENT_ROLE` (customizable
  `UNTRUSTED_AGENT_ROLES` list), `agent-task ready` refuses inside
  untrusted-role sessions and requires `--confirm-untrusted` for
  untrusted-origin tasks, `agent-task show` surfaces origin, and
  `queue-monitor` skips untrusted-origin tasks in its auto-reset sweep.
- **Doc: shipped vs. your-server split** — `untrusted_content.md` gains a
  "What the Shipped Scripts Implement" section making explicit that the
  server-side gate (persist origin, propagate to chained children, reject
  ready without `confirm_untrusted`) must be ported to your own task API;
  the go-live checklist now marks each item *(shipped)* or *(your server)*.

## [1.2.0] — 2026-07-14

### Added
- **`pro/processes/untrusted_content.md`** — prompt-injection hardening for
  agent queues, distilled from production incidents: origin tagging on queue
  tasks, a human-confirm gate for untrusted-origin work, deny-by-default
  permissions enforced at the harness layer (not the prompt), content-as-data
  fencing rules, and memory provenance. Includes a go-live checklist for any
  agent that reads external content.
- **Integrity verification** — `checksums.txt` (SHA-256 manifest of every kit
  file) plus `full/scripts/verify-kit`, a dependency-free Ruby script that
  verifies a downloaded or cloned copy is unmodified (exit 0 clean, exit 1
  with a list of modified/missing/extra files).
- **README: Cross-Harness Compatibility section** — what ports to other
  harnesses (Codex CLI, Cursor, Opencode: all the markdown) and what assumes
  Claude Code (the `full/` orchestration scripts and launchd plists).

### Changed
- MANIFEST updated: 30 files, 12 process docs, 5 scripts.

## [1.1.0] — 2026-06-11

### Changed
- **Positioning:** this kit is now explicitly the **extended superset** of the
  [Agent Starter Kit Pro](https://ultrathink.art/items/250), which is the
  canonical free starting point. New users should begin with the starter kit
  and graduate here — the two kits previously overlapped without a clear
  relationship.
- Updated origin stat to 5,000+ autonomously processed tasks.

### Added
- This CHANGELOG, with a version header in the README, so "last updated" is
  visible.

## [1.0.1] — 2026-03-27

- README rewritten with What/Why/How structure; removed price-tier labels
  (the kit is and has always been free).
- Added Related Tools section linking to the Agent Suite repos.

## [1.0.0] — 2026-03-05

- Initial release: CLAUDE.md template, 6 agent role definitions, memory
  directive with curation system, 11 process docs, 4 orchestration scripts,
  launchd automation plists.
