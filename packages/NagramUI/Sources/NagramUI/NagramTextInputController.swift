import Cocoa
import TGUIKit
import SwiftSignalKit
import TelegramTheme
import InputDataUI
import GeneralRows
import Localization
import NagramCore

private let _id_value = InputDataIdentifier("_id_nagram_text_value")

public func NagramTextInputController(title: String, value: String, placeholder: String, validate: ((String) -> String?)?, multiline: Bool = false, secure: Bool = false, limit: Int32 = 1024, save: @escaping (String) -> Void) -> InputDataModalController {
    let errorValue = ValuePromise<String?>(nil, ignoreRepeated: true)

    let signal = errorValue.get() |> deliverOnPrepareQueue |> map { error -> InputDataSignalValue in
        var entries: [InputDataEntry] = []
        entries.append(.sectionId(0, type: .normal))
        entries.append(.input(sectionId: 1, index: 0, value: .string(value), error: error.map { InputDataValueError(description: $0, target: .data) }, identifier: _id_value, mode: secure ? .secure : .plain, data: .init(viewType: .singleItem, defaultText: value), placeholder: nil, inputPlaceholder: placeholder, filter: { $0 }, limit: limit))
        entries.append(.sectionId(1, type: .normal))
        return InputDataSignalValue(entries: entries)
    }

    var close: (() -> Void)? = nil

    let controller = InputDataController(dataSignal: signal, title: title, validateData: { data in
        let raw = data[_id_value]?.stringValue ?? ""
        let text = multiline ? raw.trimmingCharacters(in: .whitespacesAndNewlines) : raw.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\n", with: " ")
        if let validate = validate, let error = validate(text) {
            errorValue.set(error)
            return .fail(.fields([_id_value: .shake]))
        }
        save(text)
        close?()
        return .none
    })

    let modalInteractions = ModalInteractions(acceptTitle: nagramString("lng_nagram_text_save"), accept: { [weak controller] in
        _ = controller?.returnKeyAction()
    }, singleButton: true)

    let modalController = InputDataModalController(controller, modalInteractions: modalInteractions)
    controller.leftModalHeader = ModalHeaderData(image: theme.icons.modalClose, handler: {
        close?()
    })
    close = { [weak modalController] in
        modalController?.modal?.close()
    }
    return modalController
}
