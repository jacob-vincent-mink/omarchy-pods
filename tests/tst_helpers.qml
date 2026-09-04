import QtQuick
import QtTest
import Omarchy.PluginPresentation 1.0 as Presentation

Item {
  width: 400
  height: 300

  Presentation.PanelKeyCatcher {
    id: keys
    width: 200
    height: 100
  }

  Presentation.PanelHero {
    id: hero
    y: 110
    width: 300
    title: "AirPods Pro"
    meta: "Essential Selection"
    uppercaseMeta: true
  }

  Presentation.PanelSlider {
    id: slider
    y: 220
    width: 200
    minimum: 0
    maximum: 100
    step: 5
    integer: true
    value: 20
  }

  SignalSpy { id: moveSpy; target: keys; signalName: "moveRequested" }
  SignalSpy { id: activateSpy; target: keys; signalName: "activateRequested" }
  SignalSpy { id: tabSpy; target: keys; signalName: "tabRequested" }
  SignalSpy { id: textSpy; target: keys; signalName: "textKey" }
  SignalSpy { id: releaseSpy; target: slider; signalName: "released" }

  TestCase {
    name: "LocalPresentationHelpers"
    when: windowShown

    function init() {
      moveSpy.clear()
      activateSpy.clear()
      tabSpy.clear()
      textSpy.clear()
      releaseSpy.clear()
      keys.forceActiveFocus()
    }

    function test_keyboardMappings() {
      keyClick(Qt.Key_Down)
      keyClick(Qt.Key_K)
      keyClick(Qt.Key_Left)
      keyClick(Qt.Key_L)
      compare(moveSpy.count, 4)
      keyClick(Qt.Key_Space)
      compare(activateSpy.count, 1)
      keyClick(Qt.Key_Tab)
      compare(tabSpy.count, 1)
      keyClick(Qt.Key_O)
      compare(textSpy.count, 1)
    }

    function test_heroMetadata() {
      var meta = findChild(hero, "metaText")
      verify(meta !== null)
      compare(meta.text, "ESSENTIAL SELECTION")
      verify(meta.visible)
    }

    function test_sliderDragSnapsAndReleases() {
      var area = findChild(slider, "mouseArea")
      verify(area !== null)
      mousePress(area, 103, area.height / 2, Qt.LeftButton)
      compare(slider.liveValue, 50)
      mouseMove(area, 151, area.height / 2)
      compare(slider.liveValue, 75)
      mouseRelease(area, 151, area.height / 2, Qt.LeftButton)
      compare(releaseSpy.count, 1)
      compare(releaseSpy.signalArguments[0][0], 75)
    }
  }
}
