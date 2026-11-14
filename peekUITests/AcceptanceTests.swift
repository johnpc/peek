import XCTest

/// Acceptance runner. The **source of truth is the `.feature` files** under
/// `peekUITests/Features/`. Each scenario maps to one concrete `test…` method in
/// `AcceptanceTests.generated.swift` (regenerated from the features by
/// `scripts/generate_acceptance_tests.py`). Every generated method delegates to
/// `runScenario(feature:scenario:)` below, which parses that feature at runtime
/// and executes its Given/When/Then steps against `StepDefinitions.swift`.
///
/// Concrete methods (rather than a fully dynamic suite) keep XCTest's
/// `-only-testing` filtering and crash recovery working; one subclass per
/// feature file lets CI's parallel simulators split the suite by class.
///
/// The app launches in mock mode (`--uitest-mock`): a fixture host, an
/// in-memory keychain, a fake Bonjour browser and a fake desktop. Tags:
/// `@saved-password` seeds the fixture host's password; `@no-hosts` starts empty.
class AcceptanceTests: XCTestCase {

    func runScenario(feature fileName: String, scenario name: String,
                     file: StaticString = #file, line: UInt = #line) {
        continueAfterFailure = false

        guard let scenario = Self.scenario(named: name, inFeature: fileName) else {
            XCTFail("Scenario “\(name)” not found in \(fileName) — regenerate with scripts/generate_acceptance_tests.py",
                    file: file, line: line)
            return
        }

        let app = XCUIApplication()
        // Launch-argument strings mirror MockMode in the app target (the UI-test
        // bundle doesn't link the app, so they're hardcoded here).
        var args = ["--uitest-mock"]
        if scenario.tags.contains("@saved-password") { args.append("--uitest-saved-password") }
        if scenario.tags.contains("@no-hosts") { args.append("--uitest-no-hosts") }
        app.launchArguments = args
        app.launch()

        let world = GherkinWorld(app: app)
        let registry = StepDefinitions.makeRegistry()

        for step in scenario.steps {
            XCTContext.runActivity(named: "\(step.keyword) \(step.text)") { _ in
                if registry.isAmbiguous(step.text) {
                    XCTFail("Ambiguous step matches multiple definitions: “\(step.text)” (\(name):\(step.line))",
                            file: file, line: line)
                    return
                }
                guard let run = registry.match(step.text) else {
                    XCTFail("Undefined step: “\(step.text)” — add a matching definition in StepDefinitions.swift (\(name):\(step.line))",
                            file: file, line: line)
                    return
                }
                run(world)
            }
        }
    }

    /// Locate and parse a scenario by name in a bundled `.feature` file. The file
    /// may be bundled flattened at the root or under a "Features" subdirectory.
    private static func scenario(named name: String, inFeature fileName: String) -> GherkinScenario? {
        let bundle = Bundle(for: AcceptanceTests.self)
        let resource = (fileName as NSString).deletingPathExtension
        let url = bundle.url(forResource: resource, withExtension: "feature")
            ?? bundle.url(forResource: resource, withExtension: "feature", subdirectory: "Features")
        guard let url, let contents = try? String(contentsOf: url, encoding: .utf8),
              let feature = GherkinParser.parse(contents) else { return nil }
        return feature.scenarios.first { $0.name == name }
    }
}
