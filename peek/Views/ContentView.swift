import SwiftUI

struct ContentView: View {
    @StateObject private var model: HostListModel
    private let environment: AppEnvironment

    init(environment: AppEnvironment) {
        self.environment = environment
        _model = StateObject(wrappedValue: HostListModel(environment: environment))
    }

    var body: some View {
        NavigationStack {
            HostListView(hosts: environment.hosts, discovery: environment.discovery,
                         thumbnails: environment.thumbnails, model: model)
        }
        .sheet(item: $model.draft) { draft in
            HostEditorView(draft: draft, onSave: model.save) { model.draft = nil }
        }
        .sheet(isPresented: $model.showSettings) {
            SettingsView(settings: environment.settings)
        }
        .fullScreenCover(item: $model.session) { session in
            SessionView(session: session, settings: environment.settings, onClose: model.closeSession)
        }
        .onOpenURL { url in model.open(url) }
    }
}
