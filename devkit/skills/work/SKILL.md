---
name: work
description: Become fleet worker <name> on a brief (stay in the lane, gate green, REPORT at the end).
disable-model-invocation: true
argument-hint: "<name> <brief path>"
---

# Work

You are fleet worker **$0**. Your brief: `$1`.

1. Read `AGENTS.md`, `docs/fleet/WORKER.md`, `docs/fleet/CONTEXT.md`, then the brief.
2. Load the `conventions` skill for the files in your lane. A card missing → reply
   `CONVENTIONS MISSING <list>` and stop.
3. Where you are:
   !`${CLAUDE_SKILL_DIR}/../handover/scripts/facts`
4. Behind main? `git rebase main` before you start.
5. Work the brief per WORKER.md: lane only (claim anything else through the supervisor), checkpoint if the
   brief has one, tests with every change, `devkit check` often, small commits by pathspec with evidence.
6. Done: `devkit gate` green, report from `docs/fleet/templates/report.md` to `$FLEET_HOME/reports/`, last line
   exactly `REPORT <path>`.

At the context guard's message: `/devkit:handover`, then reply `HANDOVER <sha>` and stop.
