import Foundation

public enum NagramAliases {
    public static let maxLength = 64

    private static let lock = NSLock()
    private static var cache: (String, [String: String])?

    private static func table(account: Int64?) -> [String: String] {
        let raw = NagramOptions.peerAliases.value(account: account)
        if raw.isEmpty {
            return [:]
        }
        lock.lock()
        defer { lock.unlock() }
        if let cache = cache, cache.0 == raw {
            return cache.1
        }
        let parsed = (nagramJsonObject(raw)?["aliases"] as? [String: String]) ?? [:]
        cache = (raw, parsed)
        return parsed
    }

    public static func alias(peerId: Int64, account: Int64? = nil) -> String? {
        let value = table(account: account ?? NagramSettings.shared.currentAccount)["\(peerId)"]
        return value?.isEmpty == false ? value : nil
    }

    public static func setAlias(_ alias: String?, peerId: Int64, account: Int64? = nil) {
        let account = account ?? NagramSettings.shared.currentAccount
        var aliases = table(account: account)
        let trimmed = alias?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if trimmed.isEmpty {
            aliases.removeValue(forKey: "\(peerId)")
        } else {
            aliases["\(peerId)"] = String(trimmed.prefix(maxLength))
        }
        NagramOptions.peerAliases.set(aliases.isEmpty ? "" : nagramJsonString(["version": 1, "aliases": aliases]), account: account)
    }

    public static func orderedName(first: String?, last: String?) -> String {
        let first = first ?? ""
        let last = last ?? ""
        if first.isEmpty || last.isEmpty {
            return first + last
        }
        return NagramOptions.nameOrder.value == 2 ? last + " " + first : first + " " + last
    }
}
