---
name: backlog
description: >-
  Track the project's tasks, ideas, bugs/tech debt and open questions as one file per item in
  docs/backlog/, with a generated INDEX.md. The backlog is the committed source of truth for what to do;
  the fleet board only tracks who is doing which backlog id right now. Use when planning work, capturing
  an idea or question, picking the next task, briefing a fleet worker, closing a task, or filing
  /violations findings. Triggers: /backlog, "add to backlog", "what's next", "track this", "new idea",
  "open question".
argument-hint: "[list | ready | new <type> <title> | show <ID> | promote <ID>]"
allowed-tools: Bash(backlog *)
---

# Backlog

Helper: `backlog` (on PATH from the plugin's `bin/`; run with no args for help; bash, git and python3 only). Always use it to create items and change frontmatter; it keeps `docs/backlog/INDEX.md` in sync. Edit item bodies with Edit/Write.

## Items

`docs/backlog/<ID>-<slug>.md`, frontmatter + markdown body.

| type | ID | statuses |
|------|----|----------|
| task | T-001 | todo → doing → done; blocked; dropped |
| idea | I-001 | idea → promoted (via `promote`); dropped |
| bug (incl. tech debt, convention findings) | B-001 | todo → doing → done; dropped |
| question | Q-001 | open → answered; dropped |

Frontmatter: `id, title, type, status, milestone, deps` (list of IDs), `created`; optional `owner`, `from` (promoted idea), `brief` (path), `answer` (questions, one line; details in the body).

Body: for tasks, **Goal**, **Done when** (checkable), **Notes**; for ideas, the idea and why; for questions, context and who must answer (`client` / `user`); for bugs, the failure and where.

## Rules

- **Immediate questions** go to the user through AskUserQuestion. Only non-blocking or client-side questions become `question` items. When answered, `set <ID> status answered`, `set <ID> answer "<one line>"`, and record any resulting decision in docs/decisions.md.
- **Titles to the user, IDs in files.** When telling the user about items, use the title; add the ID in brackets only when it helps ("architecture doc (T-003)"). Never a bare ID or an ID range.
- **Ideas aren't commitments.** Capture freely; promote to a task only when the user agrees.
- **A task is ready** when it's `todo` and all deps are `done` (`backlog ready`).
- **Milestones** are short labels (`M1`, `M2`); describe them in README.md or docs/, not here.
- One item = one deliverable. Split anything a worker can't finish in one context.

## With fleet

- Before spawning a worker, pick a ready task, `set <ID> status doing`, `set <ID> owner <worker>`. The fleet brief starts with the backlog ID and copies the item's **Goal** and **Done when**; the fleet board row uses the backlog ID as its task id.
- On the worker's report: verify **Done when**, then `set <ID> status done` and `set <ID> brief <report path>` if worth keeping. Follow-ups the worker found become new items.
- On close, append `**Result (<date>, <worker>).** …` (task) or `**Fix (<worker>, <sha>).** …` (bug) to the item body: briefs and reports are scratch, the item is what survives.
- Briefs: `.claude/fleet/briefs/<ID>-<worker>.md` from `docs/fleet/templates/brief.md` (fleet skill).
- Fleet briefs/reports are gitignored scratch; anything that must survive goes into the item body or docs/.

## With conventions

- `CONVENTIONS MISSING <list>` from a worker → a task `conventions doc: <name>` that blocks the code tasks needing it (`deps`).
- /violations findings → one `bug` per rule cluster (title `<RULE-ID>: <summary>`, files in the body), not one per line.

## Committing

Backlog changes are committed with the work they describe (or in a separate `backlog:` commit for pure planning).
