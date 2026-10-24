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
