import Postbox
import SwiftSignalKit
import TelegramCore
import NagramCore

public struct NagramArchiveUnread: Equatable {
    public let count: Int
    public let hasUnmutedUnread: Bool

    public init(count: Int, hasUnmutedUnread: Bool) {
        self.count = count
        self.hasUnmutedUnread = hasUnmutedUnread
    }
}

public func nagramArchiveUnread(engine: TelegramEngine) -> Signal<NagramArchiveUnread, NoError> {
    let key: PostboxViewKey = .unreadCounts(items: [.totalInGroup(Namespaces.PeerGroup.archive)])
    let tags: [PeerSummaryCounterTags] = [.contact, .nonContact, .group, .bot, .channel]
    return combineLatest(engine.account.postbox.combinedView(keys: [key]), NagramOptions.hideFolderUnreadCounters.signal) |> map { view, hidden in
        guard !hidden, let counts = view.views[key] as? UnreadMessageCountsView else {
            return NagramArchiveUnread(count: 0, hasUnmutedUnread: false)
        }
        for entry in counts.entries {
            if case let .totalInGroup(_, state) = entry {
                let count = tags.reduce(0) { $0 + Int(state.absoluteCounters[$1]?.chatCount ?? 0) }
                let unmuted = tags.contains { (state.filteredCounters[$0]?.chatCount ?? 0) != 0 }
                return NagramArchiveUnread(count: count, hasUnmutedUnread: unmuted)
            }
        }
        return NagramArchiveUnread(count: 0, hasUnmutedUnread: false)
    } |> distinctUntilChanged
}
