import Foundation
import os.log

extension OSLog {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "PersistedPropertyWrapper"

    /// An OSLog for use in PersistedPropertyWrapper.
    static let log = OSLog(subsystem: subsystem, category: "PersistedPropertyWrapper")
}
