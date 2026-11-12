import XCTest
import Postbox
import TelegramCore
@testable import InstantPageUI

final class NagramPageTranslationTests: XCTestCase {
    private let blocks: [InstantPageBlock] = [
        .title(.bold(.plain("Title"))),
        .paragraph(.concat([.plain("Hello "), .url(text: .plain("world"), url: "https://example.com", webpageId: nil)])),
        .preformatted(text: .plain("let code = 1"), language: "swift"),
        .paragraph(.concat([.plain("x = "), .formula(latex: "x^2")])),
        .list(items: [.text(.plain("one"), nil, nil), .blocks([.paragraph(.plain("two"))], nil, nil)], ordered: false),
        .details(title: .plain("More"), blocks: [.paragraph(.plain("   "))], expanded: false),
    ]

    func testCollectsTranslatableTextsInOrder() {
        let collector = NagramPageTexts()
        _ = collector.blocks(blocks)
        XCTAssertEqual(collector.texts, ["Title", "Hello world", "one", "two", "More"])
    }

    func testReplacesTextsAndKeepsSingleRunStyles() {
        let builder = NagramPageTexts(replacements: ["Titel", "Hallo Welt", "eins", "zwei", "Mehr"])
        let result = builder.blocks(blocks)
        XCTAssertEqual(result[0], .title(.bold(.plain("Titel"))))
        XCTAssertEqual(result[1], .paragraph(.plain("Hallo Welt")))
        XCTAssertEqual(result[2], blocks[2])
        XCTAssertEqual(result[3], blocks[3])
        XCTAssertEqual(result[4], .list(items: [.text(.plain("eins"), nil, nil), .blocks([.paragraph(.plain("zwei"))], nil, nil)], ordered: false))
        XCTAssertEqual(result[5], .details(title: .plain("Mehr"), blocks: [.paragraph(.plain("   "))], expanded: false))
    }

    func testBatchesAreLimitedByCountAndSize() {
        XCTAssertEqual(nagramPageBatches(Array(repeating: "a", count: 45)), [0 ..< 20, 20 ..< 40, 40 ..< 45])
        let large = String(repeating: "b", count: 20 * 1024)
        XCTAssertEqual(nagramPageBatches(["a", large, large, "c"]), [0 ..< 2, 2 ..< 4])
        XCTAssertEqual(nagramPageBatches([]), [])
    }
}
