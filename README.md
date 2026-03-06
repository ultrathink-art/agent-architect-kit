# Agent Architect Kit

A free starter kit for running multiple Claude Code agents on a single codebase. Agent definitions, memory systems, process docs, and orchestration scripts — extracted from a production system running 10 agents across 2,500+ autonomous tasks.

## The Problem

Running AI agents without structure breaks in predictable ways:

- **Agents forget everything between sessions** — the same mistakes repeat endlessly
- **Agents fabricate results** — "tests passed" when they didn't run, quality gates skipped silently
- **No coordination** — two agents edit the same file, or one deploys while another is mid-test
- **Rules don't stick** — you re-explain deploy safety, testing requirements, and style guides every session
- **Bad work ships unchecked** — no independent verification, no audit trail

## What You Get

- **Agent definitions** for 6 roles (coder, QA, designer, product, marketing, operations) — each with scoped instructions, tool access, and model selection. Ready to customize.
- **Memory system** — agents read past mistakes and learnings before starting work, and record new ones when they finish. Failures stop repeating.
- **Process docs** for common workflows — task queues, deploys, security audits, design approval, product launches, incident response. Reference material, not rigid frameworks.
- **Orchestration scripts** — a daemon that spawns agents from a task queue, monitors health, detects stuck work, and chains follow-up tasks automatically.
- **A real CLAUDE.md template** (~350 lines) with `[YOUR_VALUE]` placeholders for your stack. Annotated with `# WHY` comments explaining the reasoning behind each rule.

```
agent-architect-kit/
├── core/                  # Agent definitions + project config
│   ├── CLAUDE.md          # Project instructions template
│   ├── agents/*.md        # 6 role definitions
│   └── memory/            # Cross-session memory protocol
├── pro/                   # Process documentation
│   └── processes/*.md     # 11 workflow guides
└── full/                  # Orchestration automation
    ├── scripts/           # CLI tools (task queue, worker, monitor)
    └── automation/        # macOS daemon plists
```

## Quick Start

**1. Copy the core files into your project:**

```bash
cp core/CLAUDE.md your-project/CLAUDE.md
mkdir -p your-project/.claude/agents
cp core/agents/*.md your-project/.claude/agents/
cp core/memory/memory-directive.md your-project/.claude/agents/
```

**2. Replace placeholders** in `CLAUDE.md` and each agent file — search for `[YOUR_VALUE]`:

| Placeholder | Example |
|---|---|
| `[YOUR_COMPANY]` | Acme Corp |
| `[YOUR_FRAMEWORK]` | Rails 8, Next.js, Django |
| `[YOUR_DEPLOY_TOOL]` | Kamal, Capistrano, Vercel |
| `[YOUR_DB]` | PostgreSQL, SQLite |

Delete sections that don't apply to your stack.

**3. Create memory files** — one per agent role, in `agents/state/memory/`:

```bash
mkdir -p your-project/agents/state/memory
```

Create a file for each role (`coder.md`, `qa.md`, etc.) with sections for Mistakes, Learnings, and Session Log. Agents will read and update these automatically.

**4. Run your first agent:**

```bash
cd your-project
claude --agent coder --print "List the files in this project and describe the architecture"
```

## Three Levels of Complexity

Pick what fits your needs. You don't have to use everything.

### `core/` — Start here
Agent definitions + memory. Enough to run specialized agents that learn across sessions. This alone is a major upgrade over a single unstructured agent.

### `pro/` — Add coordination
Process docs for common workflows: task queues, deploy checklists, security audits, design approval, product launches. Copy the ones relevant to your team. Skip the rest.

### `full/` — Go autonomous
The orchestration daemon, task queue CLI, and health monitoring. For systems that run agents continuously without human intervention — spawning work, chaining tasks, detecting failures.

## Adapting to Your Stack

This kit was extracted from a Rails project, but the patterns are stack-agnostic:

- **Any language** — swap test/deploy commands in the coder agent (`pytest`, `jest`, `cargo test`, `go test`)
- **Any project type** — designer/product agents work for any creative pipeline; engineering processes apply to any deployed software
- **Solo projects** — start with just coder + QA + operations. Three agents cover the core loop: build, verify, improve. Add roles as complexity grows.

## Key Ideas

**CLAUDE.md is the control plane.** It governs agent behavior — deploy safety, testing requirements, quality gates. The template includes `# WHY` comments so you understand the reasoning and can decide what applies to your project.

**Memory prevents repeated failures.** Without it, agents start from zero every session. The memory directive ensures agents read past learnings before working and record new ones when done.

**Operations is the meta-agent.** It monitors all other agents and edits their instructions when patterns break. Agent keeps making the same mistake? Operations rewrites the rule. It's the feedback loop that makes the system self-improving.

**Quality gates must be externally verified.** Self-reported results are unreliable. The kit's patterns — exact test counts, post-commit verification, independent QA review — exist to make shortcuts detectable.

## Links

- [ultrathink.art](https://ultrathink.art) — the store this system runs
- [ultrathink.art/blog](https://ultrathink.art/blog) — technical posts about how this was built
- [GitHub Issues](https://github.com/ultrathink-art/agent-architect-kit/issues) — questions and feedback

## License

MIT
