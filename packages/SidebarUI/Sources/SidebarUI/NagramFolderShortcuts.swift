import Cocoa
import TGUIKit
import TelegramCore
import Localization
import NagramCore

func nagramShortcutFilter(_ shortcut: NagramFolderShortcut) -> ChatListFilter {
    let title: String
    let emoticon: String
    switch shortcut {
    case .saved:
        title = strings().peerSavedMessages
        emoticon = "⭐"
    case .archive:
        title = strings().chatListArchivedChats
        emoticon = "🗂"
    }
    let data = ChatListFilterData(isShared: false, hasSharedLinks: false, categories: [], excludeMuted: false, excludeRead: false, excludeArchived: false, includePeers: ChatListFilterIncludePeers(), excludePeers: [], color: nil)
    return .filter(id: shortcut.rawValue, title: ChatFolderTitle(text: title, entities: [], enableAnimations: false), emoticon: emoticon, data: data)
}

func nagramShortcutMenuItems(_ shortcut: NagramFolderShortcut) -> [ContextMenuItem] {
    return [ContextMenuItem(nagramString("lng_nagram_hide_folder_entry"), handler: {
        shortcut.option.set(false)
    })]
}
