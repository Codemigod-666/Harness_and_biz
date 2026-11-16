---
name: devkit
description: >-
  Adopt the current repo into the devkit workflow on any stack: backlog, briefs, agent fleet (supervisor +
  workers on herdr, auto mode, worktrees), context seams at 200k/250k, model policy, conventions cards and
  configurable gates. Runs `devkit init` and `devkit doctor`. Also answers questions about the rules.
  Triggers: /devkit, "adopt this repo", "set up devkit", "apply the playbook", "what do the rules say about X".
argument-hint: "[init | doctor | rule <topic>]"
allowed-tools: Bash(devkit *)
---

# devkit

Skills in this plugin: `/devkit:supervise`, `/devkit:work`, `/devkit:brief`, `/devkit:land`,
`/devkit:handover`, `/devkit:resume`, `/devkit:fleet`, `/devkit:backlog`, `/devkit:conventions`. The context guard
hook ships with it and acts only in repos that have `docs/fleet/`.

The workflow needs bash, git and python3. `herdr` is needed only for the fleet.

## Adopt this repo

1. Check you are in the git repo to adopt (`git rev-parse --show-toplevel`); if not, ask which one.
2. `devkit doctor`: shows what is missing (git identity, python3, herdr for fleet work, config, gate). Pass the
   user the one-line fix for each MISSING line.
3. `devkit init` (add `--yes` to accept the detected commands, `--cards go,ts,python,…` to pick starter
   conventions cards). It never overwrites: each file prints `added <path>` or `kept <path>`. It adds:
   - `.devkit/config.env`: the commands behind `devkit check|test|gate|e2e`, proposed from what the repo has
     (justfile, Makefile, package scripts, go.mod, pyproject, Cargo.toml, a Frappe app). Confirm them with the user;
     an empty `DEVKIT_GATE` must be filled in before anything can land.
   - an `AGENTS.md` (or a `## devkit` section appended once, marked `<!-- devkit -->`), and `@AGENTS.md` in `CLAUDE.md`.
   - `docs/fleet/` (role docs and templates), `docs/backlog/`, `docs/handovers/`, `docs/decisions.md`,
     `docs/memory/`, `docs/conventions/` (general, testing, plus the stack cards).
   - `.claude/fleet/` in `.gitignore`.
4. For every `kept <path>`, compare it with the plugin's version (`templates/core/<path>`) and propose a merge to
   the user; never overwrite silently.
5. Don't commit for them. Next steps to tell them: review and commit, then start `herdr` in the repo and run
   `/devkit:supervise`.

## Questions about the rules

Answer from the repo's own `docs/fleet/*.md` and `AGENTS.md` when present. Otherwise from the rules that ship in
the plugin: `templates/core/docs/fleet/*.md` and the stack-neutral digest `PLAYBOOK.md` at the plugin root.
Quote the rule and its file. If the repo's copy differs from the plugin's, the repo's copy wins.

## Gates

Skills and role docs never name a build tool; they call `devkit check`, `devkit test`, `devkit gate` and
`devkit e2e`, which run the commands in `.devkit/config.env`. A project that has a justfile or Makefile
sets `DEVKIT_GATE` to call it. Never edit around a red gate; fix the cause.
