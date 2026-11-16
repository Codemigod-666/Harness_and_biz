set shell := ["bash", "-euo", "pipefail", "-c"]

default:
    @just --list

# Syntax-check every script, shellcheck when installed, validate the plugins and the marketplace.
check:
    #!/usr/bin/env bash
    set -euo pipefail
    fail=0
    while IFS= read -r f; do
        case "$(head -1 "$f")" in
        *bash*) bash -n "$f" || fail=1; command -v shellcheck >/dev/null && { shellcheck -S warning "$f" || fail=1; } ;;
        *python*) python3 -m py_compile "$f" || fail=1 ;;
        esac
    done < <(git ls-files -co --exclude-standard | grep -vE '\.(md|json|html|ya?ml|toml|txt|go|ts|tsx|mod|work|baseline)$|^stacks/|^template/' | while read -r f; do [[ -f "$f" && -x "$f" ]] && echo "$f"; done)
    for p in devkit packs/*/; do [[ -f "$p/.claude-plugin/plugin.json" ]] && { claude plugin validate "$p" >/dev/null || { echo "plugin invalid: $p"; fail=1; }; }; done
    [[ ! -f .claude-plugin/marketplace.json ]] || claude plugin validate . >/dev/null || { echo "marketplace invalid"; fail=1; }
    exit $fail

# check + every tests/*.sh (each builds its own throwaway repos).
gate: check
    #!/usr/bin/env bash
    set -euo pipefail
    shopt -s nullglob
    for t in tests/*.sh; do echo "== $t"; bash "$t"; done
    echo "gate green"
