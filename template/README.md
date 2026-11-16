# __PROJECT__

<One line: what this is and for whom.>

## What it does
<Three to five bullets, in the user's words.>

## Principles
1. <e.g. Minimal human in the loop: mechanical jobs first, LLM for conflicts, humans for low confidence.>
2. <…>

## Milestones
- **M1** — <scope, the demo that proves it (docs/stories/demo-script.md)>

## Docs
- PRODUCT.md — users, purpose, constraints
- DESIGN.md — design system (tokens, rules)
- docs/decisions.md — decision log (each with its production footnote)
- docs/architecture.md — how the decisions fit together
- docs/domain.md — what the data looks like (measured)
- docs/ports.md — local port block __P__00–__P__99
- docs/stories/ — acceptance stories; docs/contracts/ — API contracts
- docs/backlog/ — tasks, ideas, bugs, questions, one file each (INDEX.md)
- docs/conventions/ — coding rules with IDs
- docs/fleet/ — how the supervisor and workers run (models, context seams, templates)
- docs/handovers/ — one per agent, rewritten at every seam
- docs/memory/ — one lesson per file

## How to work here
Human guide: `~/dev-playbook/GUIDE.md`. Agent rules: AGENTS.md and docs/fleet/.

## Run locally
```bash
tools/check-tools.sh      # toolchain present and pinned
just up                   # start the stack (see docs/ports.md)
just gate                 # lint + types + tests
just supervisor           # inside herdr: start the supervisor agent
```
