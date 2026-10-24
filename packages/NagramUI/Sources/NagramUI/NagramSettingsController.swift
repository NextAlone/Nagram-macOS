import Cocoa
import TGUIKit
import SwiftSignalKit
import TelegramContext
import TelegramTheme
import TelegramUtils
import InputDataUI
import GeneralRows
import AlertsUI
import Localization
import NagramCore
import TelegramCore

private struct State: Equatable {
    var revision: Int
    var highlighted: String?
}

private func _id_row(_ key: String) -> InputDataIdentifier {
    return InputDataIdentifier("_id_nagram_\(key)")
}

private final class Arguments {
    let context: any AccountContextProtocol
    let window: () -> Window
    let push: (ViewController) -> Void
    let changed: (Bool) -> Void
    init(context: any AccountContextProtocol, window: @escaping () -> Window, push: @escaping (ViewController) -> Void, changed: @escaping (Bool) -> Void) {
        self.context = context
        self.window = window
        self.push = push
        self.changed = changed
    }
    var actionContext: NagramActionContext {
        return NagramActionContext(context: context, window: window(), push: push)
    }
}

private func groups(_ rows: [NagramRow]) -> [[NagramRow]] {
    var result: [[NagramRow]] = []
    var current: [NagramRow] = []
    for row in rows where row.isVisible {
        if case .header = row, !current.isEmpty {
            result.append(current)
            current = []
        }
        current.append(row)
        if case .footer = row {
            result.append(current)
            current = []
        }
    }
    if !current.isEmpty {
        result.append(current)
    }
    return result
}

private func valueTitle<Value: Equatable>(_ choices: [NagramChoice<Value>], _ value: Value) -> String {
    return choices.first(where: { $0.value == value })?.title ?? "\(value)"
}

private func entries(_ section: NagramSection, state: State, arguments: Arguments) -> [InputDataEntry] {
    var entries: [InputDataEntry] = []
    var sectionId: Int32 = 0
    var index: Int32 = 0

    for group in groups(section.rows()) {
        entries.append(.sectionId(sectionId, type: .normal))
        sectionId += 1

        let interactive = group.filter {
            switch $0 {
            case .header, .footer:
                return false
            default:
                return true
            }
        }
        var position = 0
        for row in group {
            let viewType: GeneralViewType
            switch row {
            case .header, .footer:
                viewType = .singleItem
            default:
                viewType = bestGeneralViewType(interactive, for: position)
                position += 1
            }
            let restartSuffix = row.requiresRestart ? " · " + nagramString("lng_nagram_restart_required") : ""
            switch row {
            case let .header(text):
                entries.append(.desc(sectionId: sectionId, index: index, text: .plain(text), data: .init(color: theme.colors.listGrayText, viewType: .textTopItem)))
            case let .footer(text):
                entries.append(.desc(sectionId: sectionId, index: index, text: .plain(text), data: .init(color: theme.colors.listGrayText, viewType: .textBottomItem)))
            case let .toggle(option, _, info, _, enabled):
                let isEnabled = enabled?() ?? true
                let value = option.value
                entries.append(.general(sectionId: sectionId, index: index, value: .none, error: nil, identifier: _id_row(option.key), data: .init(name: row.title ?? "", color: theme.colors.text, type: .switchable(value), viewType: viewType, enabled: isEnabled, description: info.map { $0 + restartSuffix } ?? (restartSuffix.isEmpty ? nil : nagramString("lng_nagram_restart_required")), action: {
                    option.set(!option.value)
                    arguments.changed(option.flags.contains(.requiresRestart))
                })))
            case let .choice(option, _, choices, info, _):
                let current = option.value
                let items = choices.map { choice in
                    ContextMenuItem(choice.title, handler: {
                        option.set(choice.value)
                        arguments.changed(option.flags.contains(.requiresRestart))
                    }, state: choice.value == current ? .on : nil)
                }
                entries.append(.general(sectionId: sectionId, index: index, value: .none, error: nil, identifier: _id_row(option.key), data: .init(name: row.title ?? "", color: theme.colors.text, type: .contextSelector(valueTitle(choices, current), items), viewType: viewType, description: info.map { $0 + restartSuffix } ?? (restartSuffix.isEmpty ? nil : nagramString("lng_nagram_restart_required")))))
            case let .stringChoice(option, _, choices, info, _):
                let current = option.value
                let items = choices.map { choice in
                    ContextMenuItem(choice.title, handler: {
                        option.set(choice.value)
                        arguments.changed(option.flags.contains(.requiresRestart))
                    }, state: choice.value == current ? .on : nil)
                }
                entries.append(.general(sectionId: sectionId, index: index, value: .none, error: nil, identifier: _id_row(option.key), data: .init(name: row.title ?? "", color: theme.colors.text, type: .contextSelector(valueTitle(choices, current), items), viewType: viewType, description: info)))
            case let .text(option, _, placeholder, info, validate, _):
                let current = option.value
                let shown = current.isEmpty ? nagramString("lng_nagram_external_url_default") : current
                entries.append(.general(sectionId: sectionId, index: index, value: .none, error: nil, identifier: _id_row(option.key), data: .init(name: row.title ?? "", color: theme.colors.text, type: .nextContext(shown), viewType: viewType, description: info, action: {
                    let controller = NagramTextInputController(title: row.title ?? "", value: option.value, placeholder: placeholder, validate: validate, save: { value in
                        option.set(value)
                        arguments.changed(option.flags.contains(.requiresRestart))
                    })
                    showModal(with: controller, for: arguments.window())
                })))
            case let .boundToggle(id, title, info, get, set, _):
                let value = get()
                entries.append(.general(sectionId: sectionId, index: index, value: .none, error: nil, identifier: _id_row(id), data: .init(name: title, color: theme.colors.text, type: .switchable(value), viewType: viewType, description: info, action: {
                    set(!get())
                    arguments.changed(false)
                })))
            case let .boundChoice(id, title, choices, get, set, _):
                let current = get()
                let items = choices.map { choice in
                    ContextMenuItem(choice.title, handler: {
                        set(choice.value)
                        arguments.changed(false)
                    }, state: choice.value == current ? .on : nil)
                }
                entries.append(.general(sectionId: sectionId, index: index, value: .none, error: nil, identifier: _id_row(id), data: .init(name: title, color: theme.colors.text, type: .contextSelector(valueTitle(choices, current), items), viewType: viewType)))
            case let .boundText(id, title, placeholder, info, get, set, validate, _):
                let current = get()
                let shown = current.isEmpty ? nagramString("lng_nagram_external_url_default") : current.replacingOccurrences(of: "\n", with: ", ")
                entries.append(.general(sectionId: sectionId, index: index, value: .none, error: nil, identifier: _id_row(id), data: .init(name: title, color: theme.colors.text, type: .nextContext(shown.count > 40 ? String(shown.prefix(40)) + "…" : shown), viewType: viewType, description: info, action: {
                    let controller = NagramTextInputController(title: title, value: get(), placeholder: placeholder, validate: validate, multiline: true, save: { value in
                        set(value)
                        arguments.changed(false)
                    })
                    showModal(with: controller, for: arguments.window())
                })))
            case let .page(title, value, info, _, open):
                let type: GeneralInteractedType = value?().map { .nextContext($0) } ?? .next
                entries.append(.general(sectionId: sectionId, index: index, value: .none, error: nil, identifier: _id_row(title), data: .init(name: title, color: theme.colors.text, type: type, viewType: viewType, description: info, action: {
                    arguments.push(open(arguments.actionContext))
                })))
            case let .action(title, value, info, destructive, _, run):
                let type: GeneralInteractedType = value?().map { .context($0) } ?? .none
                entries.append(.general(sectionId: sectionId, index: index, value: .none, error: nil, identifier: _id_row(title), data: .init(name: title, color: destructive ? theme.colors.redUI : theme.colors.accent, type: type, viewType: viewType, description: info, action: {
                    run(arguments.actionContext)
                })))
            }
            index += 1
        }
    }

    entries.append(.sectionId(sectionId, type: .normal))
    sectionId += 1
    return entries
}

public func NagramSettingsController(context: any AccountContextProtocol, section: NagramSection, highlight: String? = nil) -> InputDataController {
    NagramSettings.shared.currentAccount = context.peerId.toInt64()
    let actionsDisposable = DisposableSet()
    let initialState = State(revision: 0, highlighted: highlight)
    let statePromise = ValuePromise(initialState, ignoreRepeated: true)
    let stateValue = Atomic(value: initialState)
    let updateState: ((State) -> State) -> Void = { f in
        statePromise.set(stateValue.modify(f))
    }

    var getController: (() -> ViewController?)? = nil
    let window: () -> Window = {
        return bestWindow(context, getController?())
    }

    let arguments = Arguments(context: context, window: window, push: { controller in
        nagramPush(controller, from: getController?(), context: context)
    }, changed: { requiresRestart in
        if requiresRestart {
            nagramAskRelaunch(window: window())
        }
    })

    actionsDisposable.add(NagramSettings.shared.revisions.start(next: { revision in
        updateState { current in
            var current = current
            current.revision = revision
            return current
        }
    }))

    let signal = statePromise.get() |> deliverOnPrepareQueue |> map { state in
        return InputDataSignalValue(entries: entries(section, state: state, arguments: arguments))
    }

    let controller = InputDataController(dataSignal: signal, title: section.title, removeAfterDisappear: false, hasDone: false, identifier: "nagram_\(section.id)")

    controller.didLoad = { controller, _ in
        if let highlight = highlight {
            controller.genericView.tableView.scroll(to: .center(id: InputDataEntryId.general(_id_row(highlight)), innerId: nil, animated: true, focus: .init(focus: true), inset: 0), inset: NSEdgeInsets())
        }
    }

    getController = { [weak controller] in
        return controller
    }
    controller.onDeinit = {
        actionsDisposable.dispose()
    }
    return controller
}

public func nagramAskRelaunch(window: Window) {
    verifyAlert(for: window, header: nagramString("lng_nagram_settings"), information: nagramString("lng_nagram_restart_confirm"), ok: nagramString("lng_nagram_restart_now"), successHandler: { _ in
        nagramRelaunch()
    })
}

public func nagramRelaunch() {
    let path = Bundle.main.bundlePath
    let process = Process()
    process.launchPath = "/bin/sh"
    process.arguments = ["-c", "sleep 1; /usr/bin/open -n \"$0\"", path]
    process.launch()
    NSApp.terminate(nil)
}

func nagramPush(_ controller: ViewController, from source: ViewController?, context: any AccountContextProtocol) {
    if let navigation = source?.navigationController {
        navigation.push(controller)
    } else {
        context.bindings.rootNavigation().push(controller)
    }
}
