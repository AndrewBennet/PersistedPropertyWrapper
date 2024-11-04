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

    static var convertor: Self { .init() }
}

/// Maps between `RawRepresentable` values and their underlying `RawValues`
public struct RawRepresentableStorageConvertor<Exposed>: PersistedStorageConvertor where Exposed: RawRepresentable, Exposed.RawValue: UserDefaultsPrimitive {
    public func convertToExposedType(_ persistedValue: Exposed.RawValue) -> Exposed? {
        return Exposed(rawValue: persistedValue)
    }

    public func convertToPersistentStorage(_ exposedValue: Exposed) -> Exposed.RawValue {
        return exposedValue.rawValue
    }

    static var convertor: Self { .init() }
}

/// Maps between a `Collection` of an exposed type and an `Array` of a persisted type, via another `PersistedStorageConvertor` applies to the elemnts.
public struct CollectionConvertor<Exposed: Collection, ElementConvertor: PersistedStorageConvertor>: PersistedStorageConvertor where Exposed.Element == ElementConvertor.Exposed {
    let elementConvertor: ElementConvertor
    let collectionInitialiser: @Sendable ([ElementConvertor.Exposed]) -> Exposed

    public func convertToExposedType(_ persistedValue: [ElementConvertor.Persisted]) -> Exposed? {
        return collectionInitialiser(persistedValue.compactMap(elementConvertor.convertToExposedType))
    }

    public func convertToPersistentStorage(_ exposedValue: Exposed) -> [ElementConvertor.Persisted] {
        return exposedValue.map(elementConvertor.convertToPersistentStorage)
    }
}

extension CollectionConvertor where Exposed == Array<ElementConvertor.Exposed> {
    init(elementConvertor: ElementConvertor) {
        self.init(elementConvertor: elementConvertor, collectionInitialiser: { $0 })
    }
}

/// Maps between some `Exposed` type and a `String` via a lossless string conversion.
public struct StringConvertor<Exposed>: PersistedStorageConvertor where Exposed: LosslessStringConvertible {
    public func convertToExposedType(_ persistedValue: String) -> Exposed? {
        return Exposed(persistedValue)
    }

    public func convertToPersistentStorage(_ exposedValue: Exposed) -> String {
        return exposedValue.description
    }

    static var convertor: Self { .init() }
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

    static var convertor: Self { .init() }
}

/// Maps between any `NSSecureCoding` conformant `NSObject` instance and `Data`
public struct ArchivedDataStorageConvertor<Exposed>: PersistedStorageConvertor where Exposed: NSObject, Exposed: NSSecureCoding {
    public func convertToExposedType(_ persistedValue: Data) -> Exposed? {
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: Exposed.self, from: persistedValue)
    }

    public func convertToPersistentStorage(_ exposedValue: Exposed) -> Data {
        return try! NSKeyedArchiver.archivedData(withRootObject: exposedValue, requiringSecureCoding: true)
    }

    static var convertor: Self { .init() }
}
