import Foundation
import SwiftSignalKit

public struct NagramChange: Equatable {
    public let key: String
    public let account: Int64?
}

public final class NagramSettings {
    public static let shared = NagramSettings(defaults: .standard)

    private let defaults: UserDefaults
    private let changesPipe = ValuePipe<NagramChange>()
    private let revisionValue = ValuePromise<Int>(0, ignoreRepeated: true)
    private var revision: Int = 0
    private let lock = NSLock()
    private var cache: [String: Any] = [:]
    private var missing: Set<String> = []

    public var currentAccount: Int64?

    public init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    private func storageKey(_ key: String, scope: NagramScope, account: Int64?) -> String? {
        switch scope {
        case .device:
            return key
        case .account:
            guard let account = account ?? currentAccount else {
                return nil
            }
            return "\(key)@\(account)"
        }
    }

    private func readRaw(_ storageKey: String) -> Any? {
        lock.lock()
        defer { lock.unlock() }
        if let value = cache[storageKey] {
            return value
        }
        if missing.contains(storageKey) {
            return nil
        }
        let value = defaults.object(forKey: storageKey)
        if let value = value {
            cache[storageKey] = value
        } else {
            missing.insert(storageKey)
        }
        return value
    }

    private func writeRaw(_ storageKey: String, _ value: Any?) {
        lock.lock()
        if let value = value {
            cache[storageKey] = value
            missing.remove(storageKey)
            defaults.set(value, forKey: storageKey)
        } else {
            cache.removeValue(forKey: storageKey)
            missing.insert(storageKey)
            defaults.removeObject(forKey: storageKey)
        }
        revision += 1
        let current = revision
        lock.unlock()
        revisionValue.set(current)
    }

    public func get<Value>(_ option: NagramOption<Value>, account: Int64? = nil) -> Value {
        guard let key = storageKey(option.key, scope: option.scope, account: account), let raw = readRaw(key), let value = Value(stored: raw), option.accepts(value) else {
            return option.fallback
        }
        return value
    }

    @discardableResult
    public func set<Value>(_ option: NagramOption<Value>, _ value: Value, account: Int64? = nil) -> Bool {
        guard option.accepts(value), let key = storageKey(option.key, scope: option.scope, account: account) else {
            return false
        }
        if value == option.fallback {
            writeRaw(key, nil)
        } else {
            writeRaw(key, value.stored)
        }
        changesPipe.putNext(NagramChange(key: option.key, account: option.scope == .account ? (account ?? currentAccount) : nil))
        return true
    }

    public func reset<Value>(_ option: NagramOption<Value>, account: Int64? = nil) {
        set(option, option.fallback, account: account)
    }

    public func isModified<Value>(_ option: NagramOption<Value>, account: Int64? = nil) -> Bool {
        return get(option, account: account) != option.fallback
    }

    public func rawValue(for info: NagramOptionInfo, account: Int64? = nil) -> Any? {
        guard let key = storageKey(info.key, scope: info.scope, account: account), let raw = readRaw(key), info.accepts(raw) else {
            return nil
        }
        return raw
    }

    func setRawValue(_ value: Any?, for info: NagramOptionInfo) {
        guard let key = storageKey(info.key, scope: info.scope, account: nil) else {
            return
        }
        writeRaw(key, value)
        changesPipe.putNext(NagramChange(key: info.key, account: nil))
    }

    public var changes: Signal<NagramChange, NoError> {
        return changesPipe.signal()
    }

    public var revisions: Signal<Int, NoError> {
        return revisionValue.get()
    }

    public func signal<Value>(_ option: NagramOption<Value>, account: Int64? = nil) -> Signal<Value, NoError> {
        let initial = Signal<Value, NoError>.single(get(option, account: account))
        let updates = changes
        |> filter { $0.key == option.key }
        |> map { [weak self] _ -> Value in
            return self?.get(option, account: account) ?? option.fallback
        }
        return (initial |> then(updates)) |> distinctUntilChanged
    }

    public func signal(flags: NagramFlags) -> Signal<Void, NoError> {
        let keys = Set(NagramOptions.all.filter { !$0.flags.intersection(flags).isEmpty }.map { $0.key })
        return changes |> filter { keys.contains($0.key) } |> map { _ in Void() }
    }
}

public extension NagramOption {
    var value: Value {
        return NagramSettings.shared.get(self)
    }

    func value(account: Int64?) -> Value {
        return NagramSettings.shared.get(self, account: account)
    }

    func set(_ value: Value, account: Int64? = nil) {
        NagramSettings.shared.set(self, value, account: account)
    }

    var signal: Signal<Value, NoError> {
        return NagramSettings.shared.signal(self)
    }
}
