---
name: handover
description: Write, check and commit this agent's handover at a context seam, then reply HANDOVER <sha>.
argument-hint: "[name]"
---

# Handover

Use at the context guard's soft/hard message, at the end of a lane, or when asked to seam.

1. Finish the step you're on, or note exactly where it stops. Commit finished work (green, by pathspec).
2. Facts (paste the relevant ones, don't retype from memory):
   !`${CLAUDE_SKILL_DIR}/scripts/facts`
3. Write `docs/handovers/<name>.md` (name = `$ARGUMENTS`, else `$FLEET_AGENT`, else `supervisor`) from
   `docs/fleet/templates/handover-worker.md` or `handover-supervisor.md`. Overwrite the old one; history keeps it.
   - Header `Written: <date time>, after <HEAD sha>, context ~<N>k (<seam kind>)`.
   - **Done** and **State**: evidence only (SHAs, counts, commands). Unchecked → `[unmeasured]`.
   - **Next steps**: the first one must be startable by a fresh session without asking anything.
   - **Decisions made and why**: so the next session doesn't reopen them.
   - **In progress / Uncommitted / Held files**: exact paths, or "None".
   - **Lessons → memory**: write `docs/memory/<lesson>.md` if a lesson is durable and new; else "none (why)".
4. Check it: `${CLAUDE_SKILL_DIR}/scripts/check docs/handovers/<name>.md` must pass (sections, placeholders,
   `after <sha>`, no secrets). Fix and rerun until it does.
5. `git add docs/handovers/<name>.md [docs/memory/…] && git commit -m "handover: <name> at <seam> seam (<done>, next <what>)"`
6. Reply with exactly one line: `HANDOVER <short sha>`. Do nothing else.
