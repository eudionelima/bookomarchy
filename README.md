<h1 align="center">BookOmarchy</h1>

![BookOmarchy](screenshot.jpg)

<h2 align="center">What it does</h2>

BookOmarchy lives in the Omarchy bar and puts your bookmarks and shortcuts one keypress away: URLs, files, folders, apps, shell commands and SSH hosts in a fast keyboard-first menu (`SUPER+B`), with a self-learning Top10, fuzzy search, categories and automatic Zen Browser sync.

<h2 align="center">Screenshots</h2>

<table>
  <tr>
    <td align="center"><b>Browse & Top10</b><br><img src="screenshots/browse.png" width="420"></td>
    <td align="center"><b>Delete</b><br><img src="screenshots/delete.png" width="420"></td>
  </tr>
  <tr>
    <td align="center"><b>Edit bookmark</b><br><img src="screenshots/edit-bookmark.png" width="420"></td>
    <td align="center"><b>Manage</b><br><img src="screenshots/manage.png" width="420"></td>
  </tr>
</table>

<h2 align="center">Features</h2>

- Fuzzy search across title, URL, category, aliases and tags (`gh` → GitHub)
- Top10 default view: most opened first, favorites as tiebreak
- Types: `url`, `file`, `directory`, `application`, `command`, `ssh` (commands always confirmed)
- Zero-mouse operation: arrows, quick-keys `1-9`, `1-7` shortcuts in manage mode
- Zen Browser auto-sync: new favorites appear on next open, never overwriting yours
- Import Chrome/Firefox HTML, JSON, CSV · export JSON/HTML · timestamped backups · local git sync
- Follows `omarchy theme set` live, zero hardcoded colors

<h2 align="center">Requirements</h2>

- Omarchy Linux with the Quickshell bar
- `python3` (standard library only, no dependencies)

<h2 align="center">Install</h2>

Via Omarchy plugin manager:

```bash
omarchy plugin add https://github.com/eudionelima/bookomarchy --enable
```

Manual:

```bash
git clone https://github.com/eudionelima/bookomarchy ~/.config/omarchy/plugins/eudionelima.bookomarchy
omarchy plugin enable eudionelima.bookomarchy
```

<h2 align="center">Uninstall</h2>

Via Omarchy plugin manager:

```bash
omarchy plugin remove eudionelima.bookomarchy
```

For manual installations, remove the plugin directory:

```bash
rm -rf ~/.config/omarchy/plugins/eudionelima.bookomarchy
```

User data stays in `~/.config/omarchy/bookomarchy/` — delete manually if wanted.

<h2 align="center">Usage</h2>

1. Press `SUPER+B` (or left-click the bar icon; right-click opens manage mode).
2. Type to search, `↑↓` to navigate, `Enter` to open.
3. `Ctrl+N` new · `Ctrl+E` edit · `Ctrl+M` manage · `Ctrl+Y` sync Zen · `Esc` close.

```bash
# summon with a filter, or straight into manage / add mode
omarchy-shell shell summon eudionelima.bookomarchy '{"filter":"gh"}'
omarchy-shell shell summon eudionelima.bookomarchy '{"mode":"manage"}'
```

```bash
# maintenance CLI (same code the UI calls)
bin/bookomarchy-maintenance backup
bin/bookomarchy-maintenance zen-sync --dry-run
bin/bookomarchy-maintenance import ~/Downloads/bookmarks.html
bin/bookomarchy-maintenance git-sync
```

<div align="center">

| Keys | Action |
| ---- | ------ |
| `↑` `↓` | Navigate |
| `←` `→` / `[` `]` | Switch category |
| `Enter` | Open |
| `Shift+Enter` | Open directory in terminal |
| `1-9` | Quick open nth row |
| `Ctrl+N` / `Ctrl+E` / `Del` | New / edit / delete |
| `Ctrl+D` | Favorite |
| `Ctrl+Y` | Sync Zen |
| `Ctrl+M` | Manage |
| `Esc` | Close |

</div>

<h2 align="center">Note</h2>

`command`/`ssh` entries always ask for confirmation and dangerous patterns are refused. No secrets are ever stored — user data lives only in `~/.config/omarchy/bookomarchy/`, never inside the plugin repo.

<h2 align="center">License</h2>

MIT — see [LICENSE](LICENSE).
