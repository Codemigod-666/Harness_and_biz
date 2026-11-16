---
id: T-002
title: "devkit cli: devkit command (init, doctor, gates), bin/ layout, backlog without yq"
type: task
status: done
milestone: "v0.2"
deps: []
created: 2026-11-16
owner: cli
---


**Goal:** One `devkit` command makes any repo devkit-ready and gives every gate a stack-neutral name; fleet and
backlog run from the plugin's `bin/` with only bash, git and python3 (docs/design/devkit-portable.md, sections 1, 2, 3, 5).

**Done when:**
- `devkit/bin/{devkit,fleet,backlog,claude-acct}` exist (fleet, backlog and claude-acct moved with `git mv`; old
  `skills/*/scripts/` copies gone; `.bak-*` files deleted).
- `devkit init [--yes] [--cards …]` copies `devkit/templates/core/**` into the repo root without overwriting
  (prints added/kept), writes `.devkit/config.env` from stack detection (justfile, Makefile, package.json with
  npm/pnpm/yarn by lockfile, go.mod, pyproject/requirements, Cargo.toml, Frappe app), appends `.claude/fleet/`
  to .gitignore once, and appends the AGENTS.md section once (rerun is a no-op).
- `devkit check|test|gate|e2e` run the configured commands and pass exit codes through; `devkit gate` with no
  DEVKIT_GATE exits 2 with a one-line fix. `devkit doctor` reports each check as ok/missing.
- `fleet land` runs `devkit gate`; fleet reads DEVKIT_PORT_BASE and DEVKIT_MAIN; the board template falls back
  to the plugin's `templates/core/docs/fleet/templates/board.md` when the repo has none.
- `backlog` no longer calls yq (python3 stdlib); every subcommand works on the existing T-001..T-003 files
  unchanged (`backlog list`, `set`, `ready`, `index` give the same output as before).
- tests/devkit-init.sh: throwaway repos for justfile, package.json+pnpm-lock, pyproject, and a bare repo; asserts
  the config each gets, that a second init changes nothing, and that `devkit gate` passes/fails with the
  configured command's exit code. tests/backlog.sh: new/set/ready/index in a throwaway repo. Both run under `just gate`.
- install.sh links `devkit/bin/*` into ~/.local/bin; `just gate` green.

**Result (2026-11-16, cli).** 2487cb7, 4c045d3, b3bda50: `devkit` command (init with stack detection incl. Frappe, doctor, check/test/gate/e2e), fleet/backlog/claude-acct in devkit/bin, backlog without yq (output identical), config read as data never executed, tests/devkit-init.sh + tests/backlog.sh. Supervisor review sent back 2 bugs (Frappe detected as python; two AGENTS.md section sources), both fixed and re-verified.
