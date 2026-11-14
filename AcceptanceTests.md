# Acceptance Tests

The **source of truth for acceptance specs is the `.feature` files** in
[`peekUITests/Features/`](peekUITests/Features/). They are real Gherkin, parsed
and executed at runtime by a native Swift runner.

## How it works

- **`peekUITests/Features/*.feature`** — one feature per file, standard Gherkin
  (`Feature:` / `Scenario:` / `Given`/`When`/`Then`/`And`). Tags change the
  launch: `@saved-password` seeds the fixture host's password (connects without
  asking); `@no-hosts` starts with an empty list.
- **`GherkinParser.swift`** — dependency-free parser.
- **`StepDefinitions.swift`** — maps each step line (by regex, with captures) to
  an XCUITest action/assertion.
- **`StepRegistry.swift`** — registration + matching (undefined/ambiguous steps fail).
- **`AcceptanceTests.generated.swift`** — `@generated`: one `AcceptanceTests`
  subclass per feature file with one concrete `test…` per scenario. **Do not
  edit by hand.**

## Adding or changing a scenario

1. Edit (or add) a `.feature` file under `peekUITests/Features/`.
2. If a step is new, add a matching definition in `StepDefinitions.swift`.
3. Regenerate: `python3 scripts/generate_acceptance_tests.py`

A quality gate (`--check`, in `scripts/quality.sh` and CI) fails if the
generated file drifts from the features.

> **Reuse step phrasings.** Each step must match **exactly one** definition.

## Determinism

The app launches in mock mode (`--uitest-mock`): one saved computer
("Studio Mac", `studio.local`, user `john`, password `secret`), one nearby Mac
("John's Mac mini"), an in-memory keychain, and a `MockDesktop` that paints a
synthetic screen and records every input. The remote screen's accessibility
value is the last action sent (e.g. `click left at 640,400`, `key esc`,
`hold ⌘`), which is what the input scenarios assert on.

## Running

```bash
xcodebuild test -scheme peek \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro" \
  -only-testing:"peekUITests" -parallel-testing-enabled YES
```
