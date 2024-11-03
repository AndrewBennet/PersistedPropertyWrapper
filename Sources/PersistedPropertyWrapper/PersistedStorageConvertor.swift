import Foundation

/// A utility which can convert between an exposed type and a type which can be stored in `UserDefaults`.
public protocol PersistedStorageConvertor: Sendable {
    associatedtype Exposed
    associatedtype Persisted: UserDefaultsPrimitive

    func convertToPersistentStorage(_ exposedValue: Exposed) -> Persisted
    func convertToExposedType(_ persistedValue: Persisted) -> Exposed?
}

/// A storage convertor which performs no conversions.
public struct IdentityStorageConvertor<Exposed>: PersistedStorageConvertor where Exposed: UserDefaultsPrimitive {
    public func convertToExposedType(_ persistedValue: Exposed) -> Exposed? {
        return persistedValue
    }

    public func convertToPersistentStorage(_ exposedValue: Exposed) -> Exposed {
        return exposedValue
    }
}

/// Maps between `RawRepresentable` values and their underlying `RawValues`
public struct RawRepresentableStorageConvertor<Exposed>: PersistedStorageConvertor where Exposed: RawRepresentable, Exposed.RawValue: UserDefaultsPrimitive {
    public func convertToExposedType(_ persistedValue: Exposed.RawValue) -> Exposed? {
        return Exposed(rawValue: persistedValue)
    }

    public func convertToPersistentStorage(_ exposedValue: Exposed) -> Exposed.RawValue {
        return exposedValue.rawValue
    }
}

/// Maps between two forms of an `Array`, where the values are convertable via another `PersistedStorageConvertor`.
public struct ArrayConvertor<ElementConvertor: PersistedStorageConvertor>: PersistedStorageConvertor {
    let elementConvertor: ElementConvertor

    public func convertToExposedType(_ persistedValue: [ElementConvertor.Persisted]) -> [ElementConvertor.Exposed]? {
        return persistedValue.compactMap(elementConvertor.convertToExposedType)
    }

    public func convertToPersistentStorage(_ exposedValue: [ElementConvertor.Exposed]) -> [ElementConvertor.Persisted] {
        return exposedValue.map(elementConvertor.convertToPersistentStorage)
    }
}

/// Maps between two forms of a `Dictionary`, where the keys and values are convertable via other `PersistedStorageConvertor`s.
public struct DictionaryConvertor<KeyConvertor: PersistedStorageConvertor, ValueConvertor: PersistedStorageConvertor>: PersistedStorageConvertor
    where KeyConvertor.Exposed: Hashable, KeyConvertor.Persisted == String {

    public typealias Persisted = Dictionary<KeyConvertor.Persisted, ValueConvertor.Persisted>
    public typealias Exposed = Dictionary<KeyConvertor.Exposed, ValueConvertor.Exposed>

    let keyConvertor: KeyConvertor
    let valueConvertor: ValueConvertor

    public func convertToExposedType(_ persistedValue: Persisted) -> Exposed? {
        return Dictionary(uniqueKeysWithValues: persistedValue.compactMap {
            guard let exposedKey = keyConvertor.convertToExposedType($0.key),
                  let exposedValue = valueConvertor.convertToExposedType($0.value) else { return nil }
            return (exposedKey, exposedValue)
        })
    }

    public func convertToPersistentStorage(_ exposedValue: Exposed) -> Persisted {
        return Dictionary(uniqueKeysWithValues: exposedValue.compactMap {
            let persistedKey = keyConvertor.convertToPersistentStorage($0.key)
            let persistedValue = valueConvertor.convertToPersistentStorage($0.value)
            return (persistedKey, persistedValue)
        })
    }
}

/// Maps between any `Codable` value and `Data`
public struct CodableStorageConvertor<Exposed>: PersistedStorageConvertor where Exposed: Codable {
    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()

    public func convertToExposedType(_ persistedValue: Data) -> Exposed? {
        return try? jsonDecoder.decode(Exposed.self, from: persistedValue)
    }

    public func convertToPersistentStorage(_ exposedValue: Exposed) -> Data {
        return try! jsonEncoder.encode(exposedValue)
    }
}

/// Maps between any `NSSecureCoding` conformant `NSObject` instance and `Data`
public struct ArchivedDataStorageConvertor<Exposed>: PersistedStorageConvertor where Exposed: NSObject, Exposed: NSSecureCoding {
    public func convertToExposedType(_ persistedValue: Data) -> Exposed? {
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: Exposed.self, from: persistedValue)
    }

    public func convertToPersistentStorage(_ exposedValue: Exposed) -> Data {
        return try! NSKeyedArchiver.archivedData(withRootObject: exposedValue, requiringSecureCoding: true)
    }
}
