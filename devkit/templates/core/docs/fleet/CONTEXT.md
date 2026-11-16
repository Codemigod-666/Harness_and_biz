# Context seams: handover, clear, resume

Status: Approved (playbook). Long contexts lose precision. Every agent (supervisor and workers) works in
seams: when the context gets big, it writes a handover, the context is cleared, and a fresh session resumes
from the handover and the repo. Nothing is lost because everything durable is already in files.

## Limits

| Limit | Tokens | What happens |
|-------|--------|--------------|
| soft | 200k (`FLEET_SOFT_TOKENS`) | the context guard tells the agent once: finish the current step, write the handover, end the turn with `HANDOVER <sha>` |
| hard | 250k (`FLEET_HARD_TOKENS`) | the guard blocks the agent from ending its turn until it writes and commits the handover |
| backstop | 300k (`--autocompact`, `FLEET_AUTOCOMPACT`) | Claude Code auto-compacts if a seam was somehow missed (lossy; should never fire) |

Also seam early, whatever the size, when: a lane is finished, the agent switches to unrelated work, or it
has been going around in circles (a fresh context with a good handover often fixes it).

## How it is enforced

- The devkit plugin's context guard (`hooks/context-guard.py` in the plugin) runs on every `PostToolUse` and `Stop`. It reads the session transcript,
  takes the last main-thread model call's context (`input + cache_creation + cache_read` tokens), writes
  it to `.claude/fleet/context/<agent>.json` (shown by `fleet status`), and nudges or blocks at the limits.
  Each limit fires once per session; `/clear` starts a new session, so the counters reset.
- Thresholds live in `.claude/settings.json` `env`; change them there, not in the script.

## The seam, step by step

1. **Agent** finishes the step it is on: nothing half-edited, or the half-edit listed under In progress.
2. **Agent** commits its finished work (green, by pathspec).
3. **Agent** writes `docs/handovers/<name>.md` from `docs/fleet/templates/handover-worker.md` (or
   `handover-supervisor.md`), commits it (`handover: <name> at soft seam (<what>, next <what>)`) and ends its
   turn with exactly `HANDOVER <sha>`.
4. **Supervisor** runs `fleet reset <name>`: it checks the handover is committed, sends `/clear`, then the
   resume prompt. For itself: `fleet reset supervisor --detach`, then it ends its turn; the reset fires once
   it is idle.
5. **Fresh session** reads AGENTS.md → its role file → its handover → its brief → the conventions cards the
   handover lists, then checks the handover against the repo (`git status`, `git log`, the state checks it
   names) before acting. **Where they differ, the repo wins** and the difference goes under Gotchas in the
   next handover.

## What makes a resume accurate

- The handover holds **facts with evidence** (SHAs, test counts, file paths), not a story.
- **Next steps** are concrete enough that a fresh agent can start the first one without asking.
- **Decisions made and why** stops the fresh session from reopening settled questions.
- **Held files** and **Uncommitted** stop it from clobbering another lane.
- Durable knowledge is *already* in the backlog item, decisions or docs; the handover only points to it.
- **MUST NOT** rely on chat history surviving a reset. If it isn't in a file, it's gone.
