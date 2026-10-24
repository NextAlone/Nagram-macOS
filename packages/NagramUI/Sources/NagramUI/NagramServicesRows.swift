import Cocoa
import TGUIKit
import SwiftSignalKit
import AlertsUI
import Localization
import NagramCore

private func updateConfig(_ f: (inout NagramServicesConfig) -> Void) {
    var config = NagramServicesConfig.current
    f(&config)
    config.save()
}

private func updateService(_ id: String, _ f: (inout NagramService) -> Void) {
    updateConfig { config in
        if let index = config.instances.firstIndex(where: { $0.id == id }) {
            f(&config.instances[index])
        }
    }
}

private func service(_ id: String) -> NagramService? {
    return NagramServicesConfig.current.service(id)
}

private func errorText(_ error: NagramServiceError) -> String {
    switch error {
    case .missingKey:
        return nagramString("lng_nagram_service_key_error")
    case let .http(code, _):
        return nagramString("lng_nagram_service_http_error", ["code": "\(code)"])
    case .network:
        return nagramString("lng_nagram_service_network_error")
    case .badResponse:
        return nagramString("lng_nagram_service_response_error")
    case .invalidAddress, .notConfigured:
        return nagramString("lng_nagram_service_invalid")
    }
}

private func testService(_ id: String, _ context: NagramActionContext) {
    guard let item = service(id) else {
        return
    }
    if item.validationError != nil {
        alert(for: context.window, info: nagramString("lng_nagram_service_invalid"))
        return
    }
    let language = nagramLanguage == .english ? "zh" : "en"
    let signal: Signal<String, NagramServiceError>
    if item.kind == .translation {
        signal = NagramServiceClient.translate(["Hello, world!"], to: language, service: item) |> map { $0.joined(separator: "\n") }
    } else {
        signal = .fail(.notConfigured)
    }
    _ = (showModalProgress(signal: signal |> deliverOnMainQueue, for: context.window)).start(next: { result in
        alert(for: context.window, header: nagramString("lng_nagram_service_test_translation"), info: result)
    }, error: { error in
        alert(for: context.window, info: errorText(error))
    })
}

private func serviceRows(_ id: String) -> [NagramRow] {
    var rows: [NagramRow] = []
    guard let initial = service(id) else {
        return rows
    }
    rows.append(.boundText(id: "service.\(id).name", title: nagramString("lng_nagram_service_name"), get: { service(id)?.name ?? "" }, set: { value in updateService(id) { $0.name = value } }))
    rows.append(.boundText(id: "service.\(id).url", title: nagramString("lng_nagram_service_url"), placeholder: "https://", get: { service(id)?.baseUrl ?? "" }, set: { value in updateService(id) { $0.baseUrl = value } }))
    rows.append(.boundText(id: "service.\(id).endpoint", title: nagramString("lng_nagram_service_endpoint"), get: { service(id)?.endpoint ?? "" }, set: { value in updateService(id) { $0.endpoint = value } }))
    let modelTitle: String
    switch initial.protocol {
    case "deepl":
        modelTitle = nagramString("lng_nagram_service_formality")
    case "microsoft":
        modelTitle = nagramString("lng_nagram_service_region")
    case "yandex":
        modelTitle = nagramString("lng_nagram_service_folder")
    default:
        modelTitle = nagramString("lng_nagram_service_model")
    }
    if initial.protocol != "google" {
        rows.append(.boundText(id: "service.\(id).model", title: modelTitle, get: { service(id)?.model ?? "" }, set: { value in updateService(id) { $0.model = value } }))
    }
    if initial.isLlm {
        rows.append(.boundText(id: "service.\(id).system", title: nagramString("lng_nagram_service_system_prompt"), get: { service(id)?.systemPrompt ?? "" }, set: { value in updateService(id) { $0.systemPrompt = value } }))
        rows.append(.boundText(id: "service.\(id).prompt", title: nagramString("lng_nagram_service_prompt"), get: { service(id)?.prompt ?? "" }, set: { value in updateService(id) { $0.prompt = value } }))
        rows.append(.boundText(id: "service.\(id).summary", title: nagramString("lng_nagram_service_summary_prompt"), get: { service(id)?.summaryPrompt ?? "" }, set: { value in updateService(id) { $0.summaryPrompt = value } }))
        rows.append(.boundText(id: "service.\(id).temperature", title: nagramString("lng_nagram_service_temperature"), get: { service(id)?.temperature.map { "\($0)" } ?? "" }, set: { value in updateService(id) { $0.temperature = Double(value) } }, validate: { value in
            if value.isEmpty {
                return nil
            }
            guard let number = Double(value), number >= 0, number <= 2 else {
                return nagramString("lng_nagram_service_invalid")
            }
            return nil
        }))
    }
    rows.append(.boundToggle(id: "service.\(id).useKey", title: nagramString("lng_nagram_service_use_key"), get: { service(id)?.useKey ?? true }, set: { value in updateService(id) { $0.useKey = value } }))
    rows.append(.action(title: nagramString("lng_nagram_service_key"), value: { () -> String? in
        guard let item = service(id) else {
            return nil
        }
        return NagramKeychain.secret(for: item.credentialAccount) == nil ? nagramString("lng_nagram_menu_quick_rating_empty") : "••••"
    }, visible: { service(id)?.useKey ?? true }, run: { context in
        let controller = NagramTextInputController(title: nagramString("lng_nagram_service_key"), value: "", placeholder: "sk-…", validate: nil, secure: true, save: { value in
            guard !value.isEmpty, let item = service(id) else {
                return
            }
            NagramKeychain.setSecret(value, for: item.credentialAccount)
            updateService(id) { _ in }
        })
        showModal(with: controller, for: context.window)
    }))
    rows.append(.footer(nagramString("lng_nagram_service_edit_about")))
    rows.append(.action(title: nagramString("lng_nagram_service_test"), info: nagramString("lng_nagram_service_test_about"), run: { context in
        testService(id, context)
    }))
    rows.append(.header(""))
    rows.append(.action(title: nagramString("lng_nagram_menu_delete"), destructive: true, run: { context in
        verifyAlert(for: context.window, information: nagramString("lng_nagram_service_delete_confirm"), successHandler: { _ in
            if let item = service(id) {
                NagramKeychain.setSecret(nil, for: item.credentialAccount)
            }
            updateConfig { config in
                config.instances.removeAll(where: { $0.id == id })
                if config.translation == id {
                    config.translation = ""
                }
                if config.summary == id {
                    config.summary = ""
                }
                if config.transcription == id {
                    config.transcription = ""
                }
            }
        })
    }))
    return rows
}

private func presetRows() -> [NagramRow] {
    var rows: [NagramRow] = [.header(nagramString("lng_nagram_service_presets_about"))]
    for preset in NagramServicePreset.all where preset.kind == .translation {
        let title = nagramString("lng_nagram_service_preset_translation", ["name": preset.name])
        rows.append(.action(title: title, run: { context in
            let item = preset.make()
            updateConfig { $0.instances.append(item) }
            context.push(NagramSettingsController(context: context.context, section: NagramSection(id: "service_\(item.id)", title: nagramString("lng_nagram_service_edit"), rows: { serviceRows(item.id) })))
        }))
    }
    return rows
}

private func instanceChoices(_ filter: (NagramService) -> Bool, empty: String) -> [NagramChoice<Int>] {
    let config = NagramServicesConfig.current
    return [NagramChoice<Int>(0, empty)] + config.instances.enumerated().filter { filter($0.element) }.map { NagramChoice($0.offset + 1, $0.element.name) }
}

private func selectedIndex(_ id: String) -> Int {
    return (NagramServicesConfig.current.instances.firstIndex(where: { $0.id == id }) ?? -1) + 1
}

private func instanceId(_ index: Int) -> String {
    let instances = NagramServicesConfig.current.instances
    return index > 0 && index <= instances.count ? instances[index - 1].id : ""
}

func nagramServicesRows() -> [NagramRow] {
    var rows: [NagramRow] = []
    let config = NagramServicesConfig.current
    rows.append(.boundChoice(id: "services.translation", title: nagramString("lng_nagram_service_translation"), choices: instanceChoices({ $0.kind == .translation }, empty: nagramFollowTelegram()), get: {
        selectedIndex(NagramServicesConfig.current.translation)
    }, set: { value in
        let id = instanceId(value)
        updateConfig { $0.translation = id }
    }))
    rows.append(.boundChoice(id: "services.summary", title: nagramString("lng_nagram_summary_service"), choices: instanceChoices({ $0.kind == .translation && $0.isLlm }, empty: nagramString("lng_nagram_summary_off")), get: {
        selectedIndex(NagramServicesConfig.current.summary)
    }, set: { value in
        let id = instanceId(value)
        updateConfig { $0.summary = id }
    }))
    rows.append(.footer(nagramString("lng_nagram_services_about")))

    rows.append(.header(nagramString("lng_nagram_services")))
    for item in config.instances {
        let id = item.id
        rows.append(.page(title: item.name, value: { service(id)?.protocol }, open: { context in
            return NagramSettingsController(context: context.context, section: NagramSection(id: "service_\(id)", title: nagramString("lng_nagram_service_edit"), rows: { serviceRows(id) }))
        }))
    }
    rows.append(.page(title: nagramString("lng_nagram_service_presets"), open: { context in
        return NagramSettingsController(context: context.context, section: NagramSection(id: "service_presets", title: nagramString("lng_nagram_service_presets"), rows: presetRows))
    }))
    return rows
}
