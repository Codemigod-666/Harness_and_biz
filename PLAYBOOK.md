# Development playbook: Claude Code + herdr

How we build software with coding agents: one human, one supervisor agent, a few worker agents, all in
herdr panes, all state in files. Distilled from running real projects this way (thousands of commits, several workers, hundreds of
backlog items), including what went wrong.

## Quick start

```bash
~/dev-playbook/install.sh                                   # once: devkit plugin + fleet/backlog commands
~/dev-playbook/new-project.sh ~/myapp --stack go,ts,api     # or, in any Claude session: "new project myapp"
cd ~/myapp && herdr                                         # then, in the herdr pane:
just supervisor                                             # supervisor agent (Opus, auto mode)
```

`template/` is the base repo, `stacks/{go,ts,api}/` add language configs and skeletons, `new-project.sh`
fills the placeholders (name, port block, Go module), sets LF line endings and runs
the tool check. `--force` adds the template into an existing repo without overwriting anything.

Contents

1. Principles
2. Repo setup
3. Memory lives in files
4. Planning: backlog, decisions, questions, stories
5. Coding
6. Verification
7. The fleet: supervisor and workers on herdr
8. Git
9. Data, secrets, safety
10. Lessons from practice (what broke and the rule it produced)
11. Checklists

Rule words: **MUST** / **MUST NOT** are hard rules. **Prefer** is the default unless there is a reason.

---

## 1. Principles

1. **Files are the memory.** An agent's context is temporary; the repo is not. Anything that must survive a
   context reset, a worker swap or a new machine goes into a committed file: backlog item, decision row,
   handover, story, convention card.
2. **The user decides, agents propose.** Agents record decisions with who made them (`user` or `supervisor`)
   and never take a product call silently.
3. **Plan before build.** No scaffolding, code or artifacts until the user says go. Until then: decisions,
   backlog, design notes.
4. **Small, verified steps.** One backlog item is one deliverable that fits in one context. Done means the
   **Done when** list was checked with evidence.
5. **Say what you measured.** Numbers, SHAs, test counts. Anything not checked is tagged `[inferred]`,
   `[unmeasured]` or `[extrapolated]`.
6. **Rules are enforced by tools, not by reminders.** Every coding rule that can be linted is linted, with a
   rule ID and a ratchet baseline for known offenders.
7. **Contract first, fakes always.** The API spec is the source of truth; every external dependency has a
   fake or a recorded mock so work and tests never wait on a live system.
8. **Design for the production target in architecture, not in code.** Every decision carries a footnote
   saying what ports as-is and what gets rewritten.
9. **Parallel agents need lanes.** Two agents never edit the same file at the same time. Ownership is
   written down.
10. **Cheap by default.** Short messages, short tool output, the smallest model that does the job well.

---

## 2. Repo setup

### MUST

- **One instructions file per agent kind, one source.** `AGENTS.md` holds the rules (Codex reads it);
  `CLAUDE.md` imports it with `@AGENTS.md` and adds only Claude-specific lines. Never maintain two copies
  by find/replace (a Claude→Codex copy once turned `~/.claude/...` paths into `~/.Codex/...`).
- **Keep `AGENTS.md` short** (under ~40 lines): what the project is, where the docs are, the hard working
  rules. Knowledge goes to `docs/`.
- **One task runner: `just`.** Every way to start, stop, seed, test, lint and gate the project is a recipe.
  Agents run recipes, never ad-hoc `kill`, `nohup` or `go run`.
- **Recipes are idempotent and observable:** pid and log files in `.run/`, port-in-use check with `lsof`
  before starting, a health-wait loop that prints the log tail on timeout, `down` stops everything,
  `reset` wipes local state but never touches source data.
- **`check` (lint + types) and `gate` (everything) exist from day one** (one project had no lint recipe
  until late; lint drifted). A starter's justfile has the recipes and `.devkit/config.env` maps
  `DEVKIT_CHECK/TEST/GATE/E2E` to them, so `devkit check|gate|e2e` run the same everywhere.
- **Pin tool versions** (`packageManager` in package.json, Go `tool` directive, pinned linters).
  `tools/check-tools.sh` verifies the toolchain.
- **A reserved port block** (e.g. 4700–4799) in `docs/ports.md`, split into bands: edge xx00–09, tooling
  xx10–19, backends xx20–29, frontends xx30–39, data xx40–49, observability xx50–59, tests xx90–99.
  One reverse proxy (Caddy) on xx00 with `*.<project>.localhost` hostnames. Dev servers use `strictPort`.
- **`.gitattributes` with `* text=auto eol=lf`** and `core.autocrlf input`. (On WSL a copy once showed
  2,065 changed files; 2,054 were only CRLF.)
- **`.env.example`** lists every env key with a comment; `.env` is gitignored.
- **Allowlist the safe shared recipes** in `.claude/settings.json` (`just restart`, `just reseed`, test
  runs). Auto mode's classifier otherwise blocks workers from restarting shared servers.
- **Machinery is global, data is per repo.** Skills, hooks and the `fleet`/`backlog` commands come from the
  devkit plugin (`~/dev-playbook/devkit`, linked into `~/.claude/skills/devkit`); never copy them into a repo
  (copies drift). Repos hold AGENTS.md, docs/ and `.claude/settings.json` (allow rules, `FLEET_*` limits).

### MUST NOT

- No second task runner, no undocumented scripts in random places. Tools go in `tools/`, each with a
  one-line purpose in its header.
- No ports outside the block, no `localhost:3000`.
- No tool used by a recipe without a check for it in `tools/check-tools.sh`.

---

## 3. Memory lives in files

| What | Where | Committed | Written by |
|------|-------|-----------|------------|
| Vision, principles, how to run | `README.md` | yes | user + supervisor |
| Product context (users, purpose, constraints) | `PRODUCT.md` | yes | user interview |
| Design system tokens and rules | `DESIGN.md` | yes | user |
| Agent working rules | `AGENTS.md` (+ `CLAUDE.md` import) | yes | user |
| Decisions | `docs/decisions.md` | yes | supervisor, user's words |
| System design | `docs/architecture.md` | yes | supervisor / a worker |
| Domain and data facts (measured) | `docs/domain.md` | yes | worker |
| Ports | `docs/ports.md` | yes | anyone, via decision |
| API contract | `api/openapi/*.yaml` + `docs/contracts/` | yes | contract owner |
| Acceptance stories | `docs/stories/` | yes | supervisor |
| Tasks, bugs, ideas, questions | `docs/backlog/<ID>-<slug>.md` | yes | backlog skill |
| Coding rules | `docs/conventions/*.md` (rule IDs) | yes | conventions tasks |
| Lessons (one per file) | `docs/memory/*.md` | yes | any agent |
| Handover per agent | `docs/handovers/<agent>.md` | yes | that agent, at each seam |
| Fleet roles and templates | `docs/fleet/` | yes | — |
| Briefs, reports, board, notes | `.claude/fleet/` | **no** (scratch) | supervisor / workers |

### MUST

- Every doc starts with a status line: `Status: Draft | Proposed | Approved <date>`, plus `Accurate as of
  <sha>` for documents that describe code (a reconciliation doc once went hundreds of commits stale silently).
- Undecided things are written as `Open: <question> (Q-0xx)`, never left implicit.
- Anything durable from scratch files (a report, a board decision) is copied into the backlog item body or
  `docs/` before the scratch is thrown away.
- Lessons go one per file in `docs/memory/` (`pocketbase-migration-applied-on-restart.md`), linked from
  `docs/memory/INDEX.md`. Check for an existing lesson before writing a new one.
- Refer to decisions by stable id (`d-<slug>`), never by line number (`decisions l.127` broke on every edit).

### MUST NOT

- No invention: PRODUCT.md and docs never contain made-up research, quotes or numbers ("No user research
  yet; don't invent it").
- No knowledge only in a chat, an agent's context, or the gitignored fleet dir.

---

## 4. Planning: backlog, decisions, questions, stories

### Backlog (skill `/devkit:backlog`, command `backlog`, needs `yq`)

- One file per item. Types and statuses:

  | type | id | statuses |
  |------|----|----------|
  | task | T-001 | todo → doing → done; blocked; dropped |
  | bug (incl. tech debt, convention findings) | B-001 | todo → doing → done; dropped |
  | idea | I-001 | idea → promoted; dropped |
  | question | Q-001 | open → answered; dropped |

- Frontmatter `id, title, type, status, milestone, deps, created`, optional `owner, from, brief, answer`.
  `INDEX.md` is generated; never hand-edit it.
- Task body: **Goal**, **Done when** (checkboxes, each one checkable), **Notes**. Bug: **Failure**,
  **Where** (file:line), **Fix** (filled in at close, with SHA). Question: context, **Options**,
  **Recommendation**, **Who answers** (`user` / `client`).
- A task is **ready** when it is `todo` and all deps are `done` (`backlog ready`).
- **MUST:** one item = one deliverable that fits one context; split anything bigger.
- **MUST:** on close, append `**Result (<date>, <worker>).** …` or `**Fix (<worker>, <sha>).** …` to the body.
- **MUST:** tell the user titles, not IDs ("the architecture doc (T-003)"); never a bare ID or an ID range.
- **MUST NOT:** ideas aren't commitments; promote only when the user agrees.

### Questions

- Blocking question → ask now with AskUserQuestion (max 4 per call, chain if needed), never a prose list,
  options first with a recommendation.
- Non-blocking or client-side question → a `question` item.
- Answered → `set <ID> status answered`, `set <ID> answer "<one line>"`, and a decisions row if it decides
  something.

### Decisions (`docs/decisions.md`)

- One table `| date | decision | by |`, `by` is `user` or `supervisor`. One row per decision, one line.
- Every row ends with a footnote `[^d-<slug>]` that says how it maps to production:
  `**Production:** … **Ports as-is:** … **Rewritten:** … See architecture.md prod-<id>.` Rows with no
  production counterpart still get one: `None; dev tooling only.`
- Superseding is explicit in the new row: `Supersedes d-<slug>`.
- A decision lands in the same commit as the docs it changes.

### Stories (`docs/stories/`)

- `S-<EPIC>-<n>`, **As / I want / so that**, then **Given / When / Then** in observable terms (routes,
  events, tables, screens), **Links**, **Status** (`none` / `spec <path>` / `passing <path>`), **Today**.
- Each story is written to become a test (integration test or Playwright spec).
- A `demo-script.md` in the user's own words is the acceptance contract for a milestone: "Done = the user
  can run it end to end on their own, with nothing dead on screen."

---

## 5. Coding

Load the `conventions` skill before writing or reviewing code. It loads the cards from
`docs/conventions/` that match the files you touch. A missing card → reply `CONVENTIONS MISSING <list>`;
the supervisor files `conventions doc: <name>` tasks that block the code tasks needing them.

### General (all languages), MUST

- Functions ≤ 40 lines, files ≤ 300 code lines, cognitive complexity ≤ 10, nesting ≤ 3, ≤ 4 parameters,
  lines ≤ 120. Enforced by linters; known offenders sit in a baseline that may only shrink.
- Inject time, randomness, env, I/O and loggers. No hidden globals.
- Config is read in one place (`config.Load(getenv)`); nothing else reads env.
- Errors are values with context (Go: wrap `"<verb> <noun>: %w"`; TS: `Result<T, E>` for declared
  failures, exceptions only for the unexpected).
- Booleans read as questions: `isX`, `hasX`, `canX`.
- Illegal states unrepresentable: discriminated unions over overlapping booleans (a real bug came from
  `held` + `done` both true).
- Exhaustive switches (`assertNever` / `exhaustive` linter).
- Named constants for magic values; one shared formatter for numbers, dates, units.
- Doc comments say *why* or the contract, in one or two sentences; no comments restating code. ~5% comment
  lines is normal.
- Every lint suppression names the rule and gives a reason (`//nolint:errcheck // read-only body`).
- Delete dead code and unused config (YAGNI). Building packages nobody calls is inventory, not progress.

### General, MUST NOT

- No LLM-written business logic at runtime: business rules are data (rules, flows, mappings) run by
  deterministic code. LLMs only resolve what the rules can't, with provenance, and humans see only
  low-confidence escalations.
- No `sed`/`perl` edits on source; use Edit/Write or `ast-grep` rewrites.
- No mocking libraries; hand-written fakes that obey the same contract as the real thing.

### Go

- Layout: `cmd/<bin>/main.go` thin (`main → run() error`, one `signal.NotifyContext`), domain packages in
  `internal/<noun>/`, short lowercase names, no stutter (`lake.Lake` is wrong).
- Consumer-defined small interfaces (≤ 5 methods); constructors `NewX(deps Deps)`; a `Deps` struct per
  package; options in an `Options` struct.
- `log/slog` only, injected; `*Context` variants, static messages, snake_case keys.
- Sentinel errors `var ErrX = errors.New(...)`; `errors.Is` / `errors.As`; cleanup via `errors.Join`.
- HTTP errors are RFC 9457 problem+json, mapped from sentinels in one table.
- Tests: stdlib + `go-cmp`, `t.Parallel()` everywhere, sentence names (`TestLoadRejectsEmptyKey`), table
  tests, `package x_test` by default, `t.TempDir()` and real embedded databases for integration, opt-in
  live tests behind an env var.
- Background jobs: every side effect inside a durable step; idempotent event IDs; one writer for
  single-writer stores; a sweep that re-sends lost work; a failure handler so nothing waits forever.
- Lint: `template/.golangci.yml` (golangci v2, ~40 linters, forbidigo for env/`context.Background`/
  `fmt.Print`/`time.Sleep`, depguard against testify/gomock/logrus/zap). Exclusion paths must work from
  the repo root (a `^(cmd|internal/config)/` exclusion once never matched).

### TypeScript / React

- pnpm workspaces (`apps/*`, `packages/*`); packages export TS source (`"exports": {".": "./src/index.ts"}`).
- tsconfig strict + `noUncheckedIndexedAccess` + `exactOptionalPropertyTypes` + `erasableSyntaxOnly` +
  `verbatimModuleSyntax`; `.ts` extensions in imports so `node --test` runs TS directly.
- Biome: recommended + the size limits, no `any`, no `!`, no default exports (except configs that need
  one), restricted imports to force the API port.
- Feature-first folders: `<feature>/{client.ts, queries.ts, <feature>-view.tsx, use-*.ts, *-model.ts,
  fake/}`. kebab-case files, PascalCase named-export components, readonly props.
- **Port + fakes:** the API client is generated from OpenAPI; each feature declares only the slice it uses
  (`Pick<ApiClient, "searchParts">`); two entries wire it (`main.tsx` live, `main-demo.tsx` fakes),
  chosen by `VITE_ADAPTER=demo`. Fakes return the same `Result` shapes and refusals as the server. URL
  params inject faults (`?fault=reads`) for tests. Prefer React context over module singletons for the
  provider.
- `check-live-bundle.sh` fails the build if fakes, fixtures or sims leak into the live bundle.
- TanStack Query via react-query-kit routers, `strictVariables`, pass `signal` through, `staleTime:
  Infinity` + change-driven invalidation (not polling), `cancelRefetch: false` on bursty invalidations.
- **Every view renders loading, error (with retry) and empty states.** Never `if (!data) return null`
  (one app rendered a blank page on any 403).
- Accessible markup is the test API: roles and names on regions, lists, toolbars, alerts; Playwright
  selects by role only.
- Styling: tokens from DESIGN.md as CSS variables → Tailwind `@theme inline`; never raw hex in
  components; `cva` variants, `cn()` merge.
- React components ≤ 40 lines, checked by `tools/lint/jsx-function-lines.sh` (Biome skips JSX functions).
- Code-split routes; watch bundle size (one app shipped a single 700+ kB chunk).
- Realtime subscriptions are scoped by filter and per view, never `"*"` on a growing collection.

### API contract

- OpenAPI 3.1 in `api/openapi/`, semver `info.version` bumped on change, linted by redocly
  `recommended-strict` + casing rules (`template/redocly.yaml`).
- Server stubs and TS client are generated; a `check:generated` script fails on drift.
- The server validates every request and response against the embedded spec in tests; a ratchet list of
  untested operations may only shrink.
- Roles and capabilities live in the spec (`x-<project>-roles`); the server reads them at startup.

### External dependencies

- **Record, then replay.** A resumable, rate-budgeted pull script records real responses into a
  content-addressed cache (`cache/<sha256(request)>.json` + `index.jsonl`); a mock server replays them
  with the real auth and rate-limit behaviour on its own port, plus `/mock/calls` and `/mock/reset` for
  tests. A small sample cache ships with the repo so the mock works without data.
- Store every raw input immutably with its source, fetch time and run id; derived values keep a pointer
  to the raw bytes.

---

## 6. Verification

### Test layers

| Layer | Runs against | Command |
|-------|--------------|---------|
| Unit | pure logic, fakes injected | `devkit test` (`go test`, `node --test`) |
| Integration | real embedded DB in a temp dir | `devkit test` |
| E2E (fake) | app on the fake adapter, own port | `devkit e2e` |
| E2E (live) | the running stack | `just e2e-live` (one run at a time) |
| Contract | server vs embedded OpenAPI spec | part of `devkit test` |
| Bundle purity | live build has no fakes | part of `devkit check` |
| Verify scripts | screenshots, audits; **tooling, not tests** | by hand |

### MUST

- A change is done only when `devkit gate` is green: lint 0, types 0, all tests pass. Report the counts
  (`go test 30 pkgs ok, lint 0, tsc 0, PW 187/0`).
- Bug fixes come with a regression test that failed before the fix.
- UI changes get screenshots at two widths (e.g. 1440 and 400) in both themes, checked against DESIGN.md.
- Before a demo or release: a full gate, then a live run from an empty start, checked against the
  demo script.
- Flaky → reproduce with `--repeat-each=10` before calling it flaky or fixed.

### MUST NOT

- Never claim "should work". Claims without a command and its output are `[unmeasured]`.
- No full E2E run while someone else edits the app's source (hot reload breaks stateful tests).
- No two E2E runs on the same port (give each worker its own test port, see §7).
- No `sleep` in tests; inject clocks or wait on conditions.

---

## 7. The fleet: supervisor and workers on herdr

### Topology

```
herdr session
└─ workspace <project>
   ├─ tab "supervisor"      claude --permission-mode auto --name <project>-supervisor
   ├─ tab "one"             claude --permission-mode auto --name <project>-one     (worktree ../<project>-one, branch fleet/one)
   ├─ tab "two"             claude ... --name <project>-two                        (worktree ../<project>-two, branch fleet/two)
   └─ tab "stack"           just up / just logs   (owned by the supervisor)
```

- **Every worker is its own Claude Code process in its own herdr tab, started in auto mode.** Never a
  background subagent of the supervisor: a separate process has its own full context, survives the
  supervisor's resets, can be watched and typed into by the user, and can be reset or replaced on its own.
- Subagents (the Agent tool) are fine *inside* any agent for read-only fan-out searches. They never own
  a lane.
- The supervisor drives workers only through the `fleet` command (devkit), which wraps the herdr
  CLI (`herdr tab create`, `herdr agent start --kind claude -- --permission-mode auto`,
  `herdr agent prompt`, `herdr agent wait`, `herdr agent read`).

### Roles

**User** decides product questions, approves anything outward-facing or destructive, restarts or
approves restarting the shared stack, answers blocked dialogs.

**Supervisor** (`docs/fleet/SUPERVISOR.md`)
- Plans: keeps the backlog, picks ready items, writes briefs, owns `docs/decisions.md`.
- Spawns, briefs, watches, resets and closes workers. Keeps the board.
- Verifies each worker's **Done when** itself (reads the diff, reruns the gate), then lands the branch.
- Owns the shared stack (`just up/down/restart`) and asks the user before restarting it.
- Talks to the user; relays worker questions as AskUserQuestion.
- **Does not write feature code.** It may fix the backlog, docs, decisions and trivial merge glue.

**Worker** (`docs/fleet/WORKER.md`)
- Works one brief at a time, inside its lane, in its own worktree.
- Loads conventions, writes code and tests, runs the gate, commits by pathspec on its branch.
- Writes a report to `.claude/fleet/reports/<ID>-<name>.md` and ends its turn with `REPORT <path>`.
- Writes a handover at every seam. Never talks to the user except through what the supervisor relays;
  never restarts shared services; never edits outside its lane without a cleared claim.

### Lifecycle

1. **Pick**: `backlog ready` → choose an item → `backlog set <ID> status doing`, `backlog set <ID> owner <name>`.
2. **Brief**: copy `docs/fleet/templates/brief.md` to `.claude/fleet/briefs/<ID>-<name>.md`. It starts
   with the backlog ID, copies **Goal** and **Done when**, and states the **Lane** (globs it may edit),
   **Reads** (docs to load), **Do not touch**, **Gate** (exact commands) and **Checkpoint** (where to stop
   and report before continuing, e.g. "design + screenshots before building the rest").
3. **Spawn**: `fleet spawn <name> -m <model> -l "<globs>"` (worktree + herdr tab + `claude --permission-mode
   auto`, `FLEET_PORT` assigned).
4. **Send**: `fleet brief <name> <brief-path>`.
5. **Watch**: `fleet wait <name>` → `idle`/`done` = turn finished, `blocked` = a dialog needs a human.
   `fleet read <name>` to see the tail. A blocked worker: read it, then ask the user; never answer an
   approval on the user's behalf.
6. **Verify**: read the report; check every **Done when** item yourself; run `devkit gate` in the worker's
   worktree; check the diff stays in the lane.
7. **Land**: `fleet land <name>` (fast-forward merge of `fleet/<name>` into main; if it isn't a
   fast-forward, the worker rebases first). Then `backlog set <ID> status done`, append the Result, file
   follow-ups as new items, commit `backlog: <ID> done (<sha>)`.
8. **Seam**: at 200k tokens (soft) the context guard tells the worker to finish its step and write its
   handover; at 250k (hard) it blocks the worker from ending its turn until it has. The worker commits
   `docs/handovers/<name>.md` and replies `HANDOVER <sha>`; the supervisor runs `fleet reset <name>` (`/clear`
   + resume prompt). Details: §7 "Context seams".
9. **Close**: `fleet close <name>` when the lane is done (exits Claude, closes the tab; the worktree is
   removed only if it is clean and merged).

`fleet` commands: `init · adopt · spawn · brief · say · wait · read · status · reset · respawn · land · close
· notify` (`fleet` with no args prints help). Skills: `/devkit:supervise`, `/devkit:work`, `/devkit:brief`,
`/devkit:land`, `/devkit:handover`, `/devkit:resume`.

### Lanes, claims and shared resources

- A **lane** is a set of path globs owned by one worker (`apps/server/internal/jobs/**`). Lanes don't
  overlap. The board lists each worker's lane and held files.
- Touching a file outside the lane needs a **claim**: the worker asks the supervisor, the supervisor checks
  the owner, records it on the board, and says "cleared". Changes to shared contracts (OpenAPI spec,
  shared packages, schema) need the consumers' OK first.
- Claims are released explicitly ("released after <sha>").
- **Shared resources have one owner**: the running stack, ports, the database, `docs/decisions.md` (the
  supervisor). Workers don't restart the stack.
- **Ports per worker**: each worker tab gets `FLEET_PORT=479<n>`; Playwright and any scratch server use
  it, so parallel E2E runs don't collide.

### Auto mode

- Every agent runs with `--permission-mode auto` (`fleet spawn` and `just supervisor` pass it; the template's
  `.claude/settings.json` also sets `defaultMode: auto`). Never `bypassPermissions` by default (workers were once spawned
  workers in bypass by config drift and nobody decided it).
- Auto mode still blocks risky actions (stopping shared servers, deleting data). The fix is a narrow
  allow rule in `.claude/settings.json` for the specific recipe, agreed with the user, not a wider mode.
- When a worker is `blocked`, the supervisor reads the dialog and asks the user.

### Messaging and context economy

- One message per seam or question; short tool output; few screenshots.
- Messages cross: say "final" when settling a split.
- Workers report into files (`REPORT <path>`), not long chat replies; the supervisor reads the file.
- Results go in files; the handover is the only thing that crosses a reset.

### Models (`docs/fleet/MODELS.md`)

- **Workers start on Sonnet.** Opus only for the kinds of work that lose quality on Sonnet: architecture,
  data model and API contract design, cross-cutting refactors, concurrency/transactions/migrations/auth,
  security review, and debugging that Sonnet couldn't explain in one attempt. The supervisor runs on Opus.
- Every brief has `Model: <model> (<reason row>)`.
- **Escalate, don't guess**: a Sonnet worker that fails the same gate twice without a clear cause, reports
  low confidence, or has a diff rejected for design → `fleet respawn <name> -m opus` (handover carries the
  context), logged on the board.
- Split mixed work: Opus writes the design note and Done-when, Sonnet builds, the supervisor verifies.
- Never use Opus because a task "feels important"; never downgrade an Opus task mid-flight.
- Every result is verified the same way regardless of model.

### Context seams (`docs/fleet/CONTEXT.md`)

| Limit | Tokens | Enforced by |
|-------|--------|-------------|
| soft | 200k | devkit's `hooks/context-guard.py` on PostToolUse: "finish the step, write the handover, end with `HANDOVER <sha>`" (once per session) |
| hard | 250k | same hook on Stop: blocks ending the turn until the handover is committed |
| backstop | 300k | `claude --autocompact 300000` (lossy; should never fire) |

- The hook measures context from the session transcript (last main-thread call's `input + cache_creation
  + cache_read` tokens) and writes it to `.claude/fleet/context/<agent>.json`; `fleet status` shows it.
- Limits are env vars in `.claude/settings.json` (`FLEET_SOFT_TOKENS`, `FLEET_HARD_TOKENS`).
- `fleet reset <name>` checks the handover is committed and the agent said `HANDOVER <sha>`, sends `/clear`,
  then the resume prompt: read AGENTS.md → role file → handover → brief → listed conventions cards, then
  **check the handover against the repo** (`git status`, `git log`, its state checks) before acting; the repo
  wins over the handover.
- The supervisor seams itself the same way: handover → `fleet reset supervisor --detach` → end turn.
- Seam early, whatever the size, when a lane ends, the work changes topic, or the agent is going in circles.

### Board (`.claude/fleet/board.md`, scratch)

```
| name | agent | tab | lane | item | state | held files |
| one  | <project>-one | w1:t2 | apps/web/src/find/** | T-012 | working | — |
## Claims
## Decisions this session (promote to docs/decisions.md)
## Pending for the user
```

### Handovers (`docs/handovers/<agent>.md`, committed, overwritten at each seam)

Templates: `docs/fleet/templates/handover-worker.md`, `handover-supervisor.md`. Sections: Goal · Done
(each with SHA) · State (measured) · In progress · Uncommitted · Held files · Next steps · Decisions made
and why · Open questions · Gotchas · Conventions loaded · Lessons → memory (or "none" and why).
Earlier seams live in git history.

---

## 8. Git

### MUST

- Branch per worker (`fleet/<name>`), worktree per worker; main moves only by fast-forward after the
  supervisor's verification.
- Commit small (~3–4 files), green, and by explicit pathspec: `git add <paths>`, never `git add -A` / `.`
  in a shared tree.
- Subject: lowercase prefix + outcome sentence + evidence:
  `T-107: import batches fan out by IMPORT_BATCH_SIZE (go test import+jobs ok, lint 0)`.
  Prefixes: `<ID>:`, `<ID> step N:`, `backlog:`, `handover:`, `decisions:`, `docs:`, `<area>:`.
- Code and its backlog close are separate commits; a decision lands with its doc edits.
- Honest subjects: `(untested)` when it is; correct an earlier false claim in a later subject.
- Trailers: `Co-Authored-By:` for the agent's model.
- Share by `git bundle create <name>-<date>-<sha>.bundle --all` + `git bundle verify` when there is no
  remote; check the bundle for secrets and client data first.

### MUST NOT

- No force push, no history rewrite on shared branches, no `--no-verify`.
- No commits of `.env`, client data, `data/`, `.run/`, build output, fleet scratch.
- No commit or push unless the user (or the brief) asks for it.

---

## 9. Data, secrets, safety

- Client data lives in `data/source/` and is never committed; generated data in `data/` is gitignored.
  `just reset` never deletes `data/source/`.
- Secrets only in `.env` (local) or a secret store; code references secrets by name. Logs never print a
  secret or a request body that may carry one.
- Artifacts (HTML prototypes, reports) stay local in `prototypes/` unless the user says to publish.
- Agents never close panes, tabs or sessions they didn't create, never run `herdr server stop`, never kill
  the herdr process.
- Destructive or outward-facing actions (deleting data, pushing, sending mail, publishing) need the user's
  explicit OK each time.

---

## 10. Lessons from practice

| What happened | Rule |
|---------------|------|
| Codex copy of CLAUDE.md rewrote real paths (`~/.Codex/design`, `.Codex/skills/...`) | One source; `CLAUDE.md` imports `AGENTS.md`; skills symlinked |
| No lint recipe; linter version mismatch; exclusion path never matched | `just check` from day one, pinned tools, paths tested from the root |
| Views rendered blank on any error | Shared loading/error/empty wrapper; regression spec with `?fault=reads` |
| One 700+ kB bundle with dev-only code inside | Code-split; live-bundle purity check |
| Unscoped realtime subscriptions | Scoped, per-view subscriptions |
| Two parallel E2E runs on port 4791 | Per-worker `FLEET_PORT` |
| Full E2E during someone's edits broke on hot reload | E2E gate only on a quiet tree (or in the worker's own worktree) |
| Workers spawned in bypass by config drift | Auto mode, set explicitly at spawn |
| Auto mode blocked workers restarting the server | Narrow allow rules for named recipes, agreed once |
| Docs cited `decisions l.127`; lines moved | Stable `d-<slug>` ids |
| Reconciliation docs went stale silently | `Accurate as of <sha>` header |
| Packages built with no caller; config parsed but unread | YAGNI; delete or file a bug |
| `last-sha` marker committed, then gitignored | Decide committed vs local up front |
| Briefs and reports gitignored, history lost | Copy durable results into the item body |
| CRLF on WSL made every file look changed | `.gitattributes eol=lf` |
| Two sessions with the same agent name | Unique names per server; `fleet status` before messaging |

---

## 11. Checklists

### New project

- [ ] `~/dev-playbook/new-project.sh <dir> --stack <go,ts,api> --ports <nn>` (template, git init, LF, symlinks)
- [ ] `tools/check-tools.sh` green
- [ ] Fill README (vision, principles), PRODUCT.md (interview the user), first decisions rows
- [ ] Reserve the port block in `docs/ports.md`
- [ ] Conventions cards for the stack exist (or `conventions doc:` tasks filed)
- [ ] `devkit check` and `devkit gate` run (even if empty)
- [ ] First backlog items with Goal / Done when; milestone M1 described in README

### Per task (worker)

- [ ] Read the brief, AGENTS.md, the conventions cards for the lane
- [ ] Stay in the lane; claim before touching anything else
- [ ] Test first for bugs; tests with the change for features
- [ ] `devkit gate` green; screenshots for UI
- [ ] Commit by pathspec with evidence in the subject
- [ ] Report file + `REPORT <path>`; follow-ups listed

### Per landing (supervisor)

- [ ] Every Done-when item checked against the diff and a rerun gate
- [ ] Diff inside the lane (`git diff --stat main...fleet/<name>`)
- [ ] Fast-forward merge, backlog closed with SHA, follow-ups filed
- [ ] Board updated; claims released

### Before a demo / release

- [ ] Full gate on main
- [ ] Ask the user, then `just reset && just up` from empty
- [ ] Walk the demo script; record measured numbers; tag anything unmeasured
- [ ] Bundle or push only after the user says so
