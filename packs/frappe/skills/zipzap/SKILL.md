---
name: zipzap
description: >-
  Zip and Zap the Frappe workspace (~/frappe). "Zip": write the handover, then commit, encrypt-backup, push and
  verify the workspace, and wipe ~/frappe. "Zap": clone it back, rebuild the bench at the locked versions,
  restore every site, prove the row counts match, and resume from the handover. Use when the user types
  "Zip" or "Zap" (any case), /zipzap, "zip the workspace", "zap it back", "restore the workspace".
argument-hint: "[zip | zap | status]"
allowed-tools: Bash(frappe-zip *), Bash(frappe-zap *)
---

# Zip / Zap

The workspace `~/frappe` is a git repo (remote in `~/.config/frappe-zip/config`). Git tracks custom apps,
docs and settings. `mybench/` is rebuilt. Sites travel as encrypted backups in `.zip/sites/`.

## "Zip"

1. Write `~/frappe/.zip/HANDOVER.md` from this session: where things stand, what's in progress, the next steps,
   decisions and open questions. Overwrite the old one, and leave out secrets. The script refuses a handover older
   than an hour.
2. Make sure the bench isn't running. If it is, ask the user to stop it.
3. Run `frappe-zip` and show its summary. The script stops, and deletes nothing, if any check fails: running
   bench, a file that would be lost, failed push, failed fresh-clone or decrypt check. Report the failure and the
   fix; never work around a check.
4. Afterwards `~/frappe` is empty and the site databases are dropped. Tell the user the tag and the time taken.

## "Zap"

1. Run `frappe-zap` (in the background: it takes about 10–20 minutes, most of it `bench init`). Wait for it to finish.
2. When it finishes, read `~/frappe/.zip/HANDOVER.md` and continue from "Next". Say in one line where you're
   resuming.
3. If it fails, show the failing step and its log tail. A failed Zap can be retried after emptying `~/frappe`. The
   snapshot is unaffected, and `~/.cache/frappe-zip-last/<tag>/` holds a local bundle and the backups for 7 days.

## Options

- `frappe-zip --no-wipe`: snapshot and push only. `--keep-db`: wipe the folder but keep the databases.
- `frappe-zap --ref zip-YYYYMMDD-HHMMSS`: restore an older snapshot.
- Rehearsal beside the live workspace: `frappe-zap --into <empty scratch dir> --rehearse` restores under
  `<db>_zr` names and skips memory and accounts. Drop the `_zr` databases afterwards.

## Never

- Don't run `frappe-zip` without a fresh handover, or edit the script to skip a check.
- Don't put secrets in git outside `.zip/sites/*.gpg`. The passphrase stays in `~/.config/frappe-zip/key`.
