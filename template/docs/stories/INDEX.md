# Stories

The living spec of the milestones. Each story's Given/When/Then is written to become a test (integration test
or Playwright spec). Update rule: a decision, a flow change or a built spec updates the story in the same commit.

## Format
- **Id** `S-<EPIC>-<n>`, stable; a dropped story keeps its id with status `dropped`.
- **As** a <role> **I want** … **so that** …
- **Given / When / Then** in observable terms: routes, events, tables, screens.
- **Links:** decisions (`d-<slug>`), backlog items.
- **Status:** `none` · `spec <path>` (exists, not passing) · `passing <path>`.
- **Today:** how the code differs, when it does.

## Epics
| file | epic | stories | status |
|------|------|---------|--------|

## Shared givens
- **empty stack**: `just reset && just up`
- **scripted LLM**: canned answers per test; specs never call a live model
