import Testing
import Foundation
@testable import PersistedPropertyWrapper

@Suite
struct DictionaryPropertyTests {
    @Persisted(UUID().uuidString, defaultValue: [.hello: .zero, .world: .one], storage: .testing)
    var rawKeyAndValueWithDefault: [StringEnumeration: IntegerEnumeration]

    @Persisted(UUID().uuidString, storage: .testing)
    var rawKeyAndValueOptional: [StringEnumeration: IntegerEnumeration]?

    @Test
    func testEnumStringStorage() {
        #expect(rawKeyAndValueWithDefault == [.hello: .zero, .world: .one])
        #expect(rawKeyAndValueOptional == nil)

        rawKeyAndValueWithDefault[.hello] = .one
        #expect(rawKeyAndValueWithDefault == [.hello: .one, .world: .one])

        rawKeyAndValueOptional = [:]
        #expect(rawKeyAndValueOptional == [:])

        rawKeyAndValueOptional?[.hello] = .zero
        #expect(rawKeyAndValueOptional == [.hello: .zero])

        rawKeyAndValueOptional = nil
        #expect(rawKeyAndValueOptional == nil)
    }
}
