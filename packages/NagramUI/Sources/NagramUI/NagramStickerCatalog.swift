import Cocoa
import TGUIKit
import AlertsUI
import NagramCore
import TelegramCore
import Postbox
import SwiftSignalKit

private let catalogTypes: [(ItemCollectionId.Namespace, String)] = [
    (Namespaces.ItemCollection.CloudStickerPacks, "stickers"),
    (Namespaces.ItemCollection.CloudMaskPacks, "masks"),
    (Namespaces.ItemCollection.CloudEmojiPacks, "emoji"),
]

private func validCatalogEntry(shortName: String, title: String) -> Bool {
    guard shortName.range(of: "\\A[a-zA-Z0-9_]{1,64}\\z", options: .regularExpression) != nil, (title as NSString).length <= 256 else {
        return false
    }
    return !title.unicodeScalars.contains { scalar in
        switch scalar.properties.generalCategory {
        case .control, .lineSeparator, .paragraphSeparator:
            return true
        default:
            return false
        }
    }
}

private func stickerCatalog(_ postbox: Postbox) -> Signal<Data, NoError> {
    return postbox.transaction { transaction -> Data in
        var sets: [[String: Any]] = []
        var seen = Set<String>()
        for (namespace, type) in catalogTypes {
            for (_, info) in transaction.getItemCollectionsInfos(namespace: namespace) {
                guard let info = info as? StickerPackCollectionInfo, validCatalogEntry(shortName: info.shortName, title: info.title), seen.insert(info.shortName.lowercased()).inserted else {
                    continue
                }
                sets.append(["shortName": info.shortName, "title": info.title, "type": type])
            }
        }
        let object: [String: Any] = ["format": "nagram-sticker-catalog", "version": 1, "sets": sets]
        return (try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])) ?? Data()
    }
}

func nagramExportStickerCatalog(_ context: NagramActionContext) {
    let window = context.window
    _ = (stickerCatalog(context.context.account.postbox) |> deliverOnMainQueue).start(next: { data in
        let panel = NSSavePanel()
        panel.allowedFileTypes = ["json"]
        panel.nameFieldStringValue = "nagram-stickers.json"
        panel.beginSheetModal(for: window) { response in
            guard response == .OK, let url = panel.url else {
                return
            }
            do {
                try data.write(to: url, options: .atomic)
                showModalText(for: window, text: nagramString("lng_nagram_config_exported"))
            } catch {
                alert(for: window, info: nagramString("lng_nagram_config_write_error") + "\n\n" + error.localizedDescription)
            }
        }
    })
}
