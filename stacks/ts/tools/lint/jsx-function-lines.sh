#!/usr/bin/env bash
# GEN-2 for React components: Biome's line limit skips functions that return JSX, so ast-grep checks them.
# Known offenders sit in the baseline, which may only shrink: a new offender fails, and so does a fixed one
# still listed (remove its line). Rebuild the list with --update only when the user agrees.
set -euo pipefail

root=$(cd "$(dirname "$0")/../.." && pwd)
rules="$root/tools/lint/jsx-function-lines.yml"
baseline="$root/tools/lint/jsx-function-lines.baseline"

hits=$(cd "$root" && ast-grep scan -r "$rules" apps packages \
    --globs '!**/node_modules' --globs '!**/dist' --json=compact 2>/dev/null || [[ $? == 1 ]])
found=$(printf '%s' "$hits" | jq -r '.[] | "\(.file) \(.text | capture("^(?:export )?(?:function )?(?<name>[A-Za-z0-9_]+)").name)"' |
    sort -u)

if [[ ${1:-} == --update ]]; then
    printf '%s\n' "$found" > "$baseline"
    echo "jsx-function-lines: baseline rewritten ($(grep -c . "$baseline") entries)"
    exit 0
fi

new=$(comm -23 <(printf '%s\n' "$found" | grep .) <(grep . "$baseline" | sort -u) || true)
fixed=$(comm -13 <(printf '%s\n' "$found" | grep .) <(grep . "$baseline" | sort -u) || true)

status=0
if [[ -n $new ]]; then
    echo "jsx-function-lines: React components over 40 lines (GEN-2), split them:"
    printf '%s\n' "$new" | sed 's/^/  /'
    status=1
fi
if [[ -n $fixed ]]; then
    echo "jsx-function-lines: no longer over 40 lines, remove from $baseline:"
    printf '%s\n' "$fixed" | sed 's/^/  /'
    status=1
fi
[[ $status == 0 ]] && echo "jsx-function-lines: ok ($(grep -c . "$baseline") known offenders left)"
exit $status
