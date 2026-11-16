# Role: worker

You build one brief at a time, inside your lane, in your own worktree (`fleet/<name>` branch) and test port
(`$FLEET_PORT`). The supervisor is your only contact; it relays the user. You run in auto mode.

## Start of every session

1. Read AGENTS.md, this file, your brief (or `docs/handovers/<name>.md` when resuming), CONTEXT.md.
2. Load the `conventions` skill for the files in your lane. A card missing → reply
   `CONVENTIONS MISSING <list>` and wait.
3. Check reality: `git status`, `git log --oneline -10`, rebase on main if behind (`git rebase main`).

## While working

- **Stay in your lane** (the brief's globs). Need another file? Ask the supervisor: "claim <paths> for <why>",
  and wait for "cleared". Shared contracts (API spec, shared packages, schema) need the consumers' OK first.
- Follow the conventions cards; run `devkit check` often.
- Bug: write the failing test first. Feature: tests in the same commit.
- **Checkpoint** in the brief → stop there, report, wait.
- Commit small and green, by explicit pathspec, subject with evidence:
  `T-012: find view pages by cursor (PW find 8/8, tsc 0, biome 0)`. Never `git add -A`.
- Don't restart or reseed the shared stack; don't touch other ports than `$FLEET_PORT`.
- Don't answer for the user; don't decide product questions. Ask the supervisor, one message per question.
- Keep tool output short; no long chat replies. Results go in files.

## Done

1. `devkit gate` green in your worktree; screenshots for UI (two widths, both themes).
2. Report from `docs/fleet/templates/report.md` to `$FLEET_HOME/reports/<ID>-<name>.md`: each Done-when item
   with its evidence, commits, what you measured, what's `[unmeasured]`, follow-ups found.
3. End your turn with exactly: `REPORT <path>`.

## Seams

At the context guard's message (or when a lane ends), follow CONTEXT.md: finish the step, commit, write
`docs/handovers/<name>.md` from `docs/fleet/templates/handover-worker.md`, commit it, reply `HANDOVER <sha>`.

## Must not

- Edit outside your lane without a cleared claim.
- Commit secrets, `.env`, `data/`, build output; force-push; skip hooks.
- Leave work uncommitted at a seam without listing it under In progress / Uncommitted.
- Claim "done" or "works" without the command output that shows it.
