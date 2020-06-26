import XCTest
@testable import PersistedPropertyWrapper

final class PrimitivePropertyWrapperTests: XCTestCase {
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

    func testIntegerStorage() {
        runPrimitiveStorageTest(Int.self) { $0 += 1 }
    }

    func testInt16Storage() {
        runPrimitiveStorageTest(Int16.self) { $0 += 1 }
    }

    func testInt32Storage() {
        runPrimitiveStorageTest(Int32.self) { $0 += 1 }
    }

    func testInt64Storage() {
        runPrimitiveStorageTest(Int64.self) { $0 += 1 }
    }

    func testStringStorage() {
        runPrimitiveStorageTest(String.self) { $0 += "World!" }
    }

    func testBoolStorage() {
        runPrimitiveStorageTest(Bool.self) { $0.toggle() }
    }

    func testDataStorage() {
        runPrimitiveStorageTest(Data.self) { $0.append("World!".data(using: .utf8)!) }
    }

    func testFloatStorage() {
        runPrimitiveStorageTest(Float.self) { $0.round(.up) }
    }

    func testDoubleStorage() {
        runPrimitiveStorageTest(Double.self) { $0.round(.down) }
    }

    private func runPrimitiveStorageTest<T>(_ type: T.Type, operation: (inout T) -> Void) where T: UserDefaultsPrimitive, T: Equatable {
        var container = PersistedPrimitivePropertyContainer<T>()
        let defaultValue = PersistedPrimitivePropertyContainer<T>.defaultValue
        XCTAssertEqual(defaultValue, container.withDefault)
        XCTAssertNil(container.optional)

        operation(&container.withDefault)
        var defaultValueCopy = defaultValue
        operation(&defaultValueCopy)
        XCTAssertEqual(defaultValueCopy, container.withDefault)

        container.optional = defaultValue
        XCTAssertEqual(defaultValue, container.optional)

        container.optional = nil
        XCTAssertNil(container.optional)
    }
}

struct PersistedPrimitivePropertyContainer<T> where T: UserDefaultsPrimitive {
    static var defaultValue: T {
        untypedtDefaultValue as! T
    }

    private static var untypedtDefaultValue: UserDefaultsPrimitive {
        if T.self == Int.self {
            return 42
        } else if T.self == Int16.self {
            return 42 as Int16
        } else if T.self == Int32.self {
           return 42 as Int32
        } else if T.self == Int64.self {
            return 42 as Int64
        } else if T.self == String.self {
            return "Hello"
        } else if T.self == Bool.self {
            return true
        } else if T.self == Data.self {
            return "Hello".data(using: .utf8)!
        } else if T.self == Float.self {
            return 99.9 as Float
        } else if T.self == Double.self {
            return 101.1 as Double
        } else {
            preconditionFailure()
        }
    }

    @Persisted(UserDefaultsKey.withDefaultValue.rawValue, defaultValue: defaultValue)
    var withDefault: T

    @Persisted(UserDefaultsKey.optional.rawValue)
    var optional: T?
}
