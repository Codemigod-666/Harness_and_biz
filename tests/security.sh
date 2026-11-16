#!/usr/bin/env bash
# security: accounts.env read as data, fleet state files can't run code, workers can't drive the fleet, land runs
# main's gate and refuses gate changes. Throwaway HOME and repos; herdr is a stub that logs its calls.
set -euo pipefail
source "$(dirname "$0")/lib/common.sh"
TMP="$(mktemp -d)"
export HOME="$TMP/home"
mkdir -p "$HOME/.claude" "$TMP/bin"
: >"$HOME/.claude/.credentials.json" # account a counts as logged in
unset FLEET_AGENT FLEET_HOME FLEET_PORT FLEET_PORT_BASE FLEET_ACCOUNT_B_DIR FLEET_MODEL CLAUDE_CONFIG_DIR
export HERDR_ENV=1 HERDR_WORKSPACE_ID=w0 HERDR_TAB_ID=t0 HERDR_PANE_ID=p0 HERDR_LOG="$TMP/herdr.log"
: >"$HERDR_LOG"
cat >"$TMP/bin/herdr" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$HERDR_LOG"
case "$1 $2" in
"tab create") echo '{"result":{"tab":{"tab_id":"t1"},"root_pane":{"pane_id":"p1"}}}' ;;
"pane split") echo '{"result":{"pane":{"pane_id":"p2","tab_id":"t0"}}}' ;;
"agent list") echo '{"result":{"agents":[]}}' ;;
"agent get") echo '{"result":{"agent":{"agent_status":"idle"}}}' ;;
"agent read") echo "HANDOVER abcdef1" ;;
esac
EOF
chmod +x "$TMP/bin/herdr"
export PATH="$TMP/bin:$PATH"

run() { set +e; OUT="$("$@" 2>&1)"; RC=$?; set -e; }
refused() { # <what> <message part> <cmd…>: exits non-zero, says why, and nothing ran
    local what="$1" msg="$2"
    shift 2
    run "$@"
    [[ $RC -ne 0 ]] && ok "$what: refused" || bad "$what: not refused ($OUT)"
    assert_has "$OUT" "$msg" "$what: says why"
}
no_pwn() { [[ -z "$(find "$TMP" -name 'pwned*' -print -quit)" ]] && ok "$1: payload not executed" || bad "$1: payload ran"; }

R="$HOME/r" # the project lives under $HOME, like a real one
mkrepo "$R"
cd "$R"
printf '.claude/\n' >.gitignore
printf 'gate:\n\ttrue\n' >justfile
mkdir -p .devkit && printf 'DEVKIT_GATE="echo main >>$GATE_LOG"\nDEVKIT_GATE_FILES="scripts/gate.sh ci/"\n' >.devkit/config.env
git add .gitignore justfile .devkit/config.env && git commit -qm base
mkdir -p .claude
ACC=.claude/accounts.env

echo "== accounts.env is data"
fn() { sed -n '/^# ---- accounts.env/,/^}/p' "$ROOT/devkit/bin/$1"; }
assert_eq "$(fn fleet)" "$(fn claude-acct)" "fleet and claude-acct share one parser"
assert_eq "$(fn fleet | grep -c 'read_accounts_env()')" "1" "parser found in fleet"
for payload in \
    'ACCOUNT_B_DIR="$HOME/.claude-b$(touch pwned1)"' \
    'ACCOUNT_B_DIR="$HOME/.claude-b`touch pwned2`"' \
    'SHARED_ITEMS="skills `touch pwned3`"' \
    'SHARED_ITEMS="skills $(touch pwned4)"' \
    'ACCOUNT_B_DIR=$(touch pwned5)'; do
    printf '%s\n' "$payload" >"$ACC"
    refused "fleet: ${payload:0:40}" "accounts.env" fleet accounts
    refused "claude-acct: ${payload:0:40}" "accounts.env" claude-acct setup
done
printf 'touch pwned6\nX=$(touch pwned7)\nACCOUNT_B_DIR="$HOME/.claude-b"\n' >"$ACC"
run fleet accounts
assert_eq "$RC" "0" "lines that are not ACCOUNT_B_DIR/SHARED_ITEMS are ignored"
no_pwn "accounts.env payloads"

# the format claude-acct init writes and a live project uses must keep working unchanged
printf '%s\n' '# comment' 'ACCOUNT_B_DIR="$HOME/.claude-b"' \
    'SHARED_ITEMS="settings.json settings.local.json skills hooks plugins CLAUDE.md"' >"$ACC"
echo '{}' >"$HOME/.claude/settings.json"
mkdir -p "$HOME/.claude/skills"
assert_has "$(fleet accounts)" "$HOME/.claude-b" "fleet expands \$HOME in ACCOUNT_B_DIR"
run claude-acct setup
assert_has "$OUT" "linked skills" "claude-acct setup links shared items"
assert_eq "$(readlink "$HOME/.claude-b/settings.json")" "$HOME/.claude/settings.json" "settings.json linked to A"
printf 'ACCOUNT_B_DIR=~/b2  # tilde\n' >"$ACC"
assert_has "$(fleet accounts)" "$HOME/b2" "~ expanded"
printf "ACCOUNT_B_DIR='\${HOME}/b3'\n" >"$ACC"
assert_has "$(fleet accounts)" "$HOME/b3" "\${HOME} expanded, single quotes"
for bad_dir in /etc/claude-b '$HOME/../x' '$HOME' '~/.claude' "$R/.claude/b" relative/b; do
    printf 'ACCOUNT_B_DIR="%s"\n' "$bad_dir" >"$ACC"
    refused "ACCOUNT_B_DIR=$bad_dir (fleet)" "ACCOUNT_B_DIR" fleet accounts
    refused "ACCOUNT_B_DIR=$bad_dir (claude-acct)" "ACCOUNT_B_DIR" claude-acct setup
done
for bad_item in .. . ../../etc a/b '*'; do
    printf 'SHARED_ITEMS="skills %s"\n' "$bad_item" >"$ACC"
    refused "SHARED_ITEMS has '$bad_item'" "SHARED_ITEMS entry" claude-acct setup
done
[[ ! -e "$HOME/etc" && ! -L "$HOME/.claude-b/etc" ]] && ok "nothing linked for refused items" || bad "linked a refused item"
rm -f "$ACC"

echo "== state files can't run code"
lane='src/** $(touch pwned8) `touch pwned9` "q" '"'"'s'"'"' \x é→'
fleet spawn w1 -l "$lane" >/dev/null
SF="$R/.claude/fleet/agents/w1.env"
assert_eq "$(bash -c 'source "$1"; printf %s "$LANE"' _ "$SF")" "$lane" "lane stays literal when the file is sourced"
assert_eq "$(bash -c 'source "$1"; printf %s "$CWD|$BRANCH|$MODEL|$EFFORT|$ACCOUNT"' _ "$SF")" \
    "$HOME/r-w1|fleet/w1|sonnet||a" "other values round-trip"
assert_has "$(fleet status)" "$lane" "status shows the literal lane"
assert_has "$(cat "$HERDR_LOG")" "--model sonnet" "spawn starts the default model"
LC_ALL=C fleet status >/dev/null && ok "status loads under a C locale" || bad "status in C locale"
no_pwn "lane payload"
before="$(wc -l <"$HERDR_LOG")"
refused "spawn -m 'opus;…'" "model must be" fleet spawn w2 -m 'opus; touch pwned10'
refused "spawn -m gpt-4" "model must be" fleet spawn w2 -m gpt-4
refused "spawn -e huge" "effort must be" fleet spawn w2 -e huge
refused "spawn -a c" "account must be" fleet spawn w2 -a c
refused "spawn lane with a newline" "lane must be" fleet spawn w2 -l $'a\nMODEL=x'
refused "spawn ../x" "name must" fleet spawn ../x
assert_eq "$(wc -l <"$HERDR_LOG")" "$before" "refused spawns never reach herdr"
assert_eq "$([[ -e "$R/.claude/fleet/agents/w2.env" ]] && echo y || echo n)" n "no state file for refused spawns"
fleet spawn w3 -m claude-opus-5-5 -e max -a a >/dev/null && ok "spawn accepts claude-<id>, max, a" || bad "spawn w3"
fleet close w3 >/dev/null
refused "adopt with FLEET_MODEL payload" "model must be" env 'FLEET_MODEL=opus$(touch pwned11)' fleet adopt
fleet adopt >/dev/null
assert_has "$(fleet status)" "supervisor: backlog, docs/decisions.md, board" "adopt writes a loadable state file"

# respawn: validated, rewrites the whole file (no sed), keeps the lane literal
git -C "$HOME/r-w1" config user.email t@example.invalid && git -C "$HOME/r-w1" config user.name t
mkdir -p "$HOME/r-w1/docs/handovers" && echo h >"$HOME/r-w1/docs/handovers/w1.md"
git -C "$HOME/r-w1" add docs/handovers/w1.md && git -C "$HOME/r-w1" commit -qm handover
refused "respawn -m payload" "model must be" fleet respawn w1 -m 'opus/$(touch pwned12)'
refused "respawn -e payload" "effort must be" fleet respawn w1 -e 'high&touch pwned13'
refused "respawn -a payload" "account must be" fleet respawn w1 -a 'b;touch pwned14'
fleet respawn w1 -m opus -e high >/dev/null
assert_eq "$(bash -c 'source "$1"; printf %s "$MODEL|$EFFORT|$LANE"' _ "$SF")" "opus|high|$lane" "respawn rewrites the state"

# a state file from an older fleet still loads; a hostile one (e.g. committed in a cloned repo) runs nothing
cat >"$R/.claude/fleet/agents/old.env" <<EOF
NAME=old
ID=r-old
TAB=t9
PANE=p9
CWD=$(printf %q "$R")
BRANCH=
PORT=4799
MODEL=opus
EFFORT=
LANE="supervisor: backlog, docs/decisions.md, board"
EOF
assert_has "$(fleet status | grep '^old ')" "opus    a    4799   supervisor: backlog" "old-format state file loads"
cat >"$R/.claude/fleet/agents/evil.env" <<'EOF'
NAME=evil$(touch pwned15)
$(touch pwned16)
CWD=`touch pwned17`
LANE=$(touch pwned18)
EOF
fleet status >/dev/null
no_pwn "hostile state file"
rm -f "$R/.claude/fleet/agents/"{old,evil}.env

echo "== workers can't drive the fleet"
before="$(wc -l <"$HERDR_LOG")"
for c in "spawn w9" "adopt" "brief w1 $R/justfile" "say w1 hi" "reset w1" "respawn w1" "land w1" "close w1"; do
    # shellcheck disable=SC2086 # split the subcommand and its args on purpose
    refused "FLEET_AGENT=w1 fleet $c" "is for the supervisor" env FLEET_AGENT=w1 fleet $c
done
assert_eq "$(wc -l <"$HERDR_LOG")" "$before" "refused worker calls never reach herdr"
run env FLEET_AGENT=w1 fleet status
assert_eq "$RC" "0" "a worker may run fleet status"
run env FLEET_AGENT=w1 fleet read w1 5
assert_has "$OUT" "HANDOVER" "a worker may run fleet read"
env FLEET_AGENT=supervisor fleet say w1 hello && ok "FLEET_AGENT=supervisor may say" || bad "supervisor say"
fleet say w1 hi && ok "unset FLEET_AGENT may say" || bad "unset say"
assert_has "$(tail -2 "$HERDR_LOG")" "agent prompt" "say reached herdr"
fleet close w1 >/dev/null 2>&1 # keeps the worktree: the handover commit is unmerged

echo "== land runs main's gate and refuses gate changes"
export GATE_LOG="$TMP/gate.log"
: >"$GATE_LOG"
fleet spawn lw >/dev/null
W="$HOME/r-lw"
git -C "$W" config user.email t@example.invalid && git -C "$W" config user.name t
on_branch() { # <msg> <cmd…>: reset lw's branch to main, run the change in the worktree, commit it
    local msg="$1"
    shift
    git -C "$W" reset -q --hard refs/heads/main
    (cd "$W" && "$@")
    git -C "$W" add -A . && git -C "$W" commit -qm "$msg"
}
main_at() { git -C "$R" rev-parse refs/heads/main; }
start="$(main_at)"
on_branch gate-config sh -c 'echo "DEVKIT_GATE=\"true\"" >.devkit/config.env'
refused "branch changes .devkit/config.env" "changes what the gate runs: .devkit/config.env" fleet land lw
on_branch justfile sh -c 'printf "gate:\n\techo weak\n" >justfile'
refused "branch changes justfile" "justfile" fleet land lw
on_branch rename-justfile git mv justfile notes.txt
refused "branch renames justfile away" "justfile" fleet land lw
on_branch makefile sh -c 'echo "gate:" >Makefile'
refused "branch adds a Makefile" "Makefile" fleet land lw
on_branch gate-file sh -c 'mkdir -p scripts && echo true >scripts/gate.sh'
refused "branch changes a DEVKIT_GATE_FILES path" "scripts/gate.sh" fleet land lw
on_branch gate-dir sh -c 'mkdir -p ci/x && echo y >ci/x/a.yml'
refused "branch changes under a DEVKIT_GATE_FILES dir" "ci/x/a.yml" fleet land lw
refused "--allow-gate-change without a terminal" "interactive terminal" fleet land lw --allow-gate-change </dev/null
refused "--no-gate without a terminal" "interactive terminal" fleet land lw --no-gate </dev/null
refused "unknown land option" "unknown option" fleet land lw --force
assert_eq "$(main_at)" "$start" "main unchanged after refusals"
assert_eq "$(cat "$GATE_LOG")" "" "no gate ran for refused lands"

on_branch feature sh -c 'echo a >a.txt'
printf 'DEVKIT_GATE="echo worktree >>$GATE_LOG"\n' >"$R/.devkit/config.env" # uncommitted on main: ignored
fleet land lw >/dev/null && ok "clean branch lands" || bad "clean branch did not land"
git -C "$R" checkout -q -- .devkit/config.env
assert_eq "$(cat "$GATE_LOG")" "main" "gate is main's committed DEVKIT_GATE"
assert_eq "$(main_at)" "$(git -C "$W" rev-parse HEAD)" "main fast-forwarded to the branch"

printf 'DEVKIT_GATE="exit 3"\n' >"$R/.devkit/config.env"
git -C "$R" commit -qam "failing gate"
start="$(main_at)"
on_branch feature2 sh -c 'echo b >b.txt'
refused "failing gate from main" "gate failed" fleet land lw
assert_eq "$(main_at)" "$start" "main unchanged when the gate fails"
git -C "$R" rm -q .devkit/config.env && git -C "$R" commit -qm "no config"
on_branch feature3 sh -c 'echo c >c.txt'
refused "main without a committed gate" "no DEVKIT_GATE" fleet land lw
mkdir -p "$R/.devkit" && printf 'DEVKIT_GATE="echo main >>$GATE_LOG"\n' >"$R/.devkit/config.env"
git -C "$R" add .devkit/config.env && git -C "$R" commit -qm "gate back"
git -C "$R" tag fleet/lw "$start" # a tag named like the branch must not stand in for it
on_branch feature4 sh -c 'echo d >d.txt'
: >"$GATE_LOG"
fleet land lw >/dev/null && ok "lands the branch, not a same-named tag" || bad "land with tag"
assert_eq "$(main_at)" "$(git -C "$W" rev-parse HEAD)" "main is the branch tip"

if script -qec true /dev/null >/dev/null 2>&1; then # a person at a terminal (util-linux script gives a tty)
    on_branch justfile2 sh -c 'printf "gate:\n\techo new\n" >justfile'
    run script -qec "fleet land lw --allow-gate-change" /dev/null <<<"nope"
    assert_has "$OUT" "not confirmed" "wrong confirmation refused"
    start="$(main_at)"
    : >"$GATE_LOG"
    run script -qec "fleet land lw --allow-gate-change" /dev/null <<<"lw"
    assert_eq "$(main_at)" "$(git -C "$W" rev-parse HEAD)" "a person can land a gate change"
    assert_eq "$(cat "$GATE_LOG")" "main" "the gate still ran (main's command)"
else
    echo "  skip interactive confirmation (no util-linux script)"
fi
fleet close lw >/dev/null
no_pwn "whole run"
finish
