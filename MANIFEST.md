# Agent Architect Kit — File Manifest

27 files organized into three tiers. Use what you need.

## Core — `core/`

The foundation: project instructions template + 6 agent role definitions + memory protocol.

```
core/
├── CLAUDE.md                    # Project instructions template (~350 lines)
│                                  Annotated with WHY comments for every rule.
│                                  Covers: deploy safety, quality gates, agent
│                                  orchestration, caching, mobile CSS, testing
│
├── agents/                      # 6 agent role definitions
│   ├── coder.md                 # Senior engineer: implement → test → deploy
│   ├── qa.md                    # QA engineer: verify deploys, inspect output
│   ├── designer.md              # Creative director: research → generate → QA
│   ├── product.md               # Product manager: catalog, quality gate, launch
│   ├── marketing.md             # Marketing lead: content, blog, social coord
│   └── operations.md            # Meta-agent: monitors others, fixes the system
│
└── memory/
    └── memory-directive.md      # Cross-session memory protocol
                                   Include in every agent via @ import
```

**8 files.** Everything you need to set up a multi-agent Claude Code project.

## Pro — `pro/`

Process documentation for scaling beyond ad-hoc tasks.

```
pro/
└── processes/                   # 11 process documents
    ├── work_queue.md            # Task queue: states, priorities, workflows
    ├── orchestrator.md          # Autonomous agent spawning system
    ├── design_approval.md       # Quality gate with 70-90% rejection target
    ├── qa_checklist.md          # Post-deploy verification checklist
    ├── security_audit.md        # Daily security audit process
    ├── shareholder_feedback.md  # Feedback → P0 task pipeline
    ├── launch.md                # Product launch coordination
    ├── engineering.md           # Engineering: review, test, deploy, incidents
    ├── new_product.md           # Product pipeline: discovery → launch
    ├── build_feature.md         # Feature dev workflow: brief → deploy
    └── incident_learnings.md    # Real incident database with fixes and rules
```

**19 files (8 core + 11 pro).** Processes that prevent the mistakes we made so you don't have to.

## Full — `full/`

Orchestration scripts that make it autonomous.

```
full/
├── scripts/                     # 4 orchestration scripts (Ruby)
│   ├── agent-task               # ~200 lines: CLI for task management
│   ├── agent-worker             # ~250 lines: Agent entry point with heartbeat
│   ├── agent-orchestrator       # ~250 lines: Daemon that spawns agents
│   └── queue-monitor            # ~200 lines: Health monitoring + auto-recovery
│
└── automation/
    └── launchd/                 # 2 macOS daemon configs
        ├── com.example.orchestrator.plist   # Keep orchestrator running
        └── com.example.queue-health.plist   # Hourly health checks
```

**27 files total.** The complete autonomous agent system.

## Placeholder Reference

All files use `[YOUR_VALUE]` placeholders for project-specific values:

| Placeholder | Example | Where Used |
|---|---|---|
| `[YOUR_COMPANY]` | Acme Corp | Agent descriptions |
| `[YOUR_SITE]` | acme.com | Product/marketing agents |
| `[YOUR_DOMAIN]` | acme.com | CLAUDE.md, scripts |
| `[YOUR_FRAMEWORK]` | Rails 8 | Coder agent |
| `[YOUR_DATABASE]` | PostgreSQL | Coder agent, CLAUDE.md |
| `[YOUR_DEPLOY_TOOL]` | kamal | CLAUDE.md, engineering |
| `[YOUR_SERVER_IP]` | 10.0.0.1 | CLAUDE.md |
| `[YOUR_TOOL]` | mise | CLAUDE.md |
| `[YOUR_VERSION]` | 3.3.4 | CLAUDE.md |
| `[YOUR_ADMIN]` | admin | CLAUDE.md, QA |
| `[YOUR_MAX_AGENTS]` | 3 | CLAUDE.md |
| `[YOUR_TARGET_AUDIENCE]` | developers | Designer, product |
| `[YOUR_TARGET_CUSTOMER]` | developer | Product, design approval |
| `[YOUR_API_PREFIX]` | ceo | Scripts |
| `[YOUR_RUBY_PATH]` | ~/.local/share/mise/... | launchd plists |
| `[YOUR_PROJECT_PATH]` | /home/user/project | launchd plists |
