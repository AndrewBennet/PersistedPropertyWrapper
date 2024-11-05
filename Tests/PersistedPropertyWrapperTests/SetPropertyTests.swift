import Testing
import Foundation
@testable import PersistedPropertyWrapper

@Suite
struct SetPropertyTests {
    @Persisted(UUID().uuidString, defaultValue: [1, 2, 3], storage: .testing)
    var setWithDefault: Set<Int>

    @Persisted(UUID().uuidString, storage: .testing)
    var optionalSet: Set<Int>?

    @Persisted(UUID().uuidString, defaultValue: [.zero], storage: .testing)
    var rawRepresentabelSet: Set<IntegerEnumeration>

    @Test
    func testIntSetStorage() {
        #expect(setWithDefault == [1, 2, 3])
        #expect(optionalSet == nil)

        setWithDefault.insert(4)
        #expect(setWithDefault == [1, 2, 3, 4])

        optionalSet = [42]
        #expect(optionalSet == [42])

        optionalSet = nil
        #expect(optionalSet == nil)
    }

    @Test
    func testRawSetStorage() {
        #expect(rawRepresentabelSet == [.zero])

        rawRepresentabelSet.insert(.one)
        #expect(rawRepresentabelSet == [.zero, .one])

        rawRepresentabelSet = []
        #expect(rawRepresentabelSet == [])
    }
}
