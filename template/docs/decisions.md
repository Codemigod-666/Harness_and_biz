# Decisions

One row per decision, one line, newest last. `by` is `user` or `supervisor`. Every row ends with a footnote
`[^d-<slug>]` saying how it maps to production; cite decisions by that id (`d-<slug>`), never by line number.
Superseding: write `Supersedes d-<slug>` in the new row.

| date | decision | by |
|------|----------|----|
| __DATE__ | Playbook setup: backlog skill, fleet on herdr (workers = separate Claude Code agents, auto mode), context seams 200k/250k, model policy docs/fleet/MODELS.md[^d-playbook] | user |
| __DATE__ | Task runner: just (root justfile); `just check` and `just gate` are the gates[^d-task-runner] | user |
| __DATE__ | Local ports: block __P__00–__P__99 by band; see docs/ports.md[^d-local-ports] | user |

[^d-playbook]: None; development process only, no production counterpart.
[^d-task-runner]: None; dev tooling. **Production:** CI runs the same `just gate`. **Ports as-is:** recipes. **Rewritten:** nothing.
[^d-local-ports]: None; local only. **Production:** service hostnames behind the platform's ingress.

<!-- Footnote schema: **Production (Proposed|Open):** … **Ports as-is:** … **Rewritten:** … **Risk:** … See architecture.md `prod-<id>`. -->
