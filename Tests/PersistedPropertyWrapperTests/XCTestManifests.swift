import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(PrimitivePropertyWrapperTests.allTests),
        testCase(EnumPropertyWrapperTests.allTests),
        testCase(CodablePropertyWrapperTests.allTests)
    ]
}
#endif
