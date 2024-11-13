import Foundation
import Combine
import os.log

/// A property wrapper that reads from and writes to a UserDefaults store, for use in an `ObservableObject`.
/// Supports properties of the following types: those which can be natively stored in `UserDefaults`,
/// `RawRepresentable` types where the `RawType` is one which an be natively stored in `UserDefaults`, and any `Codable` type.
@propertyWrapper
public struct PersistedPublished<Exposed: Sendable, NonOptionalExposed: Sendable, Convertor: StorageConvertor<NonOptionalExposed>> {

    // The regular @Persisted property wrapper, which we use to do the value conversion & storage for us.
    private let persisted: Persisted<Exposed, NonOptionalExposed, Convertor>
    private let subscriptionContainer = SubscriptionContainer()

    class SubscriptionContainer {
        var subscription: AnyCancellable?
    }

    init(key: String, defaultValue: Exposed, storage: UserDefaults) {
        self.init(persisted: Persisted(key: key, defaultValue: defaultValue, storage: storage))
    }

    init(persisted: Persisted<Exposed, NonOptionalExposed, Convertor>) {
        self.persisted = persisted
    }

    @available(*, unavailable, message: "@PersistedPublished can only be applied to classes")
    public var wrappedValue: Exposed {
        get { fatalError() }
        set { fatalError() }
    }

    // A magical undocumented feature of SwiftUI / Combine. This static function is an alternative way of handling a property
    // wrapper's value. In this case, we define this function to allow @Persisted properties to notify containing ObservableObjects
    // of changes when the value is set. We do not monitor for changes, though.
    public static subscript<T: ObservableObject>(
        _enclosingInstance instance: T,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<T, Exposed>,
        storage storageKeyPath: ReferenceWritableKeyPath<T, Self>
    ) -> Exposed {
        get {
            let storage = instance[keyPath: storageKeyPath]
            // Set up a subscription the first time the property is accessed via this mechanism.
            if storage.subscriptionContainer.subscription == nil {
                storage.subscriptionContainer.subscription = storage.persisted.publisher().sink { newValue in
                    if let observableObjectPubisher = instance.objectWillChange as? ObservableObjectPublisher {
                        observableObjectPubisher.send()
                    } else {
                        assertionFailure("ObservableObject's objectWillChange publisher is not an ObservableObjectPublisher")
                    }
                }
            }
            return storage.persisted.wrappedValue
        }
        set {
            instance[keyPath: storageKeyPath].persisted.wrappedValue = newValue
        }
    }
}

// MARK: Initialisers

public extension PersistedPublished {

    /**
     Use this initialiser to initialise a `PersistedPublished` from a `@Persisted`'s projected value.

     For instance, given a `@Persisted` value:
```
     struct Settings {
       static let instance = Settings()

       @Persisted("mySetting", defaultValue: 0)
       var mySetting: Int
     }
```
     then reference the `@Persisted` value in the initialiser of a `@PersistedState` for use in an observable object:

```
     @PersistedPublished(Settings.instance.$mySetting)
     var mySetting: Int
```

     in order to automatically use the same `UserDefaults` store and key for the `@PersistedState`.
     */
    init(_ persistedValue: Persisted<Exposed, NonOptionalExposed, Convertor>) {
        self.init(persisted: persistedValue)
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
