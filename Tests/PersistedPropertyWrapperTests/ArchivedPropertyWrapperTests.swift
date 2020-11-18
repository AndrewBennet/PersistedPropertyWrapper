import XCTest
@testable import PersistedPropertyWrapper

@available(iOS 11.0, *)
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
        XCTAssertEqual(PersistedObjectContainer.defaultValue, PersistedObjectContainer.persistedObjectWithDefault)
        
        XCTAssertNil(PersistedObjectContainer.persistedObjectWithoutDefault)
        let newObject = ExampleArchivableObject(propertyOne: 99, propertyTwo: "Another String")
        PersistedObjectContainer.persistedObjectWithoutDefault = newObject
        XCTAssertEqual(newObject, PersistedObjectContainer.persistedObjectWithoutDefault)
    }
}

@available(iOS 11.0, *)
struct PersistedObjectContainer {
    static var defaultValue = ExampleArchivableObject(propertyOne: 23, propertyTwo: "Test string")
    
    @Persisted(archivedDataKey: "persistedObject1")
    static var persistedObjectWithoutDefault: ExampleArchivableObject?
    
    @Persisted(archivedDataKey: "persistedObject2", defaultValue: defaultValue)
    static var persistedObjectWithDefault: ExampleArchivableObject
}

@available(iOS 11.0, *)
class ExampleArchivableObject: NSObject, NSSecureCoding {
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
