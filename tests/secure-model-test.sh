#!/bin/bash

set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

jq -e '.schemaVersion == 2 and .runtime.qml == "Panel.qml" and .runtime.surfaceQml == {"barWidget":"Bar.qml","airpods":"Panel.qml"}' "$root/manifest.json" >/dev/null
jq -e '.surfaces.barWidget.role == "bar-embedded" and .surfaces.airpods.role == "panel"' "$root/manifest.json" >/dev/null
jq -e '.surfaces.barWidget.keyboardFocus == false and .surfaces.airpods.keyboardFocus == "after-gesture"' "$root/manifest.json" >/dev/null
jq -e '.runtime | has("sidecars") | not' "$root/manifest.json" >/dev/null
jq -e 'has("ipc") | not' "$root/manifest.json" >/dev/null
jq -e '.settings.defaults.hideWhenDisconnected == true' "$root/manifest.json" >/dev/null
jq -e '.permissions.required[0].capability == "device.observe" and .permissions.required[0].operations == ["observe"]' "$root/manifest.json" >/dev/null
jq -e '.permissions.optional == [.permissions.optional[0]] and .permissions.optional[0].capability == "device.control" and .permissions.optional[0].operations == ["control"]' "$root/manifest.json" >/dev/null
jq -e 'all(.permissions.required[0], .permissions.optional[0]; .definitionGeneration == 1 and (.definitionDigest | test("^[0-9a-f]{64}$")))' "$root/manifest.json" >/dev/null
jq -e '(.permissions.required[0].fields | index("case-lid") != null and index("volume") == null) and (.permissions.optional[0].controls | index("set-volume") == null)' "$root/manifest.json" >/dev/null

rg -q '^import Omarchy\.PluginPresentation 1\.0' "$root/Bar.qml" "$root/Panel.qml"
! rg -n '^import Quickshell|\bProcess\s*\{|\bFileView\s*\{|execDetached|Quickshell\.env|XDG_|HOME' "$root/Bar.qml" "$root/Panel.qml" "$root/Service.qml"
! rg -n 'IpcHandler|registerIpcHandler|switchPanel' "$root/Bar.qml" "$root/Panel.qml" "$root/Service.qml"
for helper in Color CursorSurface IpcHandler KeyboardPanel PanelHero PanelKeyCatcher PanelSectionHeader PanelSeparator PanelSlider Style SurfacePanel ToggleSwitch; do
  ! test -e "$root/$helper.qml"
done
! test -e "$root/qmldir"

rg -q 'runtime.invoke\("device.observe", "observe"' "$root/Service.qml"
rg -q 'runtime.invoke\("device.control", "control"' "$root/Service.qml"
rg -q 'runtime.hasPermission\("device.control", "control"\)' "$root/Service.qml"
rg -q 'runtime.permissionState\("device.control", "control"\)' "$root/Service.qml"
rg -q 'Model.parseDeviceObservation\(raw\)' "$root/Service.qml"
rg -q 'runtime.requestSurfaceIntent\("airpods", "dismiss"\)' "$root/Panel.qml"
rg -q 'runtime.requestSurfaceIntent\("airpods", "toggle"\)' "$root/Bar.qml"
rg -q 'onPressed: function\(mouse\)' "$root/Bar.qml"
rg -q 'PanelSlider' "$root/Panel.qml"
rg -q 'ToggleSwitch' "$root/Panel.qml"
rg -q 'runtime.settings.hideWhenDisconnected' "$root/Bar.qml"
! rg -n 'set-volume|volumePercent|runtime.requestSurfaceIntent' "$root/Service.qml"

for control in set-listening-mode set-adaptive-level set-conversation-awareness set-one-bud-anc set-ear-detection; do
  jq -e --arg control "$control" '.permissions.optional[0].controls | index($control) != null' "$root/manifest.json" >/dev/null
  rg -q "\"$control\"" "$root/Service.qml"
done

rg -q 'status.insert\("device_address", connectedDeviceAddress\(\)\)' "$root/daemon/main.cpp"
rg -q 'parseBrokerControl' "$root/daemon/main.cpp" "$root/daemon/ipcverb.hpp" "$root/daemon/tests/tst_ipcverb.cpp"
rg -q 'object.size\(\) != 3' "$root/daemon/ipcverb.hpp"
rg -q 'address.compare\(connectedAddress, Qt::CaseInsensitive\) != 0' "$root/daemon/ipcverb.hpp"
rg -q 'command == u"noise:off"' "$root/daemon/ipcverb.hpp"
! rg -n 'command == u"forget"|command == u"connect"|command == u"disconnect"|command == u"reopen"' "$root/daemon/ipcverb.hpp"

printf '%s\n' 'ok - AirPods secure-model boundary'
