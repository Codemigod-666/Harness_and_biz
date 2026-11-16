<!-- devkit -->
## devkit

How we work: docs/fleet/ (roles, models, context seams). Tasks, ideas, bugs and open questions live in
docs/backlog/INDEX.md, managed with the `backlog` command / skill.

- Gates are `devkit check`, `devkit test`, `devkit gate` and `devkit e2e`; the commands behind them are in
  `.devkit/config.env`. `devkit gate` must be green before anything lands.
- Load the conventions cards (docs/conventions/, `conventions` skill) before writing or reviewing code.
- Immediate questions for the user go through AskUserQuestion (max 4 per call, chain calls if needed), never a
  prose list. Non-blocking questions become `question` items in the backlog.
- Don't start building until the user says so; record decisions and plan instead.
- Every decision gets a row in docs/decisions.md (`by: user|supervisor`).
- Say what you measured: SHAs, counts, command output. Tag the rest `[inferred]` / `[unmeasured]`.
- Commit small, green, by explicit pathspec (never `git add -A`), subject with evidence; only when asked or briefed.
- Secrets only in gitignored env files, never in code, logs or commits.
- Fleet (herdr): supervisor docs/fleet/SUPERVISOR.md, workers docs/fleet/WORKER.md. Every worker is its own
  Claude Code process in a herdr tab, auto mode, own worktree (`fleet` command), never a background subagent.
  Models: docs/fleet/MODELS.md. Context seams at 200k (soft) / 250k (hard): handover → clear → resume
  (docs/fleet/CONTEXT.md).
