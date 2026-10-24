import Foundation

public enum NagramScope: Equatable {
    case device
    case account
}

public enum NagramCategory: String, CaseIterable {
    case interface
    case chats
    case messages
    case compose
    case menu
    case media
    case privacy
    case services
    case rules
    case network
}

public struct NagramFlags: OptionSet, Hashable {
    public let rawValue: UInt
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    public static let requiresRestart = NagramFlags(rawValue: 1 << 0)
    public static let exportable = NagramFlags(rawValue: 1 << 1)
    public static let hidden = NagramFlags(rawValue: 1 << 2)
    public static let refreshMessageView = NagramFlags(rawValue: 1 << 3)
    public static let refreshDialogList = NagramFlags(rawValue: 1 << 4)
    public static let refreshComposeButtons = NagramFlags(rawValue: 1 << 5)
    public static let localOnly = NagramFlags(rawValue: 1 << 6)
}

public enum NagramValueType {
    case boolean
    case integer
    case string
    case object
}

public protocol NagramValue: Equatable {
    static var valueType: NagramValueType { get }
    init?(stored: Any)
    var stored: Any { get }
}

extension Bool: NagramValue {
    public static var valueType: NagramValueType { .boolean }
    public init?(stored: Any) {
        guard let value = stored as? Bool else { return nil }
        self = value
    }
    public var stored: Any { self }
}

extension Int: NagramValue {
    public static var valueType: NagramValueType { .integer }
    public init?(stored: Any) {
        guard let value = stored as? Int else { return nil }
        self = value
    }
    public var stored: Any { self }
}

extension String: NagramValue {
    public static var valueType: NagramValueType { .string }
    public init?(stored: Any) {
        guard let value = stored as? String else { return nil }
        self = value
    }
    public var stored: Any { self }
}

public struct NagramOptionInfo {
    public let key: String
    public let scope: NagramScope
    public let category: NagramCategory
    public let titleKey: String
    public let flags: NagramFlags
    public let type: NagramValueType
    public let fallback: Any
    public let accepts: (Any) -> Bool

    public var exportable: Bool {
        return scope == .device && flags.contains(.exportable)
    }
}

public struct NagramOption<Value: NagramValue> {
    public let key: String
    public let scope: NagramScope
    public let fallback: Value
    public let category: NagramCategory
    public let titleKey: String
    public let flags: NagramFlags
    public let isObject: Bool
    public let validate: ((Value) -> Bool)?

    public init(_ key: String, _ scope: NagramScope, _ fallback: Value, _ category: NagramCategory, _ titleKey: String, _ flags: NagramFlags, object: Bool = false, validate: ((Value) -> Bool)? = nil) {
        self.key = key
        self.scope = scope
        self.fallback = fallback
        self.category = category
        self.titleKey = titleKey
        let exportable = scope == .device && !flags.contains(.hidden)
        self.flags = exportable ? flags.union(.exportable) : flags
        self.isObject = object
        self.validate = validate
    }

    public func accepts(_ value: Value) -> Bool {
        if let validate = validate, !validate(value) {
            return false
        }
        if let string = value as? String, !isObject, string.contains("\n") || string.contains("\r") {
            return false
        }
        if isObject, let string = value as? String, !string.isEmpty {
            guard let data = string.data(using: .utf8), let object = try? JSONSerialization.jsonObject(with: data), object is [String: Any] else {
                return false
            }
        }
        return true
    }

    public var info: NagramOptionInfo {
        let option = self
        return NagramOptionInfo(key: key, scope: scope, category: category, titleKey: titleKey, flags: flags, type: isObject ? .object : Value.valueType, fallback: fallback.stored, accepts: { raw in
            guard let value = Value(stored: raw) else {
                return false
            }
            return option.accepts(value)
        })
    }
}
