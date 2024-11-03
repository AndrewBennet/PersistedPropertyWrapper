import Foundation

extension UserDefaults {
    nonisolated(unsafe) static let testing: UserDefaults = {
        let defaults = UserDefaults(suiteName: #file)!
        defaults.removePersistentDomain(forName: #file)
        return defaults
    }()
}
