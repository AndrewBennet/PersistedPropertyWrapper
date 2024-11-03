import Testing
import Foundation
@testable import PersistedPropertyWrapper

@Suite
struct ArchivedPropertyWrapperTests {
    static let defaultValue = ExampleArchivableObject(propertyOne: 23, propertyTwo: "Test string")

    @Persisted(archivedDataKey: UUID().uuidString, storage: .testing)
    var persistedObjectWithoutDefault: ExampleArchivableObject?

    @Persisted(archivedDataKey: UUID().uuidString, defaultValue: defaultValue, storage: .testing)
    var persistedObjectWithDefault: ExampleArchivableObject

    @Test
    func testAchivedObjectStorage() {
        #expect(Self.defaultValue == persistedObjectWithDefault)
        #expect(persistedObjectWithoutDefault == nil)

        let newObject = ExampleArchivableObject(propertyOne: 99, propertyTwo: "Another String")
        persistedObjectWithoutDefault = newObject
        #expect(newObject == persistedObjectWithoutDefault)
    }
}

final class ExampleArchivableObject: NSObject, NSSecureCoding, Sendable {
    static func == (lhs: ExampleArchivableObject, rhs: ExampleArchivableObject) -> Bool {
        return lhs.propertyOne == rhs.propertyOne && lhs.propertyTwo == rhs.propertyTwo
    }

    static var supportsSecureCoding: Bool {
        return true
    }

    func encode(with coder: NSCoder) {
        coder.encode(propertyOne, forKey: "propertyOne")
        coder.encode(propertyTwo, forKey: "propertyTwo")
    }

    required init?(coder: NSCoder) {
        propertyOne = coder.decodeInteger(forKey: "propertyOne")
        propertyTwo = coder.decodeObject(of: NSString.self, forKey: "propertyTwo")! as String
    }

    init(propertyOne: Int, propertyTwo: String) {
        self.propertyOne = propertyOne
        self.propertyTwo = propertyTwo
    }

    let propertyOne: Int
    let propertyTwo: String

    override func isEqual(_ object: Any?) -> Bool {
        guard let comparison = object as? ExampleArchivableObject else { return false }
        return self == comparison
    }
}
