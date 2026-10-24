import Cocoa
import NagramCore

private let implementedActions: [NagramMenuAction] = [
    .reply, .edit, .copy, .copyLink, .forward, .translate, .pin, .select, .statistics, .report, .blockSender, .image, .delete, .stickerPack, .seenBy,
    .repeatMessage, .repeatAsCopy, .messagesFromSender, .quickRating, .saveToSaved, .copyMarkdown, .mediaInfo, .deleteDownload, .messageDetails, .hideMessage, .filterAuthor, .summarize, .selectSender, .selectAll, .selectBetween,
]

func nagramMenuRows() -> [NagramRow] {
    let o = NagramOptions.self
    var rows: [NagramRow] = []
    rows.append(.toggle(o.confirmRepeat))
    rows.append(.toggle(o.repeatWithoutQuote, title: nagramString("lng_nagram_menu_repeat_without_quote")))
    rows.append(.toggle(o.noRepeatInChannels, title: nagramString("lng_nagram_menu_no_repeat_channels")))
    rows.append(.toggle(o.scrollAfterRepeat, title: nagramString("lng_nagram_menu_scroll_after_repeat")))
    rows.append(.text(o.quickRatingFirst, title: nagramString("lng_nagram_menu_quick_rating_first"), placeholder: nagramString("lng_nagram_menu_quick_rating_placeholder"), validate: { $0.count > 64 ? "64" : nil }))
    rows.append(.text(o.quickRatingSecond, title: nagramString("lng_nagram_menu_quick_rating_second"), placeholder: nagramString("lng_nagram_menu_quick_rating_placeholder"), validate: { $0.count > 64 ? "64" : nil }))

    rows.append(.header(nagramString("lng_nagram_menu")))
    let choices: [NagramChoice<Int>] = [
        NagramChoice(0, nagramString("lng_nagram_menu_shown")),
        NagramChoice(1, nagramString("lng_nagram_menu_hidden")),
        NagramChoice(2, nagramString("lng_nagram_menu_with_option")),
    ]
    for action in implementedActions {
        rows.append(.boundChoice(id: action.key, title: nagramString(action.titleKey), choices: choices, get: {
            switch action.visibility {
            case .show:
                return 0
            case .hide:
                return 1
            case .withOption:
                return 2
            }
        }, set: { value in
            action.setVisibility(value == 0 ? .show : value == 1 ? .hide : .withOption)
        }))
    }
    rows.append(.footer(nagramString("lng_nagram_menu_note")))
    return rows
}
