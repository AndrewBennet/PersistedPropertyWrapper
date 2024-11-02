import Foundation
import Combine
import os.log

/// An object that, upon initialisation, adds itself as an observer of the provided `UserDefaults` for the given `key`, and updates its
/// `@Published` `propertyValue` property
class PersistedObserver<Exposed, NonOptionalExposed, Convertor> : NSObject, ObservableObject where Convertor: PersistedStorageConvertor,
                                                                                                   Convertor.Exposed == NonOptionalExposed {
    private let key: String
    private let userDefaults: UserDefaults
    private let persistedStorage: PersistedValue<Exposed, NonOptionalExposed, Convertor>

    init(key: String, defaultValue: Exposed, valueConvertor: Convertor, storage: UserDefaults) {
        print("init for \(key)")
        // We cannot check this condition at compile time. We only publicly expose valid initialisation
        // functions, but to be safe let's check at runtime that the types are correct.
        guard Exposed.self == Convertor.Exposed.self || Exposed.self == Optional<Convertor.Exposed>.self else {
            preconditionFailure("Invalid Persisted generic arguments")
        }
        self.key = key
        self.userDefaults = storage
        self.persistedStorage = PersistedValue(key: key, defaultValue: defaultValue, valueConvertor: valueConvertor, storage: storage)
        self.value = persistedStorage.wrappedValue

        super.init()
        userDefaults.addObserver(self, forKeyPath: key, context: nil)
    }

    deinit {
        userDefaults.removeObserver(self, forKeyPath: key)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        value = persistedStorage.wrappedValue
    }

    @Published var value: Exposed {
        didSet {
            persistedStorage.wrappedValue = value
        }
    }
}
