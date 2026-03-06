# Agent Architect Kit

**Production-tested multi-agent orchestration for Claude Code projects.**

This kit contains the battle-tested configuration, agent definitions, processes, and scripts that power a real production system with 10 AI agent roles running 100+ autonomous sessions.

Every rule, checklist, and process doc in this kit exists because something went wrong without it. The dates and commit references prove these aren't theoretical — they're battle scars from running autonomous AI agents in production since January 2026.

## What's Inside

### Core ($49) — `kit/core/`
The foundation for any Claude Code multi-agent project.

| File | Description |
|------|-------------|
| `CLAUDE.md` | Battle-tested project instructions with inline WHY comments |
| `agents/coder.md` | Senior engineer agent — implements, tests, deploys |
| `agents/qa.md` | QA engineer — verifies deploys, inspects designs, catches bugs |
| `agents/designer.md` | Creative director — trend research, AI image gen, quality filtering |
| `agents/product.md` | Product manager — catalog, quality gate, launch pipeline |
| `agents/marketing.md` | Marketing lead — content strategy, blog, social coordination |
| `agents/operations.md` | Operations manager — meta-agent that improves how agents work |
| `memory/memory-directive.md` | Persistent memory protocol for cross-session learning |

### Pro ($99) — `kit/pro/` (includes Core)
Process documentation for scaling beyond ad-hoc tasks.

| File | Description |
|------|-------------|
| `processes/work_queue.md` | Task queue system — states, priorities, workflows |
| `processes/orchestrator.md` | Autonomous agent spawning and monitoring |
| `processes/design_approval.md` | Quality gate — 70-90% rejection target |
| `processes/qa_checklist.md` | Post-deploy verification checklist |
| `processes/security_audit.md` | Daily security audit process |
| `processes/shareholder_feedback.md` | Feedback capture → P0 task pipeline |
| `processes/launch.md` | Product launch coordination across agents |
| `processes/engineering.md` | Engineering process — review, test, deploy, incident response |
| `processes/new_product.md` | Full product pipeline — discovery to launch |
| `processes/build_feature.md` | Feature development workflow — brief to deploy |
| `processes/incident_learnings.md` | Real incident database with patterns and fixes |

### Full ($149) — `kit/full/` (includes Core + Pro)
The orchestration scripts that make it all autonomous.

| File | Description |
|------|-------------|
| `scripts/agent-task` | CLI for managing the task queue (add, ready, claim, complete) |
| `scripts/agent-worker` | Entry point for spawned agents — context injection, heartbeat, completion |
| `scripts/agent-orchestrator` | Daemon that polls queue and spawns agents automatically |
| `scripts/queue-monitor` | Health monitor — detects stuck tasks, auto-recovers |
| `automation/launchd/` | macOS launchd plists for daemon automation |

## Quick Start (5 minutes)

### 1. Copy Core files to your project

```bash
# Copy the CLAUDE.md template
cp kit/core/CLAUDE.md your-project/CLAUDE.md

# Copy agent definitions
mkdir -p your-project/.claude/agents
cp kit/core/agents/*.md your-project/.claude/agents/
cp kit/core/memory/memory-directive.md your-project/.claude/agents/

# Create memory directories
mkdir -p your-project/agents/state/memory
```

### 2. Customize placeholders

Open `CLAUDE.md` and replace all `[YOUR_VALUE]` placeholders:

```
[YOUR_TOOL]         → your Ruby version manager (mise, rbenv, asdf)
[YOUR_VERSION]      → your Ruby version (3.3.4)
[YOUR_DEPLOY_TOOL]  → your deploy tool (kamal, capistrano)
[YOUR_SERVER_IP]    → your production server IP
[YOUR_DB]           → your database (SQLite, PostgreSQL)
[YOUR_DOMAIN]       → your domain (example.com)
[YOUR_ADMIN]        → your admin route prefix (admin, ceo)
[YOUR_MAX_AGENTS]   → max concurrent agents (3 recommended)
```

Do the same for each agent definition in `.claude/agents/`.

### 3. Initialize memory files

```bash
for role in coder qa designer product marketing operations; do
  cat > your-project/agents/state/memory/${role}.md << 'EOF'
# ${role^} Agent Memory

## Mistakes

## Learnings

## Stakeholder Feedback

## Session Log
EOF
done
```

### 4. Test with your first agent

```bash
cd your-project
claude --agent coder --print "List the files in this project and describe the architecture"
```

## Key Concepts

### Why CLAUDE.md matters
Claude Code reads `CLAUDE.md` at session start. Every rule there governs agent behavior. A well-maintained CLAUDE.md is the difference between agents that repeat mistakes and agents that learn.

### Why memory matters
Without persistent memory, agents start from zero every session. The memory directive ensures agents read their past mistakes and learnings before starting work.

### Why operations matters
The operations agent is the meta-agent — it monitors all other agents and edits their instructions to prevent recurring failures. It's the feedback loop that makes the system self-improving.

### Why quality gates matter
Self-reported "tests passed" is meaningless. Our production system had an agent fabricate test results (Feb 2026). The quality gate rules (exact counts, post-commit testing) exist to make fabrication detectable.

## Adapting to Your Project

This kit was built for a Rails e-commerce project, but the patterns work for any Claude Code project:

- **Non-Rails projects**: Adapt the coder agent's quality gates to your stack (pytest, jest, cargo test, etc.)
- **Non-e-commerce**: The designer/product agents adapt to any creative workflow. Replace the fulfillment references with your output platform.
- **Solo projects**: Start with just coder + qa + operations. Add more agents as complexity grows.
- **SaaS projects**: The engineering and security processes apply directly. Add deployment-specific rules to CLAUDE.md.

## Support

Questions? Issues? Open a GitHub issue or email [YOUR_SUPPORT_EMAIL].
