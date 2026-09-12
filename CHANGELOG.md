# Changelog

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
