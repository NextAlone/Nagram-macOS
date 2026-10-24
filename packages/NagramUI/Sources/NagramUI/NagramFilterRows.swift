import Cocoa
import TGUIKit
import NagramCore

private var account: Int64? {
    return NagramSettings.shared.currentAccount
}

private func updateFilters(_ f: (inout NagramFilterConfig) -> Void) {
    var config = NagramFilterConfig.current(account: account)
    f(&config)
    NagramOptions.filters.set(config.serialize(), account: account)
}

private func updateRule(_ id: String, _ f: (inout NagramFilterRule) -> Void) {
    updateFilters { config in
        if let index = config.rules.firstIndex(where: { $0.id == id }) {
            f(&config.rules[index])
        }
    }
}

private func rule(_ id: String) -> NagramFilterRule? {
    return NagramFilterConfig.current(account: account).rules.first(where: { $0.id == id })
}

private func validatePattern(_ pattern: String) -> String? {
    do {
        _ = try NSRegularExpression(pattern: pattern)
        return nil
    } catch {
        return nagramString("lng_nagram_filter_pattern_error", ["index": "0", "error": error.localizedDescription])
    }
}

private func ruleRows(_ id: String) -> [NagramRow] {
    var rows: [NagramRow] = []
    rows.append(.boundToggle(id: "filter.\(id).enabled", title: nagramString("lng_nagram_filter_rule_enabled"), get: { rule(id)?.enabled ?? false }, set: { value in updateRule(id) { $0.enabled = value } }))
    rows.append(.boundText(id: "filter.\(id).title", title: nagramString("lng_nagram_filter_title"), get: { rule(id)?.title ?? "" }, set: { value in updateRule(id) { $0.title = value } }, validate: { $0.isEmpty || $0.count > 128 ? nagramString("lng_nagram_filter_title") : nil }))
    rows.append(.boundText(id: "filter.\(id).pattern", title: nagramString("lng_nagram_filter_pattern"), get: { rule(id)?.pattern ?? "" }, set: { value in updateRule(id) { $0.pattern = value } }, validate: validatePattern))
    rows.append(.boundChoice(id: "filter.\(id).action", title: nagramString("lng_nagram_filter_rule"), choices: [
        NagramChoice(0, nagramString("lng_nagram_filter_hide")),
        NagramChoice(1, nagramString("lng_nagram_filter_mask")),
        NagramChoice(2, nagramString("lng_nagram_filter_replace")),
    ], get: {
        switch rule(id)?.action ?? .hide {
        case .hide:
            return 0
        case .mask:
            return 1
        case .replace:
            return 2
        }
    }, set: { value in
        updateRule(id) { rule in
            rule.action = value == 0 ? .hide : value == 1 ? .mask : .replace
            if rule.action != .hide {
                rule.reversed = false
            }
        }
    }))
    rows.append(.boundText(id: "filter.\(id).replacement", title: nagramString("lng_nagram_filter_replacement"), get: { rule(id)?.replacement ?? "" }, set: { value in updateRule(id) { $0.replacement = value } }, visible: { rule(id)?.action == .replace }))
    rows.append(.boundToggle(id: "filter.\(id).case", title: nagramString("lng_nagram_filter_case"), get: { rule(id)?.caseInsensitive ?? true }, set: { value in updateRule(id) { $0.caseInsensitive = value } }))
    rows.append(.boundToggle(id: "filter.\(id).reversed", title: nagramString("lng_nagram_filter_reverse"), get: { rule(id)?.reversed ?? false }, set: { value in updateRule(id) { $0.reversed = value } }, visible: { rule(id)?.action == .hide }))
    rows.append(.header(""))
    rows.append(.action(title: nagramString("lng_nagram_menu_delete"), destructive: true, run: { context in
        updateFilters { config in
            config.rules.removeAll(where: { $0.id == id })
        }
        context.window.makeFirstResponder(nil)
    }))
    return rows
}

func nagramFilterRows() -> [NagramRow] {
    var rows: [NagramRow] = []
    let current = { NagramFilterConfig.current(account: account) }
    rows.append(.boundToggle(id: "filters.enabled", title: nagramString("lng_nagram_filter_enabled"), get: { current().enabled }, set: { value in updateFilters { $0.enabled = value } }))
    rows.append(.boundToggle(id: "filters.outgoing", title: nagramString("lng_nagram_filter_outgoing"), get: { current().filterOutgoing }, set: { value in updateFilters { $0.filterOutgoing = value } }))
    rows.append(.boundToggle(id: "filters.zalgo", title: nagramString("lng_nagram_filter_zalgo"), get: { current().stripZalgo }, set: { value in updateFilters { $0.stripZalgo = value } }))
    rows.append(.footer(nagramString("lng_nagram_filters_about")))

    rows.append(.header(nagramString("lng_nagram_filter_rules")))
    for item in current().rules {
        let id = item.id
        rows.append(.page(title: item.title, value: { rule(id)?.enabled == true ? nagramString("lng_nagram_config_on") : nagramString("lng_nagram_config_off") }, open: { context in
            return NagramSettingsController(context: context.context, section: NagramSection(id: "filter_\(id)", title: nagramString("lng_nagram_filter_rule"), rows: { ruleRows(id) }))
        }))
    }
    if current().rules.count < NagramFilterConfig.maxRules {
        rows.append(.action(title: nagramString("lng_nagram_filter_add"), run: { context in
            let controller = NagramTextInputController(title: nagramString("lng_nagram_filter_pattern"), value: "", placeholder: "spam|ads", validate: validatePattern, save: { pattern in
                let newRule = NagramFilterRule(title: pattern.count > 32 ? String(pattern.prefix(32)) : pattern, pattern: pattern, enabled: true)
                updateFilters { $0.rules.append(newRule) }
            })
            showModal(with: controller, for: context.window)
        }))
    }

    return rows
}
