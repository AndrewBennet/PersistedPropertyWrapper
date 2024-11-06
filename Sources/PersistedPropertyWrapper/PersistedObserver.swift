import Foundation
import Combine
import os.log

/// An object that, upon initialisation, adds itself as an observer of the provided `UserDefaults` for the given `key`, and updates its
/// `@Published` `propertyValue` property
class PersistedObserver<Exposed: Sendable, NonOptionalExposed: Sendable, Convertor: Sendable>: NSObject, ObservableObject
    where Exposed: Sendable, Convertor: StorageConvertor, Convertor.Input == NonOptionalExposed {
    let persistedStorage: Persisted<Exposed, NonOptionalExposed, Convertor>

    init(persistedStorage: Persisted<Exposed, NonOptionalExposed, Convertor>) {
        // We cannot check this condition at compile time. We only publicly expose valid initialisation
        // functions, but to be safe let's check at runtime that the types are correct.
        guard Exposed.self == Convertor.Input.self || Exposed.self == Optional<Convertor.Input>.self else {
            preconditionFailure("Invalid Persisted generic arguments")
        }
        self.persistedStorage = persistedStorage
        self.value = persistedStorage.wrappedValue

        super.init()
        persistedStorage.storage.addObserver(self, forKeyPath: persistedStorage.key, context: nil)
    }

    deinit {
        persistedStorage.storage.removeObserver(self, forKeyPath: persistedStorage.key)
    }

    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        value = persistedStorage.wrappedValue
    }

    @Published var value: Exposed {
        didSet {
            persistedStorage.wrappedValue = value
        }
    }

    /// A publisher that emits changes to the persisted value.
    var valueChanged: AnyPublisher<Exposed, Never> {
        $value.eraseToAnyPublisher()
    }
}
