import Cocoa
import NagramCore

func nagramChatsRows() -> [NagramRow] {
    let o = NagramOptions.self
    var rows: [NagramRow] = []
    rows.append(.header(nagramString("lng_nagram_chat_list")))
    rows.append(.choice(o.chatPreviewLines, choices: [
        NagramChoice(0, nagramString("lng_nagram_preview_follow")),
        NagramChoice(1, nagramString("lng_nagram_preview_one")),
    ]))
    rows.append(.toggle(o.secondsInChatList))
    rows.append(.toggle(o.hideSavedAndArchivedPreviews))
    rows.append(.toggle(o.hideStories))

    rows.append(.header(nagramString("lng_nagram_folders")))
    rows.append(.boundChoice(id: "startupFolderMode", title: nagramString("lng_nagram_startup_folder"), choices: [
        NagramChoice(0, nagramFollowTelegram()),
        NagramChoice(1, nagramString("lng_nagram_startup_folder_last")),
    ], get: { o.startupFolderMode.value(account: NagramSettings.shared.currentAccount) }, set: { value in
        o.startupFolderMode.set(value, account: NagramSettings.shared.currentAccount)
    }))
    rows.append(.toggle(o.hideAllChatsFolder))
    rows.append(.toggle(o.showArchiveInFolders))
    rows.append(.toggle(o.savedInFolderList))
    rows.append(.toggle(o.archiveInFolderList))
    rows.append(.toggle(o.hideFolderUnreadCounters))

    rows.append(.header(nagramString("lng_nagram_promotions")))
    rows.append(.toggle(o.hideSponsoredMessages))
    rows.append(.toggle(o.hideProxySponsor))
    rows.append(.toggle(o.hidePremiumPromotions))
    rows.append(.toggle(o.hideBirthdaySuggestions))

    rows.append(.header(nagramString("lng_nagram_navigation")))
    rows.append(.toggle(o.markMutualContacts))
    rows.append(.toggle(o.disableGlobalSearch))
    return rows
}
