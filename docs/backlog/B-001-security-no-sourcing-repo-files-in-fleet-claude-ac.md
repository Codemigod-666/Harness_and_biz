---
id: B-001
title: "security: no sourcing repo files in fleet/claude-acct, safe state files, gate from main, narrow fleet allowlist"
type: bug
status: doing
milestone: "v0.2"
deps: []
created: 2026-11-16
owner: sec
---


**Goal:** Running devkit commands inside an untrusted repo, or by a worker agent, can't execute repo-controlled
code or weaken the gate that guards landing.

**Done when:**
- `devkit/bin/fleet` and `devkit/bin/claude-acct` never `source` `.claude/accounts.env`: it is parsed as data
  (only `ACCOUNT_B_DIR` and `SHARED_ITEMS`; a leading `$HOME` or `~` expanded by the script; `ACCOUNT_B_DIR`
  must resolve under `$HOME`; each `SHARED_ITEMS` entry matches `^[A-Za-z0-9._-]+$` and isn't `.`/`..`).
  A test proves a `$(touch pwned)` / backtick payload in accounts.env is never executed.
- fleet state files: model, effort and account are validated against fixed sets (model: sonnet|opus|haiku or
  `claude-[a-z0-9.-]+`; effort: low|medium|high|xhigh|max|empty; account: a|b) at spawn, adopt and respawn; every
  value is written with `printf %q`, so sourcing a state file can't run code; no sed rewrite with unvalidated
  input. A test spawns-in-dry-form or writes a state file with a lane containing `$(…)` and shows it stays literal.
- `fleet land` takes the gate command from the main branch's committed `.devkit/config.env`
  (`git show <main>:.devkit/config.env`, parsed as data), and refuses to land when the branch changes
  `.devkit/config.env`, `justfile`/`Justfile`, `Makefile` or a path in `DEVKIT_GATE_FILES`, unless
  `--allow-gate-change` is given. `--no-gate` and `--allow-gate-change` require an interactive terminal
  (a human), so an agent's Bash call can't use them.
- Mutating fleet subcommands (spawn, brief, say, reset, respawn, land, close) refuse to run when
  `FLEET_AGENT` is set to anything but `supervisor` (workers can't drive the fleet).
- `template/.claude/settings.json` allowlists only read-only fleet calls (`fleet status`, `fleet read *`,
  `fleet wait *`) instead of `Bash(fleet *)`; backlog stays.
- tests cover each point; `devkit gate` green.
