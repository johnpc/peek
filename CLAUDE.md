# peek

A native iOS remote-desktop client that works like macOS **Screen Sharing**: find
Macs on the network, sign in, see their screen, and control them by touch. It
speaks VNC/RFB (what Screen Sharing serves on port 5900), so it connects to any
VNC server, but the Mac in the other room is the point.

## How we work together (read this first)

The person directing you may be **non-technical** — an "idea guy" who owns the
**product**. They define **WHAT**: features, intent, and Gherkin acceptance
scenarios. **You own the HOW**: architecture, code quality, testing, and every
technical decision below.

- **Never ask them to make a technical call.** Don't surface coverage numbers,
  CRAP, lint, file-length, or library choices as questions. Decide them yourself,
  to the standards in this file, silently.
- **Translate vague ideas into Gherkin.** When they describe a feature, propose
  concrete `.feature` scenarios (Given/When/Then) and confirm those — that's the
  spec you build to.
- **Only escalate genuine _product_ questions** — ambiguous behavior, scope, copy,
  what a screen should do. Those are theirs. Everything technical is yours.

## Workflow: specs-first vertical slices

Every feature ships as one **thin vertical slice** — view + logic helper + store
+ tests, just enough for the scenario, nothing speculative.

1. **Spec first.** Write/confirm Gherkin scenarios as `.feature` files in
   `peekUITests/Features/` (the source of truth), executed by the native Swift
   runner (`GherkinParser` + `StepDefinitions` + `StepRegistry`). Reuse existing
   step phrasings — each line must match exactly one definition; a new phrasing
   needs a new regex definition in `StepDefinitions.swift`. Then regenerate and
   commit `AcceptanceTests.generated.swift`:
   `python3 scripts/generate_acceptance_tests.py`. See `AcceptanceTests.md`.
2. **Implement to pass the spec** — follow the architecture below.
3. **Run the full quality gate** and get it green (`bash scripts/quality.sh`).
4. **Conventional commit, push, CI green.** Open a PR; CI blocks the merge.

## Stack

- **Client:** SwiftUI, iOS 26+, Swift 5 language mode with main-actor default
  isolation. UIKit only where SwiftUI can't do the job (gesture recognizers,
  the invisible key-input responder).
- **Remote desktop engine:** [RoyalVNCKit](https://github.com/royalapplications/royalvnc)
  (MIT, Swift Package). RFB with Apple Remote Desktop / VNC / no-auth security
  types and Tight/ZRLE/Zlib/Hextile encodings. The whole app talks to it only
  through the `RemoteDesktop` protocol (`peek/Remote/RemoteDesktop.swift`).
- **Discovery:** Bonjour `_rfb._tcp` via Network.framework (`BonjourBrowser`).
- **Secrets:** host passwords in the iOS keychain (`SystemKeychain`); host
  records as JSON in `UserDefaults`.
- **Backend:** none. Nothing leaves the phone except the VNC connection.
- **Tests:** Swift Testing (`@Test`) for logic; XCTest for view-render and
  Gherkin acceptance tests (XCUITest).

## Architecture (the one mental model that matters)

- **Views only render.** No fetching, no protocol handling, no math in a `View`.
- **Stores own state + side effects**: `HostStore` (saved computers + keychain),
  `DiscoveryStore` (nearby), `SettingsStore` (preferences), `VNCSession` (one
  live connection). All take injectable dependencies.
- **The `RemoteDesktop` seam.** `RoyalVNCDesktop` is production; `MockDesktop`
  paints its own screen and records inputs for unit + acceptance tests. The
  same goes for `HostBrowser` (`BonjourBrowser` / `MockBrowser`) and
  `KeychainStore` (`SystemKeychain` / `InMemoryKeychain`). `AppEnvironment`
  assembles the real set; `MockMode.environment` the fake one (`--uitest-mock`).
- **Pure logic in small structs/enums**: `ScreenGeometry` (view ↔ framebuffer
  pixels), `GestureLogic` (gesture → mouse events), `ModifierLogic` (sticky ⌘⌥⌃⇧),
  `ZoomState`, `ScrollAccumulator`, `FrameThrottle`, `HostDraft`, `DiscoveryLogic`,
  `RoyalBridge` (app types ↔ RoyalVNCKit types).
- **Threading:** RoyalVNCKit calls back on its own queues. The delegate
  extension is `nonisolated` and hops every callback to the main actor; nothing
  else in the app is off-main.

### Code organization

```
peek/App         peekApp, AppEnvironment (composition root), MockMode
peek/Models      SavedHost, DiscoveredHost
peek/Remote      RemoteDesktop protocol, RemoteState, RemoteInput, RemoteKey, KeySym
peek/Stores      HostStore, DiscoveryStore, SettingsStore
peek/Keychain    KeychainStore protocol, InMemoryKeychain, SystemKeychain
peek/Discovery   HostBrowser protocol + MockBrowser, BonjourBrowser, BonjourEndpoint, DiscoveryLogic
peek/Session     VNCSession (+Input), FrameThrottle, ModifierLogic, ScreenGeometry, ZoomState, …
peek/VNC         RoyalVNCDesktop (+Delegate), RoyalBridge, RoyalInput, MockDesktop, MockFrame
peek/Views       one file per screen/subview; HostDraft + HostListModel hold view-model logic
peekTests/       unit + view-render tests;  peekUITests/  Gherkin runner + Features/
```

## Quality gates (non-negotiable — CI + pre-commit enforce them)

Hard gates. **Enforce them yourself without asking** — when one fails, fix the
code, never the gate.

- **No force-unwraps in logic, no `as!`, no `try!` outside tests.**
- **Every source file ≤ 100 lines** (`scripts/check_file_lines.sh`). Over → split
  into a focused helper, subview or `Type+Feature.swift` extension. Never squeak
  under by deleting comments. **Never raise the limit.**
- **≥ 80% line coverage** across the app target (`scripts/coverage_check.py`).
  Fix by writing tests, never exclusions. The only intentionally thin spots are
  the RoyalVNCKit delegate hops and the live Bonjour resolver — keep them thin.
- **CRAP ≤ 15 per function** (`scripts/crap_check.py`).
- **Acceptance tests are always Gherkin** (`peekUITests/Features/*.feature`),
  executed by the native runner; generated methods must be in sync
  (`generate_acceptance_tests.py --check`).
- **Build must pass** for the app, unit, and UI-test targets.

### Honest e2e

Scenarios assert observable behaviour against the mock desktop: the remote
screen appears, the status reads "Connected", the sign-in sheet shows, and the
remote screen's accessibility value reports the **last input actually sent**
("click left at 640,400", "key esc", "hold ⌘") — never just that a screen opened.

## Definition of done

1. `bash scripts/quality.sh` green locally.
2. Gherkin scenario(s) added/updated (generated file regenerated) + unit tests.
3. Conventional commit, branch pushed, PR open, **CI green**.
4. README updated if user-facing behaviour changed.

## Conventions

- **Conventional commits** (`feat:`, `fix:`, `chore:`, `ci:`, `docs:` …).
- Inject dependencies (`UserDefaults`, `KeychainStore`, `HostBrowser`,
  `RemoteDesktopFactory`) rather than reaching for singletons.
- Throwaway scripts go in `/tmp`, not the repo.

## Building (no Xcode on the MacBook)

The MacBook only has Command Line Tools; the Mac mini (`john@johns-Mac-Mini.local`,
Xcode, `iPhone 17 Pro` simulator) is both the CI runner and the dev build box —
see the `mac-mini` skill. Edit locally, `rsync` to `~/repo/peek` on the mini,
run the gate there, detached, logging to a file.

```bash
bash scripts/quality.sh          # full gate: file lines + generated check + tests + coverage + CRAP + build
bash scripts/install-hooks.sh    # pre-commit hook = the same gate
xcodebuild test -scheme peek -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:peekTests -enableCodeCoverage YES -resultBundlePath TestResults.xcresult
```

## Key facts

- **Repo:** `johnpc/peek`. **Bundle id:** `com.johncorser.peek`. Team `JW5SC3NYUV`.
  `ITSAppUsesNonExemptEncryption=NO`. **App Store Connect:** app record
  "peek – Screen Sharing" (id 6834960831; the bare name "peek" is taken); internal
  TestFlight group "Team" gets every build automatically.
- **CI:** `.github/workflows/quality-gates.yml` on the self-hosted Mac mini
  runner (`actions-runner-peek`, label `mac-mini`): build → unit tests +
  coverage → CRAP → Gherkin acceptance; deploys to App Store Connect on push to
  `main`. Secrets: `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_CONTENT`, `TEAM_ID`.
- **Testing against a real Mac:** the mini has Screen Sharing on (port 5900,
  legacy VNC password + Apple Remote Desktop auth both enabled). From the
  simulator on the mini, connect to `127.0.0.1`.

## Decisions

- **RoyalVNCKit over a hand-rolled RFB client.** Apple Remote Desktop auth
  (DH + AES + MD5) and the encodings are fiddly and well-trodden there; our
  value is the iOS experience. Contained behind `RemoteDesktop` so it's swappable.
- **Modifier keysyms depend on the server** (`ModifierKeymap`): Apple Remote
  Desktop servers (detected because they ask for a username) get ⌘=`Hyper_L`,
  ⌥=`Meta_L`; everything else gets ⌘=`Super_L`, ⌥=`Alt_L`. Verified on a real
  Mac: `Meta_L` was NOT read as ⌘ (⌘L typed a literal "l"). RoyalVNCKit also
  remaps `Super_L`→`Hyper_L` / `Alt_L`→`Meta_L` itself when the server speaks
  RFB 003.889 (ARD), so both keymaps end up correct on a Mac; ours keeps the
  choice explicit and testable.
- **Discovery stores the resolved address AND the Bonjour service name.**
  Network.framework has no standalone resolver, so the address comes from a
  short TCP connection to the service (often IPv6 link-local with a `%en0`
  scope — keep it, it is required to route). At connect time Nearby hosts are
  re-resolved by name (`BonjourResolver`) and fall back to the saved address.
- **Sticky modifiers** (tap ⌘, then a key) instead of chords — you can't hold two
  keys on a touch keyboard.
- **The remote cursor is not drawn.** On a touchscreen the finger is the pointer.
- **No backend, no analytics, no accounts.** Passwords stay in the device keychain.
