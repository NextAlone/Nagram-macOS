import AppKit
import XCTest
import InAppSettings
import Postbox
import TelegramCore
import TGUIKit
@testable import ChatUI

final class ChatFileNameLayoutTests: XCTestCase {
    override func setUp() {
        super.setUp()
        UITestBootstrap.install()
    }

    func testLongFileNameWrapsAboveTheStatusLine() throws {
        let file = makeParameters(String(repeating: "release-notes-", count: 12) + "2026.zip")
        let _ = file.makeLabelsForWidth(220, maximumFileNameLines: 2)

        let name = try XCTUnwrap(file.name?.0)
        XCTAssertEqual(name.numberOfLines, 2)
        XCTAssertLessThanOrEqual(name.size.width, 170)
        XCTAssertGreaterThan(file.statusTextTop, 1 + name.size.height)
        XCTAssertGreaterThanOrEqual(file.contentHeight - file.statusTextTop, 20)
    }

    func testShortNameKeepsExistingHeight() throws {
        for hasThumb in [false, true] {
            let file = makeParameters("notes.zip", hasThumb: hasThumb)
            let _ = file.makeLabelsForWidth(220, maximumFileNameLines: 2)

            let name = try XCTUnwrap(file.name?.0)
            XCTAssertEqual(name.numberOfLines, 1)
            XCTAssertEqual(file.contentHeight, hasThumb ? 70 : 40)
        }
    }

    func testWrappedNameFitsAboveThumbnailCardCenter() throws {
        let file = makeParameters(String(repeating: "版本发行说明", count: 12) + ".pdf", hasThumb: true)
        let _ = file.makeLabelsForWidth(180, maximumFileNameLines: 2)

        let name = try XCTUnwrap(file.name?.0)
        XCTAssertEqual(name.numberOfLines, 2)
        XCTAssertGreaterThanOrEqual(file.contentHeight / 2 - 2 - name.size.height, 1)
    }

    func testDefaultLayoutStaysSingleLine() throws {
        let file = makeParameters(String(repeating: "release-notes-", count: 12) + "2026.zip")
        let _ = file.makeLabelsForWidth(220, maximumFileNameLines: 2)
        let _ = file.makeLabelsForWidth(220)

        let name = try XCTUnwrap(file.name?.0)
        XCTAssertEqual(name.numberOfLines, 1)
        XCTAssertEqual(file.contentHeight, 40)
    }

    private func makeParameters(_ name: String, hasThumb: Bool = false) -> ChatFileLayoutParameters {
        let resource = CloudDocumentMediaResource(datacenterId: 1, fileId: 1, accessHash: 0, size: 1024, fileReference: nil, fileName: name)
        let file = TelegramMediaFile(fileId: MediaId(namespace: 0, id: 1), partialReference: nil, resource: resource, previewRepresentations: [], videoThumbnails: [], immediateThumbnailData: nil, mimeType: "application/octet-stream", size: resource.size, attributes: [], alternativeRepresentations: [])
        return ChatFileLayoutParameters(fileName: name, hasThumb: hasThumb, presentation: .Empty, media: file, automaticDownload: false, isIncoming: true, autoplayMedia: .defaultSettings, isCopyProtected: false)
    }
}
