# Contracts

Prose companions to api/openapi/. One file per surface. Header: Status, author, readers. Each operation is
tagged `[built]` or `[spec only]`; guesses are tagged `[inferred]`.

## Conventions for every operation
- Names `verbNoun` = OpenAPI operationId; cursor paging; ISO-8601 UTC; values `{value, unit, display}`;
  errors RFC 9457 problem+json; roles from `x-__PROJECT__-roles`.
