# Conventions: TypeScript (TS)

Status: Approved (playbook). Lint/format: Biome (`biome.json`). Types: `tsconfig.base.json`.

| ID | Rule | Enforced |
|----|------|----------|
| TS-1 | tsconfig strict + `noUncheckedIndexedAccess` + `exactOptionalPropertyTypes` + `noImplicitOverride` + `verbatimModuleSyntax` + `erasableSyntaxOnly` | tsc |
| TS-2 | Imports carry `.ts`/`.tsx` extensions; no enums, no parameter properties (Node runs TS by type stripping) | tsc |
| TS-3 | No `any`, no non-null `!`; narrow with guards | Biome |
| TS-4 | Named exports only; default export only where a tool demands it, with a `biome-ignore` reason | Biome |
| TS-5 | Packages export TS source (`"exports": {".": "./src/index.ts"}`); apps depend with `workspace:*` | review |
| TS-6 | Declared failures are values: `Result<T, E> = {ok: true, value} | {ok: false, failure}`; throw only for the unexpected (network) | review |
| TS-7 | The API client is generated from OpenAPI; apps never import the HTTP library directly (restricted import) | Biome |
| TS-8 | Each feature declares the slice of the client it uses: `type FindClient = Pick<ApiClient, "searchParts">` | review |
| TS-9 | All side effects injected (`fetch`, `getToken`, clock); unit tests pass recording fakes | review |
| TS-10 | Files kebab-case; factories `createX`; providers `provideX` + accessor `x()` (or React context) | review |
| TS-11 | Constants SCREAMING_CASE at module top | review |
| TS-12 | One-line `/** … */` doc on exports saying intent | review |
| TS-17 | `readonly` all the way down for data passed around (`readonly T[]`, `ReadonlyMap`) | review |
| TS-21 | Branded ids for domain keys (`type PartId = string & {readonly __brand: "PartId"}`) | review |
| TS-25 | Derive types from the source (`z.infer`, generated types, `typeof X[number]`), don't restate them | review |
| TS-30 | Unit tests: `node --test` + `node:assert/strict`, `TZ=UTC`, no framework | review |

```ts
/** The slice of the API port the find screen calls. */
export type FindClient = Pick<ApiClient, "searchParts" | "getCommoditySchema">;
```
