import Foundation

/// Any type which can natively be stored in UserDefaults.
public protocol UserDefaultsPrimitive {}

extension Int: UserDefaultsPrimitive {}
extension Int16: UserDefaultsPrimitive {}
extension Int32: UserDefaultsPrimitive {}
extension Int64: UserDefaultsPrimitive {}
extension String: UserDefaultsPrimitive {}
extension Bool: UserDefaultsPrimitive {}
extension Double: UserDefaultsPrimitive {}
extension Float: UserDefaultsPrimitive {}
extension Date: UserDefaultsPrimitive {}
extension Data: UserDefaultsPrimitive {}
extension Array: UserDefaultsPrimitive where Element: UserDefaultsPrimitive {}
extension Dictionary: UserDefaultsPrimitive where Key: UserDefaultsPrimitive, Value: UserDefaultsPrimitive {}
