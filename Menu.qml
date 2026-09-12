import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import qs.Commons
import qs.Ui
import "models/Bookmarks.js" as Bookmarks

Item {
  id: root

  property string omarchyPath: Quickshell.env("OMARCHY_PATH")
  property var shell: null
  property var manifest: null
  readonly property string home: Quickshell.env("HOME")
  readonly property string dataDir: home + "/.config/omarchy/bookomarchy"
  readonly property string dataPath: dataDir + "/bookmarks.json"
  readonly property string settingsPath: dataDir + "/settings.json"
  readonly property string saveHelper: home + "/.config/omarchy/plugins/eudionelima.bookomarchy/bin/bookomarchy-save"
  readonly property string maintHelper: home + "/.config/omarchy/plugins/eudionelima.bookomarchy/bin/bookomarchy-maintenance"
  // Fixed trusted interpreter + clean allowlist env for internal helpers.
  // No bash, nothing resolved via PATH: env -i wipes BASH_ENV, PYTHONPATH,
  // LD_* and friends before /usr/bin/python3 starts.
  readonly property var pyRun: ["/usr/bin/env", "-i", "PATH=/usr/bin:/bin", "/usr/bin/python3"]
  readonly property var appLibrary: shell ? shell.appLibrary : null

  // mode: browse | add | edit | manage
  property string mode: "browse"
  property bool opened: false
  property string filterText: ""
  property string activeCategory: "Top10"
  property var categories: ["Top10"]
  property int selectedIndex: 0
  property bool cursorActive: true
  property var bookmarks: []
  property int maxResults: 12
  property bool confirmDelete: true
  property bool confirmCommand: true
  property string statusMsg: ""
  property bool zenSyncEnabled: true
  property bool zenSyncAuto: true
  property string zenSyncCategory: "Zen"
  property bool zenAutoFired: false

  // form state
  property string editingId: ""
  property string formTitle: ""
  property string formTarget: ""
  property string formType: "url"
  property string formCategory: ""
  property string formAliases: ""
  property string formTags: ""
  property string formDescription: ""
  property string formError: ""

  // confirms
  property bool deleteConfirmOpen: false
  property var deleteTarget: null
  property bool launchConfirmOpen: false
  property var launchTarget: null
  property string managePath: ""

  function open(payloadJson) {
    var payload = ({});
    try { payload = JSON.parse(payloadJson || "{}"); } catch (e) { payload = ({}); }
    root.mode = (payload.mode === "manage" || payload.mode === "add") ? payload.mode : "browse";
    root.filterText = payload.filter ? String(payload.filter) : "";
    root.selectedIndex = 0;
    root.cursorActive = true;
    root.statusMsg = "";
    root.deleteConfirmOpen = false;
    root.launchConfirmOpen = false;
    if (root.mode === "add") root.startAdd();
    root.opened = true;
    root.rebuildDisplay();
    root.maybeAutoZenSync();
    Qt.callLater(function() { keyCatcher.forceActiveFocus(); });
    return "ok";
  }
  function close() { root.zenAutoFired = false; root.opened = false; root.mode = "browse"; return "ok"; }
  function ping() { return "ok"; }
  function refresh() { root.zenAutoFired = false; bookmarksFile.reload(); settingsFile.reload(); return "ok"; }

  // Theme tokens — never hardcode hex.
  property string fontFamily: Style.font.menuFamily
  property color background: Color.menu.background
  property color foreground: Color.menu.text
  property color border: Color.menu.border
  property var borderSpec: Border.surfaceSpec("menu", "border", border, Math.max(1, Style.space(2)))
  property color scrim: Color.menu.scrim
  property color selectedBackground: Color.menu.selectedBackground
  property color selectedText: Color.menu.selectedText
  property color selectedBorder: Color.menu.selectedBorder
  property var selectedBorderSpec: Border.surfaceSpec("menu", "selected-border", selectedBorder, 0)
  property int cornerRadius: Style.cornerRadius
  property int contentMargin: Style.spacing.panelPadding
  property int contentSpacing: Style.spacing.md
  property int rowHeight: Math.max(Style.space(52), Style.font.body + Style.font.caption + Style.space(14))
  property int rowSpacing: Style.spacing.xs
  property int cardWidth: Math.min(Style.space(480), panel.width - Style.gapsOut * 2)

  function expandPath(p) {
    var s = String(p || "");
    if (s === "~") return root.home;
    if (s.indexOf("~/") === 0) return root.home + s.substring(1);
    if (s.indexOf("$HOME") === 0) return root.home + s.substring(5);
    return s;
  }

  function seedBookmarks() {
    return [
      { id: "github", title: "GitHub", type: "url", target: "https://github.com", category: "Development", aliases: ["gh", "git"], tags: ["git"], description: "Code hosting", favorite: true },
      { id: "archwiki", title: "ArchWiki", type: "url", target: "https://wiki.archlinux.org", category: "Linux", aliases: ["arch", "wiki"], tags: ["arch"], description: "Arch documentation", favorite: true },
      { id: "hyprland", title: "Hyprland Wiki", type: "url", target: "https://wiki.hypr.land", category: "Linux", aliases: ["hypr"], tags: ["wayland"], description: "Compositor docs", favorite: false },
      { id: "omarchy", title: "Omarchy", type: "url", target: "https://omarchy.org", category: "Omarchy", aliases: ["omarchy"], tags: ["omarchy"], description: "Omarchy website", favorite: false },
      { id: "htb", title: "HackTheBox", type: "url", target: "https://www.hackthebox.com", category: "Cybersecurity", aliases: ["htb"], tags: ["ctf"], description: "Pentest labs", favorite: false },
      { id: "thm", title: "TryHackMe", type: "url", target: "https://tryhackme.com", category: "Cybersecurity", aliases: ["thm"], tags: ["ctf"], description: "Security training", favorite: false }
    ];
  }

  function rebuildCategories() {
    root.categories = Bookmarks.categoriesOf(root.bookmarks);
    if (root.categories.indexOf(root.activeCategory) < 0) root.activeCategory = "Top10";
  }

  function rebuildDisplay() {
    displayModel.clear();
    var rows = [];
    var query = root.filterText.trim();
    var quickNum = /^[1-9]$/.test(query) ? parseInt(query, 10) : 0;
    var topMode = root.activeCategory === "Top10" && !query && !quickNum;
    for (var i = 0; i < root.bookmarks.length; i++) {
      var entry = root.bookmarks[i];
      if (!Bookmarks.matchesQuery(entry, quickNum ? "" : query, root.activeCategory)) continue;
      var n = rows.length + 1;
      rows.push({
        itemId: String(entry.id || ""),
        label: String(entry.title || ""),
        detail: categoryDetail(entry),
        target: String(entry.target || ""),
        btype: String(entry.type || "url"),
        fav: entry.favorite === true,
        opens: Number(entry.opens) || 0,
        num: n <= 9 ? String(n) : "",
        score: Bookmarks.searchScore(entry, quickNum ? "" : query)
      });
    }
    if (topMode) rows = Bookmarks.topSort(rows).slice(0, 10);
    else rows = Bookmarks.sortRows(rows).slice(0, Math.max(1, root.maxResults));
    // Renumber after sort so quick-keys match visible order.
    for (var k = 0; k < rows.length; k++) {
      rows[k].num = (k < 9) ? String(k + 1) : "";
      displayModel.append(rows[k]);
    }
    if (displayModel.count === 0) root.selectedIndex = 0;
    else if (root.selectedIndex >= displayModel.count) root.selectedIndex = displayModel.count - 1;
    else if (root.selectedIndex < 0) root.selectedIndex = 0;
  }

  function categoryDetail(entry) {
    var parts = [];
    if (entry.category) parts.push(String(entry.category));
    if (entry.aliases && entry.aliases.length > 0) parts.push(String(entry.aliases[0]));
    if (entry.type && entry.type !== "url") parts.push(String(entry.type));
    return parts.join("  ·  ");
  }

  function findBookmark(id) {
    for (var i = 0; i < root.bookmarks.length; i++) {
      if (String(root.bookmarks[i].id) === String(id)) return root.bookmarks[i];
    }
    return null;
  }

  function saveBookmarks(msg) {
    saveProc.payload = JSON.stringify(root.bookmarks);
    saveProc.pendingMsg = msg || "Saved";
    saveProc.running = true;
  }

  // Top10 accounting: bump open counter on every real launch.
  function markOpened(entry) {
    if (!entry) return;
    entry.opens = (Number(entry.opens) || 0) + 1;
    saveProc.payload = JSON.stringify(root.bookmarks);
    saveProc.pendingMsg = "";
    saveProc.running = true;
  }

  function isDangerousCommand(target) {
    return /(sudo\s|rm\s+-rf?\s+\/|chmod\s+(-R\s+)?777|chown\s+-R|curl\s.*\|\s*(sh|bash)|wget\s.*\|\s*(sh|bash)|mkfs|dd\s+of=|:\(\)\s*\{)/i.test(String(target || ""));
  }

  function launchEntry(entry, openInTerminal) {
    if (!entry) return;
    var t = String(entry.target || "");
    var type = String(entry.type || "url");
    if (type === "url") {
      root.markOpened(entry);
      Util.execArgv(["xdg-open", Bookmarks.normalizeUrl(t)]);
      root.opened = false; root.filterText = "";
    } else if (type === "file" || type === "directory") {
      var p = root.expandPath(t);
      root.markOpened(entry);
      if (type === "directory" && openInTerminal) {
        Util.execArgv(["xdg-terminal-exec", "--", "bash", "-lc", "cd " + "'" + p.replace(/'/g, "'\\''") + "' && exec \"${SHELL:-/bin/bash}\""]);
      } else {
        Util.execArgv(["xdg-open", p]);
      }
      root.opened = false; root.filterText = "";
    } else if (type === "application") {
      root.markOpened(entry);
      if (root.appLibrary) {
        try { root.appLibrary.launch(t, String(entry.title || t)); } catch (e) { Util.execArgv([root.expandPath(t)]); }
      } else {
        Util.execArgv([root.expandPath(t)]);
      }
      root.opened = false; root.filterText = "";
    } else if (type === "command" || type === "ssh") {
      if (root.isDangerousCommand(t)) {
        root.statusMsg = "Refused dangerous command. Edit the target to allow it.";
        return;
      }
      if ((type === "command" && root.confirmCommand) || type === "ssh") {
        root.launchTarget = { entry: entry, inTerminal: !!openInTerminal };
        root.launchConfirmOpen = true;
        return;
      }
      root.doLaunchConfirmed(entry, !!openInTerminal);
    }
  }

  function doLaunchConfirmed(entry, openInTerminal) {
    var t = String(entry.target || "");
    var type = String(entry.type || "url");
    root.markOpened(entry);
    root.launchConfirmOpen = false;
    root.launchTarget = null;
    if (type === "ssh") {
      Util.execArgv(["xdg-terminal-exec", "--", "ssh"].concat(t.split(/\s+/)));
    } else {
      if (openInTerminal) {
        Util.execArgv(["xdg-terminal-exec", "--", "bash", "-lc", t]);
      } else {
        Util.execDetached(t);
      }
    }
    root.opened = false; root.filterText = "";
  }

  function activateIndex(index, openInTerminal) {
    if (index < 0 || index >= displayModel.count) return;
    var row = displayModel.get(index);
    // Quick-key: typing "3" + Enter opens 3rd visible row.
    var quickNum = /^[1-9]$/.test(root.filterText.trim()) ? parseInt(root.filterText.trim(), 10) : 0;
    if (quickNum && quickNum >= 1 && quickNum <= displayModel.count) {
      row = displayModel.get(quickNum - 1);
    }
    var entry = root.findBookmark(row.itemId);
    if (entry) root.launchEntry(entry, !!openInTerminal);
  }

  function select(delta) {
    if (displayModel.count === 0) return;
    root.cursorActive = true;
    root.selectedIndex = (root.selectedIndex + delta + displayModel.count) % displayModel.count;
    resultList.positionViewAtIndex(root.selectedIndex, ListView.Contain);
  }

  function setFilter(next) {
    root.filterText = next;
    root.selectedIndex = 0;
    root.cursorActive = true;
    root.rebuildDisplay();
  }

  function cycleCategory(delta) {
    var idx = root.categories.indexOf(root.activeCategory);
    idx = (idx + delta + root.categories.length) % root.categories.length;
    root.activeCategory = root.categories[idx];
    root.selectedIndex = 0;
    root.rebuildDisplay();
  }

  function toggleFavoriteSelected() {
    if (displayModel.count === 0) return;
    var row = displayModel.get(root.cursorActive ? root.selectedIndex : 0);
    var entry = root.findBookmark(row.itemId);
    if (!entry) return;
    entry.favorite = !(entry.favorite === true);
    root.saveBookmarks(entry.favorite ? "Favorited" : "Unfavorited");
    root.rebuildDisplay();
  }

  function startAdd() {
    root.mode = "add";
    root.editingId = "";
    root.formTitle = "";
    root.formTarget = "";
    root.formType = "url";
    root.formCategory = root.activeCategory !== "Top10" ? root.activeCategory : "";
    root.formAliases = "";
    root.formTags = "";
    root.formDescription = "";
    root.formError = "";
    Qt.callLater(function() { titleField.forceActiveFocus(); });
  }

  function startEditSelected() {
    if (displayModel.count === 0) return;
    var row = displayModel.get(root.cursorActive ? root.selectedIndex : 0);
    var entry = root.findBookmark(row.itemId);
    if (!entry) return;
    root.mode = "edit";
    root.editingId = String(entry.id);
    root.formTitle = String(entry.title || "");
    root.formTarget = String(entry.target || "");
    root.formType = String(entry.type || "url");
    root.formCategory = String(entry.category || "");
    root.formAliases = (entry.aliases || []).join(", ");
    root.formTags = (entry.tags || []).join(", ");
    root.formDescription = String(entry.description || "");
    root.formError = "";
    Qt.callLater(function() { titleField.forceActiveFocus(); });
  }

  function splitList(s) {
    return String(s || "").split(/[, ]+/).map(function(x) { return x.trim(); }).filter(function(x) { return x.length > 0; });
  }

  function submitForm() {
    var entry = {
      id: root.editingId,
      title: root.formTitle.trim(),
      type: root.formType,
      target: root.formTarget.trim(),
      category: root.formCategory.trim() || "General",
      aliases: root.splitList(root.formAliases),
      tags: root.splitList(root.formTags),
      description: root.formDescription.trim(),
      favorite: false
    };
    var err = Bookmarks.validate(entry);
    if (err) { root.formError = err; return; }
    if (root.mode === "add") {
      var ids = root.bookmarks.map(function(b) { return String(b.id); });
      entry.id = Bookmarks.slugify(entry.title, ids);
      root.bookmarks.push(entry);
      root.saveBookmarks("Added");
    } else {
      var cur = root.findBookmark(root.editingId);
      if (!cur) { root.formError = "Bookmark not found"; return; }
      entry.favorite = cur.favorite === true;
      for (var i = 0; i < root.bookmarks.length; i++) {
        if (String(root.bookmarks[i].id) === String(root.editingId)) { root.bookmarks[i] = entry; break; }
      }
      root.saveBookmarks("Updated");
    }
    root.mode = "browse";
    root.rebuildCategories();
    root.rebuildDisplay();
    Qt.callLater(function() { keyCatcher.forceActiveFocus(); });
  }

  function requestDeleteSelected() {
    if (displayModel.count === 0) return;
    var row = displayModel.get(root.cursorActive ? root.selectedIndex : 0);
    var entry = root.findBookmark(row.itemId);
    if (!entry) return;
    if (!root.confirmDelete) { root.doDelete(entry.id); return; }
    root.deleteTarget = entry;
    root.deleteConfirmOpen = true;
  }

  function doDelete(id) {
    root.bookmarks = root.bookmarks.filter(function(b) { return String(b.id) !== String(id); });
    root.deleteConfirmOpen = false;
    root.deleteTarget = null;
    root.saveBookmarks("Deleted");
    root.rebuildCategories();
    root.rebuildDisplay();
    Qt.callLater(function() { keyCatcher.forceActiveFocus(); });
  }

  function runMaintenance(action, arg) {
    ioProc.actionLabel = action;
    var cmd = root.pyRun.concat([root.maintHelper, action]);
    if (arg) cmd.push(arg);
    ioProc.command = cmd;
    ioProc.running = true;
  }

  function maybeAutoZenSync() {
    if (root.zenSyncAuto && root.zenSyncEnabled && !root.zenAutoFired) {
      root.zenAutoFired = true;
      root.runMaintenance("zen-sync", "");
    }
  }

  // Manage-mode keyboard support: no mouse needed.
  property int manageIndex: 0
  property var manageActions: [
    { key: "export-json", label: "Export JSON" },
    { key: "export-html", label: "Export HTML" },
    { key: "import", label: "Import" },
    { key: "backup", label: "Backup" },
    { key: "zen-sync", label: "Sync Zen" },
    { key: "git-sync", label: "Git Sync" }
  ]
  function manageCount() { return root.manageActions.length + 1; } // + Back
  function moveManage(delta) {
    var n = root.manageCount();
    root.manageIndex = (root.manageIndex + delta + n) % n;
  }
  function activateManage(idx) {
    if (idx === undefined) idx = root.manageIndex;
    if (idx >= root.manageActions.length) { root.mode = "browse"; Qt.callLater(function() { keyCatcher.forceActiveFocus(); }); return; }
    var k = root.manageActions[idx].key;
    if (k === "import" && !root.managePath.trim()) { root.statusMsg = "Set an import path first (Tab to reach the path field)"; return; }
    root.runMaintenance(k, (k === "import" || k === "export-json" || k === "export-html") ? root.expandPath(root.managePath.trim()) : "");
  }
  function openManage() {
    root.mode = "manage";
    root.manageIndex = 0;
    Qt.callLater(function() { manageKeys.forceActiveFocus(); });
  }

  // Form type cycling without mouse: Ctrl+[ / Ctrl+]
  property var formTypes: ["url", "file", "directory", "application", "command", "ssh"]
  function cycleFormType(delta) {
    var i = root.formTypes.indexOf(root.formType);
    if (i < 0) i = 0;
    root.formType = root.formTypes[(i + delta + root.formTypes.length) % root.formTypes.length];
  }

  function formKey(event) {
    if (event.key === Qt.Key_Escape) {
      root.mode = "browse"; root.formError = "";
      event.accepted = true;
      Qt.callLater(function() { keyCatcher.forceActiveFocus(); });
      return true;
    }
    if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_BracketLeft) {
      root.cycleFormType(-1);
      event.accepted = true;
      return true;
    }
    if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_BracketRight) {
      root.cycleFormType(1);
      event.accepted = true;
      return true;
    }
    if ((event.modifiers & Qt.ControlModifier) && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
      root.submitForm();
      event.accepted = true;
      return true;
    }
    return false;
  }

  ListModel { id: displayModel }

  // Atomic save via stdin — no user data in argv, no shell quoting.
  // (ensure-dir is handled inside the helper itself; no bash here.)
  // clearEnvironment wipes the inherited env BEFORE the first executable
  // loads (loader injection happens earlier than any `env -i` cleanup);
  // `environment` is the explicit allowlist. `env -i` in pyRun stays on
  // as defense in depth.
  Process {
    id: saveProc
    stdinEnabled: true
    clearEnvironment: true
    environment: ({ "PATH": "/usr/bin:/bin" })
    property string payload: ""
    property string pendingMsg: "Saved"
    command: root.pyRun.concat([root.saveHelper])
    onStarted: { write(payload + "\n"); }
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: { root.statusMsg = (saveProc.pendingMsg + "  ·  " + String(text || "").trim()).trim(); }
    }
    onExited: function(code) {
      if (code !== 0) root.statusMsg = "Save failed — see shell log";
      bookmarksFile.reload();
    }
  }

  Process {
    id: ioProc
    clearEnvironment: true
    environment: ({ "PATH": "/usr/bin:/bin" })
    property string actionLabel: ""
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var line = String(text || "").trim().split("\n").filter(function(x) { return x.trim(); });
        root.statusMsg = (ioProc.actionLabel + ": " + (line.length ? line[line.length - 1] : "done")).substring(0, 220);
      }
    }
    onExited: function(code) {
      if (code !== 0 && !root.statusMsg) root.statusMsg = ioProc.actionLabel + " failed";
      bookmarksFile.reload();
    }
  }

  FileView {
    id: bookmarksFile
    path: root.dataPath
    watchChanges: true
    printErrors: false
    onLoaded: {
      try {
        var parsed = JSON.parse(text());
        root.bookmarks = Array.isArray(parsed) ? parsed : (parsed.bookmarks || root.seedBookmarks());
      } catch (e) { root.bookmarks = root.seedBookmarks(); }
      root.rebuildCategories();
      if (root.opened && root.mode === "browse") root.rebuildDisplay();
    }
    onLoadFailed: {
      root.bookmarks = root.seedBookmarks();
      root.rebuildCategories();
      if (root.opened && root.mode === "browse") root.rebuildDisplay();
    }
    onFileChanged: reload()
  }

  FileView {
    id: settingsFile
    path: root.settingsPath
    watchChanges: true
    printErrors: false
    onLoaded: {
      try {
        var s = JSON.parse(text());
        if (s.maxResults) root.maxResults = Math.max(4, Math.min(50, Number(s.maxResults)));
        if (s.confirmDelete !== undefined) root.confirmDelete = !!s.confirmDelete;
        if (s.confirmCommand !== undefined) root.confirmCommand = !!s.confirmCommand;
        if (s.zenSync && typeof s.zenSync === "object") {
          if (s.zenSync.enabled !== undefined) root.zenSyncEnabled = !!s.zenSync.enabled;
          if (s.zenSync.auto !== undefined) root.zenSyncAuto = !!s.zenSync.auto;
          if (s.zenSync.category) root.zenSyncCategory = String(s.zenSync.category);
        }
      } catch (e) {}
      if (root.opened) root.rebuildDisplay();
    }
    onLoadFailed: {}
    onFileChanged: reload()
  }

  Component.onCompleted: {
    root.bookmarks = root.seedBookmarks();
    root.rebuildCategories();
    root.rebuildDisplay();
  }

  PanelWindow {
    id: panel
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "eudionelima-bookomarchy"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    Rectangle { anchors.fill: parent; color: root.scrim }
    MouseArea { anchors.fill: parent; onClicked: root.close() }

    BorderSurface {
      id: card
      width: root.cardWidth
      height: Math.min(contentColumn.implicitHeight + root.contentMargin * 2, panel.height - Style.gapsOut * 2)
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.verticalCenter: parent.verticalCenter
      color: root.background
      borderSpec: root.borderSpec
      radius: root.cornerRadius
      padding: root.contentMargin
      MouseArea { anchors.fill: parent; onClicked: {} }

      Item {
        id: keyCatcher
        anchors.fill: parent
        focus: root.mode === "browse"
        Keys.onPressed: function(event) {
          if (root.deleteConfirmOpen || root.launchConfirmOpen) return;
          if (root.mode !== "browse") return;
          var ctrl = (event.modifiers & Qt.ControlModifier);
          var shift = (event.modifiers & Qt.ShiftModifier);
          if (ctrl && event.key === Qt.Key_N) { root.startAdd(); event.accepted = true; return; }
          if (ctrl && event.key === Qt.Key_E) { root.startEditSelected(); event.accepted = true; return; }
          if (ctrl && event.key === Qt.Key_D) { root.toggleFavoriteSelected(); event.accepted = true; return; }
          if (ctrl && event.key === Qt.Key_B) { root.runMaintenance("backup"); event.accepted = true; return; }
          if (ctrl && event.key === Qt.Key_M) { root.openManage(); event.accepted = true; return; }
          if (ctrl && event.key === Qt.Key_Y) { root.runMaintenance("zen-sync", ""); event.accepted = true; return; }
          if (event.key === Qt.Key_Delete) { root.requestDeleteSelected(); event.accepted = true; return; }
          if (event.key === Qt.Key_Escape) {
            if (root.filterText) root.setFilter("");
            else root.close();
            event.accepted = true; return;
          }
          if (event.key === Qt.Key_BracketLeft) { root.cycleCategory(-1); event.accepted = true; return; }
          if (event.key === Qt.Key_BracketRight) { root.cycleCategory(1); event.accepted = true; return; }
          if (Util.editsFilter(event, root.filterText)) { root.setFilter(Util.editedFilter(event, root.filterText)); event.accepted = true; return; }
          if (event.key === Qt.Key_Up) { root.select(-1); event.accepted = true; return; }
          if (event.key === Qt.Key_Down) { root.select(1); event.accepted = true; return; }
          if (event.key === Qt.Key_Left) { root.cycleCategory(-1); event.accepted = true; return; }
          if (event.key === Qt.Key_Right) { root.cycleCategory(1); event.accepted = true; return; }
          if (event.key === Qt.Key_PageUp) { root.select(-6); event.accepted = true; return; }
          if (event.key === Qt.Key_PageDown) { root.select(6); event.accepted = true; return; }
          if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (displayModel.count > 0) root.activateIndex(root.cursorActive ? root.selectedIndex : 0, shift);
            event.accepted = true; return;
          }
          if (event.text && event.text.length === 1 && event.text.charCodeAt(0) >= 32 && (event.modifiers === Qt.NoModifier || event.modifiers === Qt.ShiftModifier)) {
            root.setFilter(root.filterText + event.text);
            event.accepted = true;
          }
        }
      }

      ConfirmDialog {
        anchors.fill: parent
        opened: root.deleteConfirmOpen
        z: 30
        message: "Delete " + ((root.deleteTarget && root.deleteTarget.title) || "") + "?"
        confirmText: "Delete"
        background: root.background
        foreground: root.foreground
        scrim: root.scrim
        selectedBackground: root.selectedBackground
        selectedText: root.selectedText
        fontFamily: root.fontFamily
        cornerRadius: root.cornerRadius
        onCanceled: { root.deleteConfirmOpen = false; root.deleteTarget = null; keyCatcher.forceActiveFocus(); }
        onConfirmed: { if (root.deleteTarget) root.doDelete(root.deleteTarget.id); }
      }

      ConfirmDialog {
        anchors.fill: parent
        opened: root.launchConfirmOpen
        z: 30
        message: "Run " + ((root.launchTarget && root.launchTarget.entry && root.launchTarget.entry.type) || "") + "?\n" + ((root.launchTarget && root.launchTarget.entry && root.launchTarget.entry.target) || "")
        confirmText: "Run"
        background: root.background
        foreground: root.foreground
        scrim: root.scrim
        selectedBackground: root.selectedBackground
        selectedText: root.selectedText
        fontFamily: root.fontFamily
        cornerRadius: root.cornerRadius
        onCanceled: { root.launchConfirmOpen = false; root.launchTarget = null; keyCatcher.forceActiveFocus(); }
        onConfirmed: { if (root.launchTarget) root.doLaunchConfirmed(root.launchTarget.entry, root.launchTarget.inTerminal); }
      }

      Column {
        id: contentColumn
        width: parent.width - card.contentLeftInset - card.contentRightInset
        x: card.contentLeftInset
        y: card.contentTopInset
        spacing: root.contentSpacing

        // Header
        Row {
          width: parent.width
          spacing: Style.space(8)
          Text {
            text: root.mode === "browse" ? "BookOmarchy" : (root.mode === "add" ? "New bookmark" : (root.mode === "edit" ? "Edit bookmark" : "Manage"))
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.title
            font.bold: true
          }
          Item { width: Style.space(4); height: 1 }
          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.mode === "browse" ? (displayModel.count + " / " + root.bookmarks.length) : ""
            color: root.foreground
            opacity: 0.5
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }
        }

        // Search (browse)
        Text {
          visible: root.mode === "browse"
          width: parent.width
          text: root.filterText || ("Search " + root.activeCategory + "…  (gh, arch, 1-9)")
          color: root.foreground
          opacity: root.filterText ? 1.0 : 0.58
          font.family: root.fontFamily
          font.pixelSize: Style.font.heading
          elide: Text.ElideRight
        }

        // Categories (browse)
        Flow {
          visible: root.mode === "browse"
          width: parent.width
          spacing: Style.space(6)
          Repeater {
            model: root.categories
            BorderSurface {
              required property string modelData
              required property int index
              readonly property bool active: modelData === root.activeCategory
              width: catText.implicitWidth + Style.space(18)
              height: Style.space(26)
              radius: root.cornerRadius
              color: active ? root.selectedBackground : "transparent"
              borderSpec: active ? root.selectedBorderSpec : Border.none()
              Text {
                id: catText
                anchors.centerIn: parent
                text: modelData
                color: active ? root.selectedText : root.foreground
                opacity: active ? 1.0 : 0.65
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
              }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: { root.activeCategory = modelData; root.selectedIndex = 0; root.rebuildDisplay(); }
              }
            }
          }
        }

        // List (browse)
        ListView {
          id: resultList
          visible: root.mode === "browse"
          width: parent.width
          height: displayModel.count === 0 ? root.rowHeight : Math.min(displayModel.count * (root.rowHeight + root.rowSpacing), Math.round(panel.height * 0.45))
          model: displayModel
          clip: true
          spacing: root.rowSpacing
          boundsBehavior: Flickable.StopAtBounds
          delegate: BorderSurface {
            required property int index
            required property string itemId
            required property string label
            required property string detail
            required property string btype
            required property bool fav
            required property string num
            readonly property bool hasCursor: root.cursorActive && index === root.selectedIndex
            width: ListView.view.width
            height: root.rowHeight
            radius: root.cornerRadius
            color: hasCursor ? root.selectedBackground : "transparent"
            borderSpec: hasCursor ? root.selectedBorderSpec : Border.none()
            Text {
              anchors.left: parent.left
              anchors.leftMargin: Style.space(10)
              anchors.verticalCenter: parent.verticalCenter
              text: num
              visible: num.length > 0
              color: root.foreground
              opacity: 0.4
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              width: Style.space(14)
            }
            Column {
              anchors.left: parent.left
              anchors.leftMargin: Style.space(28)
              anchors.right: favStar.left
              anchors.rightMargin: Style.space(6)
              anchors.verticalCenter: parent.verticalCenter
              spacing: Style.space(2)
              Text {
                width: parent.width
                text: label
                textFormat: Text.PlainText
                color: hasCursor ? root.selectedText : root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.heading
                font.weight: Font.Medium
                elide: Text.ElideRight
              }
              Text {
                width: parent.width
                text: detail
                textFormat: Text.PlainText
                visible: detail.length > 0
                color: root.foreground
                opacity: 0.52
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
                elide: Text.ElideRight
              }
            }
            Text {
              id: favStar
              anchors.right: parent.right
              anchors.rightMargin: Style.space(12)
              anchors.verticalCenter: parent.verticalCenter
              text: fav ? "★" : ""
              color: hasCursor ? root.selectedText : root.foreground
              opacity: 0.8
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
            }
            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onEntered: { root.cursorActive = true; root.selectedIndex = index; }
              onClicked: root.activateIndex(index, false)
            }
          }
        }

        Text {
          visible: root.mode === "browse" && displayModel.count === 0
          width: parent.width
          text: "No matches — Ctrl+N to add"
          color: root.foreground
          opacity: 0.55
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
        }

        // Form (add/edit)
        Column {
          visible: root.mode === "add" || root.mode === "edit"
          width: parent.width
          spacing: Style.space(8)
          TextField {
            id: titleField
            width: parent.width
            text: root.formTitle
            placeholderText: "Title — e.g. GitHub"
            foreground: root.foreground
            onTextChanged: root.formTitle = text
            Keys.onPressed: function(e) { if (root.formKey(e)) e.accepted = true; }
            onAccepted: root.submitForm()
          }
          TextField {
            width: parent.width
            text: root.formTarget
            placeholderText: "Target — https://…, ~/path, app-id, command, user@host"
            foreground: root.foreground
            onTextChanged: root.formTarget = text
            Keys.onPressed: function(e) { if (root.formKey(e)) e.accepted = true; }
            onAccepted: root.submitForm()
          }
          Flow {
            width: parent.width
            spacing: Style.space(6)
            Repeater {
              model: ["url", "file", "directory", "application", "command", "ssh"]
              BorderSurface {
                required property string modelData
                readonly property bool active: modelData === root.formType
                width: typeText.implicitWidth + Style.space(16)
                height: Style.space(26)
                radius: root.cornerRadius
                color: active ? root.selectedBackground : "transparent"
                borderSpec: active ? root.selectedBorderSpec : Border.none()
                Text {
                  id: typeText
                  anchors.centerIn: parent
                  text: modelData
                  color: active ? root.selectedText : root.foreground
                  opacity: active ? 1.0 : 0.65
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.formType = modelData }
              }
            }
          }
          TextField {
            width: parent.width
            text: root.formCategory
            placeholderText: "Category — Development, Linux, …"
            foreground: root.foreground
            onTextChanged: root.formCategory = text
            Keys.onPressed: function(e) { if (root.formKey(e)) e.accepted = true; }
            onAccepted: root.submitForm()
          }
          TextField {
            width: parent.width
            text: root.formAliases
            placeholderText: "Aliases — gh, git (comma separated)"
            foreground: root.foreground
            onTextChanged: root.formAliases = text
            Keys.onPressed: function(e) { if (root.formKey(e)) e.accepted = true; }
            onAccepted: root.submitForm()
          }
          TextField {
            width: parent.width
            text: root.formDescription
            placeholderText: "Description (optional)"
            foreground: root.foreground
            onTextChanged: root.formDescription = text
            Keys.onPressed: function(e) { if (root.formKey(e)) e.accepted = true; }
            onAccepted: root.submitForm()
          }
          Text {
            visible: root.formError.length > 0
            width: parent.width
            text: root.formError
            color: Color.urgent
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }
          Row {
            spacing: Style.space(8)
            BorderSurface {
              width: Style.space(110); height: Style.space(32)
              radius: root.cornerRadius
              color: root.selectedBackground
              borderSpec: root.selectedBorderSpec
              Text { anchors.centerIn: parent; text: "Save  (Ctrl+↵)"; color: root.selectedText; font.family: root.fontFamily; font.pixelSize: Style.font.caption }
              MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.submitForm() }
            }
            BorderSurface {
              width: Style.space(110); height: Style.space(32)
              radius: root.cornerRadius
              color: "transparent"
              borderSpec: Border.flat(Util.alpha(root.foreground, 0.38), Style.normalBorderWidth)
              Text { anchors.centerIn: parent; text: "Cancel  (Esc)"; color: root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.caption }
              MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.mode = "browse"; keyCatcher.forceActiveFocus(); } }
            }
          }
        }

        // Manage — fully keyboard operable: arrows/Tab move, Enter runs, 1-7 quick.
        Column {
          visible: root.mode === "manage"
          width: parent.width
          spacing: Style.space(8)
          Item {
            id: manageKeys
            width: 1; height: 1
            focus: root.mode === "manage"
            Keys.onPressed: function(event) {
              var n = root.manageCount();
              if (event.key === Qt.Key_Escape) { root.mode = "browse"; event.accepted = true; Qt.callLater(function() { keyCatcher.forceActiveFocus(); }); return; }
              if (event.key === Qt.Key_Up || event.key === Qt.Key_Left) { root.moveManage(-1); event.accepted = true; return; }
              if (event.key === Qt.Key_Down || event.key === Qt.Key_Right || event.key === Qt.Key_Tab) { root.moveManage(1); event.accepted = true; return; }
              if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) { root.activateManage(); event.accepted = true; return; }
              var num = parseInt(event.text, 10);
              if (event.text && num >= 1 && num <= n) { root.manageIndex = num - 1; root.activateManage(); event.accepted = true; return; }
            }
          }
          TextField {
            id: managePathField
            width: parent.width
            text: root.managePath
            placeholderText: "Import/export path — e.g. ~/Downloads/bookmarks.html"
            foreground: root.foreground
            onTextChanged: root.managePath = text
            Keys.onPressed: function(e) {
              if (e.key === Qt.Key_Escape) { root.mode = "browse"; e.accepted = true; keyCatcher.forceActiveFocus(); }
              else if (e.key === Qt.Key_Tab) { manageKeys.forceActiveFocus(); e.accepted = true; }
              else if ((e.modifiers & Qt.ControlModifier) && (e.key === Qt.Key_Return || e.key === Qt.Key_Enter)) { root.activateManage(); e.accepted = true; }
            }
          }
          Flow {
            width: parent.width
            spacing: Style.space(8)
            Repeater {
              model: root.manageActions
              BorderSurface {
                required property var modelData
                required property int index
                readonly property bool active: index === root.manageIndex
                width: btnText.implicitWidth + Style.space(18)
                height: Style.space(32)
                radius: root.cornerRadius
                color: active ? root.selectedBackground : "transparent"
                borderSpec: active ? root.selectedBorderSpec : Border.flat(Util.alpha(root.foreground, 0.38), Style.normalBorderWidth)
                Text {
                  id: btnText
                  anchors.centerIn: parent
                  text: (index + 1) + " · " + modelData.label
                  color: active ? root.selectedText : root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                }
                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onEntered: root.manageIndex = index
                  onClicked: { root.manageIndex = index; root.activateManage(index); }
                }
              }
            }
          }
          BorderSurface {
            width: Style.space(110); height: Style.space(32)
            radius: root.cornerRadius
            readonly property bool active: root.manageIndex === root.manageActions.length
            color: active ? root.selectedBackground : "transparent"
            borderSpec: active ? root.selectedBorderSpec : Border.flat(Util.alpha(root.foreground, 0.38), Style.normalBorderWidth)
            Text { anchors.centerIn: parent; text: "Back  (Esc)"; color: active ? root.selectedText : root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.caption }
            MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onEntered: root.manageIndex = root.manageActions.length; onClicked: { root.mode = "browse"; keyCatcher.forceActiveFocus(); } }
          }
        }

        Text {
          visible: root.statusMsg.length > 0
          width: parent.width
          text: root.statusMsg
          color: root.foreground
          opacity: 0.6
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
        }

        Text {
          width: parent.width
          text: root.mode === "browse"
            ? "↑↓ Navigate  ←→ Category  Enter Open  ⇧↵ Terminal  1-9 Quick  Ctrl+N New  Ctrl+E Edit  Del Delete  Ctrl+D ★  Ctrl+Y Zen  Ctrl+M Manage  Esc"
            : (root.mode === "manage" ? "↑↓←→ Select  Enter Run  1-7 Quick  Tab Path  Esc Back" : "Ctrl+↵ Save  Ctrl+[ ] Type  Esc Cancel")
          color: root.foreground
          opacity: 0.45
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
        }
      }
    }
  }
}
