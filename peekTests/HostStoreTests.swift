import Foundation
import Testing
@testable import peek

struct HostStoreTests {
    private func makeStore(keychain: InMemoryKeychain = InMemoryKeychain()) -> (HostStore, UserDefaults) {
        let suite = "HostStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        defaults.removePersistentDomain(forName: suite)
        return (HostStore(defaults: defaults, keychain: keychain), defaults)
    }

    @Test func startsEmpty() {
        let (store, _) = makeStore()
        #expect(store.hosts.isEmpty)
    }

    @Test func saveAddsThenReplaces() {
        let (store, _) = makeStore()
        var host = SavedHost(name: "A", hostname: "a.local")
        store.save(host, password: nil)
        host.name = "B"
        store.save(host, password: nil)
        #expect(store.hosts.count == 1)
        #expect(store.hosts.first?.name == "B")
    }

    @Test func persistsAcrossInstances() {
        let keychain = InMemoryKeychain()
        let (store, defaults) = makeStore(keychain: keychain)
        store.save(SavedHost(name: "A", hostname: "a.local"), password: nil)
        let reloaded = HostStore(defaults: defaults, keychain: keychain)
        #expect(reloaded.hosts.map(\.name) == ["A"])
    }

    @Test func passwordStoredOnlyWhenRemembering() {
        let keychain = InMemoryKeychain()
        let (store, _) = makeStore(keychain: keychain)
        let forgetful = SavedHost(name: "A", hostname: "a.local", rememberPassword: false)
        store.save(forgetful, password: "pw")
        #expect(keychain.password(for: forgetful.id) == nil)
        #expect(store.password(for: forgetful) == nil)

        var remembering = forgetful
        remembering.rememberPassword = true
        store.save(remembering, password: "pw")
        #expect(store.password(for: remembering) == "pw")

        store.save(remembering, password: "")
        #expect(store.password(for: remembering) == "pw", "blank password leaves the stored one alone")

        store.save(forgetful, password: nil)
        #expect(keychain.password(for: forgetful.id) == nil, "turning remember off forgets the password")
    }

    @Test func rememberPasswordFlipsFlagAndStores() {
        let keychain = InMemoryKeychain()
        let (store, _) = makeStore(keychain: keychain)
        let host = SavedHost(name: "A", hostname: "a.local")
        store.save(host, password: nil)
        store.rememberPassword("later", for: host)
        #expect(store.hosts.first?.rememberPassword == true)
        #expect(keychain.password(for: host.id) == "later")
    }

    @Test func removeDropsHostAndPassword() {
        let keychain = InMemoryKeychain()
        let (store, _) = makeStore(keychain: keychain)
        let host = SavedHost(name: "A", hostname: "a.local", rememberPassword: true)
        store.save(host, password: "pw")
        store.save(SavedHost(name: "B", hostname: "b.local"), password: nil)
        store.remove(at: IndexSet(integer: 0))
        #expect(store.hosts.map(\.name) == ["B"])
        #expect(keychain.password(for: host.id) == nil)
    }

    @Test func ignoresCorruptDefaults() {
        let suite = "HostStoreTests.corrupt"
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        defaults.set(Data("nope".utf8), forKey: "peek.hosts")
        let store = HostStore(defaults: defaults, keychain: InMemoryKeychain())
        #expect(store.hosts.isEmpty)
    }
}

struct KeychainTests {
    @Test func inMemoryRoundTrip() {
        let keychain = InMemoryKeychain()
        let id = UUID()
        #expect(keychain.password(for: id) == nil)
        keychain.setPassword("a", for: id)
        #expect(keychain.password(for: id) == "a")
        keychain.removePassword(for: id)
        #expect(keychain.password(for: id) == nil)
    }

    @Test func systemKeychainRoundTrip() {
        let keychain = SystemKeychain(service: "com.johncorser.peek.tests")
        let id = UUID()
        #expect(keychain.password(for: id) == nil)
        keychain.setPassword("first", for: id)
        #expect(keychain.password(for: id) == "first")
        keychain.setPassword("second", for: id)
        #expect(keychain.password(for: id) == "second")
        keychain.removePassword(for: id)
        #expect(keychain.password(for: id) == nil)
    }
}

struct SettingsStoreTests {
    private func makeDefaults() -> UserDefaults {
        let suite = "SettingsStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    @Test func defaultsAndPersistence() {
        let defaults = makeDefaults()
        let settings = SettingsStore(defaults: defaults)
        #expect(settings.colorDepth == 24)
        #expect(settings.isShared)
        #expect(settings.isScalingEnabled)
        #expect(!settings.hasSeenGestureTips)
        settings.hasSeenGestureTips = true
        settings.colorDepth = 16
        settings.isShared = false
        settings.isScalingEnabled = false
        let reloaded = SettingsStore(defaults: defaults)
        #expect(reloaded.options == DesktopOptions(colorDepth: 16, isShared: false, isScalingEnabled: false))
        #expect(reloaded.hasSeenGestureTips)
    }

    @Test func rejectsUnknownDepth() {
        let defaults = makeDefaults()
        defaults.set(12, forKey: "peek.settings.colorDepth")
        #expect(SettingsStore(defaults: defaults).colorDepth == 24)
        #expect(SettingsStore.label(forDepth: 8) == "8-bit")
    }
}
