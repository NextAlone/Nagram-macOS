import Foundation
import CommonCrypto

public enum NagramSyncEnvelopeError: Error, Equatable {
    case tooLarge
    case damaged
    case foreign
    case newer
}

public struct NagramSyncEnvelope: Equatable {
    public let updatedAt: Int64
    public let app: String
    public let payload: Data
    public let hash: String
}

public enum NagramSyncAction: Equatable {
    case upToDate
    case upload
    case download
    case conflict
}

public struct NagramSyncState: Equatable {
    public let user: Int64
    public let messageId: Int32
    public let hash: String
    public let updatedAt: Int64

    public init(user: Int64, messageId: Int32, hash: String, updatedAt: Int64) {
        self.user = user
        self.messageId = messageId
        self.hash = hash
        self.updatedAt = updatedAt
    }
}

public enum NagramSync {
    public static let fileName = "nagram-sync-v1.json"
    public static let caption = "#nagram_sync"
    public static let maxBackupBytes = 8 * 1024 * 1024
    public static let autoDebounceSeconds: Int64 = 30
    public static let autoIntervalSeconds: Int64 = 15 * 60
    public static let autoTimeoutSeconds: Int64 = 60

    private static let version = 1
    private static let kind = "nagram-sync"
    private static let appLimit = 32
    private static let hashLength = 64

    private static func object(_ data: Data) -> [String: Any]? {
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }

    private static func integer(_ value: Any?) -> Int64? {
        guard let number = value as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID() else {
            return nil
        }
        let double = number.doubleValue
        guard double >= 0, double < 1e15, double == double.rounded() else {
            return nil
        }
        return Int64(double)
    }

    private static func decimalId(_ value: Any?, allowZero: Bool = false) -> Int64? {
        guard let text = value as? String, let id = UInt64(text), id <= UInt64(Int64.max), (id != 0 || allowZero), String(id) == text else {
            return nil
        }
        return Int64(id)
    }

    private static func canonical(_ object: [String: Any]) -> Data {
        return (try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys, .withoutEscapingSlashes])) ?? Data()
    }

    private static func sha256Hex(_ data: Data) -> String {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(data.count), &digest)
        }
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private static func validHash(_ hash: String) -> Bool {
        return hash.count == hashLength && hash.allSatisfy { ("0"..."9").contains($0) || ("a"..."f").contains($0) }
    }

    public static func payloadHash(_ exported: Data) -> String? {
        return object(exported).map { sha256Hex(canonical($0)) }
    }

    public static func encodeEnvelope(_ exported: Data, updatedAt: Int64, app: String) -> Data? {
        guard let payload = object(exported) else {
            return nil
        }
        let root: [String: Any] = [
            "version": version,
            "kind": kind,
            "updatedAt": updatedAt,
            "app": String(app.prefix(appLimit)),
            "payload": payload,
        ]
        return try? JSONSerialization.data(withJSONObject: root, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
    }

    public static func decodeEnvelope(_ data: Data) -> Result<NagramSyncEnvelope, NagramSyncEnvelopeError> {
        if data.count > maxBackupBytes {
            return .failure(.tooLarge)
        }
        guard let root = object(data) else {
            return .failure(.damaged)
        }
        guard root["kind"] as? String == kind else {
            return .failure(.foreign)
        }
        guard let rootVersion = integer(root["version"]), rootVersion != 0 else {
            return .failure(.damaged)
        }
        if rootVersion > version {
            return .failure(.newer)
        }
        guard Set(root.keys) == ["version", "kind", "updatedAt", "app", "payload"], let updatedAt = integer(root["updatedAt"]), let app = root["app"] as? String, app.count <= appLimit, let payload = root["payload"] as? [String: Any] else {
            return .failure(.damaged)
        }
        guard let format = integer(payload["version"]), format != 0 else {
            return .failure(.damaged)
        }
        if format > version {
            return .failure(.newer)
        }
        guard payload.count == 2, payload["options"] is [String: Any] else {
            return .failure(.damaged)
        }
        let compact = canonical(payload)
        return .success(NagramSyncEnvelope(updatedAt: updatedAt, app: app, payload: compact, hash: sha256Hex(compact)))
    }

    public static func decide(local: String?, synced: String?, remote: String?) -> NagramSyncAction {
        guard let remote = remote, !remote.isEmpty else {
            return .upload
        }
        if remote == local {
            return .upToDate
        } else if synced == remote {
            return .upload
        } else if synced == local {
            return .download
        }
        return .conflict
    }

    public static func parseState(_ raw: String) -> NagramSyncState? {
        guard let data = raw.data(using: .utf8), let object = object(data), Set(object.keys) == ["version", "user", "messageId", "hash", "updatedAt"], integer(object["version"]) == 1, let user = decimalId(object["user"]), let messageId = decimalId(object["messageId"], allowZero: true), messageId <= Int64(Int32.max), let hash = object["hash"] as? String, validHash(hash), let updatedAt = integer(object["updatedAt"]) else {
            return nil
        }
        return NagramSyncState(user: user, messageId: Int32(messageId), hash: hash, updatedAt: updatedAt)
    }

    public static func serializeState(_ state: NagramSyncState) -> String {
        let object: [String: Any] = [
            "version": 1,
            "user": String(state.user),
            "messageId": String(state.messageId),
            "hash": state.hash,
            "updatedAt": state.updatedAt,
        ]
        return String(data: canonical(object), encoding: .utf8) ?? ""
    }

    public static func supersededBackups(_ remote: [Int32], known: Int32, uploaded: Int32) -> [Int32] {
        var result = remote
        if known != 0 {
            result.append(known)
        }
        result.removeAll(where: { $0 == uploaded })
        return Array(Set(result)).sorted()
    }

    public enum AutoPlan: Equatable {
        case skip
        case wait(Int64)
        case run
    }

    public static func planAuto(now: Int64, lastAttempt: Int64, local: String?, synced: String?) -> AutoPlan {
        guard let local = local, !local.isEmpty, local != synced else {
            return .skip
        }
        let passed = now - lastAttempt
        if lastAttempt > 0, passed >= 0, passed < autoIntervalSeconds {
            return .wait(autoIntervalSeconds - passed)
        }
        return .run
    }

    public static func autoEnabled(_ owner: String, user: Int64) -> Bool {
        return user != 0 && decimalId(owner) == user
    }
}
