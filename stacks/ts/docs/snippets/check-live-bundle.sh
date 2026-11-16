#!/usr/bin/env bash
# Fails when the live build pulls in demo-only code (fakes, fixtures, sims, main-demo) (REACT-22).
set -euo pipefail
out="$(mktemp -d)"
trap 'rm -rf "$out"' EXIT
pnpm exec vite build --outDir "$out" --sourcemap --logLevel error
leaks="$(python3 - "$out"/assets/*.map <<'PY'
import json, re, sys
demo = re.compile(r"/(sim|fixture|fake)/|main-demo")
for path in sys.argv[1:]:
    for source in json.load(open(path)).get("sources", []):
        if "node_modules" not in source and demo.search(source):
            print(source)
PY
)"
if [[ -n "$leaks" ]]; then echo "live bundle contains demo-only modules:" >&2; echo "$leaks" >&2; exit 1; fi
echo "live bundle: no fake, fixture or sim modules"
