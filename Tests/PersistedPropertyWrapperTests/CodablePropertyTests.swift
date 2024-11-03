import Testing
import Foundation
@testable import PersistedPropertyWrapper

@Suite
struct CodablePropertyWrapperTests {
    @Persisted(encodedDataKey: UUID().uuidString, defaultValue: .init(), storage: .testing)
    var structWithDefault: ExampleStuct

    @Persisted(encodedDataKey: UUID().uuidString, storage: .testing)
    var structOptional: ExampleStuct?

    static let defaultIntValue = 123

    @Persisted(encodedDataKey: UUID().uuidString, defaultValue: defaultIntValue, storage: .testing)
    var intWithDefault: Int

    @Persisted(encodedDataKey: UUID().uuidString, storage: .testing)
    var intOptional: Int?

    @Test
    func testCodableStorage() {
        let defaultValue = ExampleStuct()
        #expect(defaultValue == structWithDefault)
        #expect(structOptional == nil)

        structWithDefault.integerValue += 1
        var defaultCopy = defaultValue
        defaultCopy.integerValue += 1
        #expect(defaultCopy == structWithDefault)

        structOptional = defaultCopy
        #expect(defaultCopy == structOptional)

        structOptional = nil
        #expect(structOptional == nil)
    }

    @Test
    func testCodableInteger() {
        #expect(Self.defaultIntValue == intWithDefault)
        #expect(intOptional == nil)

        intWithDefault += 1
        #expect(Self.defaultIntValue + 1 == intWithDefault)

        intOptional = Self.defaultIntValue
        #expect(Self.defaultIntValue == intOptional)

        intOptional = nil
        #expect(intOptional == nil)
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
