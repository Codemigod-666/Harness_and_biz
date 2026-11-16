# Conventions: Python (PY)

Status: Draft starter card. Lint/format: ruff (`pyproject.toml`). Types: mypy or pyright, strict on new code.
Tune the enforcement column to what the project actually runs.

| ID | Rule | Enforced |
|----|------|----------|
| PY-1 | Type-annotate every public function and attribute; no bare `Any` without a reason | mypy/pyright |
| PY-2 | One formatter (`ruff format`) and one linter (`ruff check`), configured in `pyproject.toml` | ruff |
| PY-3 | Never `except:` or `except Exception: pass`; catch the narrowest type, handle, wrap (`raise X from err`) or re-raise | ruff E722/BLE001, review |
| PY-4 | No mutable default arguments; use `None` and build inside | ruff B006 |
| PY-5 | Data shapes are `dataclass(frozen=True)`, `TypedDict` or `pydantic` models, not loose dicts passed around | review |
| PY-6 | Closed sets are `Enum` / `Literal`; match exhaustively and end with `assert_never` | mypy/pyright |
| PY-7 | Imports at the top, absolute, sorted; no `from x import *`; no import-time side effects | ruff F403/I |
| PY-8 | Config is read once in a `Settings` object at startup; nothing else touches `os.environ` | review |
| PY-9 | Inject clocks, randomness and I/O (`now: Callable[[], datetime]`); no `datetime.now()` inside logic | review |
| PY-10 | Use `logging` with a module logger, lazy args (`log.info("x %s", v)`); no `print` outside CLIs | ruff T201 |
| PY-11 | Paths via `pathlib`, files via `with`; subprocess with an argument list, `check=True`, never `shell=True` on input | ruff S, review |
| PY-12 | Each project picks one dependency manager (uv, poetry, pip-tools) and pins versions in a lock file | review |
| PY-13 | Tests with pytest: plain `assert`, fixtures over setUp, `tmp_path` for files, parametrize repeated cases | review |
| PY-14 | `# noqa` / `# type: ignore` name the rule and give a reason | ruff PGH |
