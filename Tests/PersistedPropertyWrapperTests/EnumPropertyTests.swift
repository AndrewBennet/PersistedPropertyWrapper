import XCTest
@testable import PersistedPropertyWrapper

final class EnumPropertyWrapperTests: XCTestCase {
    override func setUp() {
        super.setUp()
        for key in UserDefaultsKey.allCases {
            UserDefaults.standard.removeObject(forKey: key.rawValue)
        }
    }

    override func tearDown() {
       super.tearDown()
       for key in UserDefaultsKey.allCases {
           UserDefaults.standard.removeObject(forKey: key.rawValue)
       }
    }

    func testEnumStringStorage() {
        runEnumStorageTest(StringEnumeration.self)
    }

    func testEnumIntStorage() {
        runEnumStorageTest(IntegerEnumeration.self)
    }

    private func runEnumStorageTest<T>(_ type: T.Type) where T: RawRepresentable, T.RawValue: UserDefaultsPrimitive, T: CaseIterable {
        var container = PersistedEnumPropertyContainer<StringEnumeration>()
        let defaultValue = PersistedEnumPropertyContainer<StringEnumeration>.defaultValue
        XCTAssertEqual(defaultValue, container.withDefault)
        XCTAssertNil(container.optional)

        guard let otherValue = StringEnumeration.allCases.filter({ $0 != defaultValue }).first else {
            preconditionFailure()
        }
        container.withDefault = otherValue
        XCTAssertEqual(otherValue, container.withDefault)

        container.optional = otherValue
        XCTAssertEqual(otherValue, container.optional)

        container.optional = nil
        XCTAssertNil(container.optional)
    }

    static var allTests = [
        ("testEnumIntStorage", testEnumIntStorage),
        ("testEnumStringStorage", testEnumStringStorage)
    ]
}

struct PersistedEnumPropertyContainer<T> where T: RawRepresentable, T: CaseIterable, T.RawValue: UserDefaultsPrimitive {
    static var defaultValue: T {
        guard let firstCase = T.allCases.first else { preconditionFailure() }
        return firstCase
    }

    @Persisted(UserDefaultsKey.withDefaultValue.rawValue, defaultValue: defaultValue)
    var withDefault: T

    @Persisted(UserDefaultsKey.optional.rawValue)
    var optional: T?
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
