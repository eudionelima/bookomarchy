# Changelog

## 1.2.0 — 2026-09-12

- Zen Browser sync: new `zen-sync` in `bin/bookomarchy-maintenance`
  (stdlib only, pure-Python LZ4 decode). Reads `bookmarkbackups/*.jsonlz4`
  first (lock-free), falls back to a temp copy of `places.sqlite`
  (never touches the live DB). Merge by normalized URL — existing
  title/favorite/tags are never overwritten. Category rules
  (cyber domains → `Cybersecurity`), `recategorize` command,
  `zenSync.exclude` blocklist. Auto-sync on menu open (once per open),
  manual via `Sync Zen` button or `Ctrl+Y`.
- Top10 default view replaces `All`: 10 most opened (`opens` counter
  bumped on every launch, favorites as tiebreak). Typing a query searches everything.
- Keyboard: `←→` switch category in browse; manage mode fully keyboard
  operable (`↑↓←→` select, `Enter` run, `1-7` quick, `Tab` path field);
  `Ctrl+[`/`Ctrl+]` cycles type in add/edit forms.
- Docs: hero `screenshot.jpg` + 2x2 `screenshots/` table in README,
  OmaHack-style centered headings.

## 1.1.0 — 2026-09-12

- Bar icon: new `bar-widget` kind (`BarWidget.qml`, bookmark glyph).
  Left-click toggles the menu, right-click opens manage mode.
  Inherits bar foreground/font via `WidgetButton` — follows the theme like any native widget.
  Enable placement: `omarchy plugin enable eudionelima.bookomarchy --section right`
  (or any `left/center/right` entry in `shell.json`).

## 1.0.0 — 2026-09-12

F0–F5 complete:

- `menu` kind entry point with `open(payloadJson)/close()/ping()`
- Theme-reactive UI: 100% `Color.menu.*` + `Style.*` + `Border.surfaceSpec("menu",…)`, zero hardcoded hex
- Browse: fuzzy multi-term search, categories, favorites-first scoring, quick-keys `1-9`
- Types: `url`, `file`, `directory`, `application`, `command`, `ssh`
- CRUD: add / edit / delete with validation, slugified ids, atomic stdin save
- Power: `Ctrl+N/E/D/B/M`, `Del`, `[`/`]` categories, `Shift+Enter` open dir in terminal
- Trust: `ConfirmDialog` for `command/ssh`, dangerous-command refusal, `SECURITY.md`
- Import (`json/html/csv`), export (`json/html`), timestamped backup, local git sync
- Helpers: `bin/bookomarchy-save` + `bin/bookomarchy-maintenance` (stdlib Python only)
