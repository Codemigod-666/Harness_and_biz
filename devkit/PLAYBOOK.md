# devkit playbook (stack-neutral digest)

The rules the devkit workflow runs on, for any repo and any stack. The full text for a repo lives in its own
`docs/fleet/*.md` and `AGENTS.md` (added by `devkit init`); where they differ from this digest, the repo wins.
MUST / MUST NOT are hard rules; "prefer" is the default unless there is a reason.

## Principles

1. **Files are the memory.** Anything that must survive a context reset, a worker swap or a new machine goes in
   a committed file: backlog item, decision row, handover, convention card.
2. **The user decides, agents propose.** Decisions are recorded with who made them (`user` or `supervisor`).
3. **Plan before build.** No scaffolding or code until the user says go.
4. **Small, verified steps.** One backlog item is one deliverable that fits in one context; done means the
   Done-when list was checked with evidence.
5. **Say what you measured**: SHAs, counts, command output. Tag the rest `[inferred]` / `[unmeasured]`.
6. **Rules are enforced by tools, not reminders.** Lint what can be linted; known offenders sit in a baseline
   that may only shrink.
7. **Parallel agents need lanes.** Two agents never edit the same file at once; ownership is written down.
8. **Cheap by default**: short messages, short tool output, the smallest model that does the job.

## Gates

`devkit check` (fast: lint, types), `devkit test`, `devkit gate` (everything; green before landing),
`devkit e2e` (on the worker's `$FLEET_PORT`). Their commands live in `.devkit/config.env`; skills and role
docs never name a build tool.

## Planning (backlog skill)

- Tasks, ideas, bugs and questions are one file per item in `docs/backlog/`, indexed by `backlog index`.
  Every task has a Goal and a checkable Done-when list.
- Blocking questions to the user go through AskUserQuestion (max 4 per call), never a prose list; non-blocking
  ones become `question` items.
- Every decision is a row in `docs/decisions.md`, cited by its stable `d-<slug>` id, never by line number.

## Coding (conventions skill)

- Load the cards in `docs/conventions/` that match the files in hand (`general.md` and `testing.md` always).
  A needed card that is missing → `CONVENTIONS MISSING <list>`; the supervisor files a `conventions doc` task.
- Small units: functions ≤ 40 lines, files ≤ 300 code lines, nesting ≤ 3, ≤ 4 parameters.
- Inject time, randomness, env, I/O and loggers; read config in one place.
- Never swallow errors; make illegal states unrepresentable; handle enums exhaustively.
- Delete dead code (YAGNI). Comments say why, not what. Every lint suppression names its rule and a reason.
- Business rules are data run by deterministic code; models only resolve what rules can't, with provenance.
- No `sed`/`perl` edits on source; generated files are regenerated, never hand-edited.

## Verification

- A bug fix starts with a test that fails before the fix; a feature ships with its tests.
- Fakes over mocks; E2E on the worker's own port; no sleeps. Claims of "done" cite command output.

## The fleet (herdr)

- A **supervisor** (Opus) plans, briefs, verifies and lands; it writes no feature code. **Workers** (Sonnet by
  default) each run as their own Claude Code process in a herdr tab, auto mode, own worktree `fleet/<name>`
  and test port. Never a background subagent.
- Lifecycle: pick a ready item → `/devkit:brief` → `fleet spawn` + `fleet brief` → worker builds in its lane →
  `REPORT <path>` → supervisor checks every Done-when item against the diff and reruns the gate →
  `fleet land` (fast-forward only) → close the backlog item with the SHA.
- Workers stay in their lane; anything else is a claim through the supervisor. Nothing reaches main except
  through the supervisor.
- Models: cheapest that keeps quality; Opus for design, concurrency, security and escalations
  (docs/fleet/MODELS.md).
- Context seams at 200k (soft) / 250k (hard): finish the step, commit, write `docs/handovers/<name>.md`, reply
  `HANDOVER <sha>`; the supervisor resets the agent; a fresh session resumes from the handover and the repo.
  The repo wins where they differ.

## Git

- Commit small and green, by explicit pathspec, never `git add -A`; subject carries evidence
  (`T-012: find view pages by cursor (tests 8/8, lint 0)`).
- No force-push, no skipped hooks. Fast-forward merges to main, by the supervisor only.
- Destructive or outward-facing actions (deleting data, pushing, sending mail, publishing) need the user's
  explicit OK each time.

## Secrets and safety

- Secrets live only in gitignored env files; never in code, logs, handovers or error text.
- Agents never close panes or tabs they didn't create and never stop the herdr server.
