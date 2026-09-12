# Security Policy — BookOmarchy

BookOmarchy runs as an Omarchy shell plugin: **unsandboxed QML/JS with user
permissions**. This policy is load-bearing, not decorative.

## Allowed without confirmation

- `url` → `xdg-open` via argv-vector (`Util.execArgv`), no shell interpolation
- `file` / `directory` → `xdg-open` with `~` expanded to `$HOME` in JS
- `application` → `shell.appLibrary.launch()` or argv-vector exec

## Requires explicit confirmation

- `command` → `ConfirmDialog` showing the exact target; honors `confirmCommand`
- `ssh` → always confirms; launches via `xdg-terminal-exec -- ssh <args>`
- `directory` + `Shift+Enter` → opens in terminal after the same path expansion

## Refused

The launcher refuses (no exec, status message only) targets matching:

`sudo …`, `rm -rf /`, `chmod 777`, `chown -R`, `curl … | sh`,
`wget … | sh`, `mkfs`, `dd of=`, fork-bombs.

See `Menu.qml → isDangerousCommand()`.

## Data rules

- Never store `password`, `token`, `private_key`, `secret` — `bin/bookomarchy-save`
  aborts the write if any of these keys appear.
- Bookmarks persist via stdin (`Process.stdinEnabled`), never via
  `bash -c` string interpolation of user data.
- No `eval`, no dynamic QML loading, no network fetch, no telemetry.

## Dependencies

- Runtime: `xdg-open`, `xdg-terminal-exec`, `python3`, `git` (optional, sync only)
- No npm/pip packages. Helpers are stdlib-only Python 3 + bash.

## Reporting

Open an issue in the plugin repo with steps to reproduce. Do not include
private bookmarks in reports.
