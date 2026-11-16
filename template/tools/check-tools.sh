#!/usr/bin/env bash
# Checks the toolchain this repo's recipes and agents need; prints what is missing and how to get it.
set -uo pipefail

missing=0
need() { # <command> <why> <install hint>
    if command -v "$1" > /dev/null 2>&1; then
        printf '  ok       %-14s %s\n' "$1" "$("$1" --version 2>/dev/null | head -1)"
    else
        printf '  MISSING  %-14s %s — %s\n' "$1" "$2" "$3"
        missing=1
    fi
}

echo "core"
need git "everything" "apt install git"
need just "task runner" "https://just.systems (cargo install just / apt install just)"
need yq "backlog helper (mikefarah yq v4)" "https://github.com/mikefarah/yq/releases"
need python3 "context guard hook, fleet helper" "apt install python3"
need lsof "recipes: port checks" "apt install lsof"
need curl "recipes: health waits" "apt install curl"
echo "agents"
need claude "Claude Code" "https://claude.com/claude-code"
need herdr "fleet: agents in panes" "herdr update"
[ -f go.work ] || [ -f go.mod ] && {
    echo "go"
    need go "server" "https://go.dev/dl"
    need golangci-lint "just check (v2, built with the same Go)" "go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@latest"
}
[ -f package.json ] && {
    echo "node"
    need node "web apps" "nvm install --lts"
    need pnpm "workspaces (version pinned in package.json)" "corepack enable"
    need ast-grep "jsx component length lint" "pnpm add -g @ast-grep/cli"
}

if [ -z "$(git config user.name)" ] || [ -z "$(git config user.email)" ]; then
    echo "  MISSING  git identity   workers' commits fail — git config --global user.name/user.email"
    missing=1
fi
[ -L "$HOME/.claude/skills/devkit" ] || { echo "  MISSING  devkit plugin  skills + context guard — ~/dev-playbook/install.sh"; missing=1; }
if [ "$(git config core.autocrlf)" = "true" ]; then
    echo "  WARN     core.autocrlf=true: set 'git config core.autocrlf input' (.gitattributes forces LF)"
fi
exit $missing
