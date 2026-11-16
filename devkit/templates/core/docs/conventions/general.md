# Conventions: general (GEN)

Status: Approved (playbook). Applies to every language. Enforced = lint rule, or `review`.

| ID | Rule | Why | Enforced |
|----|------|-----|----------|
| GEN-1 | Functions ≤ 40 lines, ≤ 4 parameters, cognitive complexity ≤ 10, nesting ≤ 3 | small units are testable and reviewable | funlen/gocognit/nestif, Biome |
| GEN-2 | UI components ≤ 40 lines (linters often skip functions that return markup) | same limit as GEN-1 | project lint script or `review` |
| GEN-3 | Files ≤ 300 code lines, lines ≤ 120 | one concern per file | revive file-length, Biome, golines |
| GEN-4 | Known offenders live in a baseline that may only shrink; a fixed offender must be removed from it | ratchet, never regress | lint scripts |
| GEN-5 | Names say what, not how: booleans `is/has/can`, no abbreviations except the domain's, no stutter (`config.Config`) | readable at the call site | revive, review |
| GEN-6 | Inject time, randomness, env, I/O, loggers; no hidden globals | deterministic tests | forbidigo, gochecknoglobals, review |
| GEN-7 | No magic values: named constants, one shared formatter for numbers/dates/units, one source per literal | change in one place | review |
| GEN-8 | Make illegal states unrepresentable: discriminated unions / typed enums over overlapping booleans | bugs like held+done both true | review |
| GEN-9 | Exhaustive handling of enums and unions | new cases fail loudly | exhaustive, `assertNever` |
| GEN-10 | Never swallow errors (`catch {}`, `_ = err`); handle, wrap or return them; kill child processes you start | silent failures | errcheck, review |
| GEN-11 | Don't mutate arguments; return new values | aliasing bugs | review |
| GEN-12 | Config is read in one place and validated at startup; nothing else reads env | one source of truth | forbidigo |
| GEN-13 | Comments say why or the contract, one or two sentences; no comments restating code | ~5% comment lines | review |
| GEN-14 | Every lint suppression names the rule and gives the reason | suppressions stay honest | nolintlint, review |
| GEN-15 | YAGNI: no code, config or package without a caller; delete dead code | inventory is not progress | unused, review |
| GEN-16 | No unused injected dependencies | misleading wiring | review |
| GEN-17 | Business rules are data run by deterministic code; LLMs never write runtime logic, they only resolve what rules can't, with provenance | auditable, reproducible | review |
| GEN-18 | Edit source with Edit/Write or `ast-grep`, never `sed`/`perl` | sed breaks code silently | review |
| GEN-19 | Generated files are never hand-edited; regenerate, and a drift check fails the build | spec stays the source | `check:generated` |
| GEN-20 | Secrets never in code, logs or error text; reference them by name | leaks | gosec, review |
