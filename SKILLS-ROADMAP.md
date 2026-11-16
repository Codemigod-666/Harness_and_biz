# Skills roadmap: making the playbook global

Status: 2026-10-15. **Built:** §1 (devkit plugin, installed) and the P1 skills (supervise, work, brief, land,
handover, resume), tested in one real supervisor → worker → land → reset cycle. **Installed:** pr-review-toolkit,
code-review, hookify, security-guidance, frontend-design, plugin-dev (user scope) and webapp-testing (personal
skill copy). **Open:** P2, P3, the subagents in §4, Trail of Bits.

## 1. How to make it global: one user-level plugin, "devkit"

Today every project gets copies of `backlog`, `fleet`, `conventions` and the context-guard hook. Copies drift
(a Codex copy once rewrote real paths). Claude Code has a better vehicle:

- A folder in `~/.claude/skills/` that contains `.claude-plugin/plugin.json` **loads as a plugin in every
  session, no install step** (`claude plugin init` scaffolds one). Source: Create a plugin, "Make a plugin load
  in every session".
- A plugin bundles `skills/`, `agents/` (subagent definitions), `hooks/hooks.json` (same shape as settings
  hooks) and `.mcp.json`. Plugin skills are namespaced: `/devkit:fleet`, `/devkit:handover`.
- `claude plugin validate <dir>` checks it; `/reload-plugins` picks up edits; `claude plugin eval` measures
  whether a skill actually changes behaviour.
- Cost to watch: every model-invocable skill's name + description sits in context on every turn. Keep
  descriptions short; mark user-only skills `disable-model-invocation: true`.

Proposed layout (`~/dev-playbook/devkit/`, symlinked to `~/.claude/skills/devkit`):

```
devkit/
├─ .claude-plugin/plugin.json          {"name": "devkit", "version": "0.1.0", ...}
├─ SKILL.md                            /devkit: "what the playbook says about X", new project
├─ skills/<name>/SKILL.md (+ scripts/)  everything in §3
├─ agents/{reviewer,verifier,auditor}.md   read-only subagents (§4)
└─ hooks/hooks.json                    context guard via ${CLAUDE_PLUGIN_ROOT}/hooks/context-guard.py
```

What stays per project: data, not machinery. `AGENTS.md`/`CLAUDE.md`, `docs/` (backlog items, decisions,
handovers, conventions cards, fleet templates if customised), `.claude/settings.json` (allow rules, the
`FLEET_*` limits). `new-project.sh` stops copying skills; old projects can delete theirs.

Guards needed when global: the context guard and fleet act only in a repo that has `docs/fleet/` (or
`FLEET_AGENT` set), so personal one-off sessions aren't nagged about handovers.

## 2. Install, don't rebuild (existing plugins)

| Plugin | From | Take | Why / caveat |
|--------|------|------|--------------|
| `pr-review-toolkit` | claude-plugins-official | yes | review agents for comments, tests, error handling, type design, simplification; supervisor uses them to verify a worker's diff |
| `code-review` | claude-plugins-official | yes | multi-agent PR review with confidence scoring (fewer false positives) |
| `commit-commands` | claude-plugins-official | maybe | commit/push/PR flows; must not override "pathspec only, no `git add -A`" |
| `hookify` | claude-plugins-official | yes | turns a recurring mistake into a hook; fits "rules enforced by tools" |
| `security-guidance` | claude-plugins-official | yes | warns on risky edits |
| `frontend-design` | claude-plugins-official / anthropics/skills | yes | UI quality; pairs with DESIGN.md |
| `plugin-dev` | claude-plugins-official | yes, for building devkit | scaffolds/validates plugins |
| `webapp-testing` | anthropics/skills (`example-skills`) | yes | Claude drives a live browser to check UI |
| Trail of Bits `static-analysis`, `differential-review`, `supply-chain-risk-auditor`, `sharp-edges` | trailofbits/skills | yes, release gate | CodeQL/Semgrep, diff-focused security review, dependency risk |
| `superpowers` | obra/superpowers | **don't install whole**; borrow ideas | strong TDD / debugging / verification / planning skills (MIT), but its `subagent-driven-development` and `dispatching-parallel-agents` run workers as subagents, which conflicts with our rule that every worker is a separate herdr agent; skills auto-trigger, so both would fight |

## 3. Skills to build into devkit

Priority **P1** = the fleet works end to end; **P2** = quality; **P3** = project lifecycle.

| P | Skill | What it does | Comes from |
|---|-------|--------------|------------|
| P1 | `supervise` | loads the supervisor role (SUPERVISOR.md), adopts the pane, reads its handover, runs the loop | our docs/fleet |
| P1 | `work` | loads the worker role (WORKER.md) for a named worker; start-of-session checks | our docs/fleet |
| P1 | `fleet` | (exists) spawn/brief/wait/reset/respawn/land/close on herdr | built |
| P1 | `brief` | backlog item → brief file: Goal/Done-when copied, lane, reads, checkpoint, model row from MODELS.md | practice |
| P1 | `handover` | writes the handover from the template, fills git state automatically (SHAs, `git status`, held files), checks every section is filled and no secrets leak, commits, prints `HANDOVER <sha>` | session-handoff (davila7) validation idea |
| P1 | `resume` | fresh-session restart: reads the handover, **staleness check** (commits since, files changed, gate status vs handover), lists differences before acting | session-handoff staleness check |
| P1 | `land` | supervisor's verification: each Done-when vs the diff, lane check (`git diff --stat`), gate rerun, ff merge, close item with SHA, file follow-ups | practice |
| P1 | `backlog` | (exists) | built |
| P2 | `tdd` | red → green → refactor; failing test first for every bug; testing anti-patterns | superpowers test-driven-development (adapted) |
| P2 | `debug` | root cause before fix: reproduce, isolate, hypothesise, prove; `--repeat-each` for flakes; escalate to Opus after one failed explanation | superpowers systematic-debugging + MODELS.md |
| P2 | `verify-done` | no "done" without the command and its output; tags `[unmeasured]` | superpowers verification-before-completion + our honesty tags |
| P2 | `conventions` | (exists) load cards | built |
| P2 | `violations` | chunked conventions audit since `last-sha`, one bug per rule cluster, workers per chunk | practice |
| P2 | `design-review` | screenshots at two widths × both themes, contrast/target/landmark audit, checked against DESIGN.md | practice |
| P2 | `write-conventions` | `CONVENTIONS MISSING <lib>` → a card with rule IDs from official docs + real incidents | practice |
| P3 | `interview` | PRODUCT.md / README interview with AskUserQuestion; anti-invention rule | practice |
| P3 | `decide` | adds a decisions row + production footnote, supersedes by `d-<slug>`, updates affected docs in the same commit | practice |
| P3 | `stories` | demo script and Given/When/Then stories → test stubs (Go integration / Playwright) | practice |
| P3 | `reconcile` | docs vs code drift pass: resolved (with SHAs), consistent, open (options + recommendation → question items), not covered; footnote ref/def balance | practice |
| P3 | `record-mock` | scaffold record/replay for an external API: budgeted pull script, content-addressed cache, mock server with auth + rate limits | practice |
| P3 | `measure` | perf work starts with measurement: per-step timings, baseline vs change, report table | practice |
| P3 | `demo-prep` | full gate → ask → empty start → walk demo script → measured run sheet | practice |
| P3 | `release` | secrets/data scan, security plugins (Trail of Bits), bundle or push, version bump | practice |
| P3 | `port-plan` | production port checklist: component map, access asks, gaps, ordered steps each with a verify | practice |
| P3 | `lessons` | one-lesson files in docs/memory with dedup against existing lessons, conventions, AGENTS.md | practice |

## 4. Subagents (read-only helpers, `agents/`)

Fine under the fleet rules because they never own a lane or edit files:

- `reviewer`: reviews a diff against the loaded conventions cards; findings with rule IDs and file:line.
- `verifier`: given a report and a diff, checks each Done-when claim and says which lack evidence.
- `auditor`: one chunk of a `/violations` audit.
- `explorer`: cheap fan-out search (Haiku/Sonnet) for the supervisor.

## 5. Order of work

1. Build `devkit` with what exists (fleet, backlog, conventions, context-guard hook, playbook skill); move
   the `docs/fleet` role text into `supervise` / `work`; change `new-project.sh` to stop copying skills.
2. P1 skills: `brief`, `handover`, `resume`, `land`. Then one real supervisor + worker cycle on a test repo.
3. Install the official plugins in §2 (user scope); check `/plugin` context cost after.
4. P2, then P3, each with a `claude plugin eval` case or two so we know the skill changes behaviour.

## Sources

- [Plugins overview (Claude Code docs)](https://code.claude.com/docs/en/plugins)
- [Create a plugin (Claude Code docs)](https://code.claude.com/docs/en/plugins/create)
- [anthropics/claude-code plugins](https://github.com/anthropics/claude-code/tree/main/plugins)
- [anthropics/skills](https://github.com/anthropics/skills)
- [obra/superpowers](https://github.com/obra/superpowers)
- [trailofbits/skills](https://github.com/trailofbits/skills)
- [session-handoff (davila7/claude-code-templates)](https://claudemarketplaces.com/skills/davila7/claude-code-templates/session-handoff)
- Roundups (popularity numbers unverified): [Firecrawl](https://www.firecrawl.dev/blog/best-claude-code-skills), [Composio](https://composio.dev/content/top-claude-skills), [DEV Community](https://dev.to/raxxostudios/best-claude-code-skills-plugins-2026-guide-4ak4)
