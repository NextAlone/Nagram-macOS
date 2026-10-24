import Cocoa
import NagramCore

func nagramComposeRows() -> [NagramRow] {
    let o = NagramOptions.self
    var rows: [NagramRow] = []
    rows.append(.header(nagramString("lng_nagram_compose_buttons")))
    rows.append(.toggle(o.hideAttachButton))
    rows.append(.toggle(o.hideBotCommandButton))
    rows.append(.toggle(o.hideBotMenu))
    rows.append(.toggle(o.hideAutoDeleteButton))
    rows.append(.toggle(o.hideGiftButton))
    rows.append(.toggle(o.hideAiButton))
    rows.append(.toggle(o.hideSendAsButton))
    rows.append(.toggle(o.hideChannelMuteButton))
    rows.append(.toggle(o.channelDiscussButton))

    rows.append(.header(nagramString("lng_nagram_input_behavior")))
    rows.append(.toggle(o.disableEmojiHover))
    rows.append(.toggle(o.botCommandsToDraft))
    rows.append(.toggle(o.tallMentionList))
    rows.append(.choice(o.inputPlaceholderMode, choices: [
        NagramChoice(0, nagramFollowTelegram()),
        NagramChoice(1, nagramString("lng_nagram_placeholder_chat")),
        NagramChoice(2, nagramString("lng_nagram_placeholder_sender")),
    ]))

    rows.append(.header(nagramString("lng_nagram_text_format")))
    rows.append(.toggle(o.disableAutoMarkdown))
    rows.append(.toggle(o.disableLinkPreview))
    rows.append(.toggle(o.spaceOnSend))
    rows.append(.toggle(o.spaceOnEdit))
    rows.append(.choice(o.inputChinese, choices: [
        NagramChoice(0, nagramString("lng_nagram_reading_off")),
        NagramChoice(1, nagramString("lng_nagram_reading_simplified")),
        NagramChoice(2, nagramString("lng_nagram_reading_traditional")),
    ]))
    rows.append(.text(o.defaultCodeLanguage, placeholder: "swift"))

    rows.append(.header(nagramString("lng_nagram_send_confirmation")))
    rows.append(.toggle(o.confirmSticker))
    rows.append(.toggle(o.confirmGif))
    rows.append(.toggle(o.confirmPrivateCall))

    rows.append(.header(nagramString("lng_nagram_forwarding")))
    rows.append(.toggle(o.forwardBeforeComment))
    return rows
}
