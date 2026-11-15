import Foundation
import Network

/// Turns transport errors into one plain sentence a person can act on. Falls
/// back to the library's own description for anything it doesn't recognise.
nonisolated enum FriendlyError {
    static let refused = "Nothing answered at that address. Is Screen Sharing turned on?"
    static let unreachable = "Couldn't reach the computer. Is it awake and on the same network?"
    static let notFound = "Couldn't find that address on the network."

    /// Walks the error (and its wrapped errors) looking for a network cause.
    static func message(for error: Error) -> String? {
        var seen: [Error] = [error]
        var queue: [Error] = [error]
        while let current = queue.first {
            queue.removeFirst()
            if let network = current as? NWError, let text = message(forNetwork: network) { return text }
            let nsError = current as NSError
            if nsError.domain == NSPOSIXErrorDomain, let text = message(forPOSIX: Int32(nsError.code)) { return text }
            for child in nestedErrors(of: current) where !seen.contains(where: { ($0 as NSError) == (child as NSError) }) {
                seen.append(child)
                queue.append(child)
            }
        }
        return nil
    }

    static func message(forNetwork error: NWError) -> String? {
        switch error {
        case .posix(let code): return message(forPOSIX: code.rawValue)
        case .dns: return notFound
        default: return nil
        }
    }

    static func message(forPOSIX code: Int32) -> String? {
        switch code {
        case ECONNREFUSED: return refused
        case ETIMEDOUT, EHOSTUNREACH, ENETUNREACH, EHOSTDOWN, ENETDOWN: return unreachable
        default: return nil
        }
    }

    /// Underlying errors reachable through `NSUnderlyingErrorKey` or a Swift
    /// enum payload (RoyalVNCKit wraps `NWError` inside its own cases).
    private static func nestedErrors(of error: Error) -> [Error] {
        var found: [Error] = []
        if let underlying = (error as NSError).userInfo[NSUnderlyingErrorKey] as? Error { found.append(underlying) }
        for child in Mirror(reflecting: error).children {
            if let nested = child.value as? Error { found.append(nested) }
            for grandchild in Mirror(reflecting: child.value).children {
                if let nested = grandchild.value as? Error { found.append(nested) }
            }
        }
        return found
    }
}
