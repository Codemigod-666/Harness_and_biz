---
name: resume
description: Restart an agent after a context clear from its handover, checking the handover against the repo first.
argument-hint: "[name]"
---

# Resume

Your context was cleared on purpose. Rebuild it from files, then check before acting.

1. Read `AGENTS.md`, your role file (`docs/fleet/SUPERVISOR.md` or `docs/fleet/WORKER.md`),
   `docs/fleet/CONTEXT.md`, then `docs/handovers/<name>.md` (name = `$ARGUMENTS`, else `$FLEET_AGENT`, else
   `supervisor`), then the brief it names.
2. Load the conventions cards listed under **Conventions**.
3. What changed since the handover:
   !`${CLAUDE_SKILL_DIR}/scripts/stale-check $ARGUMENTS`
4. Reconcile: for each claim under **State**, **In progress**, **Uncommitted** and **Held files**, check it
   against the facts above (and rerun any state check the handover names). **Where they differ, the repo wins.**
   Note each difference; it goes under Gotchas in your next handover.
5. If the differences change the plan (someone else touched your files, main moved under you, the gate is
   red), tell the supervisor in one message before continuing. Otherwise continue from **Next steps** step 1.
