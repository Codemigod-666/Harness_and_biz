# Design: project-free devkit (v0.2)

Accurate as of the commit that adds this file. Decided by the supervisor on 2026-11-16, at the user's request:
"a version of devkit which is project free, can be installed and used in any project irrespective of the project
and tech stack".

## Goal

Any git repo, on any stack, gets the devkit workflow (backlog, briefs, fleet, seams, handovers, conventions) by:

```
/plugin marketplace add Codemigod-666/Harness_and_biz
/plugin install devkit@harness
# then, in the repo:   devkit init
```

No `~/dev-playbook` path, no `just`, and no Go/TS assumption anywhere in the core plugin.

## Contract (every lane builds to this)

### 1. Layout

```
.claude-plugin/marketplace.json        marketplace "harness": plugins devkit (./devkit), devkit-frappe (./packs/frappe)
devkit/                                core plugin, version 0.2.0
  .claude-plugin/plugin.json
  bin/                                 on the Bash tool's PATH while the plugin is enabled
    devkit  fleet  backlog  claude-acct
  skills/<name>/SKILL.md               devkit, supervise, work, brief, land, handover, resume, fleet, backlog, conventions
  skills/<name>/scripts/               helpers called via ${CLAUDE_SKILL_DIR} (new-brief, facts, check, stale-check)
  templates/core/                      files `devkit init` adds to a repo (see 3)
  templates/conventions/               optional cards: go.md typescript.md react.md api.md python.md
  hooks/                               context guard
packs/frappe/                          plugin devkit-frappe: skill zipzap, bin/frappe-zip, bin/frappe-zap
packs/local/                           plugin devkit-local (this machine only, not in the marketplace): skill harness-docs
```

`devkit/skills/fleet/scripts/fleet` and `backlog/scripts/backlog` move to `devkit/bin/`. install.sh keeps
working for a local checkout (it symlinks `devkit/bin/*` into ~/.local/bin, so the commands also work in a plain
terminal) and links `packs/*` into ~/.claude/skills.

### 2. Project config: `.devkit/config.env` (committed)

Shell-sourced `KEY="value"` lines. All optional except DEVKIT_GATE.

| Key | Meaning | Default |
|---|---|---|
| `DEVKIT_CHECK` | fast checks (lint, types) | unset → `devkit check` says "not configured", exit 0 |
| `DEVKIT_TEST` | tests | unset → same |
| `DEVKIT_GATE` | everything; must be green to land | required by `devkit gate` (exit 2 with a clear message if unset) |
| `DEVKIT_E2E` | end-to-end, run on `$FLEET_PORT` | unset → same as CHECK |
| `DEVKIT_PORT_BASE` | fleet test ports (base+1..9) | 4790 |
| `DEVKIT_MAIN` | main branch | `main` |

`devkit check|test|gate|e2e` runs the configured command from the repo root with `bash -c`, passing the exit code
through. Fleet, skills and role docs use these, never `just …` directly. A project that has a justfile simply
configures `DEVKIT_GATE="just gate"`.

### 3. `devkit init [--yes] [--cards go,ts,…]`

In the current git repo, never overwriting (prints `added <path>` / `kept <path>`):

- `.devkit/config.env`, commands proposed from detection, confirmed unless `--yes`:
  justfile (`just check`/`just gate`), Makefile (`make test`), package.json scripts (npm/pnpm/yarn by lockfile:
  `lint`, `test`), go.mod (`go vet ./...`, `go test ./...`), pyproject/requirements (`ruff check .` if configured,
  `pytest`), Cargo.toml (`cargo clippy`, `cargo test`), Frappe app (hooks.py + modules.txt:
  `bench --site <site> run-tests --app <app>`); otherwise DEVKIT_GATE stays a commented TODO.
- `AGENTS.md`, created if missing, else a `## devkit` section appended once (marker comment). `CLAUDE.md` gets
  `@AGENTS.md` if it lacks it.
- `docs/fleet/{SUPERVISOR,WORKER,MODELS,CONTEXT}.md`, `docs/fleet/templates/*`,
  `docs/backlog/INDEX.md`, `docs/handovers/.gitkeep`, `docs/decisions.md`, `docs/memory/INDEX.md`,
  `docs/conventions/general.md`, `docs/conventions/testing.md`, plus the cards for detected or `--cards` stacks.
- `.gitignore`: `.claude/fleet/` appended once.
- Prints next steps: commit, then `herdr` + `/devkit:supervise`.

`devkit doctor`: git repo? config present, gate set? herdr (fleet only), python3, git identity, plugin version.

### 4. Skills and role docs

Text is stack-neutral: `devkit check` / `devkit gate` / `devkit e2e`, never `just`, `go`, `pnpm`. The conventions
skill loads `general.md` and `testing.md` always, plus any `docs/conventions/<lang>.md` or `lib-<name>.md` that
matches the files in hand (file-extension table, not a fixed list). The devkit skill's "new project" becomes
"adopt this repo" (`devkit init`); `template/` and `stacks/` stay as optional starters, outside the plugin.

### 5. Dependencies

Core needs only bash, git and python3. `backlog` drops `yq`: frontmatter edits in python3 stdlib. Same file
format, so existing items keep working. herdr is needed only for fleet.

## Lanes

| Worker | Lane | Delivers |
|---|---|---|
| `core` | `devkit/skills/*/SKILL.md` except fleet/ and backlog/, `devkit/templates/**`, `docs/fleet/**` text, `template/docs/fleet/**`, `template/AGENTS.md`, `PLAYBOOK.md`, `GUIDE.md` | sections 1 (templates), 3 (the file set), 4 |
| `cli` | `devkit/bin/**`, `devkit/skills/fleet/**`, `devkit/skills/backlog/**`, `devkit/skills/*/scripts/**`, `devkit/hooks/**`, `install.sh`, `tests/**` | sections 2, 3 (the `devkit` command), 5 |
| `pack` (after core + cli land) | `.claude-plugin/**`, `packs/**`, `devkit/skills/{zipzap,harness-docs}/**` (move out), `devkit/.claude-plugin/plugin.json`, `README.md`, `docs/site/**`, `tests/e2e-*.sh` | layout and marketplace, packs, README install section, field guide, an end-to-end test on 3 stacks |

`core` writes the template files; `cli` writes the `devkit init` code that copies `devkit/templates/core/**` as a
tree. Neither depends on the other's internals: the tree under `templates/core/` maps 1:1 onto the repo root.
