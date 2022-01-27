// This convoluted #if statement seems to be required (as of Xcode 13.2.1) to get this
// to build in 'Any iOS Device'. See https://stackoverflow.com/a/67853022/5513562
#if canImport(SwiftUI) && (!os(iOS) || arch(arm64))
import SwiftUI

// Enables changes to @Persisted attributed properties to trigger SwiftUI re-renders.
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension Persisted: DynamicProperty { }

#endif
