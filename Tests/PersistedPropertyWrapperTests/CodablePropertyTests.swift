import XCTest
@testable import PersistedPropertyWrapper

final class CodablePropertyWrapperTests: XCTestCase {
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

    func testCodableStorage() {
        let defaultValue = ExampleStuct()
        let codableStructContainer = CodableStructContainer()
        XCTAssertEqual(defaultValue, codableStructContainer.withDefault)
        XCTAssertNil(codableStructContainer.optional)

        codableStructContainer.withDefault.integerValue += 1
        var defaultCopy = defaultValue
        defaultCopy.integerValue += 1
        XCTAssertEqual(defaultCopy, codableStructContainer.withDefault)

        codableStructContainer.optional = defaultCopy
        XCTAssertEqual(defaultCopy, codableStructContainer.optional)

        codableStructContainer.optional = nil
        XCTAssertEqual(nil, codableStructContainer.optional)
    }

    func testCodableInteger() {
        let codableIntegerContainer = CodableIntegerContainer()

        let defaultValue = CodableIntegerContainer.defaultValue
        XCTAssertEqual(defaultValue, codableIntegerContainer.withDefault)
        XCTAssertNil(codableIntegerContainer.optional)

        codableIntegerContainer.withDefault += 1
        XCTAssertEqual(defaultValue + 1, codableIntegerContainer.withDefault)

        codableIntegerContainer.optional = defaultValue
        XCTAssertEqual(defaultValue, codableIntegerContainer.optional)

        codableIntegerContainer.optional = nil
        XCTAssertNil(codableIntegerContainer.optional)
    }
}

struct ExampleStuct: Codable, Equatable {
    enum ExampleEnum: String, Codable {
        case case1
        case case2
    }

    var enumValue: ExampleEnum
    var integerValue: Int
    var optionalIntegerValue: Int?
    var stringValue: String

    init() {
        enumValue = .case2
        integerValue = 55
        optionalIntegerValue = 99
        stringValue = "Hello world!"
    }
}

struct CodableStructContainer {
    @Persisted(encodedDataKey: UserDefaultsKey.withDefaultValue.rawValue, defaultValue: .init())
    var withDefault: ExampleStuct

    @Persisted(encodedDataKey: UserDefaultsKey.optional.rawValue)
    var optional: ExampleStuct?
}

struct CodableIntegerContainer {
    static let defaultValue = 123

    @Persisted(encodedDataKey: UserDefaultsKey.withDefaultValue.rawValue, defaultValue: defaultValue)
    var withDefault: Int

    @Persisted(encodedDataKey: UserDefaultsKey.optional.rawValue)
    var optional: Int?
}
