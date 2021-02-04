import SwiftUI

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension Persisted: DynamicProperty {
    public var binding: Binding<Exposed> {
        Binding(
            get: {
                self.wrappedValue
            },
            set: {
                self.wrappedValue = $0
            }
        )
    }
}
