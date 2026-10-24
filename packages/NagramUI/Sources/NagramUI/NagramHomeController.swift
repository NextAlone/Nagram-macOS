import Cocoa
import TGUIKit
import SwiftSignalKit
import TelegramContext
import TelegramTheme
import TelegramUtils
import InputDataUI
import GeneralRows
import NagramCore
import Localization

public var nagramAppVersion: String {
    let info = Bundle.main.infoDictionary
    return "\(info?["CFBundleShortVersionString"] ?? "1") (\(info?["CFBundleVersion"] ?? "0"))"
}

public let nagramSourceCodeUrl = "https://github.com/NextAlone/Nagram-macOS"

private let _id_source = InputDataIdentifier("_id_nagram_source")

private func _id_section(_ id: String) -> InputDataIdentifier {
    return InputDataIdentifier("_id_nagram_section_\(id)")
}

private func entries(_ sections: [NagramSection], open: @escaping (NagramSection) -> Void) -> [InputDataEntry] {
    var entries: [InputDataEntry] = []
    var sectionId: Int32 = 0
    var index: Int32 = 0

    entries.append(.sectionId(sectionId, type: .normal))
    sectionId += 1

    entries.append(.general(sectionId: sectionId, index: index, value: .none, error: nil, identifier: _id_source, data: .init(name: nagramString("lng_nagram_source_code"), color: theme.colors.accent, type: .context(nagramAppVersion), viewType: .singleItem, action: {
        if let url = URL(string: nagramSourceCodeUrl) {
            NSWorkspace.shared.open(url)
        }
    })))
    index += 1

    entries.append(.sectionId(sectionId, type: .normal))
    sectionId += 1

    let visible = sections.filter { !$0.rows().isEmpty }
    for (i, section) in visible.enumerated() {
        entries.append(.general(sectionId: sectionId, index: index, value: .none, error: nil, identifier: _id_section(section.id), data: .init(name: section.title, color: theme.colors.text, type: .next, viewType: bestGeneralViewType(visible, for: i), action: {
            open(section)
        })))
        index += 1
    }

    entries.append(.desc(sectionId: sectionId, index: index, text: .plain(nagramString("lng_nagram_settings_note")), data: .init(color: theme.colors.listGrayText, viewType: .textBottomItem)))
    index += 1

    entries.append(.sectionId(sectionId, type: .normal))
    sectionId += 1
    return entries
}

public func NagramHomeController(context: any AccountContextProtocol) -> InputDataController {
    let sections = nagramSections()
    var getController: (() -> ViewController?)? = nil
    let open: (NagramSection) -> Void = { section in
        nagramPush(NagramSettingsController(context: context, section: section), from: getController?(), context: context)
    }
    let signal: Signal<InputDataSignalValue, NoError> = languageSignal |> deliverOnPrepareQueue |> map { _ in
        return InputDataSignalValue(entries: entries(sections, open: open))
    }
    let controller = InputDataController(dataSignal: signal, title: nagramString("lng_nagram_settings"), removeAfterDisappear: false, hasDone: false, identifier: "nagram_home")
    getController = { [weak controller] in
        return controller
    }
    return controller
}

public func NagramOpenSettingsLink(context: any AccountContextProtocol, sectionId: String?, row: String?) -> Bool {
    let sections = nagramSections()
    guard let sectionId = sectionId, !sectionId.isEmpty else {
        context.bindings.rootNavigation().push(NagramHomeController(context: context))
        return true
    }
    guard let section = sections.first(where: { $0.id == sectionId }) else {
        return false
    }
    let highlight = row.flatMap { row in
        section.rows().compactMap { $0.searchKey }.first(where: { $0 == "nagram.\(row)" || $0 == row })
    }
    context.bindings.rootNavigation().push(NagramSettingsController(context: context, section: section, highlight: highlight))
    return true
}

private let languageBinding = MetaDisposable()

public func nagramBindLanguage() {
    languageBinding.set(languageSignal.start(next: { language in
        nagramSetLanguageCodes([language.primaryLanguage.languageCode, language.languageCode])
    }))
}
