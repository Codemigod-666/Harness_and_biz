# dev-playbook (the harness)

The harness repo: `devkit/` (the Claude Code plugin, linked into ~/.claude/skills/devkit, so edits on main are live),
PLAYBOOK.md (rules), GUIDE.md (daily use), template/ and stacks/ (starters), the field guide in docs/site/, biz/.
Tasks: docs/backlog/INDEX.md (`backlog` command). How we work: docs/fleet/.

## Working rules
- `just check` (syntax, shellcheck, plugin validate) and `just gate` (check + tests/) are the gates.
- Scripts: bash with `set -euo pipefail`, or python3 stdlib only. No new runtime dependencies.
- Test script changes in throwaway git repos under a temp dir (tests/), never on a live fleet or a real project.
- Commit small, green, by explicit pathspec; subject with evidence.
- The repo is public: no emails, org names, client or project codenames, tokens, or paths from other repos.
- Every harness change updates the field guide (docs/site/index.html) per `/devkit-local:harness-docs`. The guide is
  local only: never published with the Artifact tool or any service.
- Git history replaces `.bak-*` copies; don't create new ones.

## Fleet (herdr)
- Supervisor: docs/fleet/SUPERVISOR.md. Workers: docs/fleet/WORKER.md. Models: docs/fleet/MODELS.md.
- Context seams at 200k / 250k: handover → clear → resume (docs/fleet/CONTEXT.md).
