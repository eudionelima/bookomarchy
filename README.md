# BookOmarchy

Fast keyboard-first bookmarks and shortcuts for Omarchy.

ID: `eudionelima.bookomarchy` · kinds `menu` + `bar-widget` · `SUPER+B`

## Features

- Search across title, URL/target, category, aliases, tags (`gh` → GitHub, `arch` → ArchWiki)
- Quick-keys `1-9`: type `3` + `Enter` opens the 3rd visible row
- Categories with `[` / `]` cycling + click filter
- Types: `url` (browser), `file`/`directory` (`xdg-open`), `application` (app library), `command`/`ssh` (confirmed)
- `Ctrl+N` new · `Ctrl+E` edit · `Del` delete · `Ctrl+D` favorite · `Ctrl+B` backup · `Ctrl+M` manage
- `Shift+Enter` on a directory opens it in the terminal
- Import Chrome/Firefox HTML, JSON, CSV · export JSON/HTML · timestamped backups · local git sync
- Adapts to `omarchy theme set` live: all colors from `Color.menu.*`, spacing/type from `Style.*`

## Install

```bash
# dev (local dir already in place)
omarchy plugin validate ~/.config/omarchy/plugins/eudionelima.bookomarchy
omarchy-shell shell rescanPlugins
omarchy plugin enable eudionelima.bookomarchy

# from git (marketplace layout: manifest.json at repo root)
omarchy plugin add https://github.com/<you>/bookomarchy --enable
```

## Use

```bash
omarchy-shell shell summon eudionelima.bookomarchy '{}'
omarchy-shell shell summon eudionelima.bookomarchy '{"filter":"gh"}'
omarchy-shell shell summon eudionelima.bookomarchy '{"mode":"manage"}'
omarchy-shell shell summon eudionelima.bookomarchy '{"mode":"add"}'
```

Hyprland:

```ini
bind = SUPER, B, exec, omarchy-shell shell toggle eudionelima.bookomarchy '{}'
bind = SUPER SHIFT, B, exec, omarchy-shell shell summon eudionelima.bookomarchy '{"mode":"manage"}'
```

## Bar icon

Left-click the bookmark icon toggles the menu, right-click opens manage mode.
The icon uses the bar's own foreground/font, so it follows every theme.

```bash
omarchy plugin enable eudionelima.bookomarchy --section right
```

## Data (never inside the plugin repo)

```
~/.config/omarchy/bookomarchy/
  bookmarks.json
  settings.json          # { "maxResults": 12, "confirmDelete": true, "confirmCommand": true }
  backups/bookomarchy-backup-YYYY-MM-DD-HHMM.json
```

## Maintenance CLI (same code the UI calls)

```bash
bin/bookomarchy-maintenance backup
bin/bookomarchy-maintenance export-json ~/Downloads/bookmarks.json
bin/bookomarchy-maintenance export-html ~/Downloads/bookmarks.html
bin/bookomarchy-maintenance import ~/Downloads/bookmarks.html
bin/bookomarchy-maintenance git-sync
```

## Security

See `SECURITY.md`. Summary: `url/file/dir/app` launch without shell;
`command/ssh` always confirm; dangerous patterns refused; no secrets stored;
saves go over stdin, never `bash -c` interpolation.

## Remove

```bash
omarchy plugin disable eudionelima.bookomarchy
omarchy plugin remove eudionelima.bookomarchy
# user data stays in ~/.config/omarchy/bookomarchy/ — delete manually if wanted
```
