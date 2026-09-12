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

## Process hardening (marketplace security baseline)

Internal helpers (`bookomarchy-save`, `bookomarchy-maintenance`) are spawned
from QML with a fixed interpreter and a wiped environment — no `bash`
anywhere in the plugin's own execution path:

```
["/usr/bin/env", "-i", "PATH=/usr/bin:/bin", "/usr/bin/python3", <helper>, ...]
```

- `env -i` clears `BASH_ENV`, `PYTHONPATH`, `LD_PRELOAD`/`LD_LIBRARY_PATH`
  and friends; the helpers scrub them again at startup as defense in depth.
  (`command`/`ssh` bookmarks still open in the user's terminal via
  `xdg-terminal-exec`, but only after the explicit ConfirmDialog above.)
- Hard wall-clock timeout per action via `SIGALRM`
  (save 15s, maintenance 30s, `import` 60s, `zen-sync` 90s);
  `git` subprocess calls additionally carry a 30s timeout.
- Bounded I/O: stdin capped at 8 MiB, max 20000 bookmarks, per-field
  length limits, output capped at 8 MiB; Zen reads capped
  (jsonlz4 file 64 MiB / decompressed 256 MiB / sqlite copy 256 MiB /
  100k rows / 200k bookmark nodes); import files capped at 8 MiB.
- State dir (`~/.config/omarchy/bookomarchy/`) is verified on every run:
  each path component `lstat`-checked (symlinks refused), mode `0700`,
  owned by the current uid.
- Writes use unpredictable `O_EXCL` tmp files + `fsync` + atomic
  `os.replace` + directory `fsync`; backups use `O_EXCL|O_NOFOLLOW`.
- Zen profile selection is constrained inside `~/.config/zen`; the live
  `places.sqlite` is never opened — only a temp copy, read-only.

## Dependencies

- Runtime: `xdg-open`, `xdg-terminal-exec`, `/usr/bin/python3` (stdlib only),
  `git` (optional, sync only), `/usr/bin/env` (clean-env spawn)
- No npm/pip packages. Helpers are stdlib-only Python 3. No bash.

## Reporting

Open an issue in the plugin repo with steps to reproduce. Do not include
private bookmarks in reports.
