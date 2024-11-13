import Foundation

extension UserDefaults {
    /// See `UserDefaults` documentation:
    /// > Thread Safety: The UserDefaults class is thread-safe.
    /// Hence `nonisolated(unsafe)`.
    nonisolated(unsafe) static let testing: UserDefaults = {
        let defaults = UserDefaults(suiteName: #file)!
        defaults.removePersistentDomain(forName: #file)
        return defaults
    }()
}
