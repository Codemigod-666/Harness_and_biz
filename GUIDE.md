# Guide: developing with the playbook

This is for you, the human. The agents follow `PLAYBOOK.md` and `docs/fleet/*.md` themselves; you mostly
talk to one agent, the **supervisor**, and decide things.

```
you ──talk──> supervisor (Opus, tab "supervisor")
                 ├─ spawns/briefs/checks ──> worker one (Sonnet, tab "one", worktree ../myapp-one)
                 ├─ ...                  ──> worker two (tab "two", worktree ../myapp-two)
                 └─ lands verified work ──> main
```

---

## 1. One-time setup (machine)

```bash
# tools (Ubuntu/WSL); check what's still missing afterwards with tools/check-tools.sh in any project
sudo apt install -y just lsof curl python3
sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 && sudo chmod +x /usr/local/bin/yq
# only if you use the stacks:
#   Go:  https://go.dev/dl, then: go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@latest
#   TS:  corepack enable   (pnpm)   and   pnpm add -g @ast-grep/cli

git config --global core.autocrlf input      # WSL: stops CRLF noise
~/dev-playbook/install.sh                    # from a local checkout: devkit plugin + fleet/backlog commands
# or install the devkit plugin from the marketplace instead of a checkout (see README.md)
git config --global user.name "Your Name"   # workers commit in worktrees; without an identity commits fail
git config --global user.email you@example.com
```

## 2. Start a project (2 minutes)

Either in a terminal:

```bash
~/dev-playbook/new-project.sh ~/myapp --stack go,ts,api --ports 48
```

or in any Claude Code session: **"new project myapp, go and ts"** (the `/devkit` skill asks what it needs,
runs the script and, inside herdr, opens a workspace for it with the supervisor running).

Stacks: `go` (server), `ts` (web apps), `api` (OpenAPI spec). None = docs-first. Ports: pick a prefix no other
project uses (47 → 4700–4799, 48 → 4800–4899).

An existing repo (any stack) adopts the workflow with `devkit init` (writes `.devkit/config.env` from the
commands it detects; `devkit doctor` checks it). Starters get the same file, mapped to their justfile recipes.

Then:

```bash
cd ~/myapp
git add -A && git commit -m "scaffold: playbook template"
herdr                     # opens the terminal workspace
just supervisor           # in the herdr pane: starts the supervisor
```

## 3. First session: plan, don't build

The supervisor will not write code until you say so. Use the first session to give it the project:

1. **"Interview me for README and PRODUCT.md."** It asks with multiple-choice questions; answer, add notes.
2. **"Record these as decisions: …"** Stack, scope, what's out. Each becomes a row in `docs/decisions.md`
   with `by: user`.
3. Drop any source data in `data/source/` (never committed). **"Analyse data/source and write docs/domain.md."**
4. **"Write the M1 demo script with me"** → `docs/stories/demo-script.md`, in your words. This is what
   "done" means for the milestone.
5. **"Plan M1 into backlog items."** It creates tasks with Goal and Done-when. Review them:
   `backlog ready` lists what can start.
6. **"Architecture doc for M1."** It may do this itself or brief an Opus worker.

Commit as you go: ask it **"commit the planning"**.

## 4. Building: the daily loop

Say **"go: build the ready M1 items, two workers"** (or name items). Then:

| The supervisor… | You… |
|-----------------|------|
| picks ready items, writes a brief per item, picks the model (Sonnet unless MODELS.md says Opus) | nothing; ask "why Opus?" if you want |
| `fleet spawn` → a new herdr tab per worker | watch any tab; you can type into a worker directly, but prefer going through the supervisor |
| waits for each `REPORT`, checks Done-when against the diff, reruns `devkit gate` | nothing |
| asks you questions it can't settle (pop-up with options) | answer; your answer becomes a decision |
| lands verified work on main, closes the backlog item with the SHA | skim `git log --oneline` |
| tells you when something needs a decision or a restart of the running app | approve or not |

Useful things to say:

- **"status"** → `fleet status`: each agent's state, context size, model, lane.
- **"what's next?"** → ready backlog items.
- **"park X, do Y first"** → it re-plans.
- **"show me"** → it runs the app or takes screenshots for you.
- **"new idea: …"** / **"bug: …"** → filed in the backlog, not started unless you say so.
- **"stop all workers"** → it asks them for handovers and closes them cleanly.

## 5. When it needs you

- **A herdr tab shows "blocked"** (or you get a herdr notification): a worker hit a permission or trust
  dialog. Go to that tab, read it, approve or deny. The first time a worker opens a new worktree, Claude asks
  "trust this folder?": approve it.
- **Auto mode keeps blocking the same safe action** (e.g. restarting the dev server): tell the supervisor
  **"allow `just restart` for agents"**; it adds a narrow rule to `.claude/settings.json`. Never switch to
  bypass mode.
- **A question pop-up**: options come with a recommendation first; "Other" lets you type your own.

## 6. Long sessions: context resets

You don't manage this; just know what you'll see:

- At **200k tokens** an agent writes `docs/handovers/<name>.md`, commits it and says `HANDOVER <sha>`.
- The supervisor runs `fleet reset <name>`: the tab clears (`/clear`) and the agent resumes from the
  handover, re-checking git before it continues.
- At **250k** the agent can't stop until it has done that.
- The supervisor resets itself the same way. If it ever ends up stuck after a reset, type in its tab:
  **"Resume: read AGENTS.md, docs/fleet/SUPERVISOR.md and docs/handovers/supervisor.md, then continue."**

Picking up the next day: `cd ~/myapp && herdr` (herdr restores the session), and if the supervisor isn't
running, `just supervisor`: it reads its handover and carries on.

## 7. Before a demo or release

Say **"prepare the demo"**. The supervisor runs the full gate, asks before wiping and restarting the stack,
walks `docs/stories/demo-script.md`, and reports numbers it measured. Share with **"bundle it"** (a git bundle,
checked for secrets) or push to your remote if you have one.

## 8. Cheat sheet

| Command | What |
|---------|------|
| `just` | list all recipes |
| `just up` / `just down` / `just restart` / `just reset` | run, stop, restart server, wipe local state |
| `devkit check` / `devkit test` / `devkit gate` | lint+types / tests / everything (must be green to land; a starter maps them to its justfile) |
| `just supervisor` | start the supervisor in the current herdr pane |
| `just fleet` | fleet status |
| `just ready` | backlog items ready to start |
| `backlog list -s todo` | open items |
| `fleet read <name> 40` | last 40 lines of a worker |
| `/devkit:supervise` · `/devkit:handover` · `/devkit:resume` | role and seam skills, if you ever need them by hand |
| `tools/check-tools.sh` | what's missing |

| File | Look here for |
|------|---------------|
| `docs/backlog/INDEX.md` | everything planned, in progress, done |
| `docs/decisions.md` | what was decided and by whom |
| `docs/handovers/*.md` | where each agent stands right now |
| `.claude/fleet/board.md` | live: who has which lane and files |
| `.claude/fleet/reports/` | each worker's report for its item |

## 9. If something goes wrong

| Symptom | Do |
|---------|----|
| `fleet: not inside a herdr pane` | start `herdr` first, run `just supervisor` inside it |
| worker tab says `gone` in status | it exited; tell the supervisor "respawn <name> from its handover" |
| a worker is going in circles | "reset <name>" (fresh context from handover) or "escalate <name> to opus" |
| gate fails on main | "fix main first": the supervisor briefs a worker on it before anything else lands |
| everything shows as changed in git | CRLF: `git config core.autocrlf input && git add --renormalize .` |
| `backlog` errors | `yq` missing (mikefarah v4) |
| want to change the limits | `.claude/settings.json` → `env` → `FLEET_SOFT_TOKENS` / `FLEET_HARD_TOKENS` |

## 10. Your rules of thumb

- Talk to the supervisor, not the workers, unless you're answering a dialog.
- Decide product questions yourself; let it decide technical ones and record them.
- Say "go" explicitly when you want building to start.
- Ask "what did you measure?" when a claim sounds too good.
- Keep milestones small: one demo script per milestone.
