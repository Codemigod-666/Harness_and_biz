# Conventions: Go (GO)

Status: Approved (playbook). Lint: `.golangci.yml` (golangci-lint v2), formatters gofumpt + goimports + golines.

## Layout

| ID | Rule | Enforced |
|----|------|----------|
| GO-1 | `cmd/<bin>/main.go` is thin: `main() { if err := run(); err != nil { fmt.Fprintln(os.Stderr, err); os.Exit(1) } }`; `run` loads config, builds the logger, wires, starts | review |
| GO-2 | Domain code in `internal/<noun>/`, short lowercase single-word packages, one concern per file | review |
| GO-3 | Generated code in its own package (`internal/api/<x>api`), handwritten handlers beside it | review |
| GO-4 | Env is read only in `cmd/` and `internal/config` via `config.Load(getenv func(string) string)` | forbidigo |
| GO-5 | Constructors `NewX(deps Deps)`; per-package `Deps` and `Options` structs; no DI framework | review |

## Errors

| ID | Rule | Enforced |
|----|------|----------|
| GO-6 | Wrap at every return: `fmt.Errorf("<verb> <noun>: %w", err)`, lowercase, no punctuation; no `pkg/errors` | wrapcheck, errorlint, depguard |
| GO-7 | Sentinels `var ErrX = errors.New("...")` with a doc comment; no dynamic `errors.New` inline; check with `errors.Is` / `errors.As` | err113, errname |
| GO-8 | Cleanup with `errors.Join`: `defer func() { err = errors.Join(err, f.Close()) }()` with a named return | review |
| GO-9 | Take `ctx` from the caller; `context.Background` only in `main` | forbidigo, contextcheck |
| GO-10 | HTTP errors are RFC 9457 `application/problem+json`, mapped from sentinels in one table; validation errors never echo the request body | review |
| GO-11 | No `nil, nil` returns without a nolint reason | nilnil |

## Design

| ID | Rule | Enforced |
|----|------|----------|
| GO-12 | Time (`Now func() time.Time`) and randomness (`io.Reader`) are injected | review |
| GO-13 | Interfaces are declared by the consumer, small (≤ 5 methods), composed | iface, interfacebloat |
| GO-14 | Return concrete types, accept interfaces | ireturn |
| GO-15 | No package-level vars or `init()` | gochecknoglobals, gochecknoinits |
| GO-16 | No unused injected deps (`Deps.Rand` nobody reads) | review |
| GO-17 | `log/slog` only, injected `*slog.Logger`; `*Context` calls, static messages, snake_case keys; no `fmt.Print`, `log.*`, zap, logrus | sloglint, forbidigo, depguard |
| GO-18 | UTC everywhere (`time.Local = time.UTC` in main, logger stamps UTC) | test |
| GO-19 | No `io/ioutil`, no `math/rand` (use `crypto/rand` or an injected source) | depguard |
| GO-25 | No stutter (`lake.Lake`, `config.Config` → `lake.Store`, `config.Values`) | revive, review |

## Tests

| ID | Rule | Enforced |
|----|------|----------|
| GO-20 | stdlib `testing` + `go-cmp` only; no testify | depguard |
| GO-21 | `t.Parallel()` in every test and subtest unless a nolint says why | paralleltest, tparallel |
| GO-22 | No `time.Sleep`: wait on ctx/conditions; tests use injected clocks or `testing/synctest` | forbidigo |
| GO-23 | No mocking frameworks; hand-written fakes that obey the real contract (one contract suite runs over real and fake) | depguard |
| GO-24 | Sentence names `TestLoadRejectsEmptyKey`; table tests `tests := []struct{name string; …}`; `package x_test` by default, `*_internal_test.go` for white-box | review |
| GO-26 | Integration tests use real embedded stores in `t.TempDir()`; live tests opt in by env var and skip otherwise | review |
| GO-27 | Contract test validates every request/response against the embedded OpenAPI spec; the untested-operations list only shrinks | test |

## Jobs (durable workflows)

| ID | Rule | Enforced |
|----|------|----------|
| GO-30 | Every side effect inside a durable step; step ids are constants | review |
| GO-31 | Events carry an idempotent id; a sweep re-sends work lost between commit and send | review |
| GO-32 | Single-writer stores get one concurrency key with limit 1 | review |
| GO-33 | Long runs chunk and re-emit their own event; a failure handler closes dangling state so nothing waits forever | review |

## Snippet

```go
// upsert inserts a seed row by key; an existing row is kept (backoffice edits win) unless overwrite is set.
func (s *store) upsert(collection, key string, fields map[string]any) (*core.Record, error) {
	record, err := s.app.FindFirstRecordByData(collection, "key", key)
	if err != nil && !errors.Is(err, sql.ErrNoRows) {
		return nil, fmt.Errorf("find %s %q: %w", collection, key, err)
	}
	// …
}
```
