---
name: fleet
description: >-
  Run a supervisor + worker team of Claude Code agents on herdr: each worker is its own `claude` process in
  auto mode, in its own herdr tab, git worktree (branch fleet/<name>) and test port. Use when the user asks to
  supervise, spawn/brief/watch/reset/land/close workers, run work in parallel, or when a context seam
  (handover → clear → resume) is due. Triggers: /fleet, "spawn a worker", "supervise", "fleet status",
  "reset <worker>", "HANDOVER <sha>", "REPORT <path>".
argument-hint: "[status | spawn <name> -m <model> -l <lane> | brief <name> <file> | reset <name> | land <name>]"
allowed-tools: Bash(fleet *), Bash(devkit *)
---

# Fleet

Helper: `fleet` (on PATH from the plugin's `bin/`; no args = help). Needs herdr (`HERDR_ENV=1`), git, python3. `fleet land` runs `devkit gate`.
Role skills: `/devkit:supervise`, `/devkit:work`; seams: `/devkit:handover`, `/devkit:resume`; `/devkit:brief`, `/devkit:land`.

Read first, by role: supervisor → `docs/fleet/SUPERVISOR.md`; worker → `docs/fleet/WORKER.md`. Both:
`docs/fleet/MODELS.md` (which model) and `docs/fleet/CONTEXT.md` (seams at 200k / 250k).

## Rules

- **Workers are separate agents, never subagents.** Every worker is spawned with `fleet spawn`, which starts
  `claude --permission-mode auto` in a new herdr tab. Don't use the Agent tool to do a worker's job.
- **Auto mode always.** Never spawn in `bypassPermissions`. Blocked by auto mode on a shared recipe → ask the
  user for a narrow allow rule in `.claude/settings.json`.
- **Model per MODELS.md**: Sonnet by default, Opus only for the listed kinds of work or an escalation
  (`fleet respawn <name> -m opus`), recorded on the board.
- **Accounts a/b**: a = default `~/.claude`; b = a second subscription in `~/.claude-b` (or `ACCOUNT_B_DIR` in
  `.claude/accounts.env`). `fleet spawn` picks the logged-in account with fewer agents unless `-a a|b` is given;
  the account is saved, so reset and respawn keep it. Account hit its usage limit → `fleet respawn <name> -a <other>`.
  `fleet accounts` shows logins and load.
- **One lane per worker**, lanes never overlap, claims go through the supervisor.
- **Seams**: a worker ends with `HANDOVER <sha>` → `fleet reset <name>`. Supervisor's own seam →
  `fleet reset supervisor --detach`, then end the turn.
- **Verify before landing**: Done-when checked against the diff, gate rerun, then `fleet land <name>`.
- `blocked` means a dialog: read it (`fleet read <name>`), ask the user; never answer it yourself.
- Never close tabs you didn't create, never `herdr server stop`.

## Typical session

```bash
fleet adopt supervisor                                  # once, from the supervisor's own pane
backlog ready
backlog set T-012 status doing && backlog set T-012 owner one
fleet spawn one -m sonnet -l "apps/web/src/find/**"
fleet brief one .claude/fleet/briefs/T-012-one.md
fleet wait one                                         # idle | done | blocked
fleet read one 40                                      # sees REPORT <path>
fleet land one                                         # gate + fast-forward main
fleet status                                           # state, context tokens, model, account, lane
fleet close one
```
