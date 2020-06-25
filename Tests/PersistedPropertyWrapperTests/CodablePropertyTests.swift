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
        XCTAssertEqual(defaultValue, ExampleStuct.withDefault)
        XCTAssertNil(ExampleStuct.optional)

        ExampleStuct.withDefault.integerValue += 1
        var defaultCopy = defaultValue
        defaultCopy.integerValue += 1
        XCTAssertEqual(defaultCopy, ExampleStuct.withDefault)

        ExampleStuct.optional = defaultCopy
        XCTAssertEqual(defaultCopy, ExampleStuct.optional)

        ExampleStuct.optional = nil
        XCTAssertEqual(nil, ExampleStuct.optional)
    }

    func testCodableInteger() {
        // This functionality relies on JSONEncoder being able to encode single values, which it can't do on iOS 12 or lower.
        if #available(iOS 13.0, *) {
            let defaultValue = CodableIntegerContainer.defaultValue
            XCTAssertEqual(defaultValue, CodableIntegerContainer.withDefault)
            XCTAssertNil(CodableIntegerContainer.optional)

            CodableIntegerContainer.withDefault += 1
            XCTAssertEqual(defaultValue + 1, CodableIntegerContainer.withDefault)

            CodableIntegerContainer.optional = defaultValue
            XCTAssertEqual(defaultValue, CodableIntegerContainer.optional)

            CodableIntegerContainer.optional = nil
            XCTAssertNil(CodableIntegerContainer.optional)
        }
    }

    static var allTests = [
        ("testCodableStorage", testCodableStorage)
    ]
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

    @Persisted(encodedDataKey: UserDefaultsKey.withDefaultValue.rawValue, defaultValue: .init())
    static var withDefault: ExampleStuct

    @Persisted(encodedDataKey: UserDefaultsKey.optional.rawValue)
    static var optional: ExampleStuct?
}

struct CodableIntegerContainer {
    static var defaultValue: Int { 123 }

    @Persisted(encodedDataKey: UserDefaultsKey.withDefaultValue.rawValue, defaultValue: defaultValue)
    static var withDefault: Int

    @Persisted(encodedDataKey: UserDefaultsKey.optional.rawValue)
    static var optional: Int?
}
