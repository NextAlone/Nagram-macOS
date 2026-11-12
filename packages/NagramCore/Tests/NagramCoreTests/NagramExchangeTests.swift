import XCTest
@testable import NagramCore

final class NagramExchangeTests: XCTestCase {
    private var settings: NagramSettings!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "nagram-exchange-tests-\(UUID().uuidString)"
        settings = NagramSettings(defaults: UserDefaults(suiteName: suiteName)!)
    }

    override func tearDown() {
        UserDefaults().removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    private func payload(_ options: [String: Any]) -> Data {
        return try! JSONSerialization.data(withJSONObject: ["version": 1, "options": options])
    }

    private func plan(_ options: [String: Any]) -> NagramExchangePlan {
        switch NagramExchange.plan(payload(options), settings: settings, target: .cloud) {
        case let .success(plan):
            return plan
        case let .failure(error):
            XCTFail("\(error)")
            return NagramExchangePlan()
        }
    }

    private func assertRejected(_ key: String, _ value: Any, file: StaticString = #filePath, line: UInt = #line) {
        guard case let .failure(error) = NagramExchange.plan(payload([key: value]), settings: settings, target: .file) else {
            return XCTFail("\(key) accepted \(value)", file: file, line: line)
        }
        XCTAssertEqual(error, .invalidValue(key), file: file, line: line)
    }

    func testEveryFallbackPassesItsRule() {
        for info in NagramOptions.all {
            XCTAssertTrue(info.accepts(info.fallback), info.key)
        }
    }

    func testSquareCornersAreAccepted() {
        XCTAssertEqual(NagramOptions.bubbleRoundness.fallback, NagramOptions.roundnessUnchanged)
        let result = plan([
            "nagram.bubbleRoundness": 0,
            "nagram.avatarRoundness": 5,
            "nagram.searchRoundness": 100,
        ])
        XCTAssertEqual(result.changes.count, 3)
    }

    func testDesktopBackupValuesAreAccepted() {
        let result = plan([
            "nagram.messageIdPlace": 2,
            "nagram.profileIdFormat": 1,
            "nagram.readingChinese": 1,
            "nagram.hashtagSearchPageChannel": 1,
            "nagram.hashtagSearchPageChat": 2,
            "nagram.secondsInMessages": true,
            "nagram.messageMenu": ["version": 2, "states": ["E10": "hide", "E15": "show", "E16": "option", "E22": "show", "E40": "option"]],
            "nagram.topBarActions": ["version": 1, "items": ["mute", "jumpToDate", "recentActions"]],
            "nagram.quickReplies": ["version": 1, "replies": ["a", ""]],
        ])
        XCTAssertEqual(result.changes.count, 9)
        XCTAssertTrue(result.skippedKeys.isEmpty)
    }

    func testOutOfRangeValuesAreRejected() {
        assertRejected("nagram.messageIdPlace", 3)
        assertRejected("nagram.bubbleRoundness", 101)
        assertRejected("nagram.bubbleRoundness", -2)
        assertRejected("nagram.textMessageWidth", 401)
        assertRejected("nagram.notificationDelay", 700)
        assertRejected("nagram.stickerScale", 60)
        assertRejected("nagram.webAppWidthScale", 75)
        assertRejected("nagram.chatPreviewLines", 4)
        assertRejected("nagram.chatSort", 1)
        assertRejected("nagram.hiddenFormatItems", 512)
        assertRejected("nagram.defaultCodeLanguage", "c#")
        assertRejected("nagram.downloadSpeedBoost", "max")
        assertRejected("nagram.quickRatingFirst", String(repeating: "a", count: 65))
    }

    func testMalformedObjectsAreRejected() {
        assertRejected("nagram.messageMenu", ["version": 2, "states": ["E33": "show"]])
        assertRejected("nagram.messageMenu", ["version": 2, "states": ["E10": "maybe"]])
        assertRejected("nagram.messageMenu", ["version": 1, "states": ["E22": "show"]])
        assertRejected("nagram.messageMenu", ["version": 3, "states": [:]])
        assertRejected("nagram.quickReplies", ["version": 1, "replies": ["only one"]])
        assertRejected("nagram.inlineBotRules", ["version": 1, "rules": [["id": "x"]]])
    }

    func testChatSortAcceptsPermutations() {
        let info = NagramOptions.chatSort.info
        XCTAssertTrue(info.accepts(0))
        XCTAssertTrue(info.accepts(0b11_10_01_00_0000))
        XCTAssertFalse(info.accepts(0b00_00_00_01_0000))
        XCTAssertFalse(info.accepts(0x1000))
    }

    func testStoredValueOutsideTheRuleReadsAsFallback() {
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.set(9, forKey: NagramOptions.messageIdPlace.key)
        XCTAssertEqual(settings.get(NagramOptions.messageIdPlace), 0)
    }

    func testUnavailableOptionsAreReportedAndStillStored() {
        let result = plan(["nagram.recentChats": true, "nagram.secondsInMessages": true])
        XCTAssertEqual(result.unavailableKeys, ["nagram.recentChats"])
        XCTAssertEqual(result.changes.map { $0.key }.sorted(), ["nagram.recentChats", "nagram.secondsInMessages"])
        guard case .success = NagramExchange.apply(result, settings: settings) else {
            return XCTFail("apply failed")
        }
        XCTAssertTrue(settings.get(NagramOptions.recentChats))
    }

    func testUnavailableOptionsAreReportedWithoutChanges() {
        guard case .success = NagramExchange.apply(plan(["nagram.recentChats": true]), settings: settings) else {
            return XCTFail("apply failed")
        }
        let again = plan(["nagram.recentChats": true])
        XCTAssertTrue(again.changes.isEmpty)
        XCTAssertEqual(again.unavailableKeys, ["nagram.recentChats"])
    }

    func testRestartIsAskedOnlyForAvailableOptions() {
        XCTAssertTrue(plan(["nagram.bubbleRoundness": 50]).requiresRestart)
        XCTAssertFalse(plan(["nagram.secondsInMessages": true]).requiresRestart)
        XCTAssertFalse(plan(["nagram.disableCommunityGrouping": true]).requiresRestart)
    }

    func testImportedInlineRulesAreTurnedOff() throws {
        let rule: [String: Any] = ["id": "6f9619ff-8b86-4011-b42d-00cf4fc964ff", "username": "gif_bot", "patterns": ["^a"], "enabled": true]
        let result = plan(["nagram.inlineBotRules": ["version": 1, "rules": [rule]]])
        XCTAssertEqual(result.adjustedKeys, ["nagram.inlineBotRules"])
        let stored = try XCTUnwrap(result.changes.first?.after as? String)
        let root = try XCTUnwrap(nagramJsonObject(stored))
        let rules = try XCTUnwrap(root["rules"] as? [[String: Any]])
        XCTAssertEqual(rules.first?["enabled"] as? Bool, false)
    }

    func testDisabledInlineRulesAreNotAdjusted() {
        let rule: [String: Any] = ["id": "6f9619ff-8b86-4011-b42d-00cf4fc964ff", "username": "gif_bot", "patterns": ["^a"], "enabled": false]
        XCTAssertTrue(plan(["nagram.inlineBotRules": ["version": 1, "rules": [rule]]]).adjustedKeys.isEmpty)
    }

    func testNotImplementedFlagMatchesTheCode() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let expression = try NSRegularExpression(pattern: "\\.([A-Za-z0-9]+)\\b")
        var references = Set<String>()
        for directory in ["packages", "Telegram-Mac"] {
            let files = FileManager.default.enumerator(at: root.appendingPathComponent(directory), includingPropertiesForKeys: nil)
            while let file = files?.nextObject() as? URL {
                if file.pathComponents.contains(".build") {
                    files?.skipDescendants()
                    continue
                }
                guard file.pathExtension == "swift", file.lastPathComponent != "NagramOptions.swift", file.lastPathComponent != "NagramExchangeTests.swift", let text = try? String(contentsOf: file, encoding: .utf8) else {
                    continue
                }
                let nsText = text as NSString
                expression.enumerateMatches(in: text, range: NSRange(location: 0, length: nsText.length)) { match, _, _ in
                    if let match = match {
                        references.insert(nsText.substring(with: match.range(at: 1)))
                    }
                }
            }
        }
        for info in NagramOptions.all where info.exportable {
            let name = String(info.key.dropFirst("nagram.".count))
            XCTAssertEqual(info.flags.contains(.notImplemented), !references.contains(name), info.key)
        }
    }
}
