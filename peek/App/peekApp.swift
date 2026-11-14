import SwiftUI

@main
struct peekApp: App {
    private let environment: AppEnvironment

    init() {
        environment = MockMode.isEnabled() ? MockMode.environment() : AppEnvironment.live()
    }

    var body: some Scene {
        WindowGroup {
            ContentView(environment: environment)
        }
    }
}
