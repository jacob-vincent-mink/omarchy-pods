import QtQuick
import Omarchy.PluginPresentation 1.0

Rectangle {
  id: root

  width: 44
  height: 32
  radius: 8
  color: Color.alpha(Color.background, pressArea.pressed ? 0.86 : 0.58)
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
    iconSize: Style.space(13)
    color: pods.hasAirPods ? "#f4f4f5" : "#737986"
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
