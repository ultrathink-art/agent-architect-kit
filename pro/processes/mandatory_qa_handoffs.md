# Mandatory QA Handoffs

## Purpose

A client default is convenience, not enforcement. Coder and product work must
receive independent QA even when a task is created through a raw API request,
an admin screen, an import, or a future client that knows nothing about
`agent-task`.

This contract has two layers:

1. `agent-task add` injects a QA definition by default and refuses a reasonless
   gated opt-out.
2. The authenticated server validates creation and idempotently ensures a QA
   child again during completion.

The second layer is authoritative.

## Creation endpoint contract

For roles `coder` and `product`:

- A missing `next_tasks` value receives a QA task definition.
- `no_chain: true` or an explicit empty `next_tasks: []` is an opt-out.
- An opt-out without a non-empty `no_chain_reason` is rejected.
- A valid opt-out persists all of:
  - `next_tasks: []`
  - `no_chain: true`
  - the exact trimmed `no_chain_reason`
  - a line-anchored note:
    `NO-CHAIN OPT-OUT (<role>): <reason>`
- The response and `show` endpoint surface the reason for review and audit.

Example justified request:

```json
{
  "role": "coder",
  "subject": "Commit documentation only",
  "no_chain": true,
  "no_chain_reason": "Documentation-only change with no executable behavior"
}
```

Do not rely on the `no_chain` flag alone. A raw request with
`next_tasks: []` produces the same bypass state and owes the same reason.

## Completion endpoint contract

Completion of a coder or product task runs this server-side transition inside
the same authenticated application boundary as the status update:

1. Mark the parent completed according to the application's state machine.
2. Spawn declared children idempotently.
3. If no QA child exists for this parent, create one unless the parent has a
   valid persisted opt-out.
4. Run the check on every completion retry. Existing `(parent_task_id, role=qa)`
   state makes the transition a no-op.

A valid opt-out is the conjunction of an explicit empty chain, a non-empty
persisted reason, and the matching audit note. A malformed or reasonless empty
chain fails safe: completion creates QA.

Enforce idempotency with a database uniqueness constraint when your stack
supports one, for example a unique partial index over the parent identifier for
QA children. The application-level existence check is still useful for a clear
transition and friendly retry behavior.

## Provenance contract

Every child copies the parent's `origin` exactly. Only the trusted internal
origin may produce an automatically ready child. Any external, imported,
unknown, or otherwise untrusted origin produces a pending child that requires
explicit human promotion.

Never reconstruct origin from subject text, child role, or the client that
happened to complete the task.

## Executable reference

The kit cannot know a consumer's database or web framework, so it ships a
standard-library reference rather than prose-only pseudocode:

- `full/lib/qa_chain_contract.rb` — pure normalization and completion rules.
- `full/reference/qa_chain_server.rb` — in-memory server transition showing
  persistence, declared-child spawning, fallback QA, idempotency, and origin.
- `test/qa_chain_contract_test.rb` — client and server regression coverage.

Run:

```bash
ruby full/reference/qa_chain_server.rb
ruby full/scripts/test-kit
```

Port the transition into authenticated endpoints and your real transaction
model. Do not expose the reference class as an unauthenticated server.

## Audit checklist

- [ ] Default coder request contains a QA child definition.
- [ ] Default product request contains a QA child definition.
- [ ] Reasonless `--no-chain` exits nonzero before an API request.
- [ ] Raw explicit empty chain without a reason is rejected server-side.
- [ ] Justified opt-out persists the exact reason and audit note.
- [ ] Completion of a raw/clientless coder task creates QA.
- [ ] Repeated completion produces only one QA child.
- [ ] Child origin equals parent origin.
- [ ] Untrusted-origin child status is pending, never ready.
- [ ] Task output and audit queries surface opt-out reasons.
