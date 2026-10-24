import Cocoa
import NagramCore

private func updateQuietHours(_ f: (inout NagramQuietHours) -> Void) {
    var value = NagramQuietHours.current
    f(&value)
    NagramOptions.quietHours.set(value.serialize())
}

private func minuteText(_ minute: Int) -> String {
    return String(format: "%02d:%02d", minute / 60, minute % 60)
}

private func parseMinute(_ text: String) -> Int? {
    let parts = text.trimmingCharacters(in: .whitespaces).components(separatedBy: ":")
    guard parts.count == 2, parts[0].count <= 2, parts[1].count == 2, let hours = Int(parts[0]), let minutes = Int(parts[1]), (0 ..< 24).contains(hours), (0 ..< 60).contains(minutes) else {
        return nil
    }
    return hours * 60 + minutes
}

func nagramQuietHoursRows() -> [NagramRow] {
    var rows: [NagramRow] = []
    let enabled = { NagramQuietHours.current.enabled }
    rows.append(.boundToggle(id: "quietHours.enabled", title: nagramString("lng_nagram_quiet_hours_enable"), get: enabled, set: { value in updateQuietHours { $0.enabled = value } }))
    rows.append(.footer(nagramString("lng_nagram_quiet_hours_about")))
    rows.append(.boundText(id: "quietHours.start", title: nagramString("lng_nagram_quiet_hours_start"), placeholder: "23:00", get: { minuteText(NagramQuietHours.current.start) }, set: { text in
        if let minute = parseMinute(text) {
            updateQuietHours { $0.start = minute }
        }
    }, validate: { parseMinute($0) == nil ? nagramString("lng_nagram_quiet_hours_bad_time") : nil }))
    rows.append(.boundText(id: "quietHours.end", title: nagramString("lng_nagram_quiet_hours_end"), placeholder: "07:00", get: { minuteText(NagramQuietHours.current.end) }, set: { text in
        if let minute = parseMinute(text) {
            updateQuietHours { $0.end = minute }
        }
    }, validate: { parseMinute($0) == nil ? nagramString("lng_nagram_quiet_hours_bad_time") : nil }))

    rows.append(.header(nagramString("lng_nagram_quiet_hours_days")))
    let symbols = Calendar.current.weekdaySymbols
    for day in 1 ... 7 {
        let title = symbols[day % 7]
        rows.append(.boundToggle(id: "quietHours.day\(day)", title: title, get: {
            let days = NagramQuietHours.current.weekdays
            return days.isEmpty || days.contains(day)
        }, set: { value in
            updateQuietHours { hours in
                var days = hours.weekdays.isEmpty ? Array(1 ... 7) : hours.weekdays
                if value {
                    days.append(day)
                } else {
                    days.removeAll(where: { $0 == day })
                }
                let unique = Array(Set(days)).sorted()
                hours.weekdays = unique.count == 7 ? [] : unique
            }
        }))
    }

    rows.append(.header(nagramString("lng_nagram_quiet_hours_exceptions")))
    rows.append(.boundToggle(id: "quietHours.contacts", title: nagramString("lng_nagram_quiet_hours_contacts"), get: { NagramQuietHours.current.allowContacts }, set: { value in updateQuietHours { $0.allowContacts = value } }))
    rows.append(.boundToggle(id: "quietHours.mentions", title: nagramString("lng_nagram_quiet_hours_mentions"), get: { NagramQuietHours.current.allowMentions }, set: { value in updateQuietHours { $0.allowMentions = value } }))
    rows.append(.boundToggle(id: "quietHours.keywords", title: nagramString("lng_nagram_quiet_hours_keywords"), get: { NagramQuietHours.current.allowKeywords }, set: { value in updateQuietHours { $0.allowKeywords = value } }))
    return rows
}

private func updateKeywords(_ f: (inout NagramKeywordAlerts) -> Void) {
    let account = NagramSettings.shared.currentAccount
    var value = NagramKeywordAlerts.current(account: account)
    f(&value)
    NagramOptions.keywordAlerts.set(value.serialize(), account: account)
}

func nagramKeywordAlertRows() -> [NagramRow] {
    var rows: [NagramRow] = []
    let current = { NagramKeywordAlerts.current(account: NagramSettings.shared.currentAccount) }
    rows.append(.boundToggle(id: "keywordAlerts.enabled", title: nagramString("lng_nagram_keyword_alerts_enable"), get: { current().enabled }, set: { value in updateKeywords { $0.enabled = value } }))
    rows.append(.boundToggle(id: "keywordAlerts.channels", title: nagramString("lng_nagram_keyword_alerts_channels"), get: { current().channels }, set: { value in updateKeywords { $0.channels = value } }))
    rows.append(.boundText(id: "keywordAlerts.rules", title: nagramString("lng_nagram_keyword_alerts_field"), get: { current().rules.map { $0.line }.joined(separator: "\n") }, set: { text in
        updateKeywords { $0.rules = NagramKeywordAlerts.parseLines(text) }
    }, validate: { text in
        let rules = NagramKeywordAlerts.parseLines(text)
        if rules.count > NagramKeywordAlerts.maxRules {
            return nagramString("lng_nagram_keyword_alerts_too_many", ["amount": "\(NagramKeywordAlerts.maxRules)"])
        }
        if let line = NagramKeywordAlerts.problem(rules) {
            return nagramString("lng_nagram_keyword_alerts_invalid", ["index": "\(line)", "error": nagramString("lng_nagram_keyword_alerts_too_long")])
        }
        return nil
    }))
    rows.append(.footer(nagramString("lng_nagram_keyword_alerts_about")))
    return rows
}
