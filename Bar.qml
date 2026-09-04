import QtQuick
import Omarchy.PluginPresentation 1.0

Rectangle {
  id: root

  implicitWidth: Style.bar.statusSlot
  implicitHeight: Style.bar.size
  color: "transparent"
  property var inputRegions: [{x: 0, y: 0, width: width, height: height}]
  readonly property bool acceptsKeyboardFocus: false
  readonly property int maximumFramesPerSecond: 15
  readonly property bool hideWhenDisconnected: runtime.settings.hideWhenDisconnected === undefined
    ? true : runtime.settings.hideWhenDisconnected === true
  readonly property bool shouldShow: !hideWhenDisconnected || pods.hasAirPods || pods.hasBattery

  visible: shouldShow

  function open() {}

  Service { id: pods }

  AirPodsIcon {
    anchors.centerIn: parent
    // Preserve the upstream bar mark size.
    iconSize: Style.font.icon
    color: pods.hasAirPods ? Color.bar.text : Color.alpha(Color.bar.text, 0.45)
    variant: pods.isHeadset ? "max" : pods.isProSeries ? "pro" : "buds"
  }

  MouseArea {
    id: pressArea
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onPressed: function(mouse) {
      if (mouse.button === Qt.RightButton)
        pods.cycleNoiseMode()
      else
        runtime.requestSurfaceIntent("airpods", "toggle")
    }
  }
}
