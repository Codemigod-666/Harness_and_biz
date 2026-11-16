#!/usr/bin/env bash
# devkit init/gates/doctor in throwaway repos: justfile, package.json+pnpm-lock, pyproject, bare.
set -euo pipefail
source "$(dirname "$0")/lib/common.sh"
TMP="$(mktemp -d)"

# fixture core tree (the real one is core's; this keeps the test independent of it)
CORE="$TMP/core"; mkdir -p "$CORE/docs/fleet" "$CORE/docs/backlog"
echo "worker" >"$CORE/docs/fleet/WORKER.md"; : >"$CORE/docs/backlog/INDEX.md"
CARDS="$TMP/cards"; mkdir -p "$CARDS"; echo go >"$CARDS/go.md"; echo ts >"$CARDS/typescript.md"
export DEVKIT_CORE_DIR="$CORE" DEVKIT_CARDS_DIR="$CARDS"

cfg() { grep "^$1=" .devkit/config.env | head -1 | cut -d'"' -f2; }

echo "== justfile"
mkrepo "$TMP/just"; cd "$TMP/just"
printf 'check:\n    echo c\ngate: check\n    exit 7\n' >justfile
devkit init --yes >/dev/null
assert_eq "$(cfg DEVKIT_GATE)" "just gate" "just gate detected"
assert_eq "$(cfg DEVKIT_CHECK)" "just check" "just check detected"
assert_eq "$([[ -f docs/fleet/WORKER.md ]] && echo y)" y "core tree copied"
assert_eq "$(cat .gitignore)" ".claude/fleet/" "gitignore line"
assert_has "$(cat AGENTS.md)" "## devkit" "AGENTS.md created with section"
assert_eq "$(cat CLAUDE.md)" "@AGENTS.md" "CLAUDE.md points at AGENTS.md"
snap="$(find . -path ./.git -prune -o -type f -print | sort | xargs cat | sha1sum)"
out="$(devkit init --yes)"
assert_eq "$(find . -path ./.git -prune -o -type f -print | sort | xargs cat | sha1sum)" "$snap" "second init changes nothing"
assert_eq "$(grep -c '^added' <<<"$out" || true)" "0" "second init adds nothing"
set +e; devkit gate >/dev/null 2>&1; rc=$?; set -e
assert_eq "$rc" "7" "gate passes the failing exit code through"
cat >.devkit/config.env <<'E'
DEVKIT_GATE="exit 0"
E
devkit gate && ok "gate passes with exit 0" || bad "gate exit 0"
mkdir sub; (cd sub && devkit gate) && ok "gate runs from a subdirectory" || bad "gate from subdir"
assert_has "$(devkit test)" "not configured" "test unconfigured is a no-op"
assert_has "$(devkit doctor)" "ok      DEVKIT_GATE" "doctor sees the gate"

echo "== package.json + pnpm-lock"
mkrepo "$TMP/pnpm"; cd "$TMP/pnpm"
echo '{"scripts":{"lint":"x","test":"y"},"dependencies":{"react":"1"}}' >package.json; : >pnpm-lock.yaml
devkit init --yes --cards go >/dev/null
assert_eq "$(cfg DEVKIT_CHECK)" "pnpm run lint" "pnpm lint"
assert_eq "$(cfg DEVKIT_TEST)" "pnpm test" "pnpm test"
assert_eq "$(cfg DEVKIT_GATE)" "pnpm run lint && pnpm test" "pnpm gate"
assert_eq "$([[ -f docs/conventions/go.md && -f docs/conventions/typescript.md ]] && echo y)" y "cards: --cards plus detected"

echo "== pyproject"
mkrepo "$TMP/py"; cd "$TMP/py"
printf '[tool.ruff]\nline-length=100\n' >pyproject.toml
devkit init --yes >/dev/null
assert_eq "$(cfg DEVKIT_GATE)" "ruff check . && pytest" "python gate"

echo "== frappe app (also has pyproject.toml)"
mkrepo "$TMP/fr"; cd "$TMP/fr"
printf '[project]\nname="myapp"\n' >pyproject.toml; mkdir myapp; : >myapp/hooks.py; echo "My App" >myapp/modules.txt
devkit init --yes >/dev/null
assert_has "$(cfg DEVKIT_GATE)" "run-tests --app myapp" "frappe wins over python"

echo "== bare repo"
mkrepo "$TMP/bare"; cd "$TMP/bare"
printf '# Mine\n' >AGENTS.md; printf 'x\n' >.gitignore
devkit init --yes >/dev/null
assert_has "$(cat .devkit/config.env)" "# TODO: DEVKIT_GATE" "gate left as TODO"
assert_has "$(cat AGENTS.md)" "# Mine" "existing AGENTS.md kept"
assert_has "$(cat AGENTS.md)" "## devkit" "section appended"
devkit init --yes >/dev/null
assert_eq "$(grep -c '^## devkit' AGENTS.md)" "1" "section appended once"
set +e; out="$(devkit gate 2>&1)"; rc=$?; set -e
assert_eq "$rc" "2" "gate without DEVKIT_GATE exits 2"
assert_has "$out" "DEVKIT_GATE is not set" "one-line fix"
set +e; devkit doctor >/dev/null; rc=$?; set -e
assert_eq "$rc" "1" "doctor fails when the gate is missing"

echo "== fleet init"
mkrepo "$TMP/fl"; cd "$TMP/fl"
fleet init >/dev/null
assert_eq "$([[ -d .claude/fleet/briefs && -f .claude/fleet/board.md ]] && echo y)" y "fleet init works without docs/fleet/templates"
echo "== real templates/core (no fixture)"
{
    unset DEVKIT_CORE_DIR DEVKIT_CARDS_DIR
    REAL="$ROOT/devkit/templates/core"
    mkrepo "$TMP/real"; cd "$TMP/real"
    printf '# Mine\n' >AGENTS.md
    devkit init --yes >/dev/null
    assert_eq "$(tail -n "$(wc -l <"$REAL/AGENTS.md")" AGENTS.md)" "$(cat "$REAL/AGENTS.md")" "appended section equals the template"
    assert_eq "$(head -1 "$REAL/AGENTS.md")" "<!-- devkit -->" "template starts with the marker"
    snap="$(find . -path ./.git -prune -o -type f -print | sort | xargs cat | sha1sum)"
    out="$(devkit init --yes)"
    assert_eq "$(find . -path ./.git -prune -o -type f -print | sort | xargs cat | sha1sum)" "$snap" "second init is a no-op"
    assert_eq "$(grep -c '^added' <<<"$out" || true)" "0" "second init adds nothing"
    missing="$(cd "$REAL" && find . -type f ! -name AGENTS.md | sed 's|^\./||' | while read -r f; do [[ -f "$f" ]] || echo "$f"; done)"
    assert_eq "$missing" "" "every core file landed in the repo"
    export DEVKIT_CORE_DIR="$CORE" DEVKIT_CARDS_DIR="$CARDS"
}

echo "== config is data, not code"
cd "$TMP/fl"; mkdir -p .devkit
printf 'touch %s/pwned\nDEVKIT_PORT_BASE="5000"\nDEVKIT_GATE="exit 0"\n' "$TMP" >.devkit/config.env
fleet init >/dev/null; devkit doctor >/dev/null || true
assert_eq "$([[ -e $TMP/pwned ]] && echo y || echo n)" n "fleet/doctor never execute config lines"
devkit gate && ok "gate still runs its command" || bad "gate after parse"
finish
