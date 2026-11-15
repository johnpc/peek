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
5. **Full keyboard bar.** Second row with F1–F12, media keys (volume, play,
   brightness), ⏏, and a few macro buttons (⌘Space Spotlight, ⌘Tab, ⌘Q, ⌘W,
   screenshot ⇧⌘4), with a "Mac actions" menu (Lock ⌃⌘Q, Log out ⇧⌘Q, Sleep
   display ⌃⇧⏏).
6. **Live thumbnail per saved Mac.** Last frame saved on disconnect and shown
   in the list; tells you at a glance which machine is which.
7. **Edge-swipe to reveal the toolbar** when it is tucked away.
8. **Shortcuts / URL scheme** (`peek://connect?host=…`) so a Home Screen
   shortcut or Siri opens straight into a Mac.
9. **Wake-on-LAN.** Optional MAC address per host; "Wake" button when the Mac
   is unreachable.
10. **Remote access away from home.** No relay of our own; document the Tailscale
    / VPN path in the app (a "Can't see your Mac?" help sheet) and make saved
    hosts work with Tailscale `.ts.net` names.

## Not planned (protocol-level, outside RoyalVNCKit)

Jump's Fluid / Screens' accelerated transport, RDP, SSH tunnelling, remote
audio, file transfer, multi-monitor selection beyond what the VNC server sends.
