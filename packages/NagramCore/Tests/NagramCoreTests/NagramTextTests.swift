import XCTest
@testable import NagramCore

final class NagramTextTests: XCTestCase {
    private func source(_ text: String, shown: String, stages: [[NagramTextEdit]]) -> String {
        let shownText = NagramText.apply(stages: stages, to: text) as NSString
        let range = shownText.range(of: shown)
        XCTAssertNotEqual(range.location, NSNotFound, shown)
        return (text as NSString).substring(with: NagramText.sourceRange(range, stages: stages))
    }

    func testSpacedSelectionMapsBackToTheOriginal() {
        let text = "中文English中文"
        let stages = [NagramText.panguEdits(text)]
        XCTAssertEqual(NagramText.apply(stages: stages, to: text), "中文 English 中文")
        XCTAssertEqual(source(text, shown: "English", stages: stages), "English")
        XCTAssertEqual(source(text, shown: " English ", stages: stages), "English")
        XCTAssertEqual(source(text, shown: "文 En", stages: stages), "文En")
        XCTAssertEqual(source(text, shown: "中文 English 中文", stages: stages), text)
    }

    func testReplacedCharactersMapToTheirSource() {
        let text = "ab12cd"
        let stages = [[NagramTextEdit(range: NSRange(location: 2, length: 2), replacement: "XYZ")], [NagramTextEdit(range: NSRange(location: 0, length: 0), replacement: "> ")]]
        XCTAssertEqual(NagramText.apply(stages: stages, to: text), "> abXYZcd")
        XCTAssertEqual(source(text, shown: "Y", stages: stages), "12")
        XCTAssertEqual(source(text, shown: "bXYZc", stages: stages), "b12c")
        XCTAssertEqual(source(text, shown: "cd", stages: stages), "cd")
        XCTAssertEqual(source(text, shown: "> a", stages: stages), "a")
    }
}
