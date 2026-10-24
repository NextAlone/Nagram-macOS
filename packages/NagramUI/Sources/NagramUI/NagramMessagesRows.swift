import Cocoa
import NagramCore

func nagramMessagesRows() -> [NagramRow] {
    let o = NagramOptions.self
    var rows: [NagramRow] = []
    rows.append(.header(nagramString("lng_nagram_time_and_info")))
    rows.append(.toggle(o.secondsInMessages))
    rows.append(.toggle(o.showForwardedMessageDate))
    rows.append(.toggle(o.showServiceTime))
    rows.append(.choice(o.messageIdPlace, choices: [
        NagramChoice(0, nagramString("lng_nagram_id_off")),
        NagramChoice(1, nagramString("lng_nagram_message_id_tooltip")),
        NagramChoice(2, nagramString("lng_nagram_message_id_bubble")),
    ]))

    rows.append(.header(nagramString("lng_nagram_marks_and_counts")))
    rows.append(.toggle(o.exactMessageCounters))
    rows.append(.toggle(o.hideMessageViews))
    rows.append(.toggle(o.hideChannelSignature))
    rows.append(.toggle(o.hideEditedBadge))
    rows.append(.toggle(o.editedIcon, visible: { !o.hideEditedBadge.value }))
    rows.append(.text(o.editedMark, visible: { !o.hideEditedBadge.value && !o.editedIcon.value }))

    rows.append(.header(nagramString("lng_nagram_reactions")))
    rows.append(.toggle(o.hideReactions))
    rows.append(.toggle(o.hidePrivateReactions, enabled: { !o.hideReactions.value }))
    rows.append(.toggle(o.hideGroupReactions, enabled: { !o.hideReactions.value }))
    rows.append(.toggle(o.hideChannelReactions, enabled: { !o.hideReactions.value }))
    rows.append(.toggle(o.hideReactionMenu))
    rows.append(.toggle(o.hideReactionMenuWhenSelecting))
    rows.append(.toggle(o.moveWhoReactedToTop))

    rows.append(.header(nagramString("lng_nagram_effects")))
    rows.append(.toggle(o.disablePremiumStickerEffects))
    rows.append(.toggle(o.disableEmojiInteractions))
    rows.append(.toggle(o.disableMessageEffects))

    rows.append(.header(nagramString("lng_nagram_content_display")))
    rows.append(.toggle(o.revealSpoilers, info: nagramString("lng_nagram_reveal_spoilers_note")))
    rows.append(.toggle(o.hideQuickShare))
    rows.append(.toggle(o.hideRecommendedChannels))
    rows.append(.toggle(o.collapseRecommendedChannels))
    rows.append(.toggle(o.simplifiedReplies))
    rows.append(.toggle(o.disableVideoUserpics))
    rows.append(.toggle(o.hidePremiumBadges))
    rows.append(.toggle(o.hideSavedTags))
    rows.append(.toggle(o.hidePrivateChatActivities, info: nagramString("lng_nagram_private_activities_note")))
    rows.append(.toggle(o.readingSpacing))
    rows.append(.choice(o.readingChinese, choices: [
        NagramChoice(0, nagramString("lng_nagram_reading_off")),
        NagramChoice(1, nagramString("lng_nagram_reading_simplified")),
        NagramChoice(2, nagramString("lng_nagram_reading_traditional")),
    ], info: nagramString("lng_nagram_reading_chinese_note")))
    return rows
}
