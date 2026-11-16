# shared helpers for tests/*.sh (sourced)
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export PATH="$ROOT/devkit/bin:$PATH"
FAILS=0
ok() { echo "  ok   $1"; }
bad() { echo "  FAIL $1"; FAILS=$((FAILS + 1)); }
assert_eq() { [[ "$1" == "$2" ]] && ok "$3" || bad "$3 (got '$1', want '$2')"; }
assert_has() { grep -qF -- "$2" <<<"$1" && ok "$3" || bad "$3 (missing '$2' in: $1)"; }
mkrepo() { # <dir>: throwaway git repo with one commit
    mkdir -p "$1" && git -C "$1" init -q -b main
    git -C "$1" config user.email t@example.invalid && git -C "$1" config user.name t
    git -C "$1" commit -q --allow-empty -m init
}
finish() { rm -rf "$TMP"; [[ $FAILS -eq 0 ]] && echo "pass" || { echo "$FAILS failure(s)"; exit 1; }; }
