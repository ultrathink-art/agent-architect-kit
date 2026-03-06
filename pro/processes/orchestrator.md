# Agent Orchestrator System
#
# WHY THIS EXISTS: Manual agent management doesn't scale. The orchestrator
# enables autonomous execution: monitoring the queue, spawning agents,
# handling failures, and enforcing concurrency limits.

## Overview

The orchestrator polls the work queue and spawns Claude Code agents for ready tasks.

## Components

### bin/agent-orchestrator
Main daemon that:
- Polls work queue for tasks in "ready" state
- Spawns Claude Code agents for ready tasks
- Monitors agent completion via state files
- Handles task state transitions
- Enforces concurrency limits

### bin/agent-worker
Entry point for spawned agents:
- Loads task context and brief
- Builds agent-specific system prompt
- Runs Claude Code with --print mode
- **Sends heartbeat every 30s** to state file (and remote API if configured)
- Parses output for completion status
- Reports results via completion file

## Task States

```
pending → ready → claimed → in_progress → needs_review → completed
                                       ↘                ↗
                                        → completed ────┘
                                       ↘
                                        → failed (returns to ready, max 3 retries)
```

## Agent Completion Protocol (MANDATORY for all agents)
# WHY: Without completion signals, the orchestrator can't update task status.
# Feb 2026 audit found 4 of 9 agents missing completion protocol — tasks got
# stuck in needs_review indefinitely.

Every agent `.md` file MUST include these signals:
- `TASK_COMPLETE:` — task done, ready to close
- `NEEDS_REVIEW:` — human review required
- `BLOCKED:` — cannot proceed, needs help

## Work Queue Schema

```yaml
- id: WQ-XXX
  type: feature|bugfix|content|design|analysis|security
  subject: "Short description"
  role: coder|product|marketing|designer|security
  brief: "path/to/brief.md"
  status: pending|ready|claimed|in_progress|needs_review|completed
  owner: null
  priority: P0|P1|P2
  workflow: new_product|feature_dev|content_publish|security_audit
  created: "YYYY-MM-DD"
  blocked_by: [WQ-XXX]            # Task dependencies
  claimed_at: "ISO8601"           # When orchestrator claimed it
  retry_count: 0                  # Number of retries
  max_retries: 3
  last_failure: "reason"
```

## Running the Orchestrator

```bash
bin/agent-orchestrator              # One-shot
bin/agent-orchestrator --daemon     # Continuous (poll every 60s)
bin/agent-orchestrator --status     # Check status
bin/agent-orchestrator --dry-run    # See what would spawn
```

## Configuration

| Setting | Default | Description |
|---------|---------|-------------|
| MAX_CONCURRENT_AGENTS | 3 | Max parallel agents |
| POLL_INTERVAL_SECONDS | 60 | Daemon poll frequency |
| HEARTBEAT_INTERVAL | 30 | Worker heartbeat interval (seconds) |
| HEARTBEAT_STALE_SECONDS | 90 | Heartbeat age before considered stale |

## State Files

Located in `agents/state/agent_runs/`:

### Running state (WQ-XXX.running)
```yaml
task_id: WQ-029
role: coder
pid: 12345
started_at: "2026-01-29T10:00:00Z"
last_heartbeat: "2026-01-29T10:05:30Z"
log_file: agents/state/agent_logs/WQ-029-20260129-100000.log
```

### Completion state (WQ-XXX.complete)
```yaml
task_id: WQ-029
role: coder
result: completed|needs_review|blocked|failed
notes: "Summary of what was done"
completed_at: "2026-01-29T11:30:00Z"
```

## Safety
# WHY: Agents run with full permissions for autonomy. The safety mechanisms
# are: concurrency limits, heartbeat monitoring, and audit logging.

- Agents run with `--dangerously-skip-permissions` for autonomy
- This assumes the workspace is trusted
- Security gates still apply for sensitive changes
- All actions logged for audit

## Troubleshooting

### Agent not starting
1. Check `bin/agent-orchestrator --status`
2. Verify task has `status: ready`
3. Check MAX_CONCURRENT_AGENTS not exceeded
4. Review orchestrator logs

### Agent stuck / stale heartbeat
1. Check agent log file for errors
2. Check if output files exist — agent may have completed but crashed before signaling
3. If stale heartbeat (>90s): agent may be hung
4. If output exists: mark task complete via API
5. If no output: kill PID, reset to ready

### Task not completing
1. Check for .complete file in agent_runs/
2. Agent may not have output completion signal
3. Review agent log for final output
