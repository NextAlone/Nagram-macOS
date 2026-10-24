import Cocoa
import NagramCore

func nagramPrivacyRows() -> [NagramRow] {
    let o = NagramOptions.self
    var rows: [NagramRow] = []
    rows.append(.toggle(o.hideMyPhone))
    rows.append(.toggle(o.demoMode, info: nagramString("lng_nagram_demo_mode_note")))
    rows.append(.toggle(o.hideReadTime))
    rows.append(.toggle(o.hideSharePhonePrompt))
    rows.append(.toggle(o.hideSendStatus, info: nagramString("lng_nagram_hide_send_status_about")))
    rows.append(.toggle(o.forceCopy, info: nagramString("lng_nagram_force_copy_about")))
    rows.append(.toggle(o.ignoreContentRestrictions, info: nagramString("lng_nagram_ignore_restrictions_about")))
    rows.append(.toggle(o.skipSensitiveWarning, info: nagramString("lng_nagram_skip_sensitive_warning_about")))

    rows.append(.header(nagramString("lng_nagram_profile_info")))
    rows.append(.choice(o.profileIdFormat, choices: [
        NagramChoice(0, nagramString("lng_nagram_id_off")),
        NagramChoice(1, nagramString("lng_nagram_id_bot_api")),
        NagramChoice(2, nagramString("lng_nagram_id_raw")),
    ]))
    rows.append(.toggle(o.showProfileDc))
    rows.append(.choice(o.nameOrder, choices: [
        NagramChoice(0, nagramFollowTelegram()),
        NagramChoice(1, nagramString("lng_nagram_name_order_first")),
        NagramChoice(2, nagramString("lng_nagram_name_order_last")),
    ]))
    rows.append(.toggle(o.hideProfileGifts))
    rows.append(.toggle(o.hideCreateTodo))
    return rows
}
