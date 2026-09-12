import QtQuick
import qs.Ui
import qs.Commons

BarWidget {
  id: root
  moduleName: "eudionelima.bookomarchy"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: ""
    fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
    fontSize: Style.font.title * 1.5
    horizontalMargin: 7.5
    tooltipText: "BookOmarchy — left: open, right: manage"
    onPressed: function(pressedButton) {
      if (!root.bar) return
      if (pressedButton === Qt.RightButton) root.bar.run("omarchy-shell shell summon eudionelima.bookomarchy '{\"mode\":\"manage\"}'")
      else root.bar.run("omarchy-shell shell toggle eudionelima.bookomarchy '{}'")
    }
  }
}
