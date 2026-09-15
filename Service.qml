import QtQuick
import QtQml as Qml
import "Model.js" as Model

Item {
  id: root

  property var settings: ({})

  property bool daemonReachable: false
  property bool connected: false
  property string deviceName: ""
  property string modelName: ""
  property bool isProSeries: false
  property bool isHeadset: false
  property bool supportsNoiseOff: true
  property bool supportsNoiseControl: true
  property bool supportsAdaptive: false
  property bool supportsConversationalAwareness: false
  property bool supportsOneBudANC: false
  property var supportedControls: []
  property int noiseMode: Model.NOISE_UNKNOWN
  property int adaptiveNoiseLevel: 0
  property bool oneBudANC: false
  property bool conversationalAwareness: false
  property int earDetectionBehavior: Model.EAR_PAUSE_ONE_OUT
  property int lidState: Model.LID_UNKNOWN
  property bool schemaUnsupported: false
  property var leftPod: Model.defaultPod()
  property var rightPod: Model.defaultPod()
  property var caseBattery: ({ level: Model.LEVEL_UNKNOWN, charging: false })
  property var headsetBattery: ({ level: Model.LEVEL_UNKNOWN, charging: false })
  property string lastError: ""
  property string actionStatus: ""

  readonly property bool busy: controlCalls.length > 0
  readonly property var declaredControls: [
    "set-listening-mode",
    "set-adaptive-level",
    "set-conversation-awareness",
    "set-one-bud-anc",
    "set-ear-detection"
  ]
  readonly property bool controlPermissionGranted: {
    return runtime.hasPermission("device.control", "control")
  }
  readonly property string controlPermissionState:
    runtime.permissionState("device.control", "control")
  readonly property string controlPermissionMessage:
    controlPermissionState === "granted" ? "Device controls allowed"
      : controlPermissionState === "unavailable" ? "Status only — control provider unavailable"
      : controlPermissionState === "revoked" ? "Status only — controls revoked"
      : "Status only — controls not granted"
  readonly property bool hasAirPods: daemonReachable && connected
  // Battery keeps arriving over BLE while the audio link is down, so it is not gated on connected.
  readonly property bool hasBattery: daemonReachable
    && (isHeadset
      ? headsetBattery.level !== Model.LEVEL_UNKNOWN
      : (leftPod.level !== Model.LEVEL_UNKNOWN
        || rightPod.level !== Model.LEVEL_UNKNOWN
        || caseBattery.level !== Model.LEVEL_UNKNOWN))

  // How long an optimistic value is held before the daemon's own state wins.
  readonly property int settleHoldMs: 4000
  readonly property int actionStatusMs: 2200
  readonly property int observationIntervalMs: 5000

  // Held over incoming reads until the daemon agrees, so a write already in flight
  // when the click landed cannot snap the control back.
  property var _pendingValues: ({})
  property var _latestControls: ({})
  property int _controlSerial: 0

  property var observeCall: null
  property var controlCalls: []
  property double observeCorrelation: 0
  property bool observationInFlight: false

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function canControl(name) {
    return controlPermissionGranted
      && declaredControls.indexOf(name) >= 0
      && supportedControls.indexOf(name) >= 0
  }

  function brokerError(error) {
    var value = String(error || "")
    if (value.indexOf("permission") >= 0 || value.indexOf("denied") >= 0)
      return "Permission denied"
    if (value.indexOf("unavailable") >= 0)
      return "No selected audio device is available"
    return Model.elideError(value || "The device provider did not respond")
  }

  function refresh() {
    if (observationInFlight) return false
    observationInFlight = true
    observeCall = runtime.invoke("device.observe", "observe", {
      demandScope: '{"fields":["identity","connection","battery","supported-controls","listening-mode","adaptive-level","conversation-awareness","one-bud-anc","ear-detection","case-lid"],"resourceClass":"paired-audio-device","selection":"user-selected"}',
      payload: {fields: ["identity", "connection", "battery", "supported-controls", "listening-mode", "adaptive-level", "conversation-awareness", "one-bud-anc", "ear-detection", "case-lid"]}
    })
    observeCorrelation = observeCall ? observeCall.correlation : 0
    if (observeCall && observeCall.finished) finishObserve(observeCall)
    return true
  }

  function finishObserve(call) {
    if (!observationInFlight || !call || call !== observeCall) return
    observationInFlight = false
    observeCall = null
    observeCorrelation = 0
    if (!call.ok) { stateGone(); lastError = brokerError(call.error); return }
    applyObservation(call.utf8Text)
  }

  function applyObservation(raw) {
    var status = Model.parseDeviceObservation(raw)
    if (!status.ok) {
      daemonReachable = false
      connected = false
      lastError = status.lastError
      return
    }
    daemonReachable = true
    schemaUnsupported = false
    lastError = ""
    applyStatus(status)
  }

  function stateGone() {
    daemonReachable = false
    connected = false
    schemaUnsupported = false
    lastError = ""
  }

  function applyStatus(status) {
    connected = status.connected
    deviceName = status.deviceName
    modelName = status.modelName
    isProSeries = status.isProSeries
    isHeadset = status.isHeadset
    supportsNoiseOff = status.supportsNoiseOff
    supportsNoiseControl = status.supportsNoiseControl
    supportsAdaptive = status.supportsAdaptive
    supportsConversationalAwareness = status.supportsConversationalAwareness
    supportsOneBudANC = status.supportsOneBudANC
    var controls = ["set-ear-detection"]
    if (status.supportsNoiseControl) controls.push("set-listening-mode")
    if (status.supportsAdaptive) controls.push("set-adaptive-level")
    if (status.supportsConversationalAwareness) controls.push("set-conversation-awareness")
    if (status.supportsOneBudANC) controls.push("set-one-bud-anc")
    supportedControls = controls
    leftPod = status.left
    rightPod = status.right
    caseBattery = status.caseBattery
    headsetBattery = status.headset
    lidState = status.lidState

    noiseMode = _settle("noiseMode", status.noiseMode)
    adaptiveNoiseLevel = _settle("adaptiveNoiseLevel", status.adaptiveNoiseLevel)
    oneBudANC = _settle("oneBudANC", status.oneBudANC)
    conversationalAwareness = _settle("conversationalAwareness", status.conversationalAwareness)
    earDetectionBehavior = _settle("earDetectionBehavior", status.earDetectionBehavior)
  }

  function _settle(field, reported) {
    if (_pendingValues[field] === undefined) return reported
    if (reported === _pendingValues[field]) {
      _clearPending(field)
      return reported
    }
    return _pendingValues[field]
  }

  function _setPending(field, value) {
    var next = Object.assign({}, _pendingValues)
    next[field] = value
    _pendingValues = next
    settleTimer.restart()
  }

  function _clearPending(field) {
    if (field === undefined) {
      _pendingValues = ({})
      settleTimer.stop()
      return
    }
    var next = Object.assign({}, _pendingValues)
    delete next[field]
    _pendingValues = next
    if (Object.keys(next).length === 0) settleTimer.stop()
  }

  function _send(verb, field, optimistic) {
    var operation = controlOperation(verb)
    if (operation.name === "" || !canControl(operation.name)) {
      actionStatus = "This control is unavailable"
      actionStatusTimer.restart()
      return
    }
    _setPending(field, optimistic)
    root[field] = optimistic
    var call = runtime.invoke("device.control", "control", {
      demandScope: '{"controls":["set-listening-mode","set-adaptive-level","set-conversation-awareness","set-one-bud-anc","set-ear-detection"],"resourceClass":"paired-audio-device","selection":"same-as:device.observe"}',
      payload: {control: operation.name, value: operation.value}
    })
    if (!call) {
      _clearPending(field)
      return
    }
    _controlSerial += 1
    var latest = Object.assign({}, _latestControls)
    latest[field] = _controlSerial
    _latestControls = latest
    var next = controlCalls.slice()
    next.push({call: call, field: field, serial: _controlSerial})
    controlCalls = next
    if (call.finished) finishControl(call)
  }

  function finishControl(call) {
    var index = -1
    for (var i = 0; i < controlCalls.length; i++) {
      if (controlCalls[i].call === call) { index = i; break }
    }
    if (!call || index < 0) return
    var completed = controlCalls[index]
    var next = controlCalls.slice()
    next.splice(index, 1)
    controlCalls = next
    if (_latestControls[completed.field] !== completed.serial) return
    if (!call.ok) {
      _clearPending(completed.field)
      actionStatus = brokerError(call.error)
      actionStatusTimer.restart()
      refresh()
      return
    }
    actionStatus = "Applied"
    actionStatusTimer.restart()
    refresh()
  }

  function controlOperation(verb) {
    if (verb.indexOf("noise:") === 0)
      return {name: "set-listening-mode", value: verb.slice(6)}
    if (verb.indexOf("adaptive:") === 0)
      return {name: "set-adaptive-level", value: parseInt(verb.slice(9), 10)}
    if (verb === "ca:on" || verb === "ca:off")
      return {name: "set-conversation-awareness", value: verb === "ca:on"}
    if (verb === "onebud:on" || verb === "onebud:off")
      return {name: "set-one-bud-anc", value: verb === "onebud:on"}
    if (verb === "ear:one") return {name: "set-ear-detection", value: "pause-one-out"}
    if (verb === "ear:both") return {name: "set-ear-detection", value: "pause-both-out"}
    if (verb === "ear:off") return {name: "set-ear-detection", value: "disabled"}
    return {name: "", value: ""}
  }

  // Guards the bar's right click too, not just the panel rows.
  function setNoiseMode(mode) {
    if (!canControl("set-listening-mode") || availableModes().indexOf(mode) < 0) return
    _send(Model.noiseModeVerb(mode), "noiseMode", mode)
  }

  function availableModes() {
    return Model.availableModes(supportsNoiseControl, supportsNoiseOff, supportsAdaptive)
  }

  function cycleNoiseMode() {
    if (!hasAirPods) return
    var modes = availableModes()
    if (modes.length === 0) return
    var at = modes.indexOf(noiseMode)
    // An unknown current mode has no next one, so start at the head instead of past it.
    setNoiseMode(at < 0 ? modes[0] : modes[(at + 1) % modes.length])
  }

  function setAdaptiveNoiseLevel(level) {
    if (!canControl("set-adaptive-level")) return
    var clamped = Math.max(0, Math.min(100, Math.round(level)))
    _send("adaptive:" + clamped, "adaptiveNoiseLevel", clamped)
  }

  function setConversationalAwareness(enabled) {
    if (!canControl("set-conversation-awareness")) return
    _send(enabled ? "ca:on" : "ca:off", "conversationalAwareness", enabled)
  }

  function setOneBudANC(enabled) {
    if (!canControl("set-one-bud-anc")) return
    _send(enabled ? "onebud:on" : "onebud:off", "oneBudANC", enabled)
  }

  function setEarDetectionBehavior(behavior) {
    if (!canControl("set-ear-detection")) return
    _send(Model.earDetectionVerb(behavior), "earDetectionBehavior", behavior)
  }

  function cycleEarDetection() {
    setEarDetectionBehavior((earDetectionBehavior + 1) % Model.EAR_BEHAVIOR_COUNT)
  }

  Qml.Timer {
    // Bounds the optimistic hold, and re-reads because a verb that changed nothing
    // leaves the daemon's file untouched, so no watch fires to correct the display.
    id: settleTimer
    interval: root.settleHoldMs
    repeat: false
    onTriggered: { root._clearPending(); root.refresh() }
  }

  Qml.Timer {
    id: actionStatusTimer
    interval: root.actionStatusMs
    repeat: false
    onTriggered: root.actionStatus = ""
  }

  Qml.Timer {
    interval: root.observationIntervalMs
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Qml.Timer { interval: 0; running: true; repeat: false; onTriggered: root.refresh() }
  Qml.Connections {
    target: runtime
    function onCallFinished(call) {
      if (root.observationInFlight && call && call === root.observeCall)
        root.finishObserve(call)
      else if (call) root.finishControl(call)
    }
  }
}
