# Conventions: API contract (API)

Status: Approved (playbook). Spec: `api/openapi/<project>.yaml` (OpenAPI 3.1). Lint: `redocly.yaml`.

| ID | Rule | Enforced |
|----|------|----------|
| API-1 | The spec is the source of truth; server stubs and the TS client are generated from it and committed; drift fails the build | `check:generated` |
| API-2 | `info.version` is semver, bumped with every change; breaking changes need the consumers' OK first | review |
| API-3 | Paths kebab-case and plural, no verbs; operationId camelCase `verbNoun`; properties camelCase | redocly |
| API-4 | One tag per operation, tags alphabetical and described | redocly |
| API-5 | Requests `application/json`; responses `application/json` or `application/problem+json`; every 4xx is RFC 9457 problem details | redocly |
| API-6 | Roles and capabilities live in the spec (`x-<project>-roles`, `x-<project>-capability`); the server reads them at startup and fails if one is missing | test |
| API-7 | Cursor paging (`cursor`, `nextCursor`), ISO-8601 UTC times, values with units as `{value, unit, display}` | review |
| API-8 | No unused components; refs strict | redocly |
| API-9 | Prose contracts in `docs/contracts/` tag each operation `[built]`, `[spec only]` | review |
| API-10 | Every operation has a contract test; the untested list only shrinks | test |
