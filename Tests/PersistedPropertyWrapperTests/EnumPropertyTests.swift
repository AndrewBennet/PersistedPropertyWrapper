import Testing
import Foundation
@testable import PersistedPropertyWrapper

@Suite
struct EnumPropertyWrapperTests {
    @Persisted(UUID().uuidString, defaultValue: IntegerEnumeration.allCases.first!, storage: .testing)
    var intWithDefault: IntegerEnumeration

    @Persisted(UUID().uuidString, storage: .testing)
    var intOptional: IntegerEnumeration?

    @Persisted(UUID().uuidString, defaultValue: StringEnumeration.allCases.first!, storage: .testing)
    var stringWithDefault: StringEnumeration

    @Persisted(UUID().uuidString, storage: .testing)
    var stringOptional: StringEnumeration?

    @Test
    func testEnumStringStorage() {
        #expect(stringWithDefault == .hello)
        #expect(stringOptional == nil)

        stringWithDefault = .world
        #expect(stringWithDefault == .world)

        stringOptional = .world
        #expect(stringOptional == .world)

        stringOptional = nil
        #expect(stringOptional == nil)
    }

    @Test
    func testEnumIntStorage() {
        #expect(intWithDefault == .zero)
        #expect(intOptional == nil)

        intWithDefault = .two
        #expect(intWithDefault == .two)

        intOptional = .two
        #expect(intOptional == .two)

        intOptional = nil
        #expect(intOptional == nil)
    }
}

fileprivate extension UserDefaults {
    nonisolated(unsafe) static let testing: UserDefaults = {
        let defaults = UserDefaults(suiteName: #file)!
        defaults.removePersistentDomain(forName: #file)
        return defaults
    }()
}

enum IntegerEnumeration: Int, CaseIterable {
    case zero
    case one
    case two
}

enum StringEnumeration: String, CaseIterable {
    case hello
    case world
}
