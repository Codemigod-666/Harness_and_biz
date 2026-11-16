---
name: land
description: Supervisor's verification and landing of a worker's branch (Done-when vs diff, lane, gate, ff merge, close item).
disable-model-invocation: true
argument-hint: "<worker> [ID]"
---

# Land

Worker **$0**. Never land on the worker's word; check it yourself.

1. Read the worker's report (the path from its `REPORT <path>` line; `fleet read $0 40` if you lost it).
2. The diff: `git -C <worktree> log --oneline main..fleet/$0` and `git diff --stat main...fleet/$0`
   (worktree path: `fleet status`, or `../<repo>-$0`).
3. **Lane**: every changed path is inside the brief's Lane or a claim cleared on the board. Anything else →
   reject.
4. **Done when**: for each item in the brief, find the evidence in the diff or rerun the command yourself.
   Report claims don't count as evidence. Missing or wrong → reject with a numbered list, by `fleet say $0 "…"`,
   and wait for the next REPORT. Don't fix it yourself.
5. **Quality**: for non-trivial diffs, run a review subagent (pr-review-toolkit or code-review if installed) on
   `main...fleet/$0` against the conventions cards; pass blocking findings back to the worker.
6. **Land**: `fleet land $0` (runs `devkit gate` in the worktree, then fast-forwards main; not a fast-forward →
   `fleet say $0 "rebase on main, rerun the gate, REPORT again"`).
7. **Close the item** (`$1`, or the ID in the brief): `backlog set <ID> status done`; append
   `**Result (<date>, $0).** …` (task) or `**Fix ($0, <sha>).** …` (bug) to the item body with the SHAs;
   follow-ups from the report become new items; commit `backlog: <ID> done (<sha>)`.
8. Board: clear the worker's claims; then brief its next item, or `fleet close $0`.
