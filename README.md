# Persisted Property Wrapper
![Swift](https://github.com/AndrewBennet/PersistedPropertyWrapper/workflows/Swift/badge.svg)

**Persisted Property Wrapper** is a Swift library to enable extremely easy persistance of variables in the [`UserDefaults`](https://developer.apple.com/documentation/foundation/userdefaults) database on iOS.

To use **Persisted Property Wrapper** you simply annotate a variable as being `@Persisted`. It supports the standard `UserDefaults` types, along with `RawRepresentable` types - where the `RawValue` is storable in `UserDefaults` - and `Codable` types. Plus of course any `Optional` type wrapping any of these types. The type-validity is checked at compile-time: attempting to use on any variables of a non-supported type will cause a compile-time error. 

## Usage

Stick a `@Persisted` attribute on your variable.

The first parameter of the argument is the string key under which the value will be stored in `UserDefaults`. If the type is non-Optional, you must also supply a `defaultValue`, which will be used when there is no value stored in `UserDefaults`.

For example:
```swift
@Persisted("UserSetting1", defaultValue: 42)
var someUserSetting: Int

@Persisted("UserSetting2") // defaultValue not necessary since Int? is an Optional type
var someOtherUserSetting: Int?
```

### Storing Enums
Want to store an enum value? If the enum has a backing type which is supported for storage in `UserDefaults` (e.g., `Int` or `String`), then those can also be marked as `@Persisted`, and the actual value stored in `UserDefaults` will be the enum's raw value. For example:

```swift
enum AppTheme: Int {
    case brightRed
    case vibrantOrange
    case plainBlue
}

struct ThemeSettings {
    @Persisted("theme", defaultValue: .plainBlue)
    var selectedTheme: AppTheme
}
```

### Storing Codable types
Any codable type can be Persisted too:

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

Note the different initializer argument: `encodedDataKey` rather than a parameterless argument. This is required since plain `UserDefaults` types (and `RawRepresentable` types) can be `Codable` too. To remove ambiguity about which storage method is used, `@Persisted` needs an initializer overload.

For example, the following two variables are stored via different mechanisms:
```swift
@Persisted("storedAsInteger", defaultValue: 10)
var storedAsInteger: Int

@Persisted(encodedDataKey: "storedAsData", defaultValue: 10)
var storedAsData: Int
```

## Why a Library?
After all, there are lots of examples of similar utilities on the web. For example, [this post by John Sundell](https://www.swiftbysundell.com/articles/property-wrappers-in-swift/#a-propertys-properties) shows how a `@UserDefaultsBacked` property wrapper can be written in a handful of lines. 

However, during development of [my app](https://github.com/AndrewBennet/ReadingList), I found that I really wanted to store _enum values_ in `UserDefaults`. For any enum which is backed by integer or a string, there was an obvious ideal implementation - store the enum's raw value. To provide a single API to persist both  `UserDefaults`-supported types as well as enum values _backed_ by `UserDefaults`-supported types proved a little tricky; adding the requirement that everything needed to also work on `Optional` wrappers of any supported type, and the problem became more complex still. Once solved for my app, I thought why not package up?

## Installation

### Swift Package Manager
Add `https://github.com/AndrewBennet/PersistedPropertyWrapper.git` as a Swift Package Dependency in Xcode.

### Manually
Copy the contents of the `Sources` directory into your project.

## Alternatives

- [SwiftyUserDefaults](https://github.com/sunshinejr/SwiftyUserDefaults) has more functionality, but you are required to define your stored properties in a specific extension.
- [AppStorage](https://developer.apple.com/documentation/swiftui/appstorage): native Apple property wrapper, but tailored to (and defined in) SwiftUI, and only available in iOS 14
