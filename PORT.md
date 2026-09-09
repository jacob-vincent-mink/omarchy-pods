# Ward compatibility branch

This branch targets `jacob-vincent-mink/omarchy-pods:main`. The original daemon, model, controls and artwork stay in place. Ward runs the panel in a separate process. The service reads a selected status directory and calls the existing host-side `librepods-ctl` through five selectable command leaves.

## Setup and review

Build and install the daemon with the original `setup` command. This is an explicit host installation, not a plugin activation hook. Install the same built control binary at the manifest's stable path:

```bash
sudo install -m 755 daemon/build/librepods-ctl /usr/local/bin/librepods-ctl
```

For a different executable location, edit `sandbox.requests.exec.controls.executable` before review. The old inline `ctlPath` preference is replaced by this reviewed executable selection. It cannot redirect an already-approved command. Ward pins the executable bytes, so an updated control binary requires reapproval.

Review the installed plugin and approve its exact revision. Select `hideWhenDisconnected` for settings reads, select the host's `~/.local/state/librepods` directory read-only for the `status` slot, and choose the control leaves you want. The directory mount preserves the daemon's atomic replacement and file-change notifications; a single-file mount would retain the old inode. Each leaf is optional and independent:

- `noise-mode`: Off, Noise Cancellation, Transparency and Adaptive.
- `adaptive-level`: integer levels from 0 through 100.
- `conversation-awareness`: on or off.
- `one-bud-anc`: on or off.
- `ear-detection`: one bud out, both out, or never pause.

The panel requests no network, Bluetooth socket, host session bus, media socket, writable host files or persistent private storage. It cannot invoke connect, disconnect, forget, reopen, arbitrary verbs or extra arguments. The trusted daemon retains its normal Bluetooth and audio-profile responsibilities. The control program's acknowledgement means delivery, not confirmation that hardware applied the setting; the original status reconciliation remains authoritative.

Declining status access produces review guidance rather than claiming the daemon is stopped. A declined control uses the original bounded action-error display and clears the optimistic change. Hardware-dependent verification must distinguish a disconnected or unsupported device from a denied operation.

## Verification

The original daemon's 19 tests and the plugin's model checks pass. A temporary external trial ran the actual panel and service in Ward with synthetic status and the installed control executable pointed at a private daemon socket. It verified all five control families, denied access and forbidden arguments, read-only status, atomic replacement, file removal and recovery, unsupported schema feedback, keyboard noise selection, cursor navigation and Escape. Connected earbuds, headset battery and declined-status panels were rendered and inspected.

The original daemon and sandboxed widget are also installed on the live desktop. The panel reads the paired AirPods Pro 2 model and correctly reports the disconnected state. Physical listening-mode changes and fresh battery reports remain unverified until the earbuds are awake and connected. No Bluetooth profile changes were introduced by this port. Cross-plugin keyboard panel switching remains a Ward compatibility limitation, not a completed parity claim.
