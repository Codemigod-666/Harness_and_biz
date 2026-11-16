# Model policy

Status: Approved (playbook). Pick the cheapest model that keeps the result quality. Every brief has a
`Model:` line with the reason. The supervisor checks every result the same way, whichever model made it.

## Default: Sonnet for workers, Opus for the supervisor

| Work | Model | Effort | Why |
|------|-------|--------|-----|
| Supervisor (plans, verifies, decides what to ask the user) | opus | high | judgement across the whole repo; mistakes multiply |
| Architecture, data model, API contract design, cross-cutting refactor | opus | high | many constraints at once, hard to verify after the fact |
| Concurrency, transactions, migrations, idempotency, security/auth code | opus | high | subtle bugs that tests miss |
| Debugging a failure Sonnet could not explain in one attempt | opus | high | escalation, see below |
| Security review, conventions audit of risky lanes | opus | medium | needs to spot what is absent |
| Feature in an existing pattern (new endpoint, view, job like the others) | sonnet | medium | the pattern carries the design |
| Tests from a clear story or spec; regression tests for a found bug | sonnet | medium | |
| UI component or screen from DESIGN.md + an existing screen | sonnet | medium | |
| Lint, type and convention fixes; style sweeps lane by lane | sonnet | low | mechanical |
| Renames, moves, codegen updates, dependency bumps | sonnet | low | mechanical |
| Docs reconciliation, handover-to-docs, backlog grooming | sonnet | medium | Sonnet handles docs reconciliation fine |
| Research reads, summarising logs, measuring and reporting numbers | sonnet | low | |
| One-line lookups, formatting, file inventories | haiku | low | |

Rules:
- **MUST** start a worker on Sonnet unless its task is in an Opus row. Write the row in the brief's `Model:` line.
- **MUST NOT** use Opus because a task "feels important". Use it when the work is in an Opus row or
  escalated.
- **MUST** escalate to Opus (`fleet respawn <name> -m opus`) when a Sonnet worker:
  - fails the same gate twice for a reason it can't explain,
  - reports low confidence or asks a design question the brief doesn't answer,
  - or produces a diff the supervisor rejects for design, not style.
  Record the escalation on the board with the reason; the handover carries the context over.
- **Prefer** splitting mixed work: Opus designs (writes the design note and the Done when), Sonnet builds
  from it, Opus or the supervisor reviews the risky parts.
- **MUST NOT** downgrade a task mid-flight to save cost if it is already on Opus for a listed reason.
- Measure, don't guess: if Sonnet keeps passing a kind of task that sits in an Opus row, propose moving the
  row (a decision row, `by: user`).

## Inside an agent

Subagents (Agent tool) for read-only search can run on Sonnet or Haiku. They never edit lanes.
