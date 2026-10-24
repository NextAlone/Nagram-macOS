import Foundation

public enum NagramLanguage: String {
    case english = "en"
    case simplifiedChinese = "zh-hans"
    case traditionalChinese = "zh-hant"

    public static func resolve(_ code: String) -> NagramLanguage {
        let lowered = code.lowercased()
        if lowered.contains("hant") || lowered.contains("zh-tw") || lowered.contains("zh-hk") || lowered.contains("taiwan") {
            return .traditionalChinese
        }
        if lowered.hasPrefix("zh") || lowered.contains("-zh") || lowered.contains("hans") || lowered.contains("chinese") {
            return .simplifiedChinese
        }
        return .english
    }
}

private final class NagramStringTable {
    static let shared = NagramStringTable()

    private let lock = NSLock()
    private var tables: [NagramLanguage: [String: String]] = [:]

    func table(_ language: NagramLanguage) -> [String: String] {
        lock.lock()
        defer { lock.unlock() }
        if let table = tables[language] {
            return table
        }
        var table: [String: String] = [:]
        for name in [language.rawValue, "mac-" + language.rawValue] {
            guard let url = Bundle.module.url(forResource: name, withExtension: "strings", subdirectory: "Resources") else {
                preconditionFailure("Nagram strings resource \(name).strings is missing from the bundle")
            }
            guard let values = NSDictionary(contentsOf: url) as? [String: String] else {
                preconditionFailure("Nagram strings resource \(name).strings is not a valid strings file")
            }
            table.merge(values, uniquingKeysWith: { _, mac in mac })
        }
        tables[language] = table
        return table
    }
}

private let languageCodes = NagramLocked<[String]>(["en"])

public func nagramSetLanguageCodes(_ codes: [String]) {
    languageCodes.value = codes
}

public var nagramLanguage: NagramLanguage {
    for code in languageCodes.value {
        let resolved = NagramLanguage.resolve(code)
        if resolved != .english {
            return resolved
        }
    }
    return .english
}

final class NagramLocked<T> {
    private let lock = NSLock()
    private var stored: T
    init(_ value: T) {
        self.stored = value
    }
    var value: T {
        get {
            lock.lock()
            defer { lock.unlock() }
            return stored
        }
        set {
            lock.lock()
            stored = newValue
            lock.unlock()
        }
    }
}

public func nagramString(_ key: String, _ arguments: [String: String] = [:]) -> String {
    let language = nagramLanguage
    var value = NagramStringTable.shared.table(language)[key] ?? NagramStringTable.shared.table(.english)[key] ?? key
    for (name, replacement) in arguments {
        value = value.replacingOccurrences(of: "{\(name)}", with: replacement)
    }
    return value
}

public func nagramStringExists(_ key: String) -> Bool {
    return NagramStringTable.shared.table(.english)[key] != nil
}
