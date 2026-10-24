import Foundation

public struct NagramFilterRule: Equatable {
    public enum Action: String, CaseIterable {
        case mask
        case replace
        case hide
    }

    public var id: String
    public var title: String
    public var pattern: String
    public var replacement: String
    public var enabled: Bool
    public var caseInsensitive: Bool
    public var reversed: Bool
    public var action: Action

    public init(id: String = UUID().uuidString.lowercased(), title: String, pattern: String, replacement: String = "", enabled: Bool = false, caseInsensitive: Bool = true, reversed: Bool = false, action: Action = .hide) {
        self.id = id
        self.title = title
        self.pattern = pattern
        self.replacement = replacement
        self.enabled = enabled
        self.caseInsensitive = caseInsensitive
        self.reversed = reversed
        self.action = action
    }

    init?(json: [String: Any]) {
        guard let id = json["id"] as? String, let title = json["title"] as? String, let pattern = json["pattern"] as? String, let replacement = json["replacement"] as? String, let enabled = json["enabled"] as? Bool, let caseInsensitive = json["caseInsensitive"] as? Bool, let reversed = json["reversed"] as? Bool, let raw = json["action"] as? String, let action = Action(rawValue: raw) else {
            return nil
        }
        self.init(id: id, title: title, pattern: pattern, replacement: replacement, enabled: enabled, caseInsensitive: caseInsensitive, reversed: reversed, action: action)
    }

    var json: [String: Any] {
        return ["id": id, "title": title, "pattern": pattern, "replacement": replacement, "enabled": enabled, "caseInsensitive": caseInsensitive, "reversed": reversed, "action": action.rawValue]
    }

    public var expression: NSRegularExpression? {
        return NagramRegexCache.shared.expression(pattern, caseInsensitive: caseInsensitive)
    }

    public var isValid: Bool {
        return !title.isEmpty && title.count <= 128 && !pattern.isEmpty && pattern.count <= 2048 && replacement.count <= 4096 && (!reversed || action == .hide) && expression != nil
    }
}

public struct NagramFilterConfig: Equatable {
    public static let maxRules = 32

    public var enabled = false
    public var filterOutgoing = false
    public var hideBlocked = false
    public var stripZalgo = false
    public var hiddenAuthors: [String] = []
    public var excludedPeers: [String] = []
    public var rules: [NagramFilterRule] = []

    public init() {}

    public static func parse(_ raw: String) -> NagramFilterConfig? {
        if raw.isEmpty {
            return NagramFilterConfig()
        }
        guard let object = nagramJsonObject(raw), object["version"] as? Int == 1 else {
            return nil
        }
        var result = NagramFilterConfig()
        result.enabled = object["enabled"] as? Bool ?? false
        result.filterOutgoing = object["filterOutgoing"] as? Bool ?? false
        result.hideBlocked = object["hideBlocked"] as? Bool ?? false
        result.stripZalgo = object["stripZalgo"] as? Bool ?? false
        result.hiddenAuthors = object["hiddenAuthors"] as? [String] ?? []
        result.excludedPeers = object["excludedPeers"] as? [String] ?? []
        result.rules = (object["rules"] as? [[String: Any]] ?? []).compactMap(NagramFilterRule.init(json:))
        return result
    }

    public func serialize() -> String {
        if self == NagramFilterConfig() {
            return ""
        }
        return nagramJsonString([
            "version": 1,
            "enabled": enabled,
            "filterOutgoing": filterOutgoing,
            "hideBlocked": hideBlocked,
            "stripZalgo": stripZalgo,
            "hiddenAuthors": hiddenAuthors,
            "excludedPeers": excludedPeers,
            "rules": rules.map { $0.json },
        ])
    }

    public static func current(account: Int64?) -> NagramFilterConfig {
        return NagramRegexCache.shared.config(NagramOptions.filters.value(account: account))
    }

    public static func globalRules() -> [NagramFilterRule] {
        return NagramRegexCache.shared.globalRules(NagramOptions.filtersGlobal.value)
    }

    public static func setGlobalRules(_ rules: [NagramFilterRule]) {
        NagramOptions.filtersGlobal.set(rules.isEmpty ? "" : nagramJsonString(["version": 1, "rules": rules.map { $0.json }]))
    }
}

public struct NagramTextEdit {
    public let range: NSRange
    public let replacement: String
}

public struct NagramFilterResult {
    public var text: String
    public var hidden: Bool
    public var stages: [[NagramTextEdit]]

    public var changed: Bool {
        return !stages.isEmpty
    }

    public func remap(_ range: Range<Int>) -> Range<Int>? {
        var current: Range<Int>? = range
        for stage in stages {
            guard let value = current else {
                return nil
            }
            current = NagramFilter.remap(value, edits: stage)
        }
        return current
    }
}

public enum NagramFilter {
    public static let maxText = 16384

    private static func zalgoEdits(_ text: NSString) -> [NagramTextEdit] {
        var edits: [NagramTextEdit] = []
        var marks = 0
        var index = 0
        while index < text.length {
            let range = text.rangeOfComposedCharacterSequence(at: index)
            let piece = text.substring(with: range)
            var hasMark = false
            for scalar in piece.unicodeScalars.dropFirst() {
                let props = scalar.properties.generalCategory
                if props == .nonspacingMark || props == .spacingMark || props == .enclosingMark {
                    hasMark = true
                    marks += 1
                }
            }
            if hasMark && marks > 3, let first = piece.unicodeScalars.first {
                edits.append(NagramTextEdit(range: range, replacement: String(first)))
            }
            if !hasMark {
                marks = 0
            }
            index = range.location + range.length
        }
        return edits
    }

    public static func apply(edits: [NagramTextEdit], to text: String) -> String {
        let result = NSMutableString(string: text)
        for edit in edits.sorted(by: { $0.range.location > $1.range.location }) {
            result.replaceCharacters(in: edit.range, with: edit.replacement)
        }
        return result as String
    }

    public static func remap(_ range: Range<Int>, edits: [NagramTextEdit]) -> Range<Int>? {
        var lower = range.lowerBound
        var upper = range.upperBound
        for edit in edits.sorted(by: { $0.range.location > $1.range.location }) {
            let start = edit.range.location
            let end = edit.range.location + edit.range.length
            let delta = (edit.replacement as NSString).length - edit.range.length
            if end <= range.lowerBound {
                lower += delta
                upper += delta
            } else if start >= range.upperBound {
                continue
            } else if start >= range.lowerBound && end <= range.upperBound {
                upper += delta
            } else {
                return nil
            }
        }
        return lower < upper ? lower ..< upper : nil
    }

    public static func run(text: String, author: String, peer: String, blocked: Bool, outgoing: Bool, account: Int64?) -> NagramFilterResult {
        let unchanged = NagramFilterResult(text: text, hidden: false, stages: [])
        let config = NagramFilterConfig.current(account: account)
        if !config.enabled || config.excludedPeers.contains(peer) || (outgoing && !config.filterOutgoing) {
            return unchanged
        }
        if (blocked && config.hideBlocked) || config.hiddenAuthors.contains(author) {
            return NagramFilterResult(text: text, hidden: true, stages: [])
        }
        if (text as NSString).length > maxText {
            return unchanged
        }
        var current = text
        var stages: [[NagramTextEdit]] = []
        if config.stripZalgo {
            let edits = zalgoEdits(current as NSString)
            if !edits.isEmpty {
                current = apply(edits: edits, to: current)
                stages.append(edits)
            }
        }
        let rules = NagramFilterConfig.globalRules() + config.rules
        for rule in rules where rule.enabled {
            guard let expression = rule.expression else {
                continue
            }
            let nsText = current as NSString
            let matches = expression.matches(in: current, range: NSRange(location: 0, length: nsText.length))
            switch rule.action {
            case .hide:
                if !matches.isEmpty != rule.reversed {
                    return NagramFilterResult(text: text, hidden: true, stages: [])
                }
            case .mask, .replace:
                let edits = matches.filter { $0.range.length > 0 }.map { NagramTextEdit(range: $0.range, replacement: rule.action == .mask ? "•••" : rule.replacement) }
                if !edits.isEmpty {
                    current = apply(edits: edits, to: current)
                    stages.append(edits)
                }
            }
        }
        return NagramFilterResult(text: current, hidden: false, stages: stages)
    }
}

public enum NagramHiddenMessages {
    public static let maxCount = 1000

    private static func entries(account: Int64?) -> [String] {
        let raw = NagramOptions.hiddenMessages.value(account: account)
        return raw.isEmpty ? [] : raw.components(separatedBy: ",")
    }

    public static func contains(peerId: Int64, messageId: Int32, account: Int64?) -> Bool {
        let raw = NagramOptions.hiddenMessages.value(account: account)
        if raw.isEmpty {
            return false
        }
        return entries(account: account).contains("\(peerId):\(messageId)")
    }

    @discardableResult
    public static func toggle(peerId: Int64, messageId: Int32, account: Int64?) -> Bool {
        var list = entries(account: account)
        let key = "\(peerId):\(messageId)"
        if let index = list.firstIndex(of: key) {
            list.remove(at: index)
        } else {
            if list.count >= maxCount {
                return false
            }
            list.append(key)
        }
        NagramOptions.hiddenMessages.set(list.joined(separator: ","), account: account)
        return true
    }

    public static func count(account: Int64?) -> Int {
        return entries(account: account).count
    }

    public static func clear(account: Int64?) {
        NagramOptions.hiddenMessages.set("", account: account)
    }
}

final class NagramRegexCache {
    static let shared = NagramRegexCache()
    private let lock = NSLock()
    private var expressions: [String: NSRegularExpression] = [:]
    private var configs: [String: NagramFilterConfig] = [:]

    func expression(_ pattern: String, caseInsensitive: Bool) -> NSRegularExpression? {
        let key = (caseInsensitive ? "i:" : "s:") + pattern
        lock.lock()
        defer { lock.unlock() }
        if let cached = expressions[key] {
            return cached
        }
        guard let expression = try? NSRegularExpression(pattern: pattern, options: caseInsensitive ? [.caseInsensitive] : []) else {
            return nil
        }
        if expressions.count > 128 {
            expressions.removeAll()
        }
        expressions[key] = expression
        return expression
    }

    private var global: (String, [NagramFilterRule])?

    func globalRules(_ raw: String) -> [NagramFilterRule] {
        lock.lock()
        defer { lock.unlock() }
        if let global = global, global.0 == raw {
            return global.1
        }
        var rules: [NagramFilterRule] = []
        if let object = nagramJsonObject(raw), let list = object["rules"] as? [[String: Any]] {
            rules = list.compactMap(NagramFilterRule.init(json:))
        }
        global = (raw, rules)
        return rules
    }

    func config(_ raw: String) -> NagramFilterConfig {
        lock.lock()
        defer { lock.unlock() }
        if let cached = configs[raw] {
            return cached
        }
        let config = NagramFilterConfig.parse(raw) ?? NagramFilterConfig()
        if configs.count > 8 {
            configs.removeAll()
        }
        configs[raw] = config
        return config
    }
}
