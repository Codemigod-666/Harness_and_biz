# dev-playbook

How we build with Claude Code + herdr, and a template to start any repo that way.

| Path | What |
|------|------|
| `GUIDE.md` | **start here**: how you use it day to day (setup, first session, daily loop, cheat sheet, troubleshooting) |
| `PLAYBOOK.md` | the rules: MUST / MUST NOT for setup, memory-in-files, planning, coding, verification, fleet, git, safety; lessons from practice |
| `devkit/` | **core plugin**, any stack: skills `/devkit:supervise · work · brief · land · handover · resume · fleet · backlog · conventions`, the context-guard hook, commands `devkit`, `fleet`, `backlog`, `claude-acct` |
| `packs/frappe` | plugin `devkit-frappe`: Zip and Zap for a Frappe workspace (skill `zipzap`, `frappe-zip`, `frappe-zap`) |
| `packs/local` | plugin `devkit-local`, this machine only (not in the marketplace): `harness-docs`, the local field guide |
| `.claude-plugin/` | the marketplace `harness`: devkit and devkit-frappe |
| `template/` | base repo (data, not machinery): AGENTS.md + CLAUDE.md, justfile, .claude/settings.json, docs/{decisions, architecture, domain, ports, stories, contracts, design, backlog, handovers, memory, conventions, fleet}, tools/check-tools.sh |
| `stacks/go` | golangci v2 config, go.work, a minimal server (`main → run`, `config.Load(getenv)`, table test) |
| `stacks/ts` | pnpm workspace, Biome, strict tsconfig, JSX component-length lint, snippets (Playwright fake + live configs on `$FLEET_PORT`, live-bundle check, Result, feature client slice, ViewState) |
| `stacks/api` | redocly strict config and a starter OpenAPI 3.1 spec with RFC 9457 problems |
| `new-project.sh` | generator: copy, fill placeholders, LF, git init, tool check |
| `install.sh` | local checkout install: links devkit and the packs into ~/.claude/skills, their commands into ~/.local/bin |
| `biz/` | the business: PLAN-v2.md (current plan, draft), discovery-script.md (customer conversations) |
| `SKILLS-ROADMAP.md` | research: what else to add (P2/P3 skills, third-party plugins) |

## Install devkit in any project

Two commands in Claude Code, then one in your repo:

```
/plugin marketplace add Codemigod-666/Harness_and_biz
/plugin install devkit@harness
```
```bash
cd your-repo && devkit init      # detects the stack, adds .devkit/config.env, AGENTS.md and docs/; never overwrites
devkit doctor                    # checks the setup
```

The plugin puts `devkit` on the Bash tool's PATH inside Claude Code; `install.sh` does the same for a plain terminal.
`devkit check | test | gate` run the commands in `.devkit/config.env`, so the workflow does not care about your
stack. Needs bash, git and python3; herdr only for the fleet. For Frappe workspaces also run
`/plugin install devkit-frappe@harness`.

**From a local checkout** (edits apply at once): `git clone` this repo, then `./install.sh`. It links `devkit`,
`devkit-frappe` and `devkit-local` into `~/.claude/skills` and their commands into `~/.local/bin`.

## Start a new project from the starters

```bash
~/dev-playbook/install.sh                                      # once
~/dev-playbook/new-project.sh ~/myapp --stack go,ts,api         # or tell Claude: "new project myapp"
cd ~/myapp && herdr
just supervisor
```

## The fleet in one paragraph

You talk to the **supervisor** (Opus, auto mode). It keeps the backlog and decisions, writes briefs, and
spawns **workers** with `fleet spawn`: each one is its own Claude Code process in its own herdr tab, auto
mode, own git worktree and branch, own test port, Sonnet unless the work needs Opus. Workers build inside
their lane and end with `REPORT <path>`; the supervisor verifies and fast-forwards main. At 200k tokens the
context guard asks an agent for a handover, at 250k it insists; `fleet reset` clears and resumes it from the
handover.
