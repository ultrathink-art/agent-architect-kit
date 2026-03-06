# Work Queue System
#
# WHY THIS EXISTS: Without a centralized work queue, agents duplicate work,
# miss priorities, and lose track of what's been done. The queue is the
# nervous system of the agent team.

## Overview

The work queue is the single source of truth for all agent work. Tasks flow through defined states with mandatory gates at each transition.

**Source of truth**: Database-backed API at `/[YOUR_API_PREFIX]/orchestrator/api/queue.json`
(Legacy: `agents/state/work_queue.yml` for local-only setups)

## Quick Commands
```bash
bin/agent-task add coder "Fix bug"      # Create task
bin/agent-task ready WQ-029             # Mark ready for orchestrator
bin/agent-orchestrator --status         # Check queue/running agents
bin/agent-orchestrator --dry-run        # See what would spawn
bin/agent-orchestrator                  # Run orchestrator once
```

## Adding Work
```bash
bin/agent-task add <role> <subject> [type] [priority]
bin/agent-task add coder "Add analytics" feature P1
```

### Task Schema
```yaml
- id: WQ-XXX
  type: feature|content|analysis|design|bugfix|security
  subject: "Short description"
  role: coder|product|marketing|designer|security
  brief: "path/to/brief.md"  # Optional detailed spec
  status: pending|ready|needs_brief|needs_review
  owner: null
  priority: P0|P1|P2
  workflow: new_product|feature_dev|content_publish|security_audit
  created: "YYYY-MM-DD"
  blocked_by: [WQ-XXX]  # Optional: task dependencies
```

### Task States
# WHY: Clear state machine prevents tasks from being lost or worked on
# by multiple agents simultaneously.

- **pending**: Task created, not ready for execution
- **ready**: Task can be picked up (manually or by orchestrator)
- **claimed**: Orchestrator spawning agent
- **in_progress**: Agent actively working
- **needs_review**: Work done, awaiting human review
- **completed**: Task finished

### Priorities
- **P0**: Do today, blocks other work
- **P1**: Important, do this session if possible
- **P2**: Backlog, do when P0/P1 clear

## Workflow Gates
# WHY: Mandatory gates exist because every time they were skipped, something
# broke. Security review prevents vulnerabilities. QA prevents visible defects.
# Design QA prevents technical issues in print-ready assets.

**feature_dev:**
- Implement → QA check (tests pass) → Security review (if auth/data) → Deploy

**new_product:**
- Brief → Design → Design QA → Design review → Implement → QA → Deploy

**content_publish:**
- Draft → Editor review → Approval → Publish

## Mandatory Gates (NEVER skip)

1. **Security review** for: new controllers, auth changes, customer data, external APIs
2. **QA check**: tests must pass, manual verification on production
3. **Design QA** for all design tasks: `bin/design-qa` must pass, transparent bg for apparel, dimensions match spec
4. **No unauthenticated access** on internal tools

## Task Chains
# WHY: Without automatic task chains, completed work creates orphaned artifacts.
# Designs sit as files without fulfillment uploads. Code deploys without QA.

`next_tasks` field on tasks auto-spawns children on completion:
```yaml
next_tasks:
  - role: qa
    subject: "QA review for {{parent_task_id}}"
```

Chains fire server-side via the completion handler.

## Escalation

If blocked:
```yaml
blocked: true
blocked_reason: "Waiting for X"
blocked_since: "YYYY-MM-DD"
```
CEO reviews blocked items each session.

## Monitoring
```bash
bin/agent-orchestrator --status   # Running agents + queue
bin/agent-task list               # All tasks by status
```
