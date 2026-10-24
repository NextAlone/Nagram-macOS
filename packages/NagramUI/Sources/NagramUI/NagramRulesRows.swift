import Cocoa
import NagramCore
import AlertsUI

func nagramRulesRows() -> [NagramRow] {
    var rows: [NagramRow] = []
    rows.append(.page(title: nagramString("lng_nagram_filters"), value: { NagramFilterConfig.current(account: NagramSettings.shared.currentAccount).enabled ? nagramString("lng_nagram_config_on") : nagramString("lng_nagram_config_off") }, open: { context in
        return NagramSettingsController(context: context.context, section: NagramSection(id: "filters", title: nagramString("lng_nagram_filters"), rows: nagramFilterRows))
    }))
    rows.append(.action(title: nagramString("lng_nagram_hidden_messages"), value: { "\(NagramHiddenMessages.count(account: NagramSettings.shared.currentAccount))" }, run: { context in
        let account = NagramSettings.shared.currentAccount
        guard NagramHiddenMessages.count(account: account) > 0 else {
            return
        }
        verifyAlert(for: context.window, information: nagramString("lng_nagram_hidden_messages_clear"), successHandler: { _ in
            NagramHiddenMessages.clear(account: account)
        })
    }))
    rows.append(.page(title: nagramString("lng_nagram_keyword_alerts"), value: { NagramKeywordAlerts.current(account: NagramSettings.shared.currentAccount).enabled ? nagramString("lng_nagram_config_on") : nagramString("lng_nagram_config_off") }, open: { context in
        return NagramSettingsController(context: context.context, section: NagramSection(id: "keywordAlerts", title: nagramString("lng_nagram_keyword_alerts"), rows: nagramKeywordAlertRows))
    }))
    rows.append(contentsOf: nagramLinkRows())
    return rows
}

func nagramLinkRows() -> [NagramRow] {
    let o = NagramOptions.self
    var rows: [NagramRow] = []
    rows.append(.header(nagramString("lng_nagram_links_search_group")))
    rows.append(.toggle(o.disableOfficialAutoLogin))
    rows.append(.toggle(o.skipOpenLinkConfirm))
    let hashtagChoices = [
        NagramChoice(0, nagramFollowTelegram()),
        NagramChoice(1, nagramString("lng_nagram_hashtag_page_this_chat")),
        NagramChoice(2, nagramString("lng_nagram_hashtag_page_my_messages")),
    ]
    rows.append(.choice(o.hashtagSearchPageChannel, choices: hashtagChoices))
    rows.append(.choice(o.hashtagSearchPageChat, choices: hashtagChoices))
    rows.append(.header(nagramString("lng_nagram_web_app_group")))
    rows.append(.choice(o.webAppWidthScale, choices: [100, 125, 150, 175, 200].map { NagramChoice($0, "\($0)%") }))
    rows.append(.choice(o.webAppHeightScale, choices: [100, 125, 150, 175, 200].map { NagramChoice($0, "\($0)%") }))
    return rows
}
