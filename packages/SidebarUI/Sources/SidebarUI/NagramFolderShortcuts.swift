import Cocoa
import TGUIKit
import TelegramCore
import TelegramContext
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

func nagramShortcutMenuItems(_ shortcut: NagramFolderShortcut, context: any AccountContextProtocol, environment: SidebarUIEnvironment) -> [ContextMenuItem] {
    var items: [ContextMenuItem] = []
    switch shortcut {
    case .saved:
        items.append(ContextMenuItem(strings().accountOpenInWindow, handler: {
            environment.nagramOpenFolderShortcut(shortcut.rawValue, newWindow: true)
        }))
    case .archive:
        items.append(ContextMenuItem(strings().chatListFilterReadAll, handler: {
            _ = context.engine.messages.markAllChatsAsReadInteractively(items: [(groupId: .archive, filterPredicate: nil)]).start()
        }, itemImage: environment.menuImage(.menu_folder_read)))
    }
    items.append(ContextMenuItem(nagramString("lng_nagram_hide_folder_entry"), handler: {
        shortcut.option.set(false)
    }))
    return items
}
