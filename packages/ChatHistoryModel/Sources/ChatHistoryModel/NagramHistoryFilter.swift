import Foundation
import Postbox
import TelegramCore
import NagramCore

private func codeRanges(_ entities: [MessageTextEntity]) -> [Range<Int>] {
    return entities.compactMap { entity in
        switch entity.type {
        case .Code, .Pre, .Url, .TextUrl, .Email, .Mention, .TextMention, .Hashtag, .BotCommand, .CustomEmoji:
            return entity.range
        default:
            return nil
        }
    }
}

private func hiddenPlaceholder(_ message: Message) -> Message {
    let attributes = message.attributes.filter { attribute in
        return !(attribute is TextEntitiesMessageAttribute || attribute is ReplyMarkupMessageAttribute || attribute is WebpagePreviewMessageAttribute)
    }
    return message.withUpdatedText(nagramString("lng_nagram_filter_hidden")).withUpdatedMedia([]).withUpdatedAttributes(attributes)
}

func nagramFilteredMessage(_ message: Message, accountPeerId: PeerId?) -> Message {
    let account = accountPeerId?.toInt64() ?? NagramSettings.shared.currentAccount
    if NagramHiddenMessages.contains(peerId: message.id.peerId.toInt64(), messageId: message.id.id, account: account) {
        return hiddenPlaceholder(message)
    }
    if message.text.isEmpty || message.media.contains(where: { $0 is TelegramMediaAction }) {
        return message
    }
    let outgoing = !message.flags.contains(.Incoming)
    let author = message.author.map { String($0.id.toInt64()) } ?? ""
    let result = NagramFilter.run(text: message.text, author: author, peer: String(message.id.peerId.toInt64()), blocked: false, outgoing: outgoing, account: account)
    if result.hidden {
        return hiddenPlaceholder(message)
    }
    let originalEntities = message.textEntitiesAttribute?.entities ?? []
    let filteredEntities = originalEntities.compactMap { entity -> MessageTextEntity? in
        guard let range = result.remap(entity.range) else {
            return nil
        }
        return MessageTextEntity(range: range, type: entity.type)
    }
    let reading = NagramText.readingStages(result.text, codeRanges: codeRanges(filteredEntities))
    guard result.changed || !reading.isEmpty else {
        return message
    }
    let text = NagramText.apply(stages: reading, to: result.text)
    let entities = filteredEntities.compactMap { entity -> MessageTextEntity? in
        guard let range = NagramText.remap(entity.range, stages: reading) else {
            return nil
        }
        return MessageTextEntity(range: range, type: entity.type)
    }
    var attributes = message.attributes.filter { !($0 is TextEntitiesMessageAttribute) }
    if !entities.isEmpty {
        attributes.append(TextEntitiesMessageAttribute(entities: entities))
    }
    return message.withUpdatedText(text).withUpdatedAttributes(attributes)
}

public func nagramReadingQuoteSource(_ original: Message, accountPeerId: PeerId?, shown: NSRange) -> (text: String, offset: Int, entities: [MessageTextEntity])? {
    let account = accountPeerId?.toInt64() ?? NagramSettings.shared.currentAccount
    if original.text.isEmpty || NagramHiddenMessages.contains(peerId: original.id.peerId.toInt64(), messageId: original.id.id, account: account) {
        return nil
    }
    let outgoing = !original.flags.contains(.Incoming)
    let author = original.author.map { String($0.id.toInt64()) } ?? ""
    let result = NagramFilter.run(text: original.text, author: author, peer: String(original.id.peerId.toInt64()), blocked: false, outgoing: outgoing, account: account)
    if result.hidden || result.changed {
        return nil
    }
    let entities = original.textEntitiesAttribute?.entities ?? []
    let reading = NagramText.readingStages(original.text, codeRanges: codeRanges(entities))
    if reading.isEmpty {
        return nil
    }
    let text = original.text as NSString
    var range = NagramText.sourceRange(shown, stages: reading)
    guard range.location + range.length <= text.length else {
        return nil
    }
    while range.length > 0, let scalar = UnicodeScalar(text.character(at: range.location)), CharacterSet.whitespacesAndNewlines.contains(scalar) {
        range = NSRange(location: range.location + 1, length: range.length - 1)
    }
    while range.length > 0, let scalar = UnicodeScalar(text.character(at: range.location + range.length - 1)), CharacterSet.whitespacesAndNewlines.contains(scalar) {
        range.length -= 1
    }
    if range.length == 0 {
        return nil
    }
    return (text: text.substring(with: range), offset: range.location, entities: messageTextEntitiesInRange(entities: entities, range: range, onlyQuoteable: true))
}
