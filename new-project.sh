#!/usr/bin/env bash
# new-project.sh: create a repo from the playbook template, ready for Claude Code + herdr fleets.
# Usage: new-project.sh <dir> [--name <name>] [--ports <2-digit prefix, e.g. 47>] [--stack go,ts,api]
#                              [--module <go module prefix>] [--force]
set -euo pipefail

readonly PLAYBOOK="$(cd "$(dirname "$0")" && pwd)"

die() { echo "new-project: $*" >&2; exit 1; }

usage() {
    sed -n '2,4p' "$0" | sed 's/^# \{0,1\}//'
    exit 1
}

dir="" name="" ports="47" stack="" module="" force=0
while [[ $# -gt 0 ]]; do
    case "$1" in
    --name) name="$2"; shift 2 ;;
    --ports) ports="$2"; shift 2 ;;
    --stack) stack="$2"; shift 2 ;;
    --module) module="$2"; shift 2 ;;
    --force) force=1; shift ;;
    -h | --help) usage ;;
    -*) die "unknown option $1" ;;
    *) dir="$1"; shift ;;
    esac
done
[[ -n "$dir" ]] || usage
[[ "$ports" =~ ^[1-6][0-9]$ ]] || die "--ports is a two-digit prefix 10–65 (47 → 4700–4799)"
dir="$(realpath -m "$dir")"
name="${name:-$(basename "$dir")}"
name="$(echo "$name" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g')"
prefix="$(echo "$name" | tr '[:lower:]-' '[:upper:]_')"
module="${module:-example.com/$name}"

if [[ -e "$dir" && -n "$(ls -A "$dir" 2>/dev/null)" && $force == 0 ]]; then
    die "$dir is not empty (use --force to add the template into an existing repo; existing files are kept)"
fi
mkdir -p "$dir"

copy() { # <src dir>: copy without overwriting existing files
    (cd "$1" && find . -type f -print0) | while IFS= read -r -d '' file; do
        if [[ -e "$dir/$file" ]]; then
            echo "  kept     ${file#./}"
        else
            mkdir -p "$dir/$(dirname "$file")"
            cp -p "$1/$file" "$dir/$file"
        fi
    done
}

echo "template → $dir"
copy "$PLAYBOOK/template"
IFS=',' read -r -a stacks <<<"$stack"
for one in "${stacks[@]}"; do
    [[ -z "$one" ]] && continue
    [[ -d "$PLAYBOOK/stacks/$one" ]] || die "unknown stack '$one' (have: $(ls "$PLAYBOOK/stacks" | tr '\n' ' '))"
    echo "stack $one → $dir"
    copy "$PLAYBOOK/stacks/$one"
done

# Fill placeholders in every text file we may have copied.
grep -rlZ --exclude-dir=.git -e '__PROJECT__' -e '__P__' -e '__PREFIX__' -e '__MODULE__' -e '__DATE__' "$dir" 2>/dev/null |
    xargs -0 -r sed -i \
        -e "s|__PROJECT__|$name|g" -e "s|__PREFIX__|$prefix|g" -e "s|__MODULE__|$module|g" \
        -e "s|__P__|$ports|g" -e "s|__DATE__|$(date +%F)|g"
# Placeholder in file names (api spec).
find "$dir" -depth -name '*__PROJECT__*' -not -path '*/.git/*' | while read -r path; do
    mv "$path" "${path//__PROJECT__/$name}"
done

# devkit config: the starter keeps its justfile; `devkit check|gate|e2e` run the same recipes.
if [[ -e "$dir/.devkit/config.env" ]]; then
    echo "  kept     .devkit/config.env"
else
    mkdir -p "$dir/.devkit"
    cat >"$dir/.devkit/config.env" <<EOF
# devkit project config: shell-sourced KEY="value" lines (see devkit/templates/core/.devkit/config.env.example).
DEVKIT_CHECK="just check"
DEVKIT_TEST="just test"
DEVKIT_GATE="just gate"
DEVKIT_E2E="just e2e"
DEVKIT_PORT_BASE="${ports}90"
DEVKIT_MAIN="main"
EOF
fi

find "$dir/tools" -name '*.sh' -exec chmod +x {} + 2>/dev/null || true
# Skills and hooks are not copied: they come from the global devkit plugin (~/dev-playbook/install.sh).
[[ -L "$HOME/.claude/skills/devkit" ]] || echo "note: devkit plugin not installed; run ~/dev-playbook/install.sh"

cd "$dir"
if [[ ! -d .git ]]; then
    git init -q -b main
fi
git config core.autocrlf input
mkdir -p .claude/fleet .run data/source

if command -v yq > /dev/null; then
    command -v backlog > /dev/null && backlog index > /dev/null
else
    : # INDEX.md ships with the template; yq regenerates it on the first backlog change
fi

echo
echo "created $name in $dir  (ports ${ports}00–${ports}99, stacks: ${stack:-none})"
echo
tools/check-tools.sh || echo "→ install what is MISSING above, then rerun tools/check-tools.sh"
cat <<EOF

next:
  cd $dir
  herdr                      # open herdr, then in its pane:
  just supervisor            # supervisor agent (Opus, auto mode); it interviews you for README/PRODUCT,
                             # records decisions and plans the backlog; workers come later via fleet spawn
  git add -A && git commit -m "scaffold: playbook template"   # first commit, when you're happy
EOF
