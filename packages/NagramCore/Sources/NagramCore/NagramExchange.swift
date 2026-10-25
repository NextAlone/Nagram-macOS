import Foundation

public enum NagramExchangeTarget {
    case file
    case cloud
}

public struct NagramExchangeChange {
    public let key: String
    public let before: Any?
    public let after: Any?
}

public struct NagramExchangePlan {
    public var changes: [NagramExchangeChange] = []
    public var skippedKeys: [String] = []
}

public enum NagramExchangeError: Error, Equatable {
    case tooLarge
    case invalidJson
    case unsupportedSchema
    case invalidValue(String)
    case changedSincePreview(String)
}

public enum NagramExchange {
    public static let version = 1
    public static let maxImportBytes = 8 * 1024 * 1024

    private static func carried(_ info: NagramOptionInfo, _ target: NagramExchangeTarget) -> Bool {
        return info.exportable && (target == .file || !info.flags.contains(.localOnly))
    }

    private static func jsonValue(_ info: NagramOptionInfo, _ raw: Any) -> Any? {
        switch info.type {
        case .boolean, .integer, .string:
            return raw
        case .object:
            guard let string = raw as? String, let data = string.data(using: .utf8) else {
                return nil
            }
            return try? JSONSerialization.jsonObject(with: data)
        }
    }

    private static func storedValue(_ info: NagramOptionInfo, _ json: Any) -> Any? {
        switch info.type {
        case .boolean:
            guard let number = json as? NSNumber, CFGetTypeID(number) == CFBooleanGetTypeID() else {
                return nil
            }
            return number.boolValue
        case .integer:
            guard let number = json as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID(), number.doubleValue == Double(number.intValue) else {
                return nil
            }
            return number.intValue
        case .string:
            return json as? String
        case .object:
            guard json is [String: Any], let data = try? JSONSerialization.data(withJSONObject: json, options: [.sortedKeys]) else {
                return nil
            }
            return String(data: data, encoding: .utf8)
        }
    }

    public static func modifiedOptions(_ settings: NagramSettings = .shared) -> [NagramOptionInfo] {
        return NagramOptions.all.filter { info in
            guard !info.flags.contains(.hidden) else { return false }
            return settings.rawValue(for: info) != nil
        }
    }

    public static func export(_ settings: NagramSettings = .shared, target: NagramExchangeTarget = .file) -> Data {
        var values: [String: Any] = [:]
        for info in NagramOptions.all where carried(info, target) {
            if let raw = settings.rawValue(for: info), let value = jsonValue(info, raw) {
                values[info.key] = value
            }
        }
        let root: [String: Any] = ["version": version, "options": values]
        return (try? JSONSerialization.data(withJSONObject: root, options: [.prettyPrinted, .sortedKeys])) ?? Data()
    }

    public static func plan(_ data: Data, settings: NagramSettings = .shared, target: NagramExchangeTarget = .file) -> Result<NagramExchangePlan, NagramExchangeError> {
        if data.count > maxImportBytes {
            return .failure(.tooLarge)
        }
        guard let root = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            return .failure(.invalidJson)
        }
        guard root.count == 2, let version = root["version"] as? NSNumber, version.intValue == NagramExchange.version, let options = root["options"] as? [String: Any] else {
            return .failure(.unsupportedSchema)
        }
        var plan = NagramExchangePlan()
        for key in options.keys.sorted() {
            guard let info = NagramOptions.all.first(where: { $0.key == key }), carried(info, target) else {
                plan.skippedKeys.append(key)
                continue
            }
            guard let json = options[key], let stored = storedValue(info, json), info.accepts(stored) else {
                return .failure(.invalidValue(key))
            }
            let before = settings.rawValue(for: info)
            let after: Any? = isEqual(stored, info.fallback) ? nil : stored
            if info.type == .object, sameObject(before, json) {
                continue
            }
            if !isEqual(before, after) {
                plan.changes.append(NagramExchangeChange(key: key, before: before, after: after))
            }
        }
        return .success(plan)
    }

    public static func apply(_ plan: NagramExchangePlan, settings: NagramSettings = .shared) -> Result<Void, NagramExchangeError> {
        for change in plan.changes {
            guard let info = NagramOptions.all.first(where: { $0.key == change.key }), info.exportable, isEqual(settings.rawValue(for: info), change.before) else {
                return .failure(.changedSincePreview(change.key))
            }
        }
        for change in plan.changes {
            if let info = NagramOptions.all.first(where: { $0.key == change.key }) {
                settings.setRawValue(change.after, for: info)
            }
        }
        return .success(())
    }

    private static func sameObject(_ raw: Any?, _ json: Any) -> Bool {
        guard let string = raw as? String, let data = string.data(using: .utf8), let current = (try? JSONSerialization.jsonObject(with: data)) as? NSObject, let incoming = json as? NSObject else {
            return false
        }
        return current.isEqual(incoming)
    }

    private static func isEqual(_ lhs: Any?, _ rhs: Any?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            return true
        case let (lhs as NSObject, rhs as NSObject):
            return lhs.isEqual(rhs)
        default:
            return false
        }
    }

    public static func diagnostics(appVersion: String, settings: NagramSettings = .shared) -> String {
        let all = NagramOptions.all
        let modified = modifiedOptions(settings)
        var lines: [String] = []
        lines.append("Nagram macOS \(appVersion)")
        lines.append("System: \(ProcessInfo.processInfo.operatingSystemVersionString)")
        lines.append("Options: \(all.count), modified: \(modified.count)")
        for category in NagramCategory.allCases {
            let count = modified.filter { $0.category == category }.count
            if count > 0 {
                lines.append("  \(category.rawValue): \(count)")
            }
        }
        return lines.joined(separator: "\n")
    }
}
