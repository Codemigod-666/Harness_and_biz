---
id: T-003
title: "devkit pack: marketplace, frappe and local packs, README, e2e test on 3 stacks"
type: task
status: done
milestone: "v0.2"
deps: [T-001, T-002]
created: 2026-11-16
owner: pack
---


**Goal:** devkit installs from GitHub into any project with two `/plugin` commands, Frappe and machine-local
skills live outside the core, and an end-to-end test proves it on three stacks (docs/design/devkit-portable.md, section 1).

**Done when:**
- `.claude-plugin/marketplace.json` (name `harness`) lists devkit (./devkit) and devkit-frappe (./packs/frappe);
  `claude plugin validate .` passes.
- zipzap moves to packs/frappe (skill + bin/frappe-zip, bin/frappe-zap), harness-docs to packs/local; install.sh
  links packs into ~/.claude/skills; the live ~/.local/bin links still resolve.
- devkit plugin.json version 0.2.0 and a description that names no stack.
- README.md: install from the marketplace, `devkit init`, local-checkout install, what the packs are.
- tests/e2e-stacks.sh: for a node, a python and a go-less shell repo in a temp dir: `devkit init --yes`,
  `devkit doctor`, `backlog new task …`, `devkit gate`, and `claude plugin validate` on the plugin; all pass.
- Field guide (docs/site/index.html) updated per /devkit:harness-docs: install, `devkit init`, packs, changelog v0.4.
- `just gate` green.

**Result (2026-11-16, pack).** 3447a3d; supervisor reran devkit gate (e2e 3 stacks, starters, plugin + marketplace validation) green.
