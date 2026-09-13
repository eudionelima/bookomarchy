import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui
import qs.Commons

BarWidget {
  id: root
  moduleName: "eudionelima.bookomarchy"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  // Trusted absolute interpreter + clean allowlisted environment for the
  // bar-widget IPC path.  Previous code used root.bar.run() which delegates
  // to Util.execDetached → bash -lc under the full inherited environment,
  // allowing loader/env injection before omarchy-shell even loads.
  // clearEnvironment wipes the inherited env BEFORE the first executable;
  // the minimal PATH allowlist and absolute argv avoid ambient resolution.
  readonly property string omarchyPath: Quickshell.env("OMARCHY_PATH")
  readonly property string waylandDisplay: Quickshell.env("WAYLAND_DISPLAY")
  readonly property string xdgRuntimeDir: Quickshell.env("XDG_RUNTIME_DIR")

  Process {
    id: shellProc
    clearEnvironment: true
    environment: ({
      "PATH": "/usr/bin:/bin",
      "OMARCHY_PATH": root.omarchyPath,
      "WAYLAND_DISPLAY": root.waylandDisplay,
      "XDG_RUNTIME_DIR": root.xdgRuntimeDir
    })
    property var pendingCommand: []
    command: pendingCommand
    onExited: function(code) {}
  }

  function runShellCmd(argv) {
    shellProc.pendingCommand = ["/usr/bin/omarchy-shell"].concat(argv);
    shellProc.running = true;
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: ""
    fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
    fontSize: Style.bar.iconFont
    horizontalMargin: 7.5
    tooltipText: "BookOmarchy — left: open, right: manage"
    onPressed: function(pressedButton) {
      if (!root.bar) return
      if (pressedButton === Qt.RightButton) root.runShellCmd(["shell", "summon", "eudionelima.bookomarchy", '{"mode":"manage"}'])
      else root.runShellCmd(["shell", "toggle", "eudionelima.bookomarchy", "{}"])
    }
  }
}
