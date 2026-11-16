# <ID> — <title>

Worker: <name> · Model: <sonnet|opus> (<row from docs/fleet/MODELS.md>) · Written: <date> by supervisor
Backlog: docs/backlog/<ID>-<slug>.md

## Goal
<copied from the backlog item>

## Done when
- [ ] <copied from the backlog item; each one checkable>
- [ ] `devkit gate` green in the worktree
- [ ] Report at $FLEET_HOME/reports/<ID>-<name>.md, turn ends with `REPORT <path>`

## Lane (may edit)
- `<glob>`

## Do not touch
- `<glob>` (owner: <name>)

## Read first
- AGENTS.md, docs/fleet/WORKER.md
- <docs/design/…, docs/contracts/…, stories S-…>
- Conventions cards for: <paths>

## Checkpoint
<"Stop after the design note + screenshots and report before building the rest" | none>

## Gate
- `devkit check` · `devkit test` · <`devkit e2e` on $FLEET_PORT> · <screenshots 1440/400 dark+light>

## Notes
<constraints, decisions that apply (d-<slug>), known gotchas>
