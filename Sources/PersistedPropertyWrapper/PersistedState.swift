import Foundation
import Combine
import SwiftUI
import os.log

/// A property wrapper that reads from and writes to a UserDefaults store, and also monitors the `UserDefaults` for external changes, and triggers SwiftUI
/// view updates when any change occurs. Supports properties of the following types: those which can be natively stored in `UserDefaults`,
/// `RawRepresentable` types where the `RawType` is one which an be natively stored in `UserDefaults`, and any `Codable` type.
/// If you wish to use a persisted value in code outside of SwiftUI, or in code not on the Main Actor, use `@Persisted` instead, which is a simpler
/// and more lightweight wrapper around `UserDefaults`.
@MainActor
@propertyWrapper
public struct PersistedState<Exposed: Sendable, NonOptionalExposed: Sendable, Convertor>: DynamicProperty
    where Convertor: StorageConvertor, Convertor.Input == NonOptionalExposed, Exposed: Sendable {

    /// An object that watches `UserDefaults` for changes and publishes its values.
    @StateObject private var persistedObserver: PersistedObserver<Exposed, NonOptionalExposed, Convertor>

    // Initialiser is private so that we can selectively expose the overloads with/without default value parameter
    // depending on whether the exposed type is Optional.
    private init(key: String, defaultValue: Exposed, storage: UserDefaults) {
        self.init(PersistedObserver(persistedStorage: Persisted(key: key, defaultValue: defaultValue, storage: storage)))
    }

    private init(_ observer: @escaping @autoclosure () -> PersistedObserver<Exposed, NonOptionalExposed, Convertor>) {
        // We cannot check this condition at compile time. We only publicly expose valid initialisation
        // functions, but to be safe let's check at runtime that the types are correct.
        guard Exposed.self == Convertor.Input.self || Exposed.self == Optional<Convertor.Input>.self else {
            preconditionFailure("Invalid Persisted generic arguments")
        }
        self._persistedObserver = StateObject(wrappedValue: observer())
    }

    /// Getting this property will lookup the value from UserDefaults; setting will write the value to UserDefaults.
    public var wrappedValue: Exposed {
        get {
            return persistedObserver.persistedStorage.wrappedValue
        }
        nonmutating set {
            persistedObserver.persistedStorage.wrappedValue = newValue
        }
    }

    /// Returns a binding to the persisted value.
    public var projectedValue: Binding<Exposed> {
        Binding<Exposed>(
            get: { wrappedValue },
            set: { wrappedValue = $0 }
        )
    }

    /// A publisher that emits changes to the value of the `PersistedState`.
    public var valueChanged: AnyPublisher<Exposed, Never> {
        persistedObserver.eraseToAnyPublisher()
    }
}

// MARK: Initialisers

public extension PersistedState {
    /**
     Use this initialiser to initialise a `PersistedState` from a `@Persisted`'s projected value.
     
     For instance, given a `@Persisted` value:
```
     struct Settings {
       static let instance = Settings()

       @Persisted("mySetting", defaultValue: 0)
       var mySetting: Int
     }
```
     then reference the `@Persisted` value in the initialiser of a `@PersistedState` for use in a SwiftUI view:

```
     @PersistedState(Settings.instance.$mySetting)
     var mySetting: Int
```

     in order to automatically use the same `UserDefaults` store and key for the `@PersistedState`.
     */
    init(_ persistedValue: Persisted<Exposed, NonOptionalExposed, Convertor>) {
        self.init(PersistedObserver(persistedStorage: persistedValue))
    }

    // Simple

    init(_ key: String, defaultValue: Exposed, storage: UserDefaults = .standard) where Exposed == NonOptionalExposed,
        Convertor == IdentityConvertor<NonOptionalExposed> {
        self.init(key: key, defaultValue: defaultValue, storage: storage)
    }

    init(_ key: String, storage: UserDefaults = .standard) where Exposed == NonOptionalExposed?,
        Convertor == IdentityConvertor<NonOptionalExposed> {
        self.init(key: key, defaultValue: nil, storage: storage)
    }

    // RawRepresentable

    init(_ key: String, defaultValue: Exposed, storage: UserDefaults = .standard) where Exposed == NonOptionalExposed,
        Convertor == RawRepresentableConvertor<NonOptionalExposed> {
        self.init(key: key, defaultValue: defaultValue, storage: storage)
    }

    init(_ key: String, storage: UserDefaults = .standard) where Exposed == NonOptionalExposed?,
        Convertor == RawRepresentableConvertor<NonOptionalExposed> {
        self.init(key: key, defaultValue: nil, storage: storage)
    }

    // Array<RawRepresentable>

    init<Element>(_ key: String, defaultValue: Exposed, storage: UserDefaults = .standard) where Exposed == NonOptionalExposed,
        NonOptionalExposed == Array<Element>,
        Convertor == ArrayConvertor<RawRepresentableConvertor<Element>> {
        self.init(key: key, defaultValue: defaultValue, storage: storage)
    }

    init<Element>(_ key: String, storage: UserDefaults = .standard) where Exposed == NonOptionalExposed?,
        NonOptionalExposed == Array<Element>,
        Convertor == ArrayConvertor<RawRepresentableConvertor<Element>> {
        self.init(key: key, defaultValue: nil, storage: storage)
    }

    // Set<RawRepresentable>

    init<Element>(_ key: String, defaultValue: Exposed, storage: UserDefaults = .standard) where Exposed == NonOptionalExposed,
        NonOptionalExposed == Set<Element>,
        Convertor == SetConvertor<RawRepresentableConvertor<Element>> {
        self.init(key: key, defaultValue: defaultValue, storage: storage)
    }

    init<Element>(_ key: String, storage: UserDefaults = .standard) where Exposed == NonOptionalExposed?,
        NonOptionalExposed == Set<Element>,
        Convertor == SetConvertor<RawRepresentableConvertor<Element>> {
        self.init(key: key, defaultValue: nil, storage: storage)
    }

    // Dictionary<RawRepresentable<StringConvertable>, Simple>

    init<Key, Value>(_ key: String, defaultValue: Exposed, storage: UserDefaults = .standard) where Exposed == NonOptionalExposed,
        NonOptionalExposed == Dictionary<Key, Value>,
        Key: RawRepresentable, Key.RawValue: LosslessStringConvertible,
        Convertor == DictionaryConvertor<
            ComposedConvertor<StringConvertor<Key.RawValue>, RawRepresentableConvertor<Key>>,
            IdentityConvertor<Value>
        > {
        self.init(key: key, defaultValue: defaultValue, storage: storage)
    }

    init<Key, Value>(_ key: String, storage: UserDefaults = .standard) where Exposed == NonOptionalExposed?,
        NonOptionalExposed == Dictionary<Key, Value>,
        Key: RawRepresentable, Key.RawValue: LosslessStringConvertible,
        Convertor == DictionaryConvertor<
            ComposedConvertor<StringConvertor<Key.RawValue>, RawRepresentableConvertor<Key>>,
            IdentityConvertor<Value>
        > {
        self.init(key: key, defaultValue: nil, storage: storage)
    }

    // Dictionary<RawRepresentable<StringConvertable>, RawRepresentable>

    init<Key, Value>(_ key: String, defaultValue: Exposed, storage: UserDefaults = .standard) where Exposed == NonOptionalExposed,
        NonOptionalExposed == Dictionary<Key, Value>,
        Key: RawRepresentable, Key.RawValue: LosslessStringConvertible,
        Convertor == DictionaryConvertor<
            ComposedConvertor<StringConvertor<Key.RawValue>, RawRepresentableConvertor<Key>>,
            RawRepresentableConvertor<Value>
        > {
        self.init(key: key, defaultValue: defaultValue, storage: storage)
    }

    init<Key, Value>(_ key: String, storage: UserDefaults = .standard) where Exposed == NonOptionalExposed?,
        NonOptionalExposed == Dictionary<Key, Value>,
        Key: RawRepresentable, Key.RawValue: LosslessStringConvertible,
        Convertor == DictionaryConvertor<
            ComposedConvertor<StringConvertor<Key.RawValue>, RawRepresentableConvertor<Key>>,
            RawRepresentableConvertor<Value>
        > {
        self.init(key: key, defaultValue: nil, storage: storage)
    }

    // Dictionary<StringConvertable, Simple>

    init<Key, Value>(_ key: String, defaultValue: Exposed, storage: UserDefaults = .standard) where Exposed == NonOptionalExposed,
        NonOptionalExposed == Dictionary<Key, Value>,
        Key: LosslessStringConvertible,
        Convertor == DictionaryConvertor<
            StringConvertor<Key>,
            IdentityConvertor<Value>
        > {
        self.init(key: key, defaultValue: defaultValue, storage: storage)
    }

    init<Key, Value>(_ key: String, storage: UserDefaults = .standard) where Exposed == NonOptionalExposed?,
        NonOptionalExposed == Dictionary<Key, Value>,
        Key: LosslessStringConvertible,
        Convertor == DictionaryConvertor<
            StringConvertor<Key>,
            IdentityConvertor<Value>
        > {
        self.init(key: key, defaultValue: nil, storage: storage)
    }

    // Dictionary<StringConvertable, RawRepresentable>

    init<Key, Value>(_ key: String, defaultValue: Exposed, storage: UserDefaults = .standard) where Exposed == NonOptionalExposed,
        NonOptionalExposed == Dictionary<Key, Value>,
        Key: LosslessStringConvertible,
        Value: RawRepresentable, Value.RawValue: UserDefaultsStorable,
        Convertor == DictionaryConvertor<
            StringConvertor<Key>,
            RawRepresentableConvertor<Value>
        > {
        self.init(key: key, defaultValue: defaultValue, storage: storage)
    }

    init<Key, Value>(_ key: String, storage: UserDefaults = .standard) where Exposed == NonOptionalExposed?,
        NonOptionalExposed == Dictionary<Key, Value>,
        Key: LosslessStringConvertible,
        Value: RawRepresentable, Value.RawValue: UserDefaultsStorable,
        Convertor == DictionaryConvertor<
            StringConvertor<Key>,
            RawRepresentableConvertor<Value>
        > {
        self.init(key: key, defaultValue: nil, storage: storage)
    }

    // Note the different parameter name in the following: encodedDataKey vs unnamed. This is reqired since some Codable types
    // are also UserDefaultsStorable or RawRepresentable. We need a different key to be able to avoid ambiguity.
    init(encodedDataKey key: String, defaultValue: Exposed, storage: UserDefaults = .standard) where Exposed == NonOptionalExposed,
        Convertor == CodableStorageConvertor<NonOptionalExposed> {
        self.init(key: key, defaultValue: defaultValue, storage: storage)
    }

    init(encodedDataKey key: String, storage: UserDefaults = .standard) where Exposed == NonOptionalExposed?,
        Convertor == CodableStorageConvertor<NonOptionalExposed> {
        self.init(key: key, defaultValue: nil, storage: storage)
    }

    // Note the different parameter name in the following: archivedDataKey vs encodedDataKey vs unnamed. This is reqired since some
    // NSSecureCoding types are also UserDefaultsStorable or RawRepresentable. We need a different key to be able to avoid ambiguity.
    init(archivedDataKey key: String, defaultValue: Exposed, storage: UserDefaults = .standard) where Exposed == NonOptionalExposed,
        Convertor == ArchivedDataStorageConvertor<NonOptionalExposed> {
        self.init(key: key, defaultValue: defaultValue, storage: storage)
    }

    init(archivedDataKey key: String, storage: UserDefaults = .standard) where Exposed == NonOptionalExposed?,
        Convertor == ArchivedDataStorageConvertor<NonOptionalExposed> {
        self.init(key: key, defaultValue: nil, storage: storage)
    }
}
