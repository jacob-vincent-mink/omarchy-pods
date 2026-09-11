# Ward compatibility branch

This branch targets `jacob-vincent-mink/omarchy-pods:main`. The original daemon, model, controls and artwork stay in place. Ward runs the panel in a separate process. The manifest declares the read-only host status directory `$XDG_STATE_HOME/librepods`; the service reads its approved mount and calls the existing host-side `librepods-ctl` through five selectable command leaves.

## Portable runtime

The same plugin revision can now run in Ward or explicit YOLO with Omarchy's shared runtime. The panel passes `bar.shell.runtime` to the service. `runtime.filesystemPath("status")` resolves the selected Ward mount or declared host directory; `qs.Plugin.Process` keeps the original `librepods-ctl` command through Omarchy's declared-command adapter. The plugin no longer parses Ward's private grants file or hardcodes `/bootstrap` and `/grants` paths.

YOLO trusts arbitrary same-account code and does not enforce Ward's selected command leaves. Installation provenance, not a downloaded manifest, selects this mode. The daemon and its Bluetooth/audio profile behavior are unchanged.

Production-code churn relative to original `main` falls from 32 to 25 changed lines compared with the prior Ward-only port (additions plus deletions; manifest, documentation and tests excluded). Fresh external private-display trials installed, enabled and opened this revision in both modes using disposable status data. Both displayed the same schema error for incomplete data and matching connected-earbud panels with synthetic 79%, 93% and 100% batteries for valid data. YOLO also saved its own display preference through the real shell IPC. This is current runtime/render evidence, not physical hardware control verification or a rerun of the earlier control matrix below.

## Setup and review

Build and install the daemon with the original `setup` command. This is an explicit host installation, not a plugin activation hook. Install the same built control binary at the manifest's stable path:

```bash
sudo install -m 755 daemon/build/librepods-ctl /usr/local/bin/librepods-ctl
```

For a different executable location, edit `sandbox.requests.exec.controls.executable` before review. The old inline `ctlPath` preference is replaced by this reviewed executable selection. It cannot redirect an already-approved command. Ward pins the executable bytes, so an updated control binary requires reapproval.

Review the installed plugin and approve its exact revision. The reviewer resolves `$XDG_STATE_HOME/librepods` against the host environment (normally `~/.local/state/librepods`) and shows that directory before approval. Allow or deny the declared `status` request; there is no user-entered folder field. Status access is required because a battery/status display has no useful data without it. The directory mount exposes the whole declared directory, preserves the daemon's atomic replacement and file-change notifications, and does not permit writes. An exact-file grant would need reapproval after the daemon replaces that file.

The equivalent CLI selection is `--read status`, never `--read status=/different/folder`. The `hideWhenDisconnected` own-setting read is optional; without it the plugin uses its built-in display default. Device controls are optional so the status panel can remain read-only. Each control leaf is independent:

- `noise-mode`: Off, Noise Cancellation, Transparency and Adaptive.
- `adaptive-level`: integer levels from 0 through 100.
- `conversation-awareness`: on or off.
- `one-bud-anc`: on or off.
- `ear-detection`: one bud out, both out, or never pause.

The panel requests no network, Bluetooth socket, host session bus, media socket, writable host files or persistent private storage. It cannot invoke connect, disconnect, forget, reopen, arbitrary verbs or extra arguments. The trusted daemon retains its normal Bluetooth and audio-profile responsibilities. The control program's acknowledgement means delivery, not confirmation that hardware applied the setting; the original status reconciliation remains authoritative.

Denying required status access prevents activation. A declined optional control uses the original bounded action-error display and clears the optimistic change. Hardware-dependent verification must distinguish a disconnected or unsupported device from a denied operation.

## Verification

The original daemon's 19 tests and the plugin's model checks passed during the earlier port trials. A temporary external trial ran the actual panel and service in Ward with synthetic status and the installed control executable pointed at a private daemon socket. It verified all five control families, denied access and forbidden arguments, read-only status, atomic replacement, file removal and recovery, unsupported schema feedback, keyboard noise selection, cursor navigation and Escape. Connected earbuds, headset battery and declined-status panels were rendered and inspected. Those trials used the earlier user-selected-path contract; they are not validation of this revision's declarative path and required-status admission.

The original daemon and sandboxed widget are also installed on the live desktop. The panel reads the paired AirPods Pro 2 model and correctly reports the disconnected state. Physical listening-mode changes and fresh battery reports remain unverified until the earbuds are awake and connected. No Bluetooth profile changes were introduced by this port. Cross-plugin keyboard panel switching remains a Ward compatibility limitation, not a completed parity claim.
