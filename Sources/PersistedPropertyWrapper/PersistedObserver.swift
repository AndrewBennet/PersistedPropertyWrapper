import Foundation
import Combine
import os.log

/// A `Publisher` of the converted value stored in `UserDefaults` (publishes even with external changes).
/// Conforms to `ObservableObject` and triggers `objectWillChange` when the `UserDefaults` store changes for the specified key.
class PersistedObserver<Exposed: Sendable, NonOptionalExposed: Sendable, Convertor: StorageConvertor>: NSObject, Publisher, ObservableObject
    where Convertor.Input == NonOptionalExposed {

    typealias Output = Exposed
    typealias Failure = Never

    let persistedStorage: Persisted<Exposed, NonOptionalExposed, Convertor>
    private let currentValueSubject: CurrentValueSubject<Exposed, Never>

    init(persistedStorage: Persisted<Exposed, NonOptionalExposed, Convertor>) {
        // We cannot check this condition at compile time. We only publicly expose valid initialisation
        // functions, but to be safe let's check at runtime that the types are correct.
        guard Exposed.self == Convertor.Input.self || Exposed.self == Optional<Convertor.Input>.self else {
            preconditionFailure("Invalid Persisted generic arguments")
        }
        self.persistedStorage = persistedStorage
        self.currentValueSubject = CurrentValueSubject(persistedStorage.wrappedValue)
        super.init()
        persistedStorage.storage.addObserver(self, forKeyPath: persistedStorage.key, context: nil)
    }

    deinit {
        persistedStorage.storage.removeObserver(self, forKeyPath: persistedStorage.key)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        objectWillChange.send()
        currentValueSubject.send(persistedStorage.wrappedValue)
    }

    func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, Exposed == S.Input {
        currentValueSubject.receive(subscriber: subscriber)
    }
}
