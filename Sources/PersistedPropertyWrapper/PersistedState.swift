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
public struct PersistedState<Exposed, NonOptionalExposed, Convertor>: DynamicProperty
    where Convertor: PersistedStorageConvertor, Convertor.Exposed == NonOptionalExposed, Exposed: Sendable {

    /// An object that exposes the persisted value in a `@Published` property, and observes the `UserDefaults` for changes, auto-updating
    /// the property when these occur externally.
    @StateObject private var persistedObserver: PersistedObserver<Exposed, NonOptionalExposed, Convertor>

    // Initialiser is private so that we can selectively expose the overloads with/without default value parameter
    // depending on whether the exposed type is Optional.
    private init(key: String, defaultValue: Exposed, valueConvertor: Convertor, storage: UserDefaults) {
        // We cannot check this condition at compile time. We only publicly expose valid initialisation
        // functions, but to be safe let's check at runtime that the types are correct.
        guard Exposed.self == Convertor.Exposed.self || Exposed.self == Optional<Convertor.Exposed>.self else {
            preconditionFailure("Invalid Persisted generic arguments")
        }
        // StateObject's initialiser taken an @autoclosure, so we'll only construct the PersistedObserver once, the first
        // time this constructor is called.
        self._persistedObserver = StateObject(wrappedValue: PersistedObserver<Exposed, NonOptionalExposed, Convertor>(
            key: key,
            defaultValue: defaultValue,
            valueConvertor: valueConvertor,
            storage: storage
        ))
    }

    /// Getting this property will lookup the value from UserDefaults; setting will write the value to UserDefaults.
    public var wrappedValue: Exposed {
        get {
            return persistedObserver.value
        }
        nonmutating set {
            persistedObserver.value = newValue
        }
    }

    /// Returns a binding to the persisted value.
    public var projectedValue: Binding<Exposed> {
        Binding<Exposed>(
            get: { wrappedValue },
            set: { wrappedValue = $0 }
        )
    }
}

// MARK: Initialisers

public extension PersistedState {
    /**
    Use this initialiser to initialise a `PersistedState` from a `@Persisted`'s projected value.

    For instance, given a `@Persisted` value:

        struct Settings {
            static let instance = Settings()

            @Persisted("mySetting", defaultValue: 0)
            var mySetting: Int
        }

    then reference the `@Persisted` value in the initialiser of a `@PersistedState` for use in a SwiftUI view:

        @PersistedState(Settings.instance.$mySetting)
        var mySetting: Int

    in order to automatically use the same `UserDefaults` store and key for the `@PersistedState`.
    */
    init(_ persistedValue: Persisted<Exposed, NonOptionalExposed, Convertor>) {
        self.init(key: persistedValue.key, defaultValue: persistedValue.defaultValue, valueConvertor: persistedValue.valueConvertor, storage: persistedValue.storage)
    }

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
