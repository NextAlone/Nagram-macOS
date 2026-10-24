import Cocoa
import TGUIKit
import AlertsUI
import NagramCore
import TelegramCore
import Postbox
import SwiftSignalKit
import TelegramContext
import EntertainmentUI
import TelegramTheme
import GeneralRows
import InputDataUI
import TelegramUtils

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

struct NagramStickerCatalogEntry: Equatable {
    let shortName: String
    let title: String
    let type: String
}

private let catalogMaxBytes = 1024 * 1024
private let catalogMaxEntries = 1000

func nagramParseStickerCatalog(_ data: Data) -> [NagramStickerCatalogEntry]? {
    guard data.count <= catalogMaxBytes, let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any], object.count == 3, object["format"] as? String == "nagram-sticker-catalog", (object["version"] as? NSNumber)?.intValue == 1, let sets = object["sets"] as? [Any], sets.count <= catalogMaxEntries else {
        return nil
    }
    var result: [NagramStickerCatalogEntry] = []
    var seen = Set<String>()
    for value in sets {
        guard let fields = value as? [String: Any], fields.count == 3, let shortName = fields["shortName"] as? String, let title = fields["title"] as? String, let type = fields["type"] as? String, catalogTypes.contains(where: { $0.1 == type }), validCatalogEntry(shortName: shortName, title: title), seen.insert(shortName.lowercased()).inserted else {
            return nil
        }
        result.append(NagramStickerCatalogEntry(shortName: shortName, title: title, type: type))
    }
    return result
}

private typealias InstalledPacks = [ItemCollectionId.Namespace: [(ItemCollectionId, StickerPackCollectionInfo)]]

private func plannedOrder(_ catalog: [NagramStickerCatalogEntry], type: String, installed: [(ItemCollectionId, StickerPackCollectionInfo)]) -> [ItemCollectionId] {
    var byName: [String: ItemCollectionId] = [:]
    for (id, info) in installed where !info.shortName.isEmpty {
        byName[info.shortName.lowercased()] = id
    }
    var result: [ItemCollectionId] = []
    for entry in catalog where entry.type == type {
        if let id = byName[entry.shortName.lowercased()], !result.contains(id) {
            result.append(id)
        }
    }
    for (id, _) in installed where !result.contains(id) {
        result.append(id)
    }
    return result
}

private func applyCatalogOrder(_ catalog: [NagramStickerCatalogEntry], installed: InstalledPacks, context: any AccountContextProtocol, window: Window) {
    var changed = 0
    for (namespace, type) in catalogTypes {
        let current = installed[namespace] ?? []
        let planned = plannedOrder(catalog, type: type, installed: current)
        if planned == current.map({ $0.0 }) {
            continue
        }
        changed += 1
        _ = context.engine.stickers.reorderStickerPacks(namespace: namespace, itemIds: planned).start()
    }
    showModalText(for: window, text: nagramString(changed == 0 ? "lng_nagram_catalog_unchanged" : "lng_nagram_catalog_submitted"))
}

private func catalogPreviewEntries(_ catalog: [NagramStickerCatalogEntry], installed: InstalledPacks, open: @escaping (NagramStickerCatalogEntry) -> Void, apply: @escaping () -> Void) -> [InputDataEntry] {
    var entries: [InputDataEntry] = []
    var sectionId: Int32 = 0
    var index: Int32 = 0
    entries.append(.sectionId(sectionId, type: .normal))
    sectionId += 1
    entries.append(.desc(sectionId: sectionId, index: index, text: .plain(nagramString("lng_nagram_catalog_preview_about")), data: .init(color: theme.colors.listGrayText, viewType: .textTopItem)))
    index += 1
    for (i, entry) in catalog.enumerated() {
        let namespace = catalogTypes.first(where: { $0.1 == entry.type })?.0
        let isInstalled = namespace.flatMap { installed[$0] }?.contains(where: { $0.1.shortName.lowercased() == entry.shortName.lowercased() }) ?? false
        let value = nagramString(isInstalled ? "lng_nagram_catalog_installed" : "lng_nagram_catalog_open")
        entries.append(.general(sectionId: sectionId, index: index, value: .none, error: nil, identifier: InputDataIdentifier("_id_catalog_\(i)"), data: .init(name: entry.title.isEmpty ? entry.shortName : entry.title, color: theme.colors.text, type: .nextContext(value), viewType: bestGeneralViewType(catalog, for: i), action: {
            open(entry)
        })))
        index += 1
    }
    entries.append(.sectionId(sectionId, type: .normal))
    sectionId += 1
    entries.append(.general(sectionId: sectionId, index: index, value: .none, error: nil, identifier: InputDataIdentifier("_id_catalog_apply"), data: .init(name: nagramString("lng_nagram_catalog_apply_order"), color: theme.colors.accent, type: .none, viewType: .singleItem, action: apply)))
    index += 1
    entries.append(.sectionId(sectionId, type: .normal))
    return entries
}

private func NagramStickerCatalogPreview(context: any AccountContextProtocol, catalog: [NagramStickerCatalogEntry]) -> InputDataController {
    let namespaces = catalogTypes.map { $0.0 }
    let installed: Signal<InstalledPacks, NoError> = context.account.postbox.combinedView(keys: [.itemCollectionInfos(namespaces: namespaces)]) |> map { view in
        var result: InstalledPacks = [:]
        if let infos = view.views[.itemCollectionInfos(namespaces: namespaces)] as? ItemCollectionInfosView {
            for (namespace, list) in infos.entriesByNamespace {
                result[namespace] = list.compactMap { entry in
                    (entry.info as? StickerPackCollectionInfo).map { (entry.id, $0) }
                }
            }
        }
        return result
    }
    let latest = Atomic<InstalledPacks?>(value: nil)
    var getController: (() -> ViewController?)? = nil
    let window: () -> Window = {
        return bestWindow(context, getController?())
    }
    let open: (NagramStickerCatalogEntry) -> Void = { entry in
        let reference: StickerPackReference = .name(entry.shortName)
        showModal(with: StickerPackPreviewModalController(context, peerId: nil, references: [entry.type == "emoji" ? .emoji(reference) : .stickers(reference)]), for: window())
    }
    let apply: () -> Void = {
        guard let current = latest.with({ $0 }) else {
            return
        }
        applyCatalogOrder(catalog, installed: current, context: context, window: window())
    }
    let signal = installed |> deliverOnPrepareQueue |> map { value -> InputDataSignalValue in
        _ = latest.swap(value)
        return InputDataSignalValue(entries: catalogPreviewEntries(catalog, installed: value, open: open, apply: apply))
    }
    let controller = InputDataController(dataSignal: signal, title: nagramString("lng_nagram_catalog_preview"), removeAfterDisappear: false, hasDone: false, identifier: "nagram_sticker_catalog")
    getController = { [weak controller] in
        return controller
    }
    return controller
}

func nagramImportStickerCatalog(_ context: NagramActionContext) {
    let panel = NSOpenPanel()
    panel.allowedFileTypes = ["json"]
    panel.allowsMultipleSelection = false
    panel.beginSheetModal(for: context.window) { response in
        guard response == .OK, let url = panel.url else {
            return
        }
        guard let data = try? Data(contentsOf: url), let catalog = nagramParseStickerCatalog(data) else {
            alert(for: context.window, info: nagramString("lng_nagram_catalog_invalid"))
            return
        }
        context.push(NagramStickerCatalogPreview(context: context.context, catalog: catalog))
    }
}
