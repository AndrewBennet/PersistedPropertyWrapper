import XCTest
@testable import PersistedPropertyWrapper

final class PersistedPropertyWrapperTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(PersistedPropertyWrapper().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
