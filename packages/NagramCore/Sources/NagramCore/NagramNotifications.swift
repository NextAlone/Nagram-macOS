import Foundation

public struct NagramQuietHours: Equatable {
    public var enabled = false
    public var start = 23 * 60
    public var end = 7 * 60
    public var weekdays: [Int] = []
    public var allowContacts = false
    public var allowPinned = false
    public var allowMentions = false
    public var allowKeywords = false

    public init() {}

    public struct Facts {
        public var message = false
        public var contact = false
        public var pinned = false
        public var mention = false
        public var keyword = false
        public init(message: Bool, contact: Bool = false, pinned: Bool = false, mention: Bool = false, keyword: Bool = false) {
            self.message = message
            self.contact = contact
            self.pinned = pinned
            self.mention = mention
            self.keyword = keyword
        }
    }

    public static func parse(_ raw: String) -> NagramQuietHours? {
        if raw.isEmpty {
            return NagramQuietHours()
        }
        guard let object = nagramJsonObject(raw), object["version"] as? Int == 1 else {
            return nil
        }
        var result = NagramQuietHours()
        guard let enabled = object["enabled"] as? Bool, let start = object["start"] as? Int, let end = object["end"] as? Int, let weekdays = object["weekdays"] as? [Int], (0 ..< 1440).contains(start), (0 ..< 1440).contains(end), weekdays.allSatisfy({ (1 ... 7).contains($0) }) else {
            return nil
        }
        result.enabled = enabled
        result.start = start
        result.end = end
        result.weekdays = weekdays
        result.allowContacts = object["allowContacts"] as? Bool ?? false
        result.allowPinned = object["allowPinned"] as? Bool ?? false
        result.allowMentions = object["allowMentions"] as? Bool ?? false
        result.allowKeywords = object["allowKeywords"] as? Bool ?? false
        return result
    }

    public func serialize() -> String {
        if self == NagramQuietHours() {
            return ""
        }
        return nagramJsonString([
            "version": 1,
            "enabled": enabled,
            "start": start,
            "end": end,
            "weekdays": Array(Set(weekdays)).sorted(),
            "allowContacts": allowContacts,
            "allowPinned": allowPinned,
            "allowMentions": allowMentions,
            "allowKeywords": allowKeywords,
        ])
    }

    private func selected(_ weekday: Int) -> Bool {
        return weekdays.isEmpty || weekdays.contains(weekday)
    }

    public func active(weekday: Int, minute: Int) -> Bool {
        if !enabled {
            return false
        } else if start == end {
            return selected(weekday)
        } else if start < end {
            return selected(weekday) && minute >= start && minute < end
        }
        let previous = weekday == 1 ? 7 : weekday - 1
        return (minute >= start && selected(weekday)) || (minute < end && selected(previous))
    }

    public func silences(_ facts: Facts, date: Date = Date()) -> Bool {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.weekday, .hour, .minute], from: date)
        let weekday = ((components.weekday ?? 1) + 5) % 7 + 1
        let minute = (components.hour ?? 0) * 60 + (components.minute ?? 0)
        if !active(weekday: weekday, minute: minute) {
            return false
        }
        if !facts.message {
            return true
        }
        return !((allowContacts && facts.contact) || (allowPinned && facts.pinned) || (allowMentions && facts.mention) || (allowKeywords && facts.keyword))
    }

    public static var current: NagramQuietHours {
        return parse(NagramOptions.quietHours.value) ?? NagramQuietHours()
    }
}

public struct NagramKeywordRule: Equatable {
    public var pattern: String
    public var regex: Bool
    public var caseSensitive: Bool

    public init(pattern: String, regex: Bool = false, caseSensitive: Bool = false) {
        self.pattern = pattern
        self.regex = regex
        self.caseSensitive = caseSensitive
    }

    public var line: String {
        return regex ? "/\(pattern)/\(caseSensitive ? "" : "i")" : pattern
    }
}

public struct NagramKeywordAlerts: Equatable {
    public static let maxRules = 50
    public static let maxLength = 256
    public static let maxText = 16384

    public var enabled = false
    public var channels = false
    public var rules: [NagramKeywordRule] = []

    public init() {}

    public static func parse(_ raw: String) -> NagramKeywordAlerts? {
        if raw.isEmpty {
            return NagramKeywordAlerts()
        }
        guard let object = nagramJsonObject(raw), object["version"] as? Int == 1, let enabled = object["enabled"] as? Bool, let channels = object["channels"] as? Bool, let rules = object["rules"] as? [[String: Any]], rules.count <= maxRules else {
            return nil
        }
        var result = NagramKeywordAlerts()
        result.enabled = enabled
        result.channels = channels
        for rule in rules {
            guard let pattern = rule["pattern"] as? String, let regex = rule["regex"] as? Bool, let caseSensitive = rule["caseSensitive"] as? Bool else {
                return nil
            }
            result.rules.append(NagramKeywordRule(pattern: pattern, regex: regex, caseSensitive: caseSensitive))
        }
        return result
    }

    public func serialize() -> String {
        if self == NagramKeywordAlerts() {
            return ""
        }
        return nagramJsonString([
            "version": 1,
            "enabled": enabled,
            "channels": channels,
            "rules": rules.map { ["pattern": $0.pattern, "regex": $0.regex, "caseSensitive": $0.caseSensitive] },
        ])
    }

    public static func parseLines(_ text: String) -> [NagramKeywordRule] {
        var result: [NagramKeywordRule] = []
        for raw in text.components(separatedBy: "\n") {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty {
                continue
            }
            var rule = NagramKeywordRule(pattern: line)
            let insensitive = line.hasSuffix("/i")
            let tail = insensitive ? 2 : 1
            if line.hasPrefix("/"), insensitive || line.hasSuffix("/"), line.count > 1 + tail {
                let start = line.index(after: line.startIndex)
                let end = line.index(line.endIndex, offsetBy: -tail)
                rule = NagramKeywordRule(pattern: String(line[start ..< end]), regex: true, caseSensitive: !insensitive)
            }
            if !result.contains(rule) {
                result.append(rule)
            }
        }
        return result
    }

    public static func problem(_ rules: [NagramKeywordRule]) -> Int? {
        if rules.count > maxRules {
            return maxRules + 1
        }
        for (i, rule) in rules.enumerated() {
            if rule.pattern.count > maxLength {
                return i + 1
            }
            if rule.regex, (try? NSRegularExpression(pattern: rule.pattern, options: rule.caseSensitive ? [] : [.caseInsensitive])) == nil {
                return i + 1
            }
        }
        return nil
    }

    public func matches(_ text: String, isChannel: Bool) -> Bool {
        guard enabled, !rules.isEmpty, !text.isEmpty else {
            return false
        }
        if isChannel && !channels {
            return false
        }
        let text = text.count > NagramKeywordAlerts.maxText ? String(text.prefix(NagramKeywordAlerts.maxText)) : text
        for rule in rules {
            if rule.regex {
                if let expression = try? NSRegularExpression(pattern: rule.pattern, options: rule.caseSensitive ? [] : [.caseInsensitive]), expression.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil {
                    return true
                }
            } else if text.range(of: rule.pattern, options: rule.caseSensitive ? [] : [.caseInsensitive]) != nil {
                return true
            }
        }
        return false
    }

    public static func current(account: Int64?) -> NagramKeywordAlerts {
        return parse(NagramOptions.keywordAlerts.value(account: account)) ?? NagramKeywordAlerts()
    }
}

public func nagramJsonObject(_ raw: String) -> [String: Any]? {
    guard let data = raw.data(using: .utf8) else {
        return nil
    }
    return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
}

public func nagramJsonString(_ object: [String: Any]) -> String {
    guard let data = try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]) else {
        return ""
    }
    return String(data: data, encoding: .utf8) ?? ""
}
