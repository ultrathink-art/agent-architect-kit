# Agent Architect Kit

**Version 1.4.0** · See [CHANGELOG.md](CHANGELOG.md) for what's new.

> **New here? Start with the [Agent Starter Kit Pro](https://ultrathink.art/items/250)** — the canonical free starter kit. This repository is its extended superset: six role definitions, deeper process docs, an auditable task queue, a dual-harness worker, health monitoring, and launchd automation.

A free kit for running structured Claude Code or Codex CLI agents on one
codebase. It is extracted from a production system that has processed 5,000+
autonomous tasks.

## The problem

Unstructured agents fail predictably:

- Sessions forget prior mistakes.
- Agents self-report success without reproducible evidence.
- Parallel work collides.
- Safety and deployment rules drift between sessions.
- A client default promises QA, but another client or raw API silently skips it.
- A README says a harness is portable while the launcher cannot actually run it.

## What you get

- **First-class Claude Code and Codex scaffolds** — each uses the project and
  custom-agent conventions its harness actually reads.
- **Six roles** — coder, QA, designer, product, marketing, and operations.
- **One dual-harness worker** — select `claude` or `codex` through
  `AGENT_HARNESS`; Claude remains the backward-compatible default.
- **Protected prompt delivery** — task and brief text goes through stdin via a
  mode-0600 temporary file, never shell interpolation or command arguments.
- **Fail-closed preflight** — executable, project instructions, role config,
  sandbox, and permission settings are validated before the orchestrator claims
  a task.
- **Auditable QA handoffs** — coder/product opt-outs require a persisted reason,
  and an executable server reference enforces an idempotent QA child again at
  completion.
- **Integrity verification** — `checksums.txt` and `full/scripts/verify-kit`
  prove whether a source tree or download was modified.

```text
agent-architect-kit/
├── core/
│   ├── CLAUDE.md                 # Claude Code project instructions
│   ├── agents/*.md               # Claude Code custom agents
│   ├── memory/                   # shared memory protocol
│   └── codex/
│       ├── AGENTS.md             # Codex project instructions
│       └── .codex/
│           ├── config.toml
│           └── agents/*.toml     # Codex custom agents
├── pro/processes/                # workflow and safety guides
├── full/
│   ├── lib/                      # harness + QA-chain contracts
│   ├── reference/                # executable server reference
│   ├── scripts/                  # queue, worker, monitor, verify, tests
│   └── automation/launchd/       # macOS daemon examples
├── test/                         # hermetic fake-harness regression suite
└── checksums.txt                 # SHA-256 release manifest
```

## Verify the kit first

From the kit root:

```bash
ruby full/scripts/verify-kit
```

Exit 0 means every tracked release file matches `checksums.txt`. Exit 1 names
modified, missing, and unexpected files.

## Quick start: Claude Code

```bash
cp core/CLAUDE.md your-project/CLAUDE.md
mkdir -p your-project/.claude/agents
cp core/agents/*.md your-project/.claude/agents/
cp core/memory/memory-directive.md your-project/.claude/agents/
cd your-project
```

Replace `[YOUR_VALUE]` placeholders, then run a no-write configuration smoke:

```bash
printf 'Reply with: CLAUDE_CONFIG_OK\n' |
  claude --agent coder --print --permission-mode plan --tools ""
```

## Quick start: Codex CLI

```bash
cp core/codex/AGENTS.md your-project/AGENTS.md
mkdir -p your-project/.codex
cp -R core/codex/.codex/. your-project/.codex/
cd your-project
```

Replace `[YOUR_VALUE]` placeholders. The role TOMLs intentionally omit model
pins so an installed Codex runtime can select a model it supports. Run this
no-write configuration and authentication smoke:

```bash
printf 'Reply with: CODEX_CONFIG_OK\n' |
  codex exec --strict-config --ephemeral --sandbox read-only -
```

Codex reads root `AGENTS.md` as project instructions and project-scoped custom
agents from `.codex/agents/*.toml`. Each included role defines `name`,
`description`, and `developer_instructions`; there is no Claude frontmatter,
Claude tool list, import syntax, or Claude model alias in the Codex scaffold.

## Install the full worker

Copy only the runtime files into an existing project root:

```bash
mkdir -p your-project/bin your-project/lib
cp full/scripts/agent-task full/scripts/agent-worker \
  full/scripts/agent-orchestrator full/scripts/queue-monitor your-project/bin/
cp full/lib/harness_adapter.rb full/lib/qa_chain_contract.rb your-project/lib/
chmod +x your-project/bin/agent-task your-project/bin/agent-worker \
  your-project/bin/agent-orchestrator your-project/bin/queue-monitor
cd your-project
```

Claude Code remains the default. Make the harness explicit and preflight it:

```bash
export AGENT_HARNESS=claude
export AGENT_ROLE=coder
bin/agent-worker --check
```

For Codex:

```bash
export AGENT_HARNESS=codex
export AGENT_ROLE=coder
bin/agent-worker --check
```

Configuration boundaries:

| Variable | Default | Purpose |
|---|---|---|
| `AGENT_HARNESS` | `claude` | Supported values: `claude`, `codex` |
| `CLAUDE_BIN` | `claude` | Claude executable override |
| `CODEX_BIN` | `codex` | Codex executable override |
| `AGENT_PROJECT_DIR` | current directory | Project root used by worker/orchestrator |
| `AGENT_CODEX_SANDBOX` | `workspace-write` | Codex sandbox; no approval bypass is added |
| `AGENT_CLAUDE_PERMISSION_MODE` | `default` | Optional explicit Claude permission mode |
| `AGENT_TIMEOUT_SECONDS` | `3600` | Hard child-process deadline |
| `ORCHESTRATOR_API_URL` | placeholder | Authenticated queue API origin |
| `ORCHESTRATOR_API_PREFIX` | placeholder | Queue API path prefix |

Task and brief bodies never appear in the constructed command. The worker
loads Codex role `developer_instructions` from the selected project TOML as a
runtime configuration layer, while dynamic task context stays on protected
stdin. It normalizes both harnesses to the same final-line protocol:

```text
TASK_COMPLETE: <verified outcome>
NEEDS_REVIEW: <what requires review>
BLOCKED: <blocker and next action>
```

## Mandatory, auditable QA handoffs

The client adds QA by default for coder and product work:

```bash
bin/agent-task add coder "Implement signed downloads" feature P1
```

An opt-out must state a reason that the server persists:

```bash
bin/agent-task add coder "Commit documentation only" feature P1 \
  --no-chain \
  --no-chain-reason "Documentation-only change with no executable behavior"
```

Client injection is not the authority. Port
`full/lib/qa_chain_contract.rb` and
`full/reference/qa_chain_server.rb` into your authenticated task endpoints.
The server must:

1. Reject a coder/product empty chain or `no_chain` request without a non-empty
   reason.
2. Persist the reason and a `NO-CHAIN OPT-OUT` audit note.
3. On completion, idempotently ensure exactly one QA child exists unless that
   valid opt-out is present.
4. Copy parent origin to every child and keep non-internal-origin children
   pending instead of auto-readying them.

See [pro/processes/mandatory_qa_handoffs.md](pro/processes/mandatory_qa_handoffs.md)
for the endpoint contract and audit checklist.

## Test the shipped contracts

The suite uses fake harness executables and a local fake HTTP server. It makes no
live agent call and no external write:

```bash
ruby full/scripts/test-kit
ruby full/reference/qa_chain_server.rb
```

It covers command arrays, protected stdin context, missing binary/config errors,
completion normalization, heartbeat shutdown, timeout process-group cleanup,
client QA defaults, reasonless rejection, persisted opt-out payloads, origin
propagation, and completion-time idempotency.

## Three levels of complexity

### `core/` — role instructions

Choose the Claude Code or Codex scaffold. Add only the roles you use.

### `pro/` — coordination

Adopt the workflow guides relevant to your stack: queue transitions, QA,
security, untrusted content, launch, and incident learning.

### `full/` — autonomous execution

Install the queue client, worker, orchestrator, health monitor, server contract,
and optional macOS launchd examples.

## Compatibility scope

- **Supported and tested:** Claude Code project/role setup and worker command;
  Codex CLI project/custom-agent setup and worker command.
- **Portable patterns:** memory and process Markdown can be adapted to other
  harnesses.
- **Not claimed:** Cursor, OpenCode, or other launchers are not configured or
  exercised by this release.
- **Platform-specific:** the launchd examples are macOS-only; the Ruby scripts
  themselves use the standard library.

## Links

- [ultrathink.art](https://ultrathink.art)
- [GitHub Issues](https://github.com/ultrathink-art/agent-architect-kit/issues)
- [Agent Orchestra](https://github.com/ultrathink-art/agent-orchestra)
- [Agent Cerebro](https://github.com/ultrathink-art/agent-cerebro)
- [AgentBrush](https://github.com/ultrathink-art/agentbrush)

## License

MIT
