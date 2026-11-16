#!/usr/bin/env bash
# backlog: new/set/ready/index/promote in a throwaway repo (no yq).
set -euo pipefail
source "$(dirname "$0")/lib/common.sh"
TMP="$(mktemp -d)"
mkrepo "$TMP/r"
cd "$TMP/r"

t1="$(backlog new task "First: a \"quoted\" title" -m v1)"
assert_eq "$(basename "$t1")" "T-001-first-a-quoted-title.md" "new task file name"
assert_eq "$(backlog list)" "T-001  task      todo      v1   First: a \"quoted\" title" "list shows quoted title"
backlog new task "Second" -d T-001 >/dev/null
assert_eq "$(backlog ready)" "T-001  First: a \"quoted\" title" "ready: only the task without open deps"
backlog set T-001 status done
assert_eq "$(backlog ready)" "T-002  Second" "ready after dep done"
backlog set T-002 deps "T-001,T-009"
assert_eq "$(backlog ready)" "" "ready blocked by missing dep"
backlog set T-002 owner worker-1
assert_has "$(backlog show T-002)" "owner: worker-1" "set adds a new field"
assert_has "$(backlog show T-002)" "deps: [T-001, T-009]" "deps written as a list"
backlog new idea "An idea" >/dev/null
promoted="$(backlog promote I-001)"
assert_has "$(backlog show T-003)" "from: I-001" "promote links the idea"
assert_eq "$(backlog list -t idea)" "I-001  idea      promoted       An idea" "idea marked promoted"
assert_eq "$([[ -f $promoted ]] && echo y)" y "promote prints the new task path"
idx="$(cat docs/backlog/INDEX.md)"
assert_has "$idx" "## tasks" "INDEX has a tasks section"
assert_has "$idx" "| [T-001](T-001-first-a-quoted-title.md) | done | v1 |  | First: a \"quoted\" title |" "INDEX row"
before="$idx"; backlog index >/dev/null
assert_eq "$(cat docs/backlog/INDEX.md)" "$before" "index is stable"
finish
