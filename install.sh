#!/usr/bin/env bash
# install.sh: install the devkit plugin for every Claude Code session (a symlink in ~/.claude/skills, so edits in
# ~/dev-playbook apply at once) and put `devkit`, `fleet`, `backlog` and `claude-acct` (devkit/bin) on PATH (~/.local/bin).
# The packs (packs/frappe, packs/local) are linked as devkit-frappe and devkit-local; their bin/ commands go on PATH too.
# Undo: rm ~/.claude/skills/{devkit,devkit-frappe,devkit-local} ~/.local/bin/{devkit,fleet,backlog,claude-acct,harness-docs,frappe-zip,frappe-zap}
set -euo pipefail

readonly PLAYBOOK="$(cd "$(dirname "$0")" && pwd)"
readonly DEVKIT="$PLAYBOOK/devkit"

link() { # <target> <link>: create or refresh a symlink; refuse to replace a real file
    if [[ -e "$2" && ! -L "$2" ]]; then
        echo "install: $2 exists and is not a symlink; leaving it alone" >&2
        return 1
    fi
    ln -sfn "$1" "$2"
    echo "  $2 → $1"
}

chmod +x "$PLAYBOOK"/*.sh "$DEVKIT"/bin/* "$DEVKIT"/skills/*/scripts/* "$DEVKIT"/hooks/*.py "$PLAYBOOK"/packs/*/bin/*
mkdir -p "$HOME/.claude/skills" "$HOME/.local/bin"
# the earlier single-skill install is replaced by the plugin
[[ -L "$HOME/.claude/skills/playbook" ]] && rm "$HOME/.claude/skills/playbook" && echo "  removed old playbook skill link"
link "$DEVKIT" "$HOME/.claude/skills/devkit"
for b in "$DEVKIT"/bin/*; do link "$b" "$HOME/.local/bin/$(basename "$b")"; done
link "$PLAYBOOK/packs/frappe" "$HOME/.claude/skills/devkit-frappe"
link "$PLAYBOOK/packs/local" "$HOME/.claude/skills/devkit-local"
for b in "$PLAYBOOK"/packs/*/bin/*; do link "$b" "$HOME/.local/bin/$(basename "$b")"; done
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) echo "add ~/.local/bin to PATH" >&2 ;; esac
if command -v claude > /dev/null; then
    for p in "$DEVKIT" "$PLAYBOOK"/packs/*; do claude plugin validate "$p"; done
fi
echo "devkit installed: it loads in new sessions as devkit@skills-dir, devkit-frappe and devkit-local likewise (/reload-plugins in a running one)"
