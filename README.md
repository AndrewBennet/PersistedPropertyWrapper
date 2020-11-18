# Persisted Property Wrapper
![Swift](https://github.com/AndrewBennet/PersistedPropertyWrapper/workflows/Swift/badge.svg)
![Swift Version](https://img.shields.io/badge/Swift-5.3-F16D39.svg?style=flat)
![Cocoapods platforms](https://img.shields.io/cocoapods/p/PersistedPropertyWrapper)
![GitHub](https://img.shields.io/github/license/AndrewBennet/PersistedPropertyWrapper)

**Persisted Property Wrapper** is a Swift library to enable extremely easy persistance of variables in the [`UserDefaults`](https://developer.apple.com/documentation/foundation/userdefaults) database on Apple platforms.

To use **Persisted Property Wrapper** you simply annotate a variable as being `@Persisted`. It supports the standard `UserDefaults` types (`Int`, `String`, `Bool`, `Date` and more), along with `RawRepresentable` enums where the `RawValue` is storable in `UserDefaults`, as well as any `Codable` type. Plus of course any `Optional` wrapper of any of these types. The type-validity is checked at compile-time: attempting to use on any variables of a non-supported type will cause a compile-time error. 

## Usage

Stick a `@Persisted` attribute on your variable.

The first argument of the initializer is the string key under which the value will be stored in `UserDefaults`. If the type is non-Optional, you must also supply a `defaultValue`, which will be used when there is no value stored in `UserDefaults`.

For example:
```swift
@Persisted("UserSetting1", defaultValue: 42)
var someUserSetting: Int

@Persisted("UserSetting2") // defaultValue not necessary since Int? is an Optional type
var someOtherUserSetting: Int?
```

### Storing Enums
Want to store an enum value? If the enum has a backing type which is supported for storage in `UserDefaults`, then those can also be marked as `@Persisted`, and the actual value stored in `UserDefaults` will be the enum's raw value. For example:

```swift
enum AppTheme: Int {
    case brightRed
    case vibrantOrange
    case plainBlue
}

struct ThemeSettings {
    // Stores the underlying integer backing the selected AppTheme
    @Persisted("theme", defaultValue: .plainBlue)
    var selectedTheme: AppTheme
}
```

### Storing Codable types
Any codable type can be Persisted too; this will store in UserDefaults the JSON-encoded representation of the variable. For example:

```swift
struct AppSettings: Codable {
    var welcomeMessage = "Hello world!"
    var isSpecialModeEnabled = false
    var launchCount = 0

    @Persisted(encodedDataKey: "appSettings", defaultValue: .init())
    static var current: AppSettings
}

// Example usage: this will update the value of the stored AppSettings
func appDidLaunch() {
    AppSettings.current.launchCount += 1
}
```

Note that the argument label `encodedDataKey` must be used. This is required to remove ambiguity about which storage method is used, since `UserDefaults`-storable types can be `Codable` too.

For example, the following two variables are stored via different mechanisms:
```swift
// Stores the integer in UserDefaults
@Persisted("storedAsInteger", defaultValue: 10)
var storedAsInteger: Int

// Store the data of a JSON-encoded representation of the value. Don't use on iOS 12!
@Persisted(encodedDataKey: "storedAsData", defaultValue: 10)
var storedAsData: Int
```

**Note:** on iOS 12, using the `encodedDataKey` initializer with a value which would encode to a JSON _fragment_ (e.g. `Int`, `String`, `Bool`, etc) will cause a crash. This is due to a [bug in the Swift runtime](https://bugs.swift.org/browse/SR-6163) shipped prior to iOS 13. Using `encodedDataKey` has no benefit in these cases anyway.

### Storing types which implement `NSCoding`
Any `NSObject` which conforms to `NSSecureCoding` can be Persisted too; this will store in UserDefaults the encoded representation of the object obtained from `NSKeyedArchiver`. For example:

```swift
class CloudKitSyncManager {
    @Persisted(archivedDataKey: "ckServerChangeToken")
    var changeToken: CKServerChangeToken?
}
```

Note that the argument label `archivedDataKey` must be used. As above, this is required to remove ambiguity about which storage method is used.

**Note:** this storage mechanism is only supported on iOS 11 and up.

### Alternative Storage
By default, a `@Persisted` property is stored in the `UserDefaults.standard` database; to store values in a different location, pass the `storage: ` parameter to the property wrapper:

```
extension UserDefaults {
    static var alternative = UserDefaults(suiteName: "alternative")!
}

@Persisted("alternativeStoredValue", storage: .alternative)
var alternativeStoredValue: Int?
```

## Why a Library?
After all, there are lots of examples of similar utilities on the web. For example, [this post by John Sundell](https://www.swiftbysundell.com/articles/property-wrappers-in-swift/#a-propertys-properties) shows how a `@UserDefaultsBacked` property wrapper can be written in a handful of lines. 

However, during development of [my app](https://github.com/AndrewBennet/ReadingList), I found that I really wanted to store _enum values_ in `UserDefaults`. For any enum which is backed by integer or a string, there was an obvious ideal implementation - store the enum's raw value. To provide a single API to persist both  `UserDefaults`-supported types as well as enum values _backed_ by `UserDefaults`-supported types proved a little tricky; adding the requirement that everything needed to also work on `Optional` wrappers of any supported type, and the problem became more complex still. Once solved for my app, I thought why not package up?

## Requirements

- Xcode 12
- Swift 5.3

## Installation

### Swift Package Manager
Add `https://github.com/AndrewBennet/PersistedPropertyWrapper.git` as a Swift Package Dependency in Xcode.

### CocoaPods
To install via CocoaPods, add the following line to your Podfile:
```
pod 'PersistedPropertyWrapper', '~> 2.0'
```

### Manually
Copy the contents of the `Sources` directory into your project.

## Alternatives

- [SwiftyUserDefaults](https://github.com/sunshinejr/SwiftyUserDefaults) has more functionality, but you are required to define your stored properties in a specific extension.
- [AppStorage](https://developer.apple.com/documentation/swiftui/appstorage): native Apple property wrapper, but tailored to (and defined in) SwiftUI, and only available in iOS 14
