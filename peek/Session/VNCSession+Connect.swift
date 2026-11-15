import Foundation

/// Connection lifecycle: resolve (for Nearby hosts), dial, retry, hang up.
extension VNCSession {
    /// Nearby hosts are re-resolved first (falling back to the saved address);
    /// everything else dials straight away.
    func connect() {
        // The previous frame stays on screen while reconnecting; a stale
        // picture beats a spinner, and the first update replaces it.
        credentialRequest = nil
        triedSavedPassword = false
        state = .connecting
        guard let resolver, let serviceName = host.serviceName else { return open(host) }
        Task { [weak self] in
            let resolved = await resolver.resolve(serviceName: serviceName)
            guard let self, self.state == .connecting else { return }
            var target = self.host
            if let resolved, resolved != target.hostname {
                target.hostname = resolved
                self.onAddressChanged?(resolved)
                self.log("\(self.host.displayName): resolved to \(resolved)")
            } else if resolved == nil {
                self.log("\(self.host.displayName): not found nearby, using \(target.address)")
            }
            self.open(target)
        }
    }

    func open(_ target: SavedHost) {
        log("\(host.displayName): connecting to \(target.address)")
        let desktop = makeDesktop(target)
        desktop.onEvent = { [weak self] event in self?.handle(event) }
        self.desktop = desktop
        desktop.connect()
    }

    /// Reconnect from a failure. After a rejected password the saved one is
    /// dropped so the user is asked again instead of looping.
    func retry() {
        if state.failure?.isAuthentication == true { savedPassword = nil }
        connect()
    }

    func disconnect() {
        desktop?.disconnect()
    }
}
