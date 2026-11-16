# Conventions: React (REACT), routing (RR), data (RQ), UI (UI)

Status: Approved (playbook). Stack default: Vite + React 19 + React Router + TanStack Query/react-query-kit +
Tailwind v4 + shadcn/Radix. Design tokens from DESIGN.md.

## Structure

| ID | Rule | Enforced |
|----|------|----------|
| REACT-1 | Feature-first folders: `<feature>/{client.ts, queries.ts, <feature>-view.tsx, use-*.ts, *-model.ts, fake/}`; shared in `components/`, `lib/`, `app/` | review |
| REACT-2 | Components are `function Name(props: NameProps)` named exports; props interface with `readonly` fields | review |
| REACT-3 | Components ≤ 40 lines (GEN-2): split into small private sub-components and `useX` hooks above the export | jsx lint |
| REACT-7 | Stable keys from data ids, never array index for dynamic lists | review |
| REACT-15 | One exported component per file | review |

## Ports and fakes

| ID | Rule | Enforced |
|----|------|----------|
| REACT-20 | Two entries: `main.tsx` (live) and `main-demo.tsx` (fakes), chosen by `VITE_ADAPTER=demo`; both call one `startApp()` | review |
| REACT-21 | Fakes return the same Result shapes and refusals as the server; URL params inject faults (`?fault=reads`) and scenarios | review |
| REACT-22 | The live bundle never contains fakes/fixtures/sims | `check-live-bundle.sh` |
| REACT-23 | Prefer providing clients through React context over module singletons | review |

## Data (react-query-kit)

| ID | Rule | Enforced |
|----|------|----------|
| RQ-1 | One `router()` per feature in `queries.ts`; `strictVariables: true` registered | review |
| RQ-2 | Pass `signal` to every fetcher; `unwrap(result)` turns a failure into a thrown problem error | review |
| RQ-3 | `staleTime: Infinity`, `retry: false`, freshness by change-driven invalidation (realtime/polling feed → `invalidateQueries`), `cancelRefetch: false` for bursts | review |
| RQ-4 | Realtime subscriptions are scoped by filter, per view; never `"*"` on a growing collection | review |

## Routing

| ID | Rule | Enforced |
|----|------|----------|
| RR-1 | Root route has an `errorElement`; every route that can fail has one | review |
| RR-6 | Auth guard as loader/middleware, not inside components | review |
| RR-8 | Login and other public routes have an `errorElement` too | review |

## UI

| ID | Rule | Enforced |
|----|------|----------|
| UI-1 | Every view renders loading, error (with retry, `role="alert"`) and empty states; never `if (!data) return null` | spec `?fault=reads` |
| UI-2 | Accessible markup is the test API: roles + names on regions, lists, toolbars; `aria-busy`, `aria-current` | Playwright by role |
| UI-3 | Tokens only (CSS variables from DESIGN.md → Tailwind `@theme inline`); no raw hex in components | review |
| UI-4 | Variants with `cva`, classes merged with `cn()` | review |
| UI-5 | WCAG AA contrast (4.5:1 text, 3:1 large), targets ≥ 24×24 px, no horizontal page scroll | audit script |
| UI-6 | Code-split routes; check bundle size on build | review |
| UI-7 | Screenshots at two widths, both themes, for every UI change | review |
