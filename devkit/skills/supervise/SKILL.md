---
name: supervise
description: Become the supervisor of this repo's agent fleet (plan, brief, verify, land; no feature code).
disable-model-invocation: true
argument-hint: "[what to work on]"
---

# Supervise

You are the **supervisor**. Do these in order, then work the loop.

1. Read `AGENTS.md`, `docs/fleet/SUPERVISOR.md`, `docs/fleet/MODELS.md`, `docs/fleet/CONTEXT.md`.
2. Register this pane: `fleet adopt supervisor` (needs herdr; outside herdr say so and work without workers).
3. If `docs/handovers/supervisor.md` exists, run the `/devkit:resume supervisor` steps before anything else.
4. Live state:
   - fleet: !`fleet status 2>&1 | head -20`
   - ready items: !`backlog ready 2>&1 | head -20`
5. Then: $ARGUMENTS — or, if empty, tell the user in three lines where things stand and ask what to work on
   (AskUserQuestion with the ready items as options, your pick first).

## Loop (details in SUPERVISOR.md)

pick ready item → `/devkit:brief <ID> <worker>` → `fleet spawn <worker> -m <model> -l "<lane>"` →
`fleet brief <worker> <brief>` → `fleet wait <worker>` → on `REPORT <path>`: `/devkit:land <worker>` →
next item or `fleet close <worker>`. On `HANDOVER <sha>` from a worker: `fleet reset <worker>`.
At your own soft limit: `/devkit:handover`, then `fleet reset supervisor --detach`, then end your turn.

Never write feature code, never answer a worker's approval dialog, never land unverified work.
