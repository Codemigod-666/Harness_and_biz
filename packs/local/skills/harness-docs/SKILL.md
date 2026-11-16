---
name: harness-docs
description: >-
  Keep the harness field guide (~/dev-playbook/docs/site/index.html) current and serve it locally on
  http://127.0.0.1:4700. Use after ANY change to the harness (devkit skills, fleet, backlog, claude-acct,
  accounts, hooks, template, PLAYBOOK/GUIDE), when the user asks to read, open, start or update the guide,
  or asks how the harness works. Triggers: /harness-docs, "update the guide", "open the guide",
  "serve the docs", "explain the system".
argument-hint: "[update | start | stop | status]"
allowed-tools: Bash(harness-docs *)
---

# Harness field guide

One self-contained HTML page, `~/dev-playbook/docs/site/index.html`, that explains the harness to the user in
plain language. It is **local only**: never publish it with the Artifact tool, a gist, a paste site or any other
service. It is committed to the playbook's git repo, and that is the only place it goes.

## Serve

```bash
harness-docs start     # http://127.0.0.1:4700 (HARNESS_DOCS_PORT to change); WSL: open it in the Windows browser
harness-docs status | stop | url | path
```

## Update (after every harness change, in the same commit as the change)

1. Read the page, then change only the sections the change touches: pieces, accounts, login, commands, files,
   roadmap. Describe what exists now; never document a feature that isn't built.
2. Roadmap: move items between `done` / `next` / `later`, and add new ideas from the session as `later`.
3. Changelog: add a dated entry at the top (`YYYY-MM-DD · vX.Y`, bump the minor), and update the date and
   version in the nav `meta` line to match.
4. Keep the page self-contained: no external scripts, fonts or images, colors only from the `:root` tokens,
   light and dark both readable, usable at phone width.
5. Keep private details out, because the repo can be public: no emails, org names, client or project
   codenames, tokens or paths from other repos.
6. Commit it with the harness change, e.g. `git -C ~/dev-playbook add docs/site && git commit`.
