import Foundation

/// A type which can natively be stored in UserDefaults.
public protocol UserDefaultsPrimitive {}

extension Int: UserDefaultsPrimitive {}
extension Int8: UserDefaultsPrimitive {}
extension Int16: UserDefaultsPrimitive {}
extension Int32: UserDefaultsPrimitive {}
extension Int64: UserDefaultsPrimitive {}
extension UInt: UserDefaultsPrimitive {}
extension UInt8: UserDefaultsPrimitive {}
extension UInt16: UserDefaultsPrimitive {}
extension UInt32: UserDefaultsPrimitive {}
extension UInt64: UserDefaultsPrimitive {}
extension String: UserDefaultsPrimitive {}
extension Bool: UserDefaultsPrimitive {}
extension Double: UserDefaultsPrimitive {}
extension Float: UserDefaultsPrimitive {}
extension Date: UserDefaultsPrimitive {}
extension Data: UserDefaultsPrimitive {}
extension Array: UserDefaultsPrimitive where Element: UserDefaultsPrimitive { }
extension Dictionary: UserDefaultsPrimitive where Key == String, Value: UserDefaultsPrimitive { }
