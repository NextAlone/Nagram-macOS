import Cocoa
import NagramCore

func nagramMediaRows() -> [NagramRow] {
    let o = NagramOptions.self
    var rows: [NagramRow] = []
    rows.append(.header(nagramString("lng_nagram_stickers_and_emoji")))
    rows.append(.toggle(o.hideStickerTime))
    rows.append(.choice(o.stickerScale, choices: [50, 75, 100, 125, 150, 175, 200].map { NagramChoice($0, "\($0)%") }))
    rows.append(.choice(o.stickerPanelScale, choices: [50, 75, 100, 125, 150, 175, 200].map { NagramChoice($0, "\($0)%") }))
    rows.append(.choice(o.recentStickerLimit, choices: [NagramChoice(0, nagramFollowTelegram())] + [5, 10, 30, 50, 100, 200].map { NagramChoice($0, "\($0)") }))
    rows.append(.toggle(o.hideGroupStickers))
    rows.append(.toggle(o.hideRecommendedStickers))
    rows.append(.toggle(o.hideRecommendedEmoji))
    rows.append(.toggle(o.hideGifCategories))
    rows.append(.toggle(o.hideGreetingSticker))

    rows.append(.header(nagramString("lng_nagram_playback")))
    rows.append(.toggle(o.disableVideoAutoplay))
    rows.append(.toggle(o.smallGifs))

    rows.append(.header(nagramString("lng_nagram_auto_download")))
    rows.append(.toggle(o.blockExecutableAutoDownload))
    rows.append(.toggle(o.blockArchiveAutoDownload, info: nagramString("lng_nagram_auto_download_note")))
    return rows
}
