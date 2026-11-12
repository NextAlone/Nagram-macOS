import Foundation

enum NagramOptionRules {
    static func range(_ lower: Int, _ upper: Int) -> (Int) -> Bool {
        return { $0 >= lower && $0 <= upper }
    }

    static func roundness(_ value: Int) -> Bool {
        return value == NagramOptions.roundnessUnchanged || (value >= 0 && value <= 100)
    }

    static func textWidth(_ value: Int) -> Bool {
        return value == 0 || (value >= 50 && value <= 400)
    }

    static func notificationDelay(_ value: Int) -> Bool {
        return [0, 500, 1000, 2000, 5000, 10000, 30000, 60000].contains(value)
    }

    static func stickerScale(_ value: Int) -> Bool {
        return value >= 50 && value <= 200 && value % 25 == 0
    }

    static func webAppScale(_ value: Int) -> Bool {
        return value >= 100 && value <= 200 && value % 25 == 0
    }

    static func voiceBitrate(_ value: Int) -> Bool {
        return [0, 16, 24, 48, 64, 96, 128].contains(value)
    }

    static func chatSort(_ value: Int) -> Bool {
        if value == 0 {
            return true
        }
        if value < 0 || value > 0xFFF {
            return false
        }
        var seen = 0
        for index in 0 ..< 4 {
            seen |= 1 << ((value >> (4 + index * 2)) & 3)
        }
        return seen == 0xF
    }

    static func quickRating(_ value: String) -> Bool {
        return value.utf16.count <= 64
    }

    static func downloadBoost(_ value: String) -> Bool {
        return ["none", "balanced", "fast"].contains(value)
    }

    static func codeLanguage(_ value: String) -> Bool {
        return value.utf16.count <= 32 && value.unicodeScalars.allSatisfy { scalar in
            switch scalar {
            case "a"..."z", "A"..."Z", "0"..."9", "+", "-":
                return true
            default:
                return false
            }
        }
    }

    static func quickReplies(_ raw: String) -> Bool {
        guard let root = nagramJsonObject(raw), root.count == 2, root["version"] as? Int == 1, let replies = root["replies"] as? [Any] else {
            return false
        }
        return replies.count == 2 && replies.allSatisfy { $0 is String }
    }

    static func messageMenu(_ raw: String) -> Bool {
        if raw.isEmpty {
            return true
        }
        guard let root = nagramJsonObject(raw), root.count == 2, let version = root["version"] as? Int, version == 1 || version == 2, let states = root["states"] as? [String: Any] else {
            return false
        }
        let known = Set(NagramMenuAction.allCases.map { $0.key })
        return states.allSatisfy { key, value in
            guard known.contains(key), !(version == 1 && key == NagramMenuAction.reading.key), let value = value as? String else {
                return false
            }
            return ["show", "hide", "option"].contains(value)
        }
    }

    static func inlineBotRules(_ raw: String) -> Bool {
        if raw.isEmpty {
            return true
        }
        guard let root = nagramJsonObject(raw), Set(root.keys) == ["version", "rules"], root["version"] as? Int == 1, let rules = root["rules"] as? [Any] else {
            return false
        }
        var ids = Set<String>()
        for entry in rules {
            guard let rule = entry as? [String: Any], validInlineRule(rule), let id = rule["id"] as? String, ids.insert(id).inserted else {
                return false
            }
        }
        return true
    }

    private static func validInlineRule(_ rule: [String: Any]) -> Bool {
        guard Set(rule.keys) == ["id", "username", "patterns", "enabled"], let id = rule["id"] as? String, UUID(uuidString: id)?.uuidString.lowercased() == id, let username = rule["username"] as? String, username.range(of: "\\A[A-Za-z][A-Za-z0-9_]{3,31}\\z", options: .regularExpression) != nil, rule["enabled"] is Bool, let patterns = rule["patterns"] as? [Any], !patterns.isEmpty else {
            return false
        }
        return patterns.allSatisfy { pattern in
            guard let pattern = pattern as? String else {
                return false
            }
            return !pattern.isEmpty && !pattern.contains("\n") && !pattern.contains("\r") && !pattern.contains("\0")
        }
    }

    static func disableInlineBotRules(_ raw: String) -> String {
        guard !raw.isEmpty, inlineBotRules(raw), var root = nagramJsonObject(raw), let rules = root["rules"] as? [[String: Any]] else {
            return raw
        }
        root["rules"] = rules.map { rule -> [String: Any] in
            var rule = rule
            rule["enabled"] = false
            return rule
        }
        guard let data = try? JSONSerialization.data(withJSONObject: root, options: [.sortedKeys]), let result = String(data: data, encoding: .utf8) else {
            return raw
        }
        return result
    }
}
