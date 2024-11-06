import Foundation

/// A type that can be represented as a `persistedValue` that can be stored in `UserDefaults`..
public protocol UserDefaultsStorable {
    associatedtype Stored: UserDefaultsPrimitive

    init(storedValue: Stored)
    var storedValue: Stored { get }
}


// The default implementation for UserDefaultsPrimitive to conform to UserDefaultsPrimitiveConvertable.
public extension UserDefaultsStorable where Self: UserDefaultsPrimitive {
    init(storedValue: Self) {
        self = storedValue
    }

    var storedValue: Self { self }
}

// The native scalar UserDefaults types:
extension Int: UserDefaultsStorable {}
extension Int8: UserDefaultsStorable {}
extension Int16: UserDefaultsStorable {}
extension Int32: UserDefaultsStorable {}
extension Int64: UserDefaultsStorable {}
extension UInt: UserDefaultsStorable {}
extension UInt8: UserDefaultsStorable {}
extension UInt16: UserDefaultsStorable {}
extension UInt32: UserDefaultsStorable {}
extension UInt64: UserDefaultsStorable {}
extension String: UserDefaultsStorable {}
extension Bool: UserDefaultsStorable {}
extension Double: UserDefaultsStorable {}
extension Float: UserDefaultsStorable {}
extension Date: UserDefaultsStorable {}
extension Data: UserDefaultsStorable {}

/// We can store any array of a convertable type in UserDefaults.
extension Array: UserDefaultsStorable where Element: UserDefaultsStorable {
    public init(storedValue: Array<Element.Stored>) {
        self = storedValue.map(Element.init(storedValue:))
    }

    public var storedValue: Array<Element.Stored> {
        map(\.storedValue)
    }
}

/// We can store dictionaries with string-convertable keys, and supported type values, in UserDefaults.
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
