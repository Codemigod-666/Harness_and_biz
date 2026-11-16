---
name: brief
description: Write a fleet brief for a backlog item and worker (Goal/Done-when copied, lane, model per MODELS.md).
disable-model-invocation: true
argument-hint: "<ID> <worker> [model]"
---

# Brief

1. Item: !`backlog show $0 2>&1 | head -60`
2. Pick the model from `docs/fleet/MODELS.md`: Sonnet unless the work is in an Opus row; write the row as the
   reason. Mixed work → split it (Opus design note, Sonnet build) into two items rather than one Opus brief.
3. Create the file (copies Goal and Done when verbatim; never overwrites):
   `${CLAUDE_SKILL_DIR}/scripts/new-brief $0 $1 <model>`
4. Fill in the rest of the brief by editing that file:
   - **Lane**: globs this worker may edit; check `fleet status` that no other lane overlaps.
   - **Do not touch**: neighbouring lanes and their owners; shared contracts.
   - **Read first**: the design notes, contracts, stories and decisions (`d-<slug>`) that apply.
   - **Checkpoint**: required when there is design risk ("stop after the design note + screenshots").
   - **Gate**: the exact commands, including `devkit e2e` on `$FLEET_PORT` for UI work.
5. `backlog set $0 status doing` and `backlog set $0 owner $1`.
6. Print the brief path; spawning is the supervisor's next step (`fleet spawn` / `fleet brief`).
