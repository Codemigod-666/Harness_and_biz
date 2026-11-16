#!/usr/bin/env python3
"""Context guard: measures this session's context from its transcript and enforces the seam limits.

Soft limit (FLEET_SOFT_TOKENS, default 200000): tells the agent once to finish the current step and write
its handover. Hard limit (FLEET_HARD_TOKENS, default 250000): blocks the agent from ending its turn until it
has written and committed the handover and replied `HANDOVER <sha>`. Every run also writes the measured
size to .claude/fleet/context/<agent>.json so `fleet status` can show it.

Shipped in the devkit plugin (hooks/hooks.json) on PostToolUse (soft nudge) and Stop (hard block). It acts only
in a repo that uses the playbook (has docs/fleet/) or in a fleet agent (FLEET_AGENT set), so other sessions are
left alone. Read-only apart from the
status file and a per-session marker; never fails the agent's tool call (exits 0 on any error).
"""
import json
import os
import pathlib
import sys
import time

SOFT = int(os.environ.get("FLEET_SOFT_TOKENS", "200000"))
HARD = int(os.environ.get("FLEET_HARD_TOKENS", "250000"))


def context_tokens(transcript: str) -> int:
    """Context of the last main-thread model call: uncached input + cache writes + cache reads."""
    last = 0
    with open(transcript, encoding="utf-8") as lines:
        for line in lines:
            if '"usage"' not in line:
                continue
            try:
                entry = json.loads(line)
            except json.JSONDecodeError:
                continue
            message = entry.get("message")
            if entry.get("type") != "assistant" or entry.get("isSidechain") or not isinstance(message, dict):
                continue
            usage = message.get("usage") or {}
            last = (usage.get("input_tokens", 0) + usage.get("cache_creation_input_tokens", 0)
                    + usage.get("cache_read_input_tokens", 0))
    return last


def agent_name() -> str:
    return os.environ.get("FLEET_AGENT") or os.environ.get("HERDR_PANE_ID", "solo").replace(":", "-")


def write_status(root: pathlib.Path, tokens: int) -> None:
    status_dir = root / ".claude" / "fleet" / "context"
    status_dir.mkdir(parents=True, exist_ok=True)
    status = {"agent": agent_name(), "tokens": tokens, "soft": SOFT, "hard": HARD, "at": int(time.time())}
    (status_dir / f"{agent_name()}.json").write_text(json.dumps(status) + "\n", encoding="utf-8")


def once(root: pathlib.Path, session: str, level: str) -> bool:
    """True the first time this session crosses this level; a marker file makes later calls False."""
    marker = root / ".claude" / "fleet" / "context" / f".{session}.{level}"
    if marker.exists():
        return False
    marker.touch()
    return True


def handover_path() -> str:
    return f"docs/handovers/{agent_name()}.md"


def soft_message(tokens: int) -> str:
    return (f"CONTEXT SOFT LIMIT: {tokens // 1000}k of {HARD // 1000}k. Finish the step you are on (leave nothing "
            f"half-edited), then write your handover to {handover_path()} from docs/fleet/templates/, commit it by "
            "pathspec, and end your turn with the line `HANDOVER <sha>`. Do not start new work before that.")


def hard_message(tokens: int) -> str:
    return (f"CONTEXT HARD LIMIT: {tokens // 1000}k >= {HARD // 1000}k. Stop feature work now. Write {handover_path()} "
            "(template docs/fleet/templates/), list anything half-edited under In progress, commit the handover by "
            "pathspec, then reply only `HANDOVER <sha>`. The supervisor (or `fleet reset`) clears and resumes you.")


def playbook_root(start: pathlib.Path) -> pathlib.Path | None:
    """The nearest ancestor that has docs/fleet/, i.e. a repo set up with the playbook."""
    for directory in (start, *start.parents):
        if (directory / "docs" / "fleet").is_dir():
            return directory
    return None


def main() -> None:
    event = json.load(sys.stdin)
    transcript = event.get("transcript_path")
    if not transcript or not os.path.exists(transcript):
        return
    cwd = pathlib.Path(event.get("cwd") or os.getcwd())
    root = playbook_root(cwd) or (cwd if os.environ.get("FLEET_AGENT") else None)
    if root is None:
        return
    tokens = context_tokens(transcript)
    write_status(root, tokens)
    session = event.get("session_id", "unknown")
    name = event.get("hook_event_name")
    if name == "Stop" and tokens >= HARD and not event.get("stop_hook_active") and once(root, session, "hard"):
        print(json.dumps({"decision": "block", "reason": hard_message(tokens)}))
    elif name == "PostToolUse" and tokens >= SOFT and once(root, session, "soft"):
        print(json.dumps({"hookSpecificOutput": {"hookEventName": "PostToolUse",
                                                 "additionalContext": soft_message(tokens)}}))


if __name__ == "__main__":
    try:
        main()
    except Exception:  # noqa: BLE001 - a guard must never break the agent's tool calls
        pass
    sys.exit(0)
