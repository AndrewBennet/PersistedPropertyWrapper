import Foundation

/// A utility which can convert between an exposed type and a type which can be stored in `UserDefaults`.
public protocol StorageConvertor<Input>: Sendable {
    associatedtype Input
    associatedtype Output

    static func convert(_ input: Input) -> Output
    static func deconvert(from output: Output) -> Input?
}

/// A convertor that uses the type-native storable capabilities. This convertor will be used fro all concrete types we can extend to supporlt
/// the `UserDefaultsStorable` protocol.
public struct IdentityConvertor<Input>: StorageConvertor where Input: UserDefaultsStorable {
    public static func convert(_ input: Input) -> Input.Stored {
        input.storedValue
    }
    
    public static func deconvert(from output: Input.Stored) -> Input? {
        Input(storedValue: output)
    }
}

/// Maps between `RawRepresentable` values and their underlying `RawValues`, where the raw value is a natively-storable value.
public struct RawRepresentableConvertor<Input>: StorageConvertor where Input: RawRepresentable, Input.RawValue: UserDefaultsScalar {
    public static func convert(_ input: Input) -> Input.RawValue {
        return input.rawValue
    }

    public static func deconvert(from output: Input.RawValue) -> Input? {
        return Input(rawValue: output)
    }
}

/// Maps between a `Set` and an `Array` applying the generic convertor to its elements.
public struct SetConvertor<ElementConvertor: StorageConvertor>: StorageConvertor where ElementConvertor.Input: Hashable {
    public static func convert(_ input: Set<ElementConvertor.Input>) -> [ElementConvertor.Output] {
        input.map(ElementConvertor.convert)
    }

    public static func deconvert(from output: [ElementConvertor.Output]) -> Set<ElementConvertor.Input>? {
        Set(output.compactMap(ElementConvertor.deconvert(from:)))
    }
}

/// Maps an array's elements based on the generic convertor applied to its elements.
public struct ArrayConvertor<ElementConvertor: StorageConvertor>: StorageConvertor {
    public static func convert(_ input: [ElementConvertor.Input]) -> [ElementConvertor.Output] {
        input.map(ElementConvertor.convert)
    }

    public static func deconvert(from output: [ElementConvertor.Output]) -> [ElementConvertor.Input]? {
        output.compactMap(ElementConvertor.deconvert(from:))
    }
}

/// A convertor that applies the two generic convertors, one after the other.
public struct ComposedConvertor<Convertor1: StorageConvertor, Convertor2: StorageConvertor>: StorageConvertor
    where Convertor1.Input == Convertor2.Output {

    public static func convert(_ input: Convertor2.Input) -> Convertor1.Output {
        Convertor1.convert(Convertor2.convert(input))
    }

    public static func deconvert(from output: Convertor1.Output) -> Convertor2.Input? {
        guard let convertor1Exposed = Convertor1.deconvert(from: output) else { return nil }
        return Convertor2.deconvert(from: convertor1Exposed)
    }
}

/// Maps between some `Exposed` type and a `String` via a lossless string conversion.
public struct StringConvertor<Input>: StorageConvertor where Input: LosslessStringConvertible {
    public static func convert(_ intput: Input) -> String {
        return intput.description
    }

    public static func deconvert(from output: String) -> Input? {
        return Input(output)
    }
}

/// Maps between two forms of a `Dictionary`, where the keys and values are convertable via other `PersistedStorageConvertor`s.
public struct DictionaryConvertor<KeyConvertor: StorageConvertor, ValueConvertor: StorageConvertor>: StorageConvertor
    where KeyConvertor.Input: Hashable, KeyConvertor.Output: Hashable {

    public typealias Input = Dictionary<KeyConvertor.Input, ValueConvertor.Input>
    public typealias Output = Dictionary<KeyConvertor.Output, ValueConvertor.Output>

    public static func convert(_ input: Input) -> Output {
        return .init(uniqueKeysWithValues: input.map {
            let persistedKey = KeyConvertor.convert($0.key)
            let persistedValue = ValueConvertor.convert($0.value)
            return (persistedKey, persistedValue)
        })
    }

    public static func deconvert(from output: Output) -> Input? {
        return .init(uniqueKeysWithValues: output.compactMap {
            guard let exposedKey = KeyConvertor.deconvert(from: $0.key),
                  let exposedValue = ValueConvertor.deconvert(from: $0.value) else { return nil }
            return (exposedKey, exposedValue)
        })
    }
}

/// Maps between any `Codable` value and `Data`.
public struct CodableStorageConvertor<Input>: StorageConvertor where Input: Codable {

    public static func convert(_ input: Input) -> Data {
        return try! JSONEncoder().encode(input)
    }

    public static func deconvert(from output: Data) -> Input? {
        return try? JSONDecoder().decode(Input.self, from: output)
    }
}

/// Maps between any `NSSecureCoding` conformant `NSObject` instance and `Data`
public struct ArchivedDataStorageConvertor<Input>: StorageConvertor where Input: NSObject, Input: NSSecureCoding {
    public static func convert(_ input: Input) -> Data {
        return try! NSKeyedArchiver.archivedData(withRootObject: input, requiringSecureCoding: true)
    }

    public static func deconvert(from output: Data) -> Input? {
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: Input.self, from: output)
    }
}
