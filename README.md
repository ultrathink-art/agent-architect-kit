# Agent Architect Kit

A starter kit for running multiple Claude Code agents as a team. Instead of one AI assistant doing everything, you define specialized roles (coder, QA, designer, ops) that work on tasks from a shared queue — each with its own instructions, tools, and persistent memory.

Extracted from a production system that has run 10 agent roles across 2,500+ autonomous tasks since January 2026. Every rule exists because something broke without it.

## Why

Claude Code is powerful with one agent. But as your project grows, a single agent can't hold all the context — deploy safety, design standards, test requirements, security rules — without its instructions becoming a 10,000-line mess that bleeds into every task.

**The Agent Architect Kit splits that into roles:**

- A **coder** agent that implements features, runs tests, and deploys — it knows your stack, your testing rules, and your deploy pipeline
- A **QA** agent that independently verifies what the coder shipped — catches bugs the coder can't see in its own work
- An **operations** agent that monitors all the other agents and edits their instructions when patterns break — the self-improving feedback loop
- Plus **designer**, **product**, and **marketing** agents for creative and go-to-market workflows

Each agent reads its own memory file at session start (past mistakes, learnings, stakeholder feedback) so it doesn't repeat failures across sessions.

## What's Included

```
agent-architect-kit/
├── core/                        # Agent definitions + project config
│   ├── CLAUDE.md                # Project instructions template (~350 lines)
│   │                            # Annotated with WHY comments explaining each rule
│   ├── agents/                  # 6 role definitions (coder, qa, designer, product,
│   │   └── *.md                 #   marketing, operations) — frontmatter + instructions
│   └── memory/
│       └── memory-directive.md  # Cross-session memory protocol (@ import in every agent)
│
├── pro/                         # Process documentation
│   └── processes/               # 11 process docs: work queue, orchestration,
│       └── *.md                 #   design approval, security audit, QA checklist,
│                                #   engineering, feature dev, product launch, incidents
│
└── full/                        # Orchestration automation
    ├── scripts/                 # agent-task, agent-worker, agent-orchestrator,
    │   └── *                    #   queue-monitor (Ruby CLIs)
    └── automation/
        └── launchd/             # macOS daemon plists for continuous orchestration
```

**27 files total.** Templates, not finished configs — you customize them for your stack.

## Quick Start

### 1. Copy files into your project

```bash
# Project instructions
cp core/CLAUDE.md your-project/CLAUDE.md

# Agent definitions
mkdir -p your-project/.claude/agents
cp core/agents/*.md your-project/.claude/agents/
cp core/memory/memory-directive.md your-project/.claude/agents/

# (Optional) Process docs — reference material for scaling
cp -r pro/processes your-project/agents/docs/processes

# (Optional) Orchestration scripts — for autonomous task queues
cp full/scripts/* your-project/bin/
```

### 2. Replace placeholders

Every file uses `[YOUR_VALUE]` placeholders. Open `CLAUDE.md` and replace them:

| Placeholder | Example |
|---|---|
| `[YOUR_COMPANY]` | Acme Corp |
| `[YOUR_FRAMEWORK]` | Rails 8, Next.js, Django |
| `[YOUR_DEPLOY_TOOL]` | kamal, capistrano, vercel |
| `[YOUR_SERVER_IP]` | 10.0.0.1 |
| `[YOUR_DB]` | PostgreSQL, SQLite |
| `[YOUR_TOOL]` | mise, rbenv, nvm |
| `[YOUR_VERSION]` | 3.3.4, 20.x |

Do the same for each agent definition in `.claude/agents/`. Delete sections that don't apply to your stack.

### 3. Create memory files

```bash
mkdir -p your-project/agents/state/memory
for role in coder qa designer product marketing operations; do
  echo "# ${role} Agent Memory

## Mistakes

## Learnings

## Stakeholder Feedback

## Session Log" > your-project/agents/state/memory/${role}.md
done
```

### 4. Run your first agent

```bash
cd your-project
claude --agent coder --print "List the files in this project and describe the architecture"
```

## Key Ideas

**CLAUDE.md is the control plane.** Claude Code reads it at session start. Every rule there governs agent behavior — deploy safety, testing requirements, quality gates. A well-maintained CLAUDE.md is the difference between agents that repeat mistakes and agents that learn. The template includes annotated `# WHY` comments so you understand the reasoning behind each rule and can decide what applies to your project.

**Memory prevents repeated failures.** Without persistent memory, agents start from zero every session. The memory directive ensures agents read past mistakes and learnings before starting work, and record new ones when they finish. In our production system, agents repeated identical failures (wrong file formats, skipped tests, incorrect API calls) until memory was added.

**Operations is the meta-agent.** It monitors all other agents and edits their instructions when patterns break. Agent keeps making the same mistake? Operations rewrites the rule to make it clearer. Quality drifting? Operations tightens the checklist. It's the feedback loop that makes the whole system self-improving.

**Quality gates must be externally verified.** Self-reported "tests passed" is unreliable — our production system had an agent fabricate test results. The kit's quality gate patterns (exact test counts, post-commit verification, separate QA agent review) exist to make shortcuts detectable.

## Adapting to Your Stack

This kit was built for a Rails project, but the patterns are stack-agnostic:

- **Any language**: Adapt the coder agent's test/deploy commands to your toolchain (pytest, jest, cargo test, go test)
- **Any project type**: The designer/product agents work for any creative pipeline. The engineering processes apply to any deployed software.
- **Solo projects**: Start with just coder + qa + operations. Three agents cover the core loop (build → verify → improve). Add roles as complexity grows.

## Links

- [ultrathink.art/tools](https://ultrathink.art/tools) — where this kit lives
- [Agent Orchestra CLI](https://github.com/ultrathink-art/agent-orchestra) — companion tool for task queue orchestration

## License

MIT
