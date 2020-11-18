import Foundation

/// A utility which can convert between an exposed type and a type which can be stored in `UserDefaults`.
public protocol PersistedStorageConvertor {
    associatedtype Exposed
    associatedtype Persisted: UserDefaultsPrimitive

    func convertToPersistentStorage(_ exposedValue: Exposed) -> Persisted
    func convertToExposedType(_ persistedValue: Persisted) -> Exposed
}

/// A storage convertor which performs no conversions.
public struct IdentityStorageConvertor<Exposed>: PersistedStorageConvertor where Exposed: UserDefaultsPrimitive {
    public func convertToExposedType(_ persistedValue: Exposed) -> Exposed {
        return persistedValue
    }

    public func convertToPersistentStorage(_ exposedValue: Exposed) -> Exposed {
        return exposedValue
    }
}

/// Maps between `RawRepresentable` values and their underlying `RawValues`
public struct RawRepresentableStorageConvertor<Exposed>: PersistedStorageConvertor where Exposed: RawRepresentable, Exposed.RawValue: UserDefaultsPrimitive {
    public func convertToExposedType(_ persistedValue: Exposed.RawValue) -> Exposed {
        return Exposed(rawValue: persistedValue)!
    }

    public func convertToPersistentStorage(_ exposedValue: Exposed) -> Exposed.RawValue {
        return exposedValue.rawValue
    }
}

/// Maps between any `Codable` value and `Data`
public struct CodableStorageConvertor<Exposed>: PersistedStorageConvertor where Exposed: Codable {
    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()

    public func convertToExposedType(_ persistedValue: Data) -> Exposed {
        return try! jsonDecoder.decode(Exposed.self, from: persistedValue)
    }

    public func convertToPersistentStorage(_ exposedValue: Exposed) -> Data {
        return try! jsonEncoder.encode(exposedValue)
    }
}

/// Maps between any `NSSecureCoding` conformant `NSObject` instance and `Data`
@available(macOS 10.13, iOS 11.0, watchOS 4.0, tvOS 11.0, *)
public struct ArchivedDataStorageConvertor<Exposed>: PersistedStorageConvertor where Exposed: NSObject, Exposed: NSSecureCoding {
    public func convertToExposedType(_ persistedValue: Data) -> Exposed {
        return try! NSKeyedUnarchiver.unarchivedObject(ofClass: Exposed.self, from: persistedValue)!
    }

    public func convertToPersistentStorage(_ exposedValue: Exposed) -> Data {
        return try! NSKeyedArchiver.archivedData(withRootObject: exposedValue, requiringSecureCoding: true)
    }
}
