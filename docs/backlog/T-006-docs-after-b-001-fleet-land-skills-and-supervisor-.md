---
id: T-006
title: "docs after B-001: fleet/land skills and SUPERVISOR.md describe main-gate landing, worker guard, accounts.env rules; narrow fleet skill allowed-tools; DEVKIT_GATE_FILES here; field guide"
type: task
status: doing
milestone: "v0.2"
deps: []
created: 2026-11-16
owner: docs
---


**Goal:** The docs and skills describe how fleet and land behave after B-001, and the fleet skill no longer grants
every fleet call.

**Done when:**
- `devkit/skills/fleet/SKILL.md`: `allowed-tools` lists only the read-only calls (`fleet status`, `fleet read *`,
  `fleet wait *`, `fleet accounts`), matching template/.claude/settings.json; the text says mutating subcommands are
  supervisor-only and that `--no-gate` / `--allow-gate-change` are human-only (terminal + one-time code).
- `devkit/skills/land/SKILL.md` and `devkit/templates/core/docs/fleet/SUPERVISOR.md` (and its mirrors
  docs/fleet/ and template/docs/fleet/, kept identical: `diff -r` empty) say land runs main's committed
  `DEVKIT_GATE` and refuses gate-file changes (`.devkit/config.env`, justfile, Makefile, `DEVKIT_GATE_FILES`).
- `docs/design/devkit-portable.md` §2 and `devkit/templates/core/.devkit/config.env.example` document
  `DEVKIT_GATE_FILES`; `.claude/accounts.env` rules (data only, `ACCOUNT_B_DIR` = `$HOME/.claude-<name>`) are in
  the fleet skill.
- This repo's `.devkit/config.env` sets `DEVKIT_GATE_FILES="tests/"`.
- Field guide (docs/site/index.html) per packs/local/skills/harness-docs/SKILL.md: security notes in the fleet and
  accounts sections, changelog v0.5, nav date/version.
- `devkit gate` green.
