---
name: conventions
description: >-
  Load the project's coding rules (cards in docs/conventions/, each rule with an ID like GEN-2, GO-4, TS-17,
  PY-3) for the files about to be written or reviewed. Use before writing or reviewing any code, and for
  /violations audits. Triggers: writing code, reviewing a diff, "conventions", "/violations", "lint rules".
argument-hint: "[cards <paths…> | violations [since <sha>]]"
---

# Conventions

Cards live in `docs/conventions/`. Each rule has a stable ID, a one-line rule, a why, and how it is enforced
(lint rule name, or `review` when no tool can check it).

## Which cards to load

Always load `general.md` and `testing.md`. Then add the cards that match the files in hand, by extension:

| Files | Card |
|-------|------|
| `*.go` | `go.md` |
| `*.ts`, `*.tsx`, `*.js`, `*.jsx`, `*.mjs` | `typescript.md` |
| `*.tsx`, `*.jsx` | `react.md` |
| `*.py` | `python.md` |
| OpenAPI / API contract files (`openapi.*`, `**/openapi/**`) | `api.md` |
| any other language (`*.rs`, `*.java`, `*.rb`, …) | `<language>.md` if present |
| uses a library with its own card (`pocketbase`, `inngest`, `tanstack-query`, `frappe`…) | `lib-<name>.md` |

Load only what matches; say which cards you loaded (handovers list them under Conventions). `ls
docs/conventions/` shows what the project has; a card the table names but the repo lacks is not an error unless
its rules matter (see below).

## Missing card

If a library or language in your files has no card and its rules matter, reply `CONVENTIONS MISSING <list>`
and stop. The supervisor files `conventions doc: <name>` tasks that block the code tasks (backlog skill).
A card is written from the library's official docs and real incidents, with IDs `<LIB>-<n>`.
Optional starter cards ship in the plugin (`templates/conventions/`); `devkit init --cards <list>` copies them.

## Writing and reviewing

- Lint-enforced rules: run `devkit check`; don't restate what the linter says, fix it.
- Review-only rules: check them by reading; cite the rule ID in review findings.
- A suppression (`//nolint`, `biome-ignore`, `# noqa`) names the rule and a reason.
- An exception to a rule is a `question` item, not a silent deviation.

## /violations audit

1. Range: `.claude/conventions-audit/last-sha..HEAD` (local marker, gitignored; first run: whole tree).
2. Split the files into chunks that fit one context; one subagent or worker per chunk, read-only.
3. Findings → one `bug` per rule cluster: title `<RULE-ID>: <summary>`, files and lines in the body, not one
   item per line.
4. Write the new HEAD sha to `last-sha` when every chunk is done.
