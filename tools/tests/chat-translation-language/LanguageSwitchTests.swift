import Foundation
import SwiftSignalKit

enum EnginePeer { typealias Id = Int }
enum HistoryLocation { case peer(peerId: Int, threadId: Int?) }
enum HistoryIndex { case upperBound }

struct Entity {
    struct Kind { let isCode: Bool }
    let type: Kind
    let range: Range<Int>
}

struct Message {
    struct Attributes { let entities: [Entity] }
    let text = "A synthetic message with a detectable language"
    let textEntitiesAttribute: Attributes? = nil
}

struct HistoryView {
    struct Entry { let message: Message }
    let entries = (0..<16).map { _ in Entry(message: Message()) }
}

struct ViewTracker {
    func aroundMessageHistoryViewForLocation(
        _ location: HistoryLocation,
        index: HistoryIndex,
        anchorIndex: HistoryIndex,
        count: Int,
        fixedCombinedReadStates: Int?
    ) -> Signal<(HistoryView, Int, Int), NoError> {
        return .single((HistoryView(), 0, 0))
    }
}

struct ChatTranslationState: Equatable {
    let baseLang: String
    let fromLang: String
    let toLang: String?
    let isEnabled: Bool?
    let paywall: Bool
}

final class Engine {
    let cache = ValuePromise<ChatTranslationState?>(
        ChatTranslationState(baseLang: "en", fromLang: "ja", toLang: nil, isEnabled: nil, paywall: false),
        ignoreRepeated: true
    )
    var pendingWrites: [ChatTranslationState] = []
    var cacheReads = 0

    func flushWrites(limit: Int) -> [String] {
        var languages: [String] = []
        while !pendingWrites.isEmpty && languages.count < limit {
            let state = pendingWrites.removeFirst()
            languages.append(state.baseLang)
            cache.set(state)
        }
        return languages
    }
}

func cachedChatTranslationState(engine: Engine, peerId: Int) -> Signal<ChatTranslationState?, NoError> {
    engine.cacheReads += 1
    return engine.cache.get()
}

func updateChatTranslationState(engine: Engine, peerId: Int, state: ChatTranslationState?) -> Signal<Never, NoError> {
    return Signal { subscriber in
        if let state = state {
            engine.pendingWrites.append(state)
        }
        subscriber.putCompletion()
        return EmptyDisposable
    }
}

struct Settings: Equatable {
    let translateChats: Bool
    let doNotTranslate: Set<String>
}

struct Account { let viewTracker = ViewTracker() }
struct SharedAccountContext {
    let accountManager = ValuePromise(Settings(translateChats: true, doNotTranslate: []))
}

protocol AccountContextProtocol {
    var account: Account { get }
    var sharedContext: SharedAccountContext { get }
    var engine: Engine { get }
}

struct TestContext: AccountContextProtocol {
    let account = Account()
    let sharedContext = SharedAccountContext()
    let engine = Engine()
}

func baseAppSettings(accountManager: ValuePromise<Settings>) -> Signal<Settings, NoError> {
    return accountManager.get()
}

struct Appearance: Equatable { let languageCode: String }
var appAppearance = Appearance(languageCode: "en")
let appearance = ValuePromise(appAppearance)
let appearanceSignal = appearance.get()

enum Translate {
    static func detectLanguage(for text: String) -> String? { return "ja" }
}

__CHAT_TRANSLATION_STATE__

func check(_ result: Bool, _ description: String) {
    print("\(result ? "PASS" : "FAIL"): \(description)")
    if !result { exit(1) }
}

let context = TestContext()
var firstLanguage: String?
var secondLanguage: String?
let first = chatTranslationState(context: context, peerId: 1).start(next: { firstLanguage = $0?.baseLang })
check(firstLanguage == "en" && context.engine.pendingWrites.isEmpty, "Initial subscription uses the existing English cache")

appAppearance = Appearance(languageCode: "zh-CN")
appearance.set(appAppearance)
let second = chatTranslationState(context: context, peerId: 1).start(next: { secondLanguage = $0?.baseLang })
let writes = context.engine.flushWrites(limit: 8)
check(!writes.isEmpty && writes.allSatisfy { $0 == "zh-CN" } && context.engine.pendingWrites.isEmpty,
      "Cache converges on Chinese with both subscriptions active (writes: \(writes))")
check(firstLanguage == "zh-CN" && secondLanguage == "zh-CN", "Both subscriptions use the Chinese cache")

let cacheReads = context.engine.cacheReads
appearance.set(appAppearance)
check(context.engine.cacheReads == cacheReads, "Appearance updates with the same language do not reload the cache")

context.sharedContext.accountManager.set(Settings(translateChats: false, doNotTranslate: []))
check(firstLanguage == nil && secondLanguage == nil && context.engine.pendingWrites.isEmpty,
      "Disabling chat translation still clears both subscriptions")

first.dispose()
second.dispose()
