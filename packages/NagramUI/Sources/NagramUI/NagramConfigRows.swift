import Cocoa
import TGUIKit
import SwiftSignalKit
import TelegramTheme
import InputDataUI
import Localization
import AlertsUI
import NagramCore
import TelegramCore
import MtProtoKit
import ApiCredentials

private func describe(_ value: Any?) -> String {
    switch value {
    case nil:
        return nagramFollowTelegram()
    case let value as Bool:
        return nagramString(value ? "lng_nagram_config_on" : "lng_nagram_config_off")
    case let value as String:
        return value.count > 48 ? String(value.prefix(48)) + "…" : value
    case let value?:
        return "\(value)"
    }
}

private func optionTitle(_ key: String) -> String {
    guard let info = NagramOptions.all.first(where: { $0.key == key }) else {
        return key
    }
    return nagramString(info.titleKey)
}

private func exportConfiguration(_ context: NagramActionContext) {
    let panel = NSSavePanel()
    panel.allowedFileTypes = ["json"]
    panel.nameFieldStringValue = "nagram-settings.json"
    panel.beginSheetModal(for: context.window) { response in
        guard response == .OK, let url = panel.url else {
            return
        }
        do {
            try NagramExchange.export().write(to: url, options: .atomic)
            showModalText(for: context.window, text: nagramString("lng_nagram_config_exported"))
        } catch {
            alert(for: context.window, info: nagramString("lng_nagram_config_write_error") + "\n\n" + error.localizedDescription)
        }
    }
}

private func importConfiguration(_ context: NagramActionContext) {
    let panel = NSOpenPanel()
    panel.allowedFileTypes = ["json"]
    panel.allowsMultipleSelection = false
    panel.beginSheetModal(for: context.window) { response in
        guard response == .OK, let url = panel.url else {
            return
        }
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            alert(for: context.window, info: nagramString("lng_nagram_config_read_error") + "\n\n" + error.localizedDescription)
            return
        }
        nagramShowImportPreview(data, target: .file, window: context.window)
    }
}

private func importPreviewSections(_ plan: NagramExchangePlan) -> [String] {
    var sections: [String] = []
    let available = plan.changes.filter { !plan.unavailableKeys.contains($0.key) }
    if plan.changes.isEmpty {
        sections.append(nagramString("lng_nagram_config_no_changes"))
    } else {
        sections.append(nagramString("lng_nagram_config_import_about"))
    }
    if !plan.unavailableKeys.isEmpty {
        sections.append(nagramString("lng_nagram_config_unavailable", ["amount": "\(plan.unavailableKeys.count)"]) + "\n" + plan.unavailableKeys.map(optionTitle).joined(separator: ", "))
    }
    if !available.isEmpty {
        let lines = available.map { "• \(optionTitle($0.key)): \(describe($0.before)) → \(describe($0.after))" }
        sections.append(([nagramString("lng_nagram_config_changes", ["amount": "\(available.count)"])] + lines).joined(separator: "\n"))
    }
    if plan.adjustedKeys.contains(where: { !plan.unavailableKeys.contains($0) }) {
        sections.append(nagramString("lng_nagram_inline_import_disabled"))
    }
    if !plan.skippedKeys.isEmpty {
        sections.append(nagramString("lng_nagram_config_unknown", ["amount": "\(plan.skippedKeys.count)"]) + "\n" + plan.skippedKeys.prefix(20).joined(separator: ", "))
    }
    return sections
}

private func showImportPreviewModal(_ plan: NagramExchangePlan, window: Window, applied: (() -> Void)?) {
    let sections = importPreviewSections(plan)
    let signal: Signal<InputDataSignalValue, NoError> = .single(InputDataSignalValue(entries: {
        var entries: [InputDataEntry] = []
        var sectionId: Int32 = 0
        var index: Int32 = 0
        entries.append(.sectionId(sectionId, type: .normal))
        sectionId += 1
        for section in sections {
            entries.append(.desc(sectionId: sectionId, index: index, text: .plain(section), data: .init(color: theme.colors.text, viewType: .textTopItem)))
            index += 1
            entries.append(.sectionId(sectionId, type: .normal))
            sectionId += 1
        }
        return entries
    }()))
    let controller = InputDataController(dataSignal: signal, title: nagramString("lng_nagram_config_preview"))
    var close: (() -> Void)?
    let interactions = ModalInteractions(acceptTitle: plan.changes.isEmpty ? strings().alertOK : nagramString("lng_nagram_config_apply"), accept: {
        close?()
        guard !plan.changes.isEmpty else {
            return
        }
        switch NagramExchange.apply(plan) {
        case .success:
            applied?()
            showModalText(for: window, text: nagramString("lng_nagram_config_imported"))
            if plan.requiresRestart {
                nagramAskRelaunch(window: window)
            }
        case let .failure(error):
            alert(for: window, info: nagramImportErrorText(error))
        }
    }, singleButton: true)
    let modal = InputDataModalController(controller, modalInteractions: interactions)
    controller.leftModalHeader = ModalHeaderData(image: theme.icons.modalClose, handler: { [weak modal] in
        modal?.close()
    })
    close = { [weak modal] in
        modal?.close()
    }
    showModal(with: modal, for: window)
}

func nagramShowImportPreview(_ data: Data, target: NagramExchangeTarget, window: Window, applied: (() -> Void)? = nil) {
    switch NagramExchange.plan(data, target: target) {
    case let .failure(error):
        alert(for: window, info: nagramImportErrorText(error))
    case let .success(plan):
        if plan.changes.isEmpty && plan.unavailableKeys.isEmpty {
            alert(for: window, info: nagramString("lng_nagram_config_no_changes"))
            return
        }
        showImportPreviewModal(plan, window: window, applied: applied)
    }
}

func nagramImportErrorText(_ error: NagramExchangeError) -> String {
    switch error {
    case .tooLarge:
        return nagramString("lng_nagram_sync_too_large")
    case .invalidJson, .unsupportedSchema:
        return nagramString("lng_nagram_sync_corrupted")
    case let .invalidValue(key):
        return nagramString("lng_nagram_config_invalid") + ": " + key
    case let .changedSincePreview(key):
        return nagramString("lng_nagram_config_changed_error") + " (" + key + ")"
    }
}

private func copyDiagnostics(_ context: NagramActionContext) {
    let all = NagramOptions.all.filter { !$0.flags.contains(.hidden) }
    let report = nagramString("lng_nagram_config_diagnostic_report", [
        "version": nagramAppVersion,
        "amount": "\(all.count)",
        "value": "\(NagramExchange.modifiedOptions().count)",
        "error": "0",
    ])
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(report, forType: .string)
    showModalText(for: context.window, text: nagramString("lng_nagram_config_copy_report"))
}

func nagramModifiedRows() -> [NagramRow] {
    let modified = NagramExchange.modifiedOptions()
    if modified.isEmpty {
        return [.footer(nagramString("lng_nagram_config_no_changes"))]
    }
    var rows: [NagramRow] = [.header(nagramString("lng_nagram_config_modified_about"))]
    let sections = nagramSections()
    for info in modified {
        let section = sections.first(where: { $0.id == info.category.rawValue })
        rows.append(.action(title: nagramString(info.titleKey), value: { describe(NagramSettings.shared.rawValue(for: info)) }, run: { context in
            if let section = section {
                context.push(NagramSettingsController(context: context.context, section: section, highlight: info.key))
            }
        }))
    }
    return rows
}

func nagramConfigRows() -> [NagramRow] {
    var rows: [NagramRow] = []
    rows.append(.header(nagramString("lng_nagram_config_scope")))
    rows.append(.page(title: nagramString("lng_nagram_config_modified"), value: { "\(NagramExchange.modifiedOptions().count)" }, open: { context in
        return NagramSettingsController(context: context.context, section: NagramSection(id: "modified", title: nagramString("lng_nagram_config_modified"), rows: nagramModifiedRows))
    }))
    rows.append(.action(title: nagramString("lng_nagram_config_export"), run: exportConfiguration))
    rows.append(.action(title: nagramString("lng_nagram_config_import"), run: importConfiguration))
    rows.append(.action(title: nagramString("lng_nagram_config_diagnostics"), run: copyDiagnostics))
    rows.append(contentsOf: nagramCloudSyncRows())
    rows.append(.header(nagramString("lng_nagram_debug_logs")))
    rows.append(.action(title: nagramString("lng_nagram_debug_logs"), value: { nagramString(Logger.shared.logToFile ? "lng_nagram_config_on" : "lng_nagram_config_off") }, run: { context in
        let enable = !Logger.shared.logToFile
        verifyAlert(for: context.window, information: nagramString(enable ? "lng_nagram_debug_logs_enable" : "lng_nagram_debug_logs_disable"), successHandler: { _ in
            MTLogSetEnabled(enable)
            _ = updateLoggingSettings(accountManager: context.context.sharedContext.accountManager, {
                $0.withUpdatedLogToFile(enable)
            }).start()
            Logger.shared.logToConsole = false
            Logger.shared.logToFile = enable
        })
    }))
    rows.append(.action(title: nagramString("lng_nagram_show_logs"), run: { _ in
        if let url = ApiEnvironment.containerURL?.appendingPathComponent("logs") {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
    }))
    rows.append(.footer(nagramString("lng_nagram_logs_note")))
    return rows
}
