# Browser playback idle protection

This is a local clone of Omarchy's `omarchy.idle` service. It adds a browser MPRIS playback inhibitor.
The upstream files' hashes are recorded in `upstream.json`; packaged files are never modified.

- A playing browser cancels pending automatic screensaver and lock timers.
- Pause, exit or removal of the last playing browser restores the usual idle deadlines.
- If the compositor already considers the session idle, a full first timeout is allowed after playback stops.
- Manual Stay Awake and Wayland inhibition remain supported. Manual locking is unaffected.
- Only player identity and playback state are inspected, never media titles or URLs.
- Browser audio also inhibits; MPRIS does not reliably distinguish audio from video.
- Browser MPRIS integration must be enabled. An unsupported/non-reporting player is not detected.

Supported identities include Chromium/Chrome, Brave, Firefox, Zen, LibreWolf, Floorp, Vivaldi, Opera and Edge.
Standalone music players are intentionally excluded.

Enable from a normal desktop terminal:

```sh
~/dotfiles/scripts/enable-browser-idle
```

This rescans plugins, enables the clone through Omarchy's own registry, and verifies its status.
If status cannot be confirmed it switches back to `omarchy.idle`. It backs up shell.json before activation.
The clone uses `clonedFrom` metadata so disabling it restores the stock service and stable idle IPC remains available.

While a browser is playing or paused, inspect:

```sh
omarchy-shell idle status
```

`browserMediaPlaying` should track playback. To return to the stock service:

```sh
omarchy plugin enable omarchy.idle
```

In the agent's restricted environment, the desktop IPC/session bus cannot be reached, so this clone is installed
but is not enabled automatically. Run the enable command in the desktop session. Static QML checks and policy
unit tests pass; an actual playback test in that session is still needed.

Omarchy shell upgrades may change the original idle service. Compare the clone with the installed source
before carrying forward upstream changes, or remove this workaround once upstream inhibition is sufficient.
Upstream issue: https://github.com/omacom/omarchy/issues/6475
