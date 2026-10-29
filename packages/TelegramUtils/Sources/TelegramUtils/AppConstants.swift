import Cocoa
import TelegramCore
import Postbox
import ColorPalette
import TelegramTheme
import FoundationUtils

public let clown: String = "🤡"

// MARK: NAGRAM
public let itunesAppLink = Bundle.main.bundleIdentifier?.hasPrefix("xyz.nextalone.nagram") == true
    ? "https://apps.apple.com/app/id6781000861"
    : "https://apps.apple.com/us/app/telegram/id747648890"
public let XTRSTAR: String = "⭐️"
public var GOLD: NSColor {
    return theme.colors.isDark ? NSColor(0xF5C555) : NSColor(0xD2720B)
}
public let clown_space: String = "\(clown)\(TINY_SPACE)"
public let XTR_USD_RATE = 0.013

public func restartApp() {
    let task = appRelaunchProcess()
    do {
        try task.run()
        NSApp.terminate(nil)
    } catch {
        NSLog("Failed to restart: \(error)")
    }
}

extension ResolvePeerResult : @retroactive Equatable {

    public var result: EnginePeer? {
        switch self {
        case .progress:
            return nil
        case let .result(peer):
            return peer
        }
    }
    public static func ==(lhs: ResolvePeerResult, rhs: ResolvePeerResult) -> Bool {
        switch lhs {
        case .progress:
            if case .progress = rhs {
                return true
            } else {
                return false
            }
        case let .result(lhsPeer):
            if case let .result(rhsPeer) = rhs {
                return PeerEquatable(lhsPeer?._asPeer()) == PeerEquatable(rhsPeer?._asPeer())
            } else {
                return false
            }
        }
    }
}
