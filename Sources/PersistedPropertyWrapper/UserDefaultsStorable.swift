import Foundation

/// A type that can be represented as a `persistedValue` that can be stored in `UserDefaults`..
public protocol UserDefaultsStorable {
    associatedtype Stored: UserDefaultsStorable

    init(storedValue: Stored)
    var storedValue: Stored { get }
}

/// A scalar type which can natively be stored in UserDefaults.
public protocol UserDefaultsScalar: UserDefaultsStorable {
    // Of course, any type that is natively storage in UserDefaults is also convertable to a native type
    // (via the identity conversion). We have to put the protocol conformance here rather than in an extension
    // due to Swift compiler constraints.
}

// The default implementation for UserDefaultsPrimitive to conform to UserDefaultsPrimitiveConvertable.
public extension UserDefaultsScalar where Stored == Self {
    init(storedValue: Self) {
        self = storedValue
    }

    var storedValue: Self { self }
}

// The native scalar UserDefaults types:
extension Int: UserDefaultsScalar {}
extension Int8: UserDefaultsScalar {}
extension Int16: UserDefaultsScalar {}
extension Int32: UserDefaultsScalar {}
extension Int64: UserDefaultsScalar {}
extension UInt: UserDefaultsScalar {}
extension UInt8: UserDefaultsScalar {}
extension UInt16: UserDefaultsScalar {}
extension UInt32: UserDefaultsScalar {}
extension UInt64: UserDefaultsScalar {}
extension String: UserDefaultsScalar {}
extension Bool: UserDefaultsScalar {}
extension Double: UserDefaultsScalar {}
extension Float: UserDefaultsScalar {}
extension Date: UserDefaultsScalar {}
extension Data: UserDefaultsScalar {}

/// We can store any array of a supported type in UserDefaults.
extension Array: UserDefaultsStorable where Element: UserDefaultsStorable {
    public init(storedValue: Array<Element.Stored>) {
        self = storedValue.map(Element.init(storedValue:))
    }

    public var storedValue: Array<Element.Stored> {
        map(\.storedValue)
    }
}

/// We can store dictionaries with string keys, and supported type values, in UserDefaults.
extension Dictionary: UserDefaultsStorable where Key: LosslessStringConvertible, Value: UserDefaultsStorable {
    public init(storedValue: Dictionary<String, Value.Stored>) {
        self = .init(uniqueKeysWithValues: storedValue.compactMap { (key, value) in
            guard let mappedKey = Key(key) else { return nil }
            return (mappedKey, Value(storedValue: value))
        })
    }

    public var storedValue: Dictionary<String, Value.Stored> {
        .init(uniqueKeysWithValues: map { ($0.key.description, $0.value.storedValue )})
    }
}

/// Sets can be represented as arrays in UserDefaults, where the element type can be stored.
extension Set: UserDefaultsStorable where Element: UserDefaultsStorable {
    public init(storedValue: [Element.Stored]) {
        self = Set(storedValue.map(Element.init(storedValue:)))
    }

    public var storedValue: [Element.Stored] {
        map(\.storedValue)
    }
}
