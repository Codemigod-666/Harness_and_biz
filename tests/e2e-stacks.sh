#!/usr/bin/env bash
# End to end on three throwaway stacks (node, python, bare shell): devkit init --yes, doctor, backlog new,
# gate; then the plugins and the marketplace validate. Uses devkit/bin from this checkout (the real templates).
set -euo pipefail
source "$(dirname "$0")/lib/common.sh"
TMP="$(mktemp -d)"
export HOME="$TMP/home"; mkdir -p "$HOME"   # nothing here may touch the real ~/.claude or ~/.local

cfg() { grep "^$1=" .devkit/config.env | head -1 | cut -d'"' -f2; }
flow() { # <name> [gate]: init, doctor, backlog new, gate in the current repo; [gate] replaces the detected gate
    local out
    devkit init --yes >/dev/null && ok "$1: devkit init --yes" || bad "$1: init"
    [[ -z "${2:-}" ]] || { printf 'DEVKIT_GATE="%s"\n' "$2" >.devkit/config.env; }
    for f in AGENTS.md docs/fleet/WORKER.md docs/backlog/INDEX.md .devkit/config.env; do
        assert_eq "$([[ -f $f ]] && echo y)" y "$1: $f exists"
    done
    out="$(devkit doctor 2>&1)" && ok "$1: devkit doctor" || bad "$1: doctor ($out)"
    assert_has "$out" "DEVKIT_GATE" "$1: doctor reports the gate"
    out="$(backlog new task "e2e $1 task" 2>&1)" && ok "$1: backlog new task" || bad "$1: backlog new ($out)"
    assert_eq "$(ls docs/backlog/T-*.md 2>/dev/null | wc -l | tr -d ' ')" 1 "$1: one backlog item file"
    out="$(devkit gate 2>&1)" && ok "$1: devkit gate" || bad "$1: gate ($out)"
}

echo "== node (package.json + pnpm-lock)"
mkrepo "$TMP/node"; cd "$TMP/node"
cat >package.json <<'J'
{ "name": "n", "version": "0.0.0", "scripts": { "lint": "exit 0", "test": "exit 0" } }
J
: >pnpm-lock.yaml
git add -A; git commit -qm fixture
# the detected commands are `pnpm ...`; a stub keeps the test independent of pnpm being installed
mkdir -p "$TMP/fakebin"; printf '#!/usr/bin/env bash\nexit 0\n' >"$TMP/fakebin/pnpm"; chmod +x "$TMP/fakebin/pnpm"
PATH="$TMP/fakebin:$PATH" flow node
assert_has "$(cfg DEVKIT_GATE)" "pnpm" "node: gate uses pnpm (lockfile)"

echo "== python (pyproject)"
mkrepo "$TMP/py"; cd "$TMP/py"
printf '[project]\nname = "p"\nversion = "0"\n' >pyproject.toml
mkdir tests; printf 'def test_ok():\n    assert True\n' >tests/test_ok.py
git add -A; git commit -qm fixture
if python3 -c 'import pytest' 2>/dev/null; then
    flow python
    assert_has "$(cfg DEVKIT_GATE)" "pytest" "python: gate uses pytest"
else   # no pytest here: a gate that can pass stands in for the detected one
    flow python "python3 -c 'print(1)'"
fi

echo "== shell (no recognised stack)"
mkrepo "$TMP/sh"; cd "$TMP/sh"
printf '#!/usr/bin/env bash\necho hi\n' >run.sh
git add -A; git commit -qm fixture
flow shell "bash -n run.sh"

echo "== plugins and marketplace validate"
cd "$ROOT"
if command -v claude >/dev/null; then
    for p in devkit packs/frappe packs/local .; do
        claude plugin validate "$p" >/dev/null 2>&1 && ok "validate $p" || bad "validate $p"
    done
    assert_eq "$(python3 -c 'import json;print(",".join(p["name"] for p in json.load(open(".claude-plugin/marketplace.json"))["plugins"]))')" "devkit,devkit-frappe" "marketplace lists devkit and devkit-frappe only"
else
    ok "claude not installed: validation skipped"
fi
finish
