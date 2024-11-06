import Testing
import Foundation
@testable import PersistedPropertyWrapper

@Suite
struct PrimitivePropertyWrapperTests {
    @Test func testIntegerStorage() {
        runPrimitiveStorageTest(Int.self) { $0 += 1 }
    }

    @Test func testInt16Storage() {
        runPrimitiveStorageTest(Int16.self) { $0 += 1 }
    }

    @Test func testInt32Storage() {
        runPrimitiveStorageTest(Int32.self) { $0 += 1 }
    }

    @Test func testInt64Storage() {
        runPrimitiveStorageTest(Int64.self) { $0 += 1 }
    }

    @Test func testStringStorage() {
        runPrimitiveStorageTest(String.self) { $0 += "World!" }
    }

    @Test func testBoolStorage() {
        runPrimitiveStorageTest(Bool.self) { $0.toggle() }
    }

    @Test func testDataStorage() {
        runPrimitiveStorageTest(Data.self) { $0.append("World!".data(using: .utf8)!) }
    }

    @Test func testFloatStorage() {
        runPrimitiveStorageTest(Float.self) { $0.round(.up) }
    }

    @Test func testDoubleStorage() {
        runPrimitiveStorageTest(Double.self) { $0.round(.down) }
    }

    @Test func testDateStorage() {
        runPrimitiveStorageTest(Date.self) { $0.addTimeInterval(100000) }
    }

    private func runPrimitiveStorageTest<T>(_ type: T.Type, operation: (inout T) -> Void) where T: TestablePrimitive, T: Equatable {
        let container = PersistedPrimitivePropertyContainer<T>()
        #expect(T.defaultValue == container.withDefault)
        #expect(container.optional == nil)

        operation(&container.withDefault)
        var defaultValueCopy = T.defaultValue
        operation(&defaultValueCopy)
        #expect(defaultValueCopy == container.withDefault)

        container.optional = T.defaultValue
        #expect(T.defaultValue == container.optional)

        container.optional = nil
        #expect(container.optional == nil)
    }
}

protocol TestablePrimitive: UserDefaultsPrimitive & UserDefaultsStorable, Sendable {
    static var defaultValue: Self { get }
}

extension Int: TestablePrimitive {
    static var defaultValue: Self { 42 }
}

extension Int8: TestablePrimitive {
    static var defaultValue: Self { 42 }
}

extension Int16: TestablePrimitive {
    static var defaultValue: Self { 42 }
}

extension Int32: TestablePrimitive {
    static var defaultValue: Self { 42 }
}

extension Int64: TestablePrimitive {
    static var defaultValue: Self { 42 }
}

extension UInt: TestablePrimitive {
    static var defaultValue: Self { 42 }
}

extension UInt8: TestablePrimitive {
    static var defaultValue: Self { 42 }
}

extension UInt16: TestablePrimitive {
    static var defaultValue: Self { 42 }
}

extension UInt32: TestablePrimitive {
    static var defaultValue: Self { 42 }
}

extension UInt64: TestablePrimitive {
    static var defaultValue: Self { 42 }
}

extension String: TestablePrimitive {
    static var defaultValue: Self { "Hello" }
}

extension Bool: TestablePrimitive {
    static var defaultValue: Self { true }
}

extension Data: TestablePrimitive {
    static var defaultValue: Self { "Hello".data(using: .utf8)! }
}

extension Float: TestablePrimitive {
    static var defaultValue: Self { 99.9 }
}

extension Double: TestablePrimitive {
    static var defaultValue: Self { 101.1 }
}

extension Date: TestablePrimitive {
    static var defaultValue: Self { Date(timeIntervalSince1970: 1593197020) }
}

struct PersistedPrimitivePropertyContainer<T> where T: TestablePrimitive {
    @Persisted(UUID().uuidString, defaultValue: T.defaultValue)
    var withDefault: T

    @Persisted(UUID().uuidString)
    var optional: T?
}
