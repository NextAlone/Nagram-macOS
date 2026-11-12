import Foundation
import Postbox
import TelegramCore
import SwiftSignalKit
import TelegramContext
import NagramCore

enum NagramPageTranslationError: Error {
    case service(String)
    case telegram
}

private func nagramPlainText(_ text: RichText) -> String {
    switch text {
    case .empty, .image, .formula, .textCustomEmoji, .textButton:
        return ""
    case let .plain(value):
        return value
    case let .bold(text), let .italic(text), let .underline(text), let .strikethrough(text), let .fixed(text), let .subscript(text), let .superscript(text), let .marked(text):
        return nagramPlainText(text)
    case let .url(text, _, _), let .email(text, _), let .phone(text, _), let .anchor(text, _):
        return nagramPlainText(text)
    case let .textAutoEmail(text), let .textAutoPhone(text), let .textAutoUrl(text), let .textBankCard(text), let .textTonAddress(text), let .textBotCommand(text), let .textCashtag(text), let .textHashtag(text), let .textMention(text), let .textSpoiler(text):
        return nagramPlainText(text)
    case let .textMentionName(text, _), let .textDate(text, _, _):
        return nagramPlainText(text)
    case let .concat(texts):
        return texts.map(nagramPlainText).joined()
    }
}

private func nagramHasInlineObjects(_ text: RichText) -> Bool {
    switch text {
    case .image, .formula, .textCustomEmoji, .textButton:
        return true
    case .empty, .plain:
        return false
    case let .bold(text), let .italic(text), let .underline(text), let .strikethrough(text), let .fixed(text), let .subscript(text), let .superscript(text), let .marked(text):
        return nagramHasInlineObjects(text)
    case let .url(text, _, _), let .email(text, _), let .phone(text, _), let .anchor(text, _):
        return nagramHasInlineObjects(text)
    case let .textAutoEmail(text), let .textAutoPhone(text), let .textAutoUrl(text), let .textBankCard(text), let .textTonAddress(text), let .textBotCommand(text), let .textCashtag(text), let .textHashtag(text), let .textMention(text), let .textSpoiler(text):
        return nagramHasInlineObjects(text)
    case let .textMentionName(text, _), let .textDate(text, _, _):
        return nagramHasInlineObjects(text)
    case let .concat(texts):
        return texts.contains(where: nagramHasInlineObjects)
    }
}

private func nagramTextRuns(_ text: RichText) -> Int {
    switch text {
    case let .plain(value):
        return value.isEmpty ? 0 : 1
    case let .concat(texts):
        return texts.reduce(0) { $0 + nagramTextRuns($1) }
    case let .bold(text), let .italic(text), let .underline(text), let .strikethrough(text), let .fixed(text), let .subscript(text), let .superscript(text), let .marked(text):
        return nagramTextRuns(text)
    case let .url(text, _, _), let .email(text, _), let .phone(text, _), let .anchor(text, _):
        return nagramTextRuns(text)
    case let .textAutoEmail(text), let .textAutoPhone(text), let .textAutoUrl(text), let .textBankCard(text), let .textTonAddress(text), let .textBotCommand(text), let .textCashtag(text), let .textHashtag(text), let .textMention(text), let .textSpoiler(text):
        return nagramTextRuns(text)
    case let .textMentionName(text, _), let .textDate(text, _, _):
        return nagramTextRuns(text)
    default:
        return 0
    }
}

private func nagramReplacingRun(_ text: RichText, with value: String) -> RichText {
    switch text {
    case let .plain(current):
        return current.isEmpty ? text : .plain(value)
    case let .concat(texts):
        return .concat(texts.map { nagramTextRuns($0) > 0 ? nagramReplacingRun($0, with: value) : $0 })
    case let .bold(text):
        return .bold(nagramReplacingRun(text, with: value))
    case let .italic(text):
        return .italic(nagramReplacingRun(text, with: value))
    case let .underline(text):
        return .underline(nagramReplacingRun(text, with: value))
    case let .strikethrough(text):
        return .strikethrough(nagramReplacingRun(text, with: value))
    case let .fixed(text):
        return .fixed(nagramReplacingRun(text, with: value))
    case let .subscript(text):
        return .subscript(nagramReplacingRun(text, with: value))
    case let .superscript(text):
        return .superscript(nagramReplacingRun(text, with: value))
    case let .marked(text):
        return .marked(nagramReplacingRun(text, with: value))
    case let .url(text, url, webpageId):
        return .url(text: nagramReplacingRun(text, with: value), url: url, webpageId: webpageId)
    case let .email(text, email):
        return .email(text: nagramReplacingRun(text, with: value), email: email)
    case let .phone(text, phone):
        return .phone(text: nagramReplacingRun(text, with: value), phone: phone)
    case let .anchor(text, name):
        return .anchor(text: nagramReplacingRun(text, with: value), name: name)
    case let .textSpoiler(text):
        return .textSpoiler(text: nagramReplacingRun(text, with: value))
    default:
        return .plain(value)
    }
}

final class NagramPageTexts {
    private(set) var texts: [String] = []
    private let replacements: [String]?
    private var index = 0

    init(replacements: [String]? = nil) {
        self.replacements = replacements
    }

    func text(_ rich: RichText) -> RichText {
        let plain = nagramPlainText(rich)
        if plain.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || nagramHasInlineObjects(rich) {
            return rich
        }
        guard let replacements = replacements else {
            texts.append(plain)
            return rich
        }
        let value = replacements[index]
        index += 1
        return nagramTextRuns(rich) == 1 ? nagramReplacingRun(rich, with: value) : .plain(value)
    }

    func caption(_ caption: InstantPageCaption) -> InstantPageCaption {
        return InstantPageCaption(text: text(caption.text), credit: text(caption.credit))
    }

    func blocks(_ blocks: [InstantPageBlock]) -> [InstantPageBlock] {
        return blocks.map(block)
    }

    func block(_ block: InstantPageBlock) -> InstantPageBlock {
        switch block {
        case let .title(value):
            return .title(text(value))
        case let .subtitle(value):
            return .subtitle(text(value))
        case let .authorDate(author, date):
            return .authorDate(author: text(author), date: date)
        case let .header(value):
            return .header(text(value))
        case let .subheader(value):
            return .subheader(text(value))
        case let .heading(value, level):
            return .heading(text: text(value), level: level)
        case let .paragraph(value):
            return .paragraph(text(value))
        case let .footer(value):
            return .footer(text(value))
        case let .kicker(value):
            return .kicker(text(value))
        case let .thinking(value):
            return .thinking(text(value))
        case let .list(items, ordered):
            return .list(items: items.map { item in
                switch item {
                case let .text(value, number, checked):
                    return .text(text(value), number, checked)
                case let .blocks(values, number, checked):
                    return .blocks(blocks(values), number, checked)
                case .unknown:
                    return item
                }
            }, ordered: ordered)
        case let .blockQuote(values, quoteCaption, collapsed):
            return .blockQuote(blocks: blocks(values), caption: text(quoteCaption), collapsed: collapsed)
        case let .pullQuote(value, quoteCaption):
            return .pullQuote(text: text(value), caption: text(quoteCaption))
        case let .image(id, value, url, webpageId, spoiler):
            return .image(id: id, caption: caption(value), url: url, webpageId: webpageId, spoiler: spoiler)
        case let .video(id, value, autoplay, loop, spoiler):
            return .video(id: id, caption: caption(value), autoplay: autoplay, loop: loop, spoiler: spoiler)
        case let .audio(id, value):
            return .audio(id: id, caption: caption(value))
        case let .document(id, value):
            return .document(id: id, caption: caption(value))
        case let .buttonRow(alignment, buttons):
            return .buttonRow(alignment: alignment, buttons: buttons.map { InstantPageButton(text: text($0.text), action: $0.action, color: $0.color, isLink: $0.isLink) })
        case let .cover(value):
            return .cover(self.block(value))
        case let .webEmbed(url, html, dimensions, value, stretchToWidth, allowScrolling, coverId):
            return .webEmbed(url: url, html: html, dimensions: dimensions, caption: caption(value), stretchToWidth: stretchToWidth, allowScrolling: allowScrolling, coverId: coverId)
        case let .postEmbed(url, webpageId, avatarId, author, date, values, value):
            return .postEmbed(url: url, webpageId: webpageId, avatarId: avatarId, author: author, date: date, blocks: blocks(values), caption: caption(value))
        case let .collage(items, value):
            return .collage(items: blocks(items), caption: caption(value))
        case let .slideshow(items, value):
            return .slideshow(items: blocks(items), caption: caption(value))
        case let .table(title, rows, bordered, striped, compact):
            return .table(title: text(title), rows: rows.map { row in
                InstantPageTableRow(cells: row.cells.map { cell in
                    InstantPageTableCell(text: cell.text.map(text), header: cell.header, alignment: cell.alignment, verticalAlignment: cell.verticalAlignment, colspan: cell.colspan, rowspan: cell.rowspan)
                })
            }, bordered: bordered, striped: striped, compact: compact)
        case let .details(title, values, expanded):
            return .details(title: text(title), blocks: blocks(values), expanded: expanded)
        case let .relatedArticles(title, articles):
            return .relatedArticles(title: text(title), articles: articles)
        case let .map(latitude, longitude, zoom, dimensions, value):
            return .map(latitude: latitude, longitude: longitude, zoom: zoom, dimensions: dimensions, caption: caption(value))
        case .unsupported, .formula, .preformatted, .divider, .anchor, .channelBanner:
            return block
        }
    }
}

private let nagramPageBatchTexts = 20
private let nagramPageBatchBytes = 24 * 1024

func nagramPageBatches(_ texts: [String]) -> [Range<Int>] {
    var result: [Range<Int>] = []
    var start = 0
    var bytes = 0
    for (index, text) in texts.enumerated() {
        let size = text.utf8.count
        if index > start && (index - start == nagramPageBatchTexts || bytes + size > nagramPageBatchBytes) {
            result.append(start ..< index)
            start = index
            bytes = 0
        }
        bytes += size
    }
    if start < texts.count {
        result.append(start ..< texts.count)
    }
    return result
}

private func nagramTranslateBatch(_ texts: [String], to language: String, context: any AccountContextProtocol) -> Signal<[String], NagramPageTranslationError> {
    if let service = NagramServicesConfig.current.translationService, service.kind == .translation {
        return NagramServiceClient.translate(texts, to: language, service: service) |> mapError { error in
            return .service(error.text)
        }
    }
    return context.engine.messages.translate(texts: texts.map { ($0, []) }, toLang: language)
    |> mapError { _ in
        return .telegram
    }
    |> mapToSignal { results -> Signal<[String], NagramPageTranslationError> in
        guard results.count == texts.count else {
            return .fail(.telegram)
        }
        return .single(results.map { $0.0 })
    }
}

func nagramTranslatePage(_ page: InstantPage, to language: String, context: any AccountContextProtocol) -> Signal<InstantPage?, NagramPageTranslationError> {
    let collector = NagramPageTexts()
    _ = collector.blocks(page.blocks)
    let texts = collector.texts
    if texts.isEmpty {
        return .single(nil)
    }
    var signal: Signal<[String], NagramPageTranslationError> = .single([])
    for batch in nagramPageBatches(texts) {
        let part = Array(texts[batch])
        signal = signal |> mapToSignal { done in
            return nagramTranslateBatch(part, to: language, context: context) |> map { done + $0 }
        }
    }
    return signal |> map { translated in
        let builder = NagramPageTexts(replacements: translated)
        return InstantPage(blocks: builder.blocks(page.blocks), media: page.media, isComplete: page.isComplete, rtl: page.rtl, url: page.url, views: page.views)
    }
}

func nagramWebpage(_ webpage: TelegramMediaWebpage, replacing page: InstantPage) -> TelegramMediaWebpage? {
    guard case let .Loaded(content) = webpage.content else {
        return nil
    }
    let updated = TelegramMediaWebpageLoadedContent(url: content.url, displayUrl: content.displayUrl, hash: content.hash, type: content.type, websiteName: content.websiteName, title: content.title, text: content.text, embedUrl: content.embedUrl, embedType: content.embedType, embedSize: content.embedSize, duration: content.duration, author: content.author, isMediaLargeByDefault: content.isMediaLargeByDefault, imageIsVideoCover: content.imageIsVideoCover, image: content.image, file: content.file, story: content.story, attributes: content.attributes, instantPage: page)
    return TelegramMediaWebpage(webpageId: webpage.webpageId, content: .Loaded(updated))
}
