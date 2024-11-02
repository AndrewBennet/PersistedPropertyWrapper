import Foundation
import os.log

/// A property wrapper that reads from and writes to a UserDefaults store.
/// Supports properties of the following types: those which can be natively stored in `UserDefaults`,
/// `RawRepresentable` types where the `RawType` is one which an be natively stored in `UserDefaults`, and any `Codable` type.
/// If you wish to use a persisted value in SwiftUI and have changes trigger view updates, use `@Persisted` instead.
@propertyWrapper
public struct Persisted<Exposed, NonOptionalExposed, Convertor>: Sendable
    where Convertor: PersistedStorageConvertor, Convertor.Exposed == NonOptionalExposed, Exposed: Sendable {
    // The use of the two generic arguments relating to Exposed is necessary as we want to be able to use this property wrapped
    // on properties of type Optional<T>, but also inspect the underlying type T. We cannot check whether a generic type is an
    // Optional<T>, so instead we provide two 'slots' for the types: the Exposed type (which may be optional), and the NonOptionalExposed
    // type. If Exposed is equal to Optional<T>, then NonOptionalExposed must be equal to T; otherwise NonOptionalExposed must
    // be equal to Exposed.

    /// The key under which the value is stored.
    let key: String
    /// A default value to be returned when the UserDefaults store does not contain any value for the given key.
    let defaultValue: Exposed
    /// The UserDefaults to read and write from and to. We mark this as `nonisolated(unsafe)` as documentation states that `UserDefaults` is threadsafe,
    /// but it is not marked as `Sendable`.
    nonisolated(unsafe) let storage: UserDefaults
    /// A convertor that can convert between the exposed and stored representations of the value.
    let valueConvertor: Convertor

    init(key: String, defaultValue: Exposed, valueConvertor: Convertor, storage: UserDefaults) {
        // We cannot check this condition at compile time. We only publicly expose valid initialisation
        // functions, but to be safe let's check at runtime that the types are correct.
        guard Exposed.self == Convertor.Exposed.self || Exposed.self == Optional<Convertor.Exposed>.self else {
            preconditionFailure("Invalid Persisted generic arguments")
        }
        self.key = key
        self.defaultValue = defaultValue
        self.valueConvertor = valueConvertor
        self.storage = storage
    }

    /// Getting this property will lookup the value from UserDefaults; setting will write the value to UserDefaults.
    public var wrappedValue: Exposed {
        get {
            // Get the object stored for the given key, and cast it to the Stored type. If the object is present but
            // not castable, this is a fatal error.
            guard let typelessStored = storage.value(forKey: key) else { return defaultValue }
            guard let stored = typelessStored as? Convertor.Persisted else {
                os_log("Value stored at key %{public}s was not of type %{public}s", log: .log, type: .error, key, String(describing: Convertor.Persisted.self))
                return defaultValue
            }
            guard let nonOptionalExposed = valueConvertor.convertToExposedType(stored) else {
                os_log("Value stored at key %{public}s could not be converted to type %{public}s", log: .log, type: .error, key, String(describing: Convertor.Persisted.self))
                return defaultValue
            }
            
            // Since Exposed is either the same as NonOptionalExposed, or equal to Optional<NonOptionalExposed>,
            // this cast will always succeed.
            return nonOptionalExposed as! Exposed
        }
        nonmutating set {
            // Setting to nil is taken as an instruction to remove the object from the UserDefaults.
            if let optional = newValue as? AnyOptional, optional.isNil {
                storage.removeObject(forKey: key)
                return
            }
            
            // Since we know that the object is not nil, it must be castable to the non-optional type.
            let nonOptionalNewValue = newValue as! NonOptionalExposed
            
            // Convert the value to a type which can be stored in UserDefaults, and then store it.
            let valueToStore = valueConvertor.convertToPersistentStorage(nonOptionalNewValue)
            storage.setValue(valueToStore, forKey: key)
        }
    }

    /** The raw `Persisted` that backs this property wrapper. */
    public var projectedValue: Persisted<Exposed, NonOptionalExposed, Convertor> { self }
}

// Enables a value of a generic type to be compared with nil, by first checking whether it conforms to this protocol.
// Thanks to https://www.swiftbysundell.com/articles/property-wrappers-in-swift/
private protocol AnyOptional {
    var isNil: Bool { get }
}

extension Optional: AnyOptional {
    var isNil: Bool { self == nil }
}

// MARK: Initialisers

public extension Persisted {
    init(_ key: String, defaultValue: Exposed, storage: UserDefaults = .standard) where Convertor == IdentityStorageConvertor<NonOptionalExposed>, Exposed == NonOptionalExposed {
        self.init(key: key, defaultValue: defaultValue, valueConvertor: .init(), storage: storage)
    }

    init(_ key: String, storage: UserDefaults = .standard) where Convertor == IdentityStorageConvertor<NonOptionalExposed>, Exposed == NonOptionalExposed? {
        self.init(key: key, defaultValue: nil, valueConvertor: .init(), storage: storage)
    }

    init(_ key: String, defaultValue: Exposed, storage: UserDefaults = .standard)  where Convertor == RawRepresentableStorageConvertor<NonOptionalExposed>, NonOptionalExposed: RawRepresentable, Exposed == NonOptionalExposed {
        self.init(key: key, defaultValue: defaultValue, valueConvertor: RawRepresentableStorageConvertor(), storage: storage)
    }

    init(_ key: String, storage: UserDefaults = .standard) where Convertor == RawRepresentableStorageConvertor<NonOptionalExposed>, NonOptionalExposed: RawRepresentable, Exposed == NonOptionalExposed? {
        self.init(key: key, defaultValue: nil, valueConvertor: RawRepresentableStorageConvertor(), storage: storage)
    }

    // Note the different parameter name in the following: encodedDataKey vs unnamed. This is reqired since some Codable types
    // are also UserDefaultsPrimitive or RawRepresentable. We need a different key to be able to avoid ambiguity.
    init(encodedDataKey key: String, defaultValue: Exposed, storage: UserDefaults = .standard) where Convertor == CodableStorageConvertor<NonOptionalExposed>, Exposed == NonOptionalExposed {
        self.init(key: key, defaultValue: defaultValue, valueConvertor: CodableStorageConvertor(), storage: storage)
    }

    init(encodedDataKey key: String, storage: UserDefaults = .standard) where Convertor == CodableStorageConvertor<NonOptionalExposed>, Exposed == NonOptionalExposed? {
        self.init(key: key, defaultValue: nil, valueConvertor: CodableStorageConvertor(), storage: storage)
    }

    // Note the different parameter name in the following: archivedDataKey vs encodedDataKey vs unnamed. This is reqired since some
    // NSSecureCoding types are also UserDefaultsPrimitive or RawRepresentable. We need a different key to be able to avoid ambiguity.
    init(archivedDataKey key: String, defaultValue: Exposed, storage: UserDefaults = .standard) where Convertor == ArchivedDataStorageConvertor<NonOptionalExposed>, Exposed == NonOptionalExposed {
        self.init(key: key, defaultValue: defaultValue, valueConvertor: ArchivedDataStorageConvertor(), storage: storage)
    }

    init(archivedDataKey key: String, storage: UserDefaults = .standard) where Convertor == ArchivedDataStorageConvertor<NonOptionalExposed>, Exposed == NonOptionalExposed? {
        self.init(key: key, defaultValue: nil, valueConvertor: ArchivedDataStorageConvertor(), storage: storage)
    }
}
