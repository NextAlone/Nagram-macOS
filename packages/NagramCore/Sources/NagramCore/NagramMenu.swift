import Foundation

public enum NagramMenuAction: Int, CaseIterable {
    case reply = 1
    case edit
    case copy
    case copyLink
    case forward
    case translate
    case pin
    case select
    case statistics
    case report
    case blockSender
    case image
    case delete
    case stickerPack
    case repeatMessage
    case repeatAsCopy
    case forwardWithoutQuote
    case batch
    case selectSender
    case mediaInfo
    case screenshot = 21
    case reading = 22
    case filterAuthor = 23
    case deleteDownload = 25
    case quickRating = 26
    case selectBetween = 27
    case seenBy = 28
    case messageDetails = 29
    case hideMessage = 30
    case saveToSaved = 31
    case selectAll = 32
    case summarize = 36
    case transcribeSelected = 37
    case copyMarkdown = 39
    case messagesFromSender = 40

    public enum Visibility: Equatable {
        case show
        case hide
        case withOption
    }

    public var key: String {
        return String(format: "E%02d", rawValue)
    }

    public var isUpstream: Bool {
        return rawValue < NagramMenuAction.repeatMessage.rawValue || self == .seenBy
    }

    public var defaultVisibility: Visibility {
        return isUpstream ? .show : .hide
    }

    public var titleKey: String {
        switch self {
        case .reply: return "lng_nagram_menu_reply"
        case .edit: return "lng_nagram_menu_edit"
        case .copy: return "lng_nagram_menu_copy"
        case .copyLink: return "lng_nagram_menu_copy_link"
        case .forward: return "lng_nagram_menu_forward"
        case .translate: return "lng_nagram_menu_translate"
        case .pin: return "lng_nagram_menu_pin"
        case .select: return "lng_nagram_menu_select"
        case .statistics: return "lng_nagram_menu_statistics"
        case .report: return "lng_nagram_menu_report"
        case .blockSender: return "lng_nagram_menu_block_sender"
        case .image: return "lng_nagram_menu_image"
        case .delete: return "lng_nagram_menu_delete"
        case .stickerPack: return "lng_nagram_menu_sticker_pack"
        case .repeatMessage: return "lng_nagram_menu_repeat"
        case .repeatAsCopy: return "lng_nagram_menu_repeat_as_copy"
        case .forwardWithoutQuote: return "lng_nagram_menu_forward_without_quote"
        case .batch: return "lng_nagram_menu_batch"
        case .selectSender: return "lng_nagram_menu_select_sender"
        case .mediaInfo: return "lng_nagram_menu_media_info"
        case .screenshot: return "lng_nagram_menu_screenshot"
        case .reading: return "lng_nagram_menu_reading"
        case .filterAuthor: return "lng_nagram_filter_author_hide"
        case .deleteDownload: return "lng_nagram_menu_delete_download"
        case .quickRating: return "lng_nagram_menu_quick_rating"
        case .selectBetween: return "lng_nagram_menu_select_between"
        case .seenBy: return "lng_nagram_menu_seen_by"
        case .messageDetails: return "lng_nagram_menu_details"
        case .hideMessage: return "lng_nagram_hide_message"
        case .saveToSaved: return "lng_nagram_menu_save_to_saved"
        case .selectAll: return "lng_nagram_menu_select_all"
        case .summarize: return "lng_nagram_menu_summarize"
        case .transcribeSelected: return "lng_nagram_menu_transcribe_selected"
        case .copyMarkdown: return "lng_nagram_menu_copy_markdown"
        case .messagesFromSender: return "lng_nagram_menu_messages_from_sender"
        }
    }

    private static func states(_ raw: String) -> [String: String] {
        guard !raw.isEmpty, let object = nagramJsonObject(raw), let states = object["states"] as? [String: String] else {
            return [:]
        }
        return states
    }

    public var visibility: Visibility {
        var key = self.key
        let raw = NagramOptions.messageMenu.value
        if let object = nagramJsonObject(raw), object["version"] as? Int == 1 {
            if self == .screenshot {
                return defaultVisibility
            }
            if self == .reading {
                key = NagramMenuAction.screenshot.key
            }
        }
        switch NagramMenuAction.states(raw)[key] {
        case "hide":
            return .hide
        case "option":
            return .withOption
        case "show":
            return .show
        default:
            return defaultVisibility
        }
    }

    public func setVisibility(_ visibility: Visibility) {
        var states = NagramMenuAction.states(NagramOptions.messageMenu.value)
        if visibility == defaultVisibility {
            states.removeValue(forKey: key)
        } else {
            switch visibility {
            case .hide:
                states[key] = "hide"
            case .withOption:
                states[key] = "option"
            case .show:
                states[key] = "show"
            }
        }
        if states.isEmpty {
            NagramOptions.messageMenu.set("")
        } else {
            NagramOptions.messageMenu.set(nagramJsonString(["version": 2, "states": states]))
        }
    }

    public func isVisible(optionHeld: Bool) -> Bool {
        switch visibility {
        case .show:
            return true
        case .hide:
            return false
        case .withOption:
            return optionHeld
        }
    }
}

public enum NagramForwardRequest {
    private static var hideNames = false

    public static func requestHideNames() {
        hideNames = true
    }

    public static func takeHideNames() -> Bool {
        defer { hideNames = false }
        return hideNames
    }
}

public enum NagramFolderShortcut: Int32, CaseIterable {
    case saved = -103
    case archive = -104

    public var option: NagramOption<Bool> {
        switch self {
        case .saved:
            return NagramOptions.savedInFolderList
        case .archive:
            return NagramOptions.archiveInFolderList
        }
    }

    public static var visible: [NagramFolderShortcut] {
        return allCases.filter { $0.option.value }
    }
}
