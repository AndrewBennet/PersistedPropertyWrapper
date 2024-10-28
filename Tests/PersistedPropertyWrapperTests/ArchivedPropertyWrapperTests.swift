import XCTest
@testable import PersistedPropertyWrapper

final class ArchivedPropertyWrapperTests: XCTestCase {
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

    func testAchivedObjectStorage() {
        let container = PersistedObjectContainer()
        XCTAssertEqual(PersistedObjectContainer.defaultValue, container.persistedObjectWithDefault)

        XCTAssertNil(container.persistedObjectWithoutDefault)
        let newObject = ExampleArchivableObject(propertyOne: 99, propertyTwo: "Another String")
        container.persistedObjectWithoutDefault = newObject
        XCTAssertEqual(newObject, container.persistedObjectWithoutDefault)
    }
}

struct PersistedObjectContainer {
    static let defaultValue = ExampleArchivableObject(propertyOne: 23, propertyTwo: "Test string")

    @Persisted(archivedDataKey: "persistedObject1")
    var persistedObjectWithoutDefault: ExampleArchivableObject?
    
    @Persisted(archivedDataKey: "persistedObject2", defaultValue: defaultValue)
    var persistedObjectWithDefault: ExampleArchivableObject
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
        propertyTwo = coder.decodeObject(forKey: "propertyTwo") as! String
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
