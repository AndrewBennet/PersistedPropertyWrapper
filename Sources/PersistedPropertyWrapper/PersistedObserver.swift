import Foundation
import Combine
import os.log

/// An object that, upon initialisation, adds itself as an observer of the provided `UserDefaults` for the given `key`, and updates its
/// `@Published` `propertyValue` property
class PersistedObserver<Exposed: Sendable, NonOptionalExposed: Sendable, Convertor: Sendable>: NSObject, ObservableObject
    where Exposed: Sendable, Convertor: StorageConvertor, Convertor.Input == NonOptionalExposed {
    private let key: String
    private let userDefaults: UserDefaults
    private let persistedStorage: Persisted<Exposed, NonOptionalExposed, Convertor>

    init(key: String, defaultValue: Exposed, storage: UserDefaults) {
        print("init for \(key)")
        // We cannot check this condition at compile time. We only publicly expose valid initialisation
        // functions, but to be safe let's check at runtime that the types are correct.
        guard Exposed.self == Convertor.Input.self || Exposed.self == Optional<Convertor.Input>.self else {
            preconditionFailure("Invalid Persisted generic arguments")
        }
        self.key = key
        self.userDefaults = storage
        self.persistedStorage = Persisted(key: key, defaultValue: defaultValue, storage: storage)
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
