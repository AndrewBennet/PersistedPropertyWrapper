import Foundation

/** An object that can be registered as an observer on the stored UserDefaults. `registerObserver` can be called only once, to supply
 a closeure that will be executed when the UserDefaults value with the provided key changes. Upon deinitialisation, the observer is removed. */
class UserDefaultsObserver: NSObject {
    private let userDefaults: UserDefaults
    private let key: String
    private var action: (() -> Void)?

    init(userDefaults: UserDefaults, key: String) {
        self.userDefaults = userDefaults
        self.key = key
        super.init()
    }

    func registerObserver(_ action: @escaping () -> Void) {
        if self.action != nil {
            fatalError("registerObserver called multiple times")
        }
        self.action = action
        userDefaults.addObserver(self, forKeyPath: key, context: nil)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?,
                               context: UnsafeMutableRawPointer?) {
        guard let action else { fatalError("observeValue unexpected called with no action set") }
        action()
    }

    deinit {
        if action != nil {
            userDefaults.removeObserver(self, forKeyPath: key)
        }
    }
}
