import Testing
import Foundation
@testable import PersistedPropertyWrapper

@Suite
struct DictionaryPropertyTests {
    @Persisted(UUID().uuidString, defaultValue: [.hello: .zero, .world: .one], storage: .testing)
    var rawKeyAndValueWithDefault: [StringEnumeration: IntegerEnumeration]

    @Persisted(UUID().uuidString, storage: .testing)
    var rawKeyAndValueOptional: [IntegerEnumeration: StringEnumeration]?

    @Test
    func testEnumStringStorage() {
        #expect(rawKeyAndValueWithDefault == [.hello: .zero, .world: .one])
        #expect(rawKeyAndValueOptional == nil)

        rawKeyAndValueWithDefault[.hello] = .one
        #expect(rawKeyAndValueWithDefault == [.hello: .one, .world: .one])

        rawKeyAndValueOptional = [:]
        #expect(rawKeyAndValueOptional == [:])

        rawKeyAndValueOptional?[.zero] = .hello
        #expect(rawKeyAndValueOptional == [.zero: .hello])

        rawKeyAndValueOptional = nil
        #expect(rawKeyAndValueOptional == nil)
    }
}
