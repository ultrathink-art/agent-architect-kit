# Stakeholder Feedback Capture Process
#
# WHY THIS EXISTS: Stakeholder mentioned a design issue 3 times before it was
# fixed. Root cause: feedback wasn't immediately converted to tracked tasks.
# This process ensures every piece of feedback becomes an actionable task
# with tracking until resolution.

## The Problem This Solves

Stakeholder feedback gets lost in conversation, deferred as "minor," or addressed partially. Without immediate capture as P0 tasks, issues linger and erode trust.

## Process

### 1. Immediate Capture

When stakeholder reports ANY issue:

```bash
bin/shareholder-issue "<issue description>"
```

This automatically:
- Creates P0 task (highest priority)
- Marks it ready (immediate orchestrator pickup)
- Adds to tracking in state file
- Infers appropriate agent role from keywords

### 2. What Gets Captured

| Stakeholder Says | Becomes |
|-----------------|---------|
| "The product images show wrong background" | P0 designer task |
| "There are duplicate products" | P0 operations task |
| "Site is loading slowly" | P0 coder task |
| "Upload failed" | P0 product task |

### 3. Tracking

```yaml
stakeholder_open_issues:
  - reported: "2026-01-31"
    times_mentioned: 3
    issue: "Product images have wrong background"
    root_cause: "Designer completed without verifying spec"
    fix_tasks: ["WQ-184", "WQ-185"]
    status: "investigating"
```

Fields:
- `times_mentioned`: Increments if stakeholder raises again
- `root_cause`: Filled in after investigation
- `fix_tasks`: All tasks created to address
- `status`: investigating → fixing → RESOLVED

### 4. Resolution

When fixed: update status to `"RESOLVED - <date>"`.

## Priority Escalation
# WHY: Repeated mentions = process failure. The escalation ladder ensures
# that persistent issues get proportionally more attention.

| Times Mentioned | Action |
|----------------|--------|
| 1 | P0 task created, normal processing |
| 2 | Escalate — check why first fix failed |
| 3+ | CRITICAL — CEO reviews immediately, may need process change |

## Who Does What

### CEO Agent
- Capture feedback immediately via `bin/shareholder-issue`
- Review open issues each session
- Escalate if issues remain open >48 hours

### Operations Agent
- Monitor open issues
- Verify fixes actually work
- Close issues when confirmed fixed

### All Agents
- If stakeholder mentions same issue again, note it
- Don't dismiss or defer feedback

## Anti-Patterns

❌ "I'll remember to fix that later"
❌ "That's a minor issue"
❌ "We already have a task for something similar"
❌ Completing task without verifying fix works

✅ Immediate capture as P0 task
✅ Track until stakeholder confirms fixed
✅ Root cause analysis to prevent recurrence

## Metrics

Track in ops audits:
- Average time to resolve stakeholder issues
- Number of issues mentioned multiple times (lower = better)
- Root causes identified (drives process improvement)
