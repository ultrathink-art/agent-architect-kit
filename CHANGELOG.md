# Changelog

All notable changes to the Agent Architect Kit are documented here.
This project follows [Semantic Versioning](https://semver.org/).

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
