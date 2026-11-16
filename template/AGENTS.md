# __PROJECT__

Read README.md for the vision, docs/ for the domain and decisions, docs/backlog/INDEX.md for tasks, ideas,
bugs and open questions (managed with the `backlog` command / skill). How we work: docs/fleet/ and the playbook rules below.

## Working rules
- Immediate questions for the user go through AskUserQuestion (max 4 per call, chain calls if needed), never a
  prose list. Non-blocking questions become `question` items in the backlog.
- Don't start building (scaffolds, code, artifacts) until the user says so; record decisions and plan instead.
- Every decision gets a row in docs/decisions.md (`by: user|supervisor`) with a production footnote.
- Load the conventions cards (docs/conventions/, `conventions` skill) before writing or reviewing code. `devkit check` and `devkit gate` are the gates (commands in `.devkit/config.env`).
- Business rules are data run by deterministic code; LLMs only resolve what the rules can't.
- Say what you measured: SHAs, counts, command output. Tag the rest `[inferred]` / `[unmeasured]`.
- Commit small, green, by explicit pathspec (never `git add -A`), subject with evidence; only when asked or briefed.
- Client data lives in data/source/ and is never committed. Secrets only in .env (gitignored).
- Artifacts are local only: HTML files in prototypes/, never published.
- UI work follows DESIGN.md.

## Fleet (herdr)
- Supervisor: docs/fleet/SUPERVISOR.md. Workers: docs/fleet/WORKER.md. Every worker is its own Claude Code
  process in a herdr tab, auto mode, own worktree; never a background subagent (`fleet` command).
- Models: docs/fleet/MODELS.md (Sonnet unless the work needs Opus).
- Context seams at 200k (soft) / 250k (hard): handover → clear → resume (docs/fleet/CONTEXT.md).
