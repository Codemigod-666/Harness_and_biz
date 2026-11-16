---
id: T-001
title: "devkit core: stack-neutral skills, role docs and init templates"
type: task
status: done
milestone: "v0.2"
deps: []
created: 2026-11-16
owner: core
---


**Goal:** Every devkit skill and role doc works in any repo on any stack, and `devkit/templates/` holds the file
set `devkit init` adds (docs/design/devkit-portable.md, sections 1, 3, 4).

**Done when:**
- `grep -rnE '\bjust\b|pnpm|go (test|vet)|~/dev-playbook|new-project\.sh' devkit/skills/*/SKILL.md devkit/templates docs/fleet`
  finds nothing outside an explicit "if your project uses a justfile" example; gates are `devkit check|gate|e2e`.
- The root `devkit/SKILL.md` moves to `devkit/skills/devkit/SKILL.md` and is rewritten around "adopt this repo"
  (`devkit init`, `devkit doctor`) and "questions about the rules" (rules ship in the plugin: `devkit/templates/core/docs/fleet/*.md`
  and a stack-neutral `devkit/PLAYBOOK.md` digest, or the repo's own docs/fleet when present).
- `devkit/templates/core/` contains exactly the tree in section 3 (AGENTS.md section text with its marker comment,
  docs/fleet/{SUPERVISOR,WORKER,MODELS,CONTEXT}.md + templates/, docs/backlog/INDEX.md, docs/handovers/.gitkeep,
  docs/decisions.md with no placeholders, docs/memory/INDEX.md, docs/conventions/{general,testing}.md,
  .devkit/config.env.example). `devkit/templates/conventions/` has go, typescript, react, api (from template/) and a new python.md.
- The conventions skill picks cards by file extension (table) plus `lib-<name>.md`, and loads general + testing always.
- `template/docs/fleet/*` and this repo's `docs/fleet/*` match the new core versions (one source: copy, then
  `diff -r` is empty), so new-project.sh starters and adopted repos get the same rules.
- `claude plugin validate devkit` passes; `just gate` green.

**Result (2026-11-16, core).** 3171b25: skills and role docs stack-neutral (gates are `devkit check|gate|e2e`), devkit skill moved to skills/devkit and rewritten around `devkit init`, devkit/templates/core + conventions cards (new python.md), stack-neutral devkit/PLAYBOOK.md digest; fleet docs identical in docs/fleet, template/ and templates/core. Supervisor verified: grep clean, diff -r empty x3, gate green.
