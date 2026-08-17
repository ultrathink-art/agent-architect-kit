# Agent Architect Kit — File Manifest

Version 1.4.0 contains **49 files** across the root and three product tiers.
`checksums.txt` covers the other 48 files; it excludes itself by design.

## Core — `core/` (16 files)

Two first-class harness scaffolds plus one shared memory protocol.

```text
core/
├── CLAUDE.md                       # Claude Code project instructions
├── agents/                         # 6 Claude Code role definitions
│   ├── coder.md
│   ├── designer.md
│   ├── marketing.md
│   ├── operations.md
│   ├── product.md
│   └── qa.md
├── memory/
│   └── memory-directive.md
└── codex/
    ├── AGENTS.md                   # Codex project instructions
    └── .codex/
        ├── config.toml
        └── agents/                 # 6 Codex custom-agent TOMLs
            ├── coder.toml
            ├── designer.toml
            ├── marketing.toml
            ├── operations.toml
            ├── product.toml
            └── qa.toml
```

## Pro — `pro/` (13 files)

```text
pro/processes/
├── build_feature.md
├── design_approval.md
├── engineering.md
├── incident_learnings.md
├── launch.md
├── mandatory_qa_handoffs.md       # authoritative QA server/audit contract
├── new_product.md
├── orchestrator.md
├── qa_checklist.md
├── security_audit.md
├── shareholder_feedback.md
├── untrusted_content.md
└── work_queue.md
```

## Full — `full/` (11 files)

```text
full/
├── lib/
│   ├── harness_adapter.rb          # Claude/Codex command + protected runner
│   └── qa_chain_contract.rb        # client/server QA invariants
├── reference/
│   └── qa_chain_server.rb          # executable framework-neutral server model
├── scripts/
│   ├── agent-orchestrator
│   ├── agent-task
│   ├── agent-worker
│   ├── queue-monitor
│   ├── test-kit
│   └── verify-kit
└── automation/launchd/
    ├── com.example.orchestrator.plist
    └── com.example.queue-health.plist
```

## Test — `test/` (5 files)

```text
test/
├── codex_scaffold_test.rb
├── harness_adapter_test.rb
├── qa_chain_contract_test.rb
├── test_helper.rb
└── fixtures/
    └── fake_harness
```

## Root (4 files)

```text
CHANGELOG.md
MANIFEST.md
README.md
checksums.txt
```

## Placeholder reference

| Placeholder | Example | Where used |
|---|---|---|
| `[YOUR_COMPANY]` | Acme Corp | Role/project instructions |
| `[YOUR_SITE]` | acme.com | Product/marketing roles |
| `[YOUR_DOMAIN]` | acme.com | Scripts/project instructions |
| `[YOUR_FRAMEWORK]` | Rails 8 | Coder/project instructions |
| `[YOUR_DATABASE]` | PostgreSQL | Coder/project instructions |
| `[YOUR_DEPLOY_TOOL]` | Kamal | Engineering/project instructions |
| `[YOUR_SERVER_IP]` | 10.0.0.1 | Project instructions |
| `[YOUR_TOOL]` | mise | Project instructions |
| `[YOUR_VERSION]` | 3.3.4 | Project instructions |
| `[YOUR_ADMIN]` | admin | Project/QA instructions |
| `[YOUR_MAX_AGENTS]` | 3 | Project instructions |
| `[YOUR_TARGET_AUDIENCE]` | developers | Designer/product roles |
| `[YOUR_TARGET_CUSTOMER]` | developer | Product/design docs |
| `[YOUR_API_PREFIX]` | internal | Scripts |
| `[YOUR_RUBY_PATH]` | /opt/ruby/bin | launchd plists |
| `[YOUR_PROJECT_PATH]` | /srv/project | launchd plists |
