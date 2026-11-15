# Roadmap

Ordered by value for the way peek is actually used (one Mac at home, phone or
iPad in hand) and by what RoyalVNCKit makes reachable. Work top to bottom; each
item ships as its own slice (spec → implement → gate → TestFlight).

## Next up

1. ~~**Clipboard sync (text).**~~ Shipped: Mac → device automatically (RoyalVNCKit
   writes server cut text to the pasteboard; peek shows "Copied from <Mac>").
   Device → Mac via the **Paste** key, which types the pasteboard (RoyalVNCKit
   exposes no public client-cut-text API), capped at 5,000 characters.
2. ~~**Three-finger swipes → macOS gestures.**~~ Shipped: left/right switch
   Spaces (⌃→/⌃←), up opens Mission Control (⌃↑), down shows App Exposé (⌃↓).
   (iPad trackpad swipes are reserved by iPadOS, so this is touch-only.)
3. ~~**Remote cursor.**~~ Shipped: the Mac's pointer image is drawn at the
   tracked pointer position, counter-scaled so it stays the same size when zoomed.
4. ~~**Touchpad mode.**~~ Shipped: toolbar toggle (remembered in Settings);
   drag moves the pointer at 1.5× finger speed, tap/double-tap click where it is,
   long-press-and-drag holds the button.
5. ~~**Full keyboard bar.**~~ Shipped: F1–F12 page and a Mac menu (Spotlight,
   Switch App, Close Window, Quit, Force Quit, Screenshot to Clipboard, Lock
   Screen, Log Out). Media keys left out: macOS's VNC server ignores them.
6. ~~**Live thumbnail per saved Mac.**~~ Shipped: the last frame is saved as a
   small JPEG when you hang up and shown in the list row.
7. ~~**Edge-swipe to reveal the toolbar**~~ Shipped: swipe down (or tap) the top
   edge while the controls are hidden.
8. ~~**Shortcuts / URL scheme**~~ Shipped: `peek://connect?host=<name or address>`
   connects (or pre-fills the add form for an unknown address); the edit screen
   has "Share Shortcut Link". Follow-on (pending): add a "Mac mini" item to
   github.com/johnpc/shortcuts.
9. ~~**Wake-on-LAN.**~~ Dropped: sending a magic packet needs Apple's
   multicast-networking entitlement (approval required), and the Mac mini is
   set to never sleep. Revisit only if a Mac that sleeps shows up.
10. ~~**Remote access away from home.**~~ Shipped as a "Can't see your Mac?"
    help sheet (same network, Screen Sharing on, Local Network permission, add
    by address, Tailscale/VPN for remote). Tailscale names are plain hostnames
    and already work.

## Ideas not yet scheduled

- Observe-only mode (look without sending input) for checking on a long job.
- Curtain mode (blank the Mac's physical display while connected).
- Per-host color depth override.
- Haptic/sound options.

## Not planned (protocol-level, outside RoyalVNCKit)

Jump's Fluid / Screens' accelerated transport, RDP, SSH tunnelling, remote
audio, file transfer, multi-monitor selection beyond what the VNC server sends.

## 🔴 Follow-up: keyboard is broken on device (reported 2026-11-15)

John: "the keyboard in peek is totally borked" (on-device, after builds 5–11). Not yet
reproduced. Plan: reproduce on the simulator against the mini, fix, and **verify with
screenshots** of each keyboard state (system keyboard up, key bar visible, Mac menu page,
typing into Safari on the mini) attached to the PR. Suspects: KeyboardBar overlaying the
keyboard, focus loss on KeyInputView, key-bar paging, modifier keysyms.
