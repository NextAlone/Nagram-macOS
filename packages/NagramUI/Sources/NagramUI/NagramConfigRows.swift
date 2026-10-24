import Cocoa
import TGUIKit
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
        switch NagramExchange.plan(data) {
        case let .failure(error):
            alert(for: context.window, info: nagramImportErrorText(error))
        case let .success(plan):
            if plan.changes.isEmpty {
                alert(for: context.window, info: nagramString("lng_nagram_config_no_changes"))
                return
            }
            var lines: [String] = [nagramString("lng_nagram_config_import_about"), "", nagramString("lng_nagram_config_changes", ["amount": "\(plan.changes.count)"])]
            for change in plan.changes {
                lines.append("• \(optionTitle(change.key)): \(describe(change.before)) → \(describe(change.after))")
            }
            if !plan.skippedKeys.isEmpty {
                lines.append("")
                lines.append(nagramString("lng_nagram_config_unknown", ["amount": "\(plan.skippedKeys.count)"]))
                lines.append(plan.skippedKeys.prefix(20).joined(separator: ", "))
            }
            verifyAlert(for: context.window, header: nagramString("lng_nagram_config_preview"), information: lines.joined(separator: "\n"), ok: nagramString("lng_nagram_config_apply"), successHandler: { _ in
                switch NagramExchange.apply(plan) {
                case .success:
                    showModalText(for: context.window, text: nagramString("lng_nagram_config_imported"))
                case let .failure(error):
                    alert(for: context.window, info: nagramImportErrorText(error))
                }
            })
        }
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
