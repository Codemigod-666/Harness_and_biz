#!/usr/bin/env bash
# new-project.sh writes .devkit/config.env mapping the starter's just recipes; devkit doctor accepts it.
set -euo pipefail
source "$(dirname "$0")/lib/common.sh"
TMP="$(mktemp -d)"
export HOME="$TMP/home"; mkdir -p "$HOME"
git config --global user.email t@example.invalid; git config --global user.name t

cfg() { grep "^$1=" "$2/.devkit/config.env" | head -1 | cut -d'"' -f2; }

check_project() { # <dir> <label>
    local d="$1" l="$2"
    assert_eq "$([[ -f $d/.devkit/config.env ]] && echo y)" y "$l: config.env exists"
    assert_eq "$(cfg DEVKIT_CHECK "$d")" "just check" "$l: DEVKIT_CHECK"
    assert_eq "$(cfg DEVKIT_TEST "$d")" "just test" "$l: DEVKIT_TEST"
    assert_eq "$(cfg DEVKIT_GATE "$d")" "just gate" "$l: DEVKIT_GATE"
    assert_eq "$(cfg DEVKIT_E2E "$d")" "just e2e" "$l: DEVKIT_E2E"
    assert_eq "$(cfg DEVKIT_PORT_BASE "$d")" "5390" "$l: DEVKIT_PORT_BASE from --ports"
    local out; out="$(cd "$d" && devkit doctor 2>&1 || true)"
    assert_has "$out" "ok      .devkit/config.env" "$l: doctor sees config"
    assert_has "$out" "ok      DEVKIT_GATE (just gate)" "$l: doctor sees the gate"
}

echo "== stacks go,ts,api"
bash "$ROOT/new-project.sh" "$TMP/full" --ports 53 --stack go,ts,api >/dev/null 2>&1
check_project "$TMP/full" "go,ts,api"

echo "== no stack"
bash "$ROOT/new-project.sh" "$TMP/bare" --ports 53 >/dev/null 2>&1
check_project "$TMP/bare" "no stack"

echo "== --force keeps an existing config"
mkdir -p "$TMP/keep/.devkit"; echo 'DEVKIT_GATE="make"' >"$TMP/keep/.devkit/config.env"
bash "$ROOT/new-project.sh" "$TMP/keep" --force >/dev/null 2>&1
assert_eq "$(cat "$TMP/keep/.devkit/config.env")" 'DEVKIT_GATE="make"' "existing config.env untouched"

finish
