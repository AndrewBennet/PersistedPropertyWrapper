#if canImport(SwiftUI) && (!os(iOS) || arch(arm64))
import SwiftUI

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension Persisted: DynamicProperty { }

#endif
