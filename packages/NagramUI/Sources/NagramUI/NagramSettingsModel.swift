import Cocoa
import TGUIKit
import NagramCore
import TelegramContext

public struct NagramChoice<Value: Equatable> {
    public let value: Value
    public let title: String
    public init(_ value: Value, _ title: String) {
        self.value = value
        self.title = title
    }
}

public struct NagramActionContext {
    public let context: any AccountContextProtocol
    public let window: Window
    public let push: (ViewController) -> Void
}

public enum NagramRow {
    case header(String)
    case footer(String)
    case toggle(NagramOption<Bool>, title: String? = nil, info: String? = nil, visible: (() -> Bool)? = nil, enabled: (() -> Bool)? = nil)
    case choice(NagramOption<Int>, title: String? = nil, choices: [NagramChoice<Int>], info: String? = nil, visible: (() -> Bool)? = nil)
    case stringChoice(NagramOption<String>, title: String? = nil, choices: [NagramChoice<String>], info: String? = nil, visible: (() -> Bool)? = nil)
    case text(NagramOption<String>, title: String? = nil, placeholder: String = "", info: String? = nil, validate: ((String) -> String?)? = nil, visible: (() -> Bool)? = nil)
    case page(title: String, value: (() -> String?)? = nil, info: String? = nil, visible: (() -> Bool)? = nil, open: (NagramActionContext) -> ViewController)
    case action(title: String, value: (() -> String?)? = nil, info: String? = nil, destructive: Bool = false, visible: (() -> Bool)? = nil, run: (NagramActionContext) -> Void)
    case boundToggle(id: String, title: String, info: String? = nil, get: () -> Bool, set: (Bool) -> Void, visible: (() -> Bool)? = nil)
    case boundChoice(id: String, title: String, choices: [NagramChoice<Int>], get: () -> Int, set: (Int) -> Void, visible: (() -> Bool)? = nil)
    case boundText(id: String, title: String, placeholder: String = "", info: String? = nil, get: () -> String, set: (String) -> Void, validate: ((String) -> String?)? = nil, visible: (() -> Bool)? = nil)

    var isVisible: Bool {
        switch self {
        case .header, .footer:
            return true
        case let .toggle(_, _, _, visible, _), let .choice(_, _, _, _, visible), let .stringChoice(_, _, _, _, visible), let .text(_, _, _, _, _, visible), let .page(_, _, _, visible, _), let .action(_, _, _, _, visible, _), let .boundToggle(_, _, _, _, _, visible), let .boundText(_, _, _, _, _, _, _, visible), let .boundChoice(_, _, _, _, _, visible):
            return visible?() ?? true
        }
    }

    var searchKey: String? {
        switch self {
        case let .toggle(option, _, _, _, _):
            return option.key
        case let .choice(option, _, _, _, _):
            return option.key
        case let .stringChoice(option, _, _, _, _):
            return option.key
        case let .text(option, _, _, _, _, _):
            return option.key
        case let .page(title, _, _, _, _), let .action(title, _, _, _, _, _):
            return title
        case let .boundToggle(id, _, _, _, _, _), let .boundText(id, _, _, _, _, _, _, _), let .boundChoice(id, _, _, _, _, _):
            return id
        case .header, .footer:
            return nil
        }
    }

    var title: String? {
        switch self {
        case let .toggle(option, title, _, _, _):
            return title ?? nagramString(option.titleKey)
        case let .choice(option, title, _, _, _):
            return title ?? nagramString(option.titleKey)
        case let .stringChoice(option, title, _, _, _):
            return title ?? nagramString(option.titleKey)
        case let .text(option, title, _, _, _, _):
            return title ?? nagramString(option.titleKey)
        case let .page(title, _, _, _, _), let .action(title, _, _, _, _, _), let .boundToggle(_, title, _, _, _, _), let .boundText(_, title, _, _, _, _, _, _), let .boundChoice(_, title, _, _, _, _):
            return title
        case .header, .footer:
            return nil
        }
    }

    var requiresRestart: Bool {
        switch self {
        case let .toggle(option, _, _, _, _):
            return option.flags.contains(.requiresRestart)
        case let .choice(option, _, _, _, _):
            return option.flags.contains(.requiresRestart)
        case let .stringChoice(option, _, _, _, _):
            return option.flags.contains(.requiresRestart)
        case let .text(option, _, _, _, _, _):
            return option.flags.contains(.requiresRestart)
        default:
            return false
        }
    }
}

public struct NagramSection {
    public let id: String
    public let title: String
    public let rows: () -> [NagramRow]

    public init(id: String, title: String, rows: @escaping () -> [NagramRow]) {
        self.id = id
        self.title = title
        self.rows = rows
    }
}

public func nagramFollowTelegram() -> String {
    return nagramString("lng_nagram_preview_follow")
}

public func nagramPercentChoices(_ values: [Int], followDefault: Bool = true) -> [NagramChoice<Int>] {
    var result: [NagramChoice<Int>] = []
    if followDefault {
        result.append(NagramChoice(0, nagramFollowTelegram()))
    }
    for value in values {
        result.append(NagramChoice(value, "\(value)%"))
    }
    return result
}
