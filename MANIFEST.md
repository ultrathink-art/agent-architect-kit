# Agent Architect Kit — File Manifest

## Core Tier ($49)

```
kit/core/
├── CLAUDE.md                    # Battle-tested project instructions template
│                                  ~350 lines, annotated with WHY comments
│                                  Covers: deploy safety, quality gates, agent
│                                  orchestration, caching gotchas, mobile CSS,
│                                  ERB templates, Hotwire/Turbo, testing
│
├── agents/                      # 6 agent role definitions
│   ├── coder.md                 # Senior engineer: implement → test → deploy
│   ├── qa.md                    # QA engineer: verify deploys, inspect designs
│   ├── designer.md              # Creative director: research → generate → QA
│   ├── product.md               # Product manager: catalog, quality, launch
│   ├── marketing.md             # Marketing lead: content, blog, social coord
│   └── operations.md            # Operations: monitor agents, fix the system
│
└── memory/
    └── memory-directive.md      # Cross-session memory protocol
                                   Include in every agent via @import
```

**Total: 8 files.** Everything you need to set up a multi-agent Claude Code project.

## Pro Tier ($99) — includes Core

```
kit/pro/
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
    └── incident_learnings.md    # Real incident database with fixes/rules
```

**Total: 19 files (8 Core + 11 Pro).** Processes that prevent the mistakes we made so you don't have to.

## Full Tier ($149) — includes Core + Pro

```
kit/full/
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

**Total: 25 files (8 Core + 11 Pro + 6 Full).** The complete autonomous agent system.

## Placeholder Reference

All files use `[YOUR_VALUE]` placeholders for project-specific values:

| Placeholder | Example | Where Used |
|-------------|---------|------------|
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
