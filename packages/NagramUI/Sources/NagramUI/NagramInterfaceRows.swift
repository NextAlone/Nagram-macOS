import Cocoa
import NagramCore

func nagramInterfaceRows() -> [NagramRow] {
    let o = NagramOptions.self
    var rows: [NagramRow] = []
    rows.append(.header(nagramString("lng_nagram_roundness_and_shapes")))
    rows.append(.choice(o.bubbleRoundness, choices: nagramPercentChoices([10, 25, 50, 75, 100])))
    rows.append(.choice(o.avatarRoundness, choices: nagramPercentChoices([10, 25, 50, 75, 100])))
    rows.append(.toggle(o.uniformAvatarShapes, visible: { o.avatarRoundness.value != 0 }))
    rows.append(.choice(o.searchRoundness, choices: nagramPercentChoices([10, 25, 50, 75, 100])))

    rows.append(.header(nagramString("lng_nagram_message_style")))
    rows.append(.choice(o.textMessageWidth, choices: nagramPercentChoices([50, 75, 125, 150, 200, 300, 400])))
    rows.append(.toggle(o.wideChannelPosts))
    rows.append(.toggle(o.hideBubbleTail))
    rows.append(.toggle(o.themeReplyColors))
    rows.append(.toggle(o.hideReplyThumbnail))
    rows.append(.toggle(o.ignoreChatTheme))
    rows.append(.toggle(o.ignorePrivateChatTheme, enabled: { !o.ignoreChatTheme.value }))
    rows.append(.toggle(o.ignoreChannelChatTheme, enabled: { !o.ignoreChatTheme.value }))

    rows.append(.header(nagramString("lng_nagram_window_notification")))
    rows.append(.toggle(o.hideAppIconBadge))
    let delays = [0, 500, 1000, 2000, 5000, 10000, 30000, 60000]
    rows.append(.choice(o.notificationDelay, choices: delays.map { NagramChoice($0, $0 == 0 ? nagramFollowTelegram() : String(format: "%g s", Double($0) / 1000)) }))
    rows.append(.page(title: nagramString("lng_nagram_quiet_hours"), value: { NagramQuietHours.current.enabled ? nagramString("lng_nagram_config_on") : nagramString("lng_nagram_config_off") }, open: { context in
        return NagramSettingsController(context: context.context, section: NagramSection(id: "quietHours", title: nagramString("lng_nagram_quiet_hours"), rows: nagramQuietHoursRows))
    }))
    return rows
}
