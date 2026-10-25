import Cocoa
import TGUIKit
import AlertsUI
import SwiftSignalKit
import TelegramCore
import Postbox
import TelegramContext
import NagramCore

enum NagramCloudSyncError: Error, Equatable {
    case busy
    case search
    case download
    case tooLarge
    case upload
    case damaged
    case foreign
    case newer
    case timeout
    case remoteChanged

    init(_ error: NagramSyncEnvelopeError) {
        switch error {
        case .tooLarge:
            self = .tooLarge
        case .damaged:
            self = .damaged
        case .foreign:
            self = .foreign
        case .newer:
            self = .newer
        }
    }

    var text: String {
        switch self {
        case .busy:
            return nagramString("lng_nagram_sync_busy")
        case .search, .download:
            return nagramString("lng_nagram_sync_download_error")
        case .tooLarge:
            return nagramString("lng_nagram_sync_too_large")
        case .upload:
            return nagramString("lng_nagram_sync_upload_error")
        case .damaged:
            return nagramString("lng_nagram_sync_invalid")
        case .foreign:
            return nagramString("lng_nagram_sync_foreign")
        case .newer:
            return nagramString("lng_nagram_sync_newer_format")
        case .timeout:
            return nagramString("lng_nagram_sync_timeout")
        case .remoteChanged:
            return nagramString("lng_nagram_sync_remote_newer")
        }
    }

    var isUnreadable: Bool {
        switch self {
        case .tooLarge, .damaged, .foreign, .newer:
            return true
        default:
            return false
        }
    }
}

struct NagramCloudSyncChecked {
    var error: NagramCloudSyncError?
    var found = false
    var action: NagramSyncAction = .upload
    var remote: NagramSyncEnvelope?
}

private struct Fetched {
    var found = false
    var id: Int32 = 0
    var data = Data()
    var all: [Int32] = []
}

final class NagramCloudSyncService {
    private static var services: [PeerId: NagramCloudSyncService] = [:]

    static func existing(account: Int64?) -> NagramCloudSyncService? {
        return services.values.first(where: { $0.context.peerId.toInt64() == account })
    }

    static func shared(_ context: any AccountContextProtocol) -> NagramCloudSyncService {
        if let current = services[context.peerId], current.context.account === context.account {
            return current
        }
        let service = NagramCloudSyncService(context: context)
        services[context.peerId] = service
        return service
    }

    let context: any AccountContextProtocol
    private(set) var busy = false
    private var remoteId: Int32 = 0
    private var remoteIds: [Int32] = []
    private let operation = MetaDisposable()
    private let autoDisposable = MetaDisposable()
    private let autoTimer = MetaDisposable()
    private var autoOn = false
    private var autoRunning = false
    private var autoAttempt: Int64 = 0
    let autoIssue = ValuePromise<NagramCloudSyncError?>(nil, ignoreRepeated: false)
    private(set) var lastAutoIssue: NagramCloudSyncError?

    private init(context: any AccountContextProtocol) {
        self.context = context
    }

    private var account: Int64 {
        return context.peerId.toInt64()
    }

    private var user: Int64 {
        return context.peerId.id._internalGetInt64Value()
    }

    private var now: Int64 {
        return Int64(Date().timeIntervalSince1970)
    }

    var state: NagramSyncState? {
        guard let state = NagramSync.parseState(NagramOptions.cloudSyncState.value(account: account)), state.user == user else {
            return nil
        }
        return state
    }

    private func save(messageId: Int32, hash: String, updatedAt: Int64) {
        NagramOptions.cloudSyncState.set(NagramSync.serializeState(NagramSyncState(user: user, messageId: messageId, hash: hash, updatedAt: updatedAt)), account: account)
    }

    var autoEnabled: Bool {
        return NagramSync.autoEnabled(NagramOptions.cloudSyncAuto.value(account: account), user: user)
    }

    func setAutoEnabled(_ enabled: Bool) {
        NagramOptions.cloudSyncAuto.set(enabled ? String(user) : "", account: account)
        updateAuto()
    }

    func cancel() {
        operation.set(nil)
        busy = false
        autoRunning = false
    }

    private func isBackup(_ message: Message) -> Bool {
        return NagramCloudSyncService.isBackup(message, me: context.peerId)
    }

    private static func isBackup(_ message: Message, me: PeerId) -> Bool {
        guard message.id.peerId == me, message.id.namespace == Namespaces.Message.Cloud, message.forwardInfo == nil, message.text == NagramSync.caption, let file = message.media.first as? TelegramMediaFile else {
            return false
        }
        return file.fileName == NagramSync.fileName
    }

    private func fetch(knownId: Int32) -> Signal<Fetched, NagramCloudSyncError> {
        let context = self.context
        let me = context.peerId
        let search = context.engine.messages.searchMessages(location: .peer(peerId: me, fromId: nil, tags: .file, reactions: nil, threadId: nil, minDate: nil, maxDate: nil), query: NagramSync.caption, state: nil, limit: 100)
        |> take(1)
        |> map { result, _ in result.messages }
        |> castError(NagramCloudSyncError.self)

        return search |> mapToSignal { [weak self] messages -> Signal<Fetched, NagramCloudSyncError> in
            guard let self = self else {
                return .complete()
            }
            var backups = messages.filter { self.isBackup($0) }
            let local = context.account.postbox.transaction { transaction -> [Message] in
                var result: [Message] = []
                transaction.scanTopMessages(peerId: me, namespace: Namespaces.Message.Cloud, limit: 50, { message in
                    if NagramCloudSyncService.isBackup(message, me: me) {
                        result.append(message)
                    }
                    return true
                })
                if knownId != 0, let known = transaction.getMessage(MessageId(peerId: me, namespace: Namespaces.Message.Cloud, id: knownId)), NagramCloudSyncService.isBackup(known, me: me) {
                    result.append(known)
                }
                return result
            } |> castError(NagramCloudSyncError.self)
            return local |> mapToSignal { local -> Signal<Fetched, NagramCloudSyncError> in
                for message in local where !backups.contains(where: { $0.id == message.id }) {
                    backups.append(message)
                }
                let all = backups.map { $0.id.id }
                guard let latest = backups.max(by: { $0.id.id < $1.id.id }), let file = latest.media.first as? TelegramMediaFile else {
                    return .single(Fetched())
                }
                if let size = file.size, size > Int64(NagramSync.maxBackupBytes) {
                    return .fail(.tooLarge)
                }
                let reference = MediaResourceReference.media(media: .message(message: MessageReference(latest), media: file), resource: file.resource)
                let fetch = fetchedMediaResource(mediaBox: context.account.postbox.mediaBox, userLocation: .peer(me), userContentType: .file, reference: reference)
                |> mapError { _ in NagramCloudSyncError.download }
                |> ignoreValues
                let data = context.account.postbox.mediaBox.resourceData(file.resource)
                |> filter { $0.complete }
                |> take(1)
                |> castError(NagramCloudSyncError.self)
                |> mapToSignal { data -> Signal<Fetched, NagramCloudSyncError> in
                    guard let contents = try? Data(contentsOf: URL(fileURLWithPath: data.path)) else {
                        return .fail(.download)
                    }
                    return .single(Fetched(found: true, id: latest.id.id, data: contents, all: all))
                }
                return Signal { subscriber in
                    let fetchDisposable = fetch.start(error: { error in
                        subscriber.putError(error)
                    })
                    let dataDisposable = data.start(next: { value in
                        subscriber.putNext(value)
                    }, error: { error in
                        subscriber.putError(error)
                    }, completed: {
                        subscriber.putCompletion()
                    })
                    return ActionDisposable {
                        fetchDisposable.dispose()
                        dataDisposable.dispose()
                    }
                }
            }
        }
    }

    func check(_ done: @escaping (NagramCloudSyncChecked) -> Void) {
        if busy {
            done(NagramCloudSyncChecked(error: .busy))
            return
        }
        let local = NagramSync.payloadHash(NagramExchange.export(target: .cloud))
        let known = state
        busy = true
        remoteId = 0
        remoteIds = []
        operation.set((fetch(knownId: known?.messageId ?? 0) |> deliverOnMainQueue).start(next: { [weak self] fetched in
            guard let self = self else {
                return
            }
            self.busy = false
            self.remoteIds = fetched.all
            guard fetched.found else {
                done(NagramCloudSyncChecked())
                return
            }
            self.remoteId = fetched.id
            switch NagramSync.decodeEnvelope(fetched.data) {
            case let .failure(error):
                done(NagramCloudSyncChecked(error: NagramCloudSyncError(error), found: true))
            case let .success(remote):
                let action = NagramSync.decide(local: local, synced: known?.hash, remote: remote.hash)
                if action == .upToDate, known?.hash != remote.hash || known?.messageId != fetched.id {
                    self.save(messageId: fetched.id, hash: remote.hash, updatedAt: self.now)
                }
                done(NagramCloudSyncChecked(found: true, action: action, remote: remote))
            }
        }, error: { [weak self] error in
            self?.busy = false
            done(NagramCloudSyncChecked(error: error, found: error == .tooLarge))
        }))
    }

    private func send(_ data: Data) -> Signal<Int32, NagramCloudSyncError> {
        let context = self.context
        let me = context.peerId
        let directory = NSTemporaryDirectory() + "nagram-sync-\(Int64.random(in: 1 ... Int64.max))"
        let path = directory + "/" + NagramSync.fileName
        do {
            try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
            try data.write(to: URL(fileURLWithPath: path))
        } catch {
            return .fail(.upload)
        }
        let randomId = Int64.random(in: Int64.min ... Int64.max)
        let correlationId = Int64.random(in: Int64.min ... Int64.max)
        let file = TelegramMediaFile(fileId: MediaId(namespace: Namespaces.Media.LocalFile, id: randomId), partialReference: nil, resource: LocalFileReferenceMediaResource(localFilePath: path, randomId: randomId, size: Int64(data.count)), previewRepresentations: [], videoThumbnails: [], immediateThumbnailData: nil, mimeType: "application/json", size: Int64(data.count), attributes: [.FileName(fileName: NagramSync.fileName)], alternativeRepresentations: [])
        let attributes: [MessageAttribute] = [
            TextEntitiesMessageAttribute(entities: [MessageTextEntity(range: 0 ..< (NagramSync.caption as NSString).length, type: .Hashtag)]),
            NotificationInfoMessageAttribute(flags: .muted),
        ]
        let message = EnqueueMessage.message(text: NagramSync.caption, attributes: attributes, inlineStickers: [:], mediaReference: .standalone(media: file), threadId: nil, replyToMessageId: nil, replyToStoryId: nil, localGroupingKey: nil, correlationId: correlationId, bubbleUpEmojiOrStickersets: [])

        let poll: (MessageId) -> Signal<Int32, NagramCloudSyncError> = { localId in
            let tick = Signal<Void, NoError>.single(Void()) |> then(.complete() |> delay(0.5, queue: .mainQueue()))
            let step = tick |> castError(NagramCloudSyncError.self) |> mapToSignal { _ -> Signal<Int32?, NagramCloudSyncError> in
                if let sent = context.account.pendingMessageManager.synchronouslyLookupCorrelationId(correlationId: correlationId), sent.namespace == Namespaces.Message.Cloud {
                    return .single(sent.id)
                }
                return context.account.postbox.transaction { transaction -> Bool in
                    return transaction.getMessage(localId)?.flags.contains(.Failed) ?? false
                }
                |> castError(NagramCloudSyncError.self)
                |> mapToSignal { failed -> Signal<Int32?, NagramCloudSyncError> in
                    return failed ? .fail(.upload) : .single(nil)
                }
            }
            return (step |> restart)
            |> filter { $0 != nil }
            |> map { $0! }
            |> take(1)
        }

        return (enqueueMessages(account: context.account, peerId: me, messages: [message])
        |> castError(NagramCloudSyncError.self)
        |> mapToSignal { ids -> Signal<Int32, NagramCloudSyncError> in
            guard let localId = ids.first ?? nil else {
                return .fail(.upload)
            }
            return poll(localId)
        })
        |> timeout(Double(NagramSync.autoTimeoutSeconds), queue: .mainQueue(), alternate: .fail(.timeout))
        |> afterDisposed {
            try? FileManager.default.removeItem(atPath: directory)
        }
    }

    func upload(_ done: @escaping (NagramCloudSyncError?) -> Void) {
        if busy {
            done(.busy)
            return
        }
        let exported = NagramExchange.export(target: .cloud)
        let updatedAt = now
        guard let hash = NagramSync.payloadHash(exported), let data = NagramSync.encodeEnvelope(exported, updatedAt: updatedAt, app: nagramAppVersion) else {
            done(.upload)
            return
        }
        busy = true
        operation.set((send(data) |> deliverOnMainQueue).start(next: { [weak self] uploaded in
            guard let self = self else {
                return
            }
            self.busy = false
            let old = NagramSync.supersededBackups(self.remoteIds, known: self.state?.messageId ?? 0, uploaded: uploaded)
            self.remoteIds = []
            self.save(messageId: uploaded, hash: hash, updatedAt: updatedAt)
            self.remoteId = uploaded
            self.remove(old)
            done(nil)
        }, error: { [weak self] error in
            self?.busy = false
            done(error)
        }))
    }

    private func remove(_ ids: [Int32]) {
        guard !ids.isEmpty else {
            return
        }
        let messageIds = ids.map { MessageId(peerId: context.peerId, namespace: Namespaces.Message.Cloud, id: $0) }
        _ = context.engine.messages.deleteMessagesInteractively(messageIds: messageIds, type: .forEveryone).start()
    }

    func removeRemote(_ done: @escaping (NagramCloudSyncError?) -> Void) {
        if busy {
            done(.busy)
            return
        }
        busy = true
        operation.set((fetch(knownId: state?.messageId ?? 0) |> deliverOnMainQueue).start(next: { [weak self] fetched in
            guard let self = self else {
                return
            }
            self.busy = false
            self.remove(fetched.all)
            self.remoteId = 0
            self.remoteIds = []
            NagramOptions.cloudSyncState.set("", account: self.account)
            done(nil)
        }, error: { [weak self] error in
            self?.busy = false
            done(error == .tooLarge ? nil : error)
        }))
    }

    func applied(_ remote: NagramSyncEnvelope) {
        save(messageId: remoteId, hash: remote.hash, updatedAt: now)
    }

    func updateAuto() {
        let enabled = autoEnabled
        guard enabled != autoOn else {
            return
        }
        autoOn = enabled
        autoTimer.set(nil)
        lastAutoIssue = nil
        autoIssue.set(nil)
        guard enabled else {
            autoDisposable.set(nil)
            if autoRunning {
                cancel()
            }
            return
        }
        autoDisposable.set((NagramSettings.shared.changes |> deliverOnMainQueue).start(next: { [weak self] _ in
            self?.autoSchedule(NagramSync.autoDebounceSeconds)
        }))
        autoSchedule(NagramSync.autoDebounceSeconds)
    }

    private func autoSchedule(_ seconds: Int64) {
        autoTimer.set((Signal<Void, NoError>.single(Void()) |> delay(Double(seconds), queue: .mainQueue())).start(next: { [weak self] in
            self?.autoRun()
        }))
    }

    private func autoRun() {
        guard autoOn else {
            return
        }
        if busy {
            autoSchedule(NagramSync.autoDebounceSeconds)
            return
        }
        let local = NagramSync.payloadHash(NagramExchange.export(target: .cloud))
        switch NagramSync.planAuto(now: now, lastAttempt: autoAttempt, local: local, synced: state?.hash) {
        case .skip:
            lastAutoIssue = nil
            autoIssue.set(nil)
            return
        case let .wait(seconds):
            autoSchedule(seconds)
            return
        case .run:
            break
        }
        autoAttempt = now
        autoRunning = true
        check { [weak self] checked in
            guard let self = self else {
                return
            }
            if let error = checked.error {
                self.autoFinish(error)
            } else if !checked.found || checked.action == .upload {
                self.upload { error in
                    self.autoFinish(error)
                }
            } else if checked.action == .upToDate {
                self.autoFinish(nil)
            } else {
                self.autoFinish(.remoteChanged)
            }
        }
    }

    private func autoFinish(_ error: NagramCloudSyncError?) {
        autoRunning = false
        lastAutoIssue = error
        autoIssue.set(error)
    }
}

private func runChecked(_ context: NagramActionContext, replacing: Bool, _ done: @escaping (NagramCloudSyncChecked) -> Void) {
    let service = NagramCloudSyncService.shared(context.context)
    if service.busy {
        showModalText(for: context.window, text: NagramCloudSyncError.busy.text)
        return
    }
    let signal = Signal<NagramCloudSyncChecked, NoError> { subscriber in
        var finished = false
        service.check { checked in
            finished = true
            subscriber.putNext(checked)
            subscriber.putCompletion()
        }
        return ActionDisposable {
            if !finished {
                service.cancel()
            }
        }
    }
    _ = showModalProgress(signal: signal, for: context.window).start(next: { checked in
        if let error = checked.error, !(replacing && checked.found && error.isUnreadable) {
            showModalText(for: context.window, text: error.text)
        } else {
            done(checked)
        }
    })
}

private func runUpload(_ context: NagramActionContext) {
    let service = NagramCloudSyncService.shared(context.context)
    let signal = Signal<NagramCloudSyncError?, NoError> { subscriber in
        service.upload { error in
            subscriber.putNext(error)
            subscriber.putCompletion()
        }
        return EmptyDisposable
    }
    _ = showModalProgress(signal: signal, for: context.window).start(next: { error in
        showModalText(for: context.window, text: error?.text ?? nagramString("lng_nagram_sync_done"))
    })
}

private func preview(_ context: NagramActionContext, _ remote: NagramSyncEnvelope) {
    let service = NagramCloudSyncService.shared(context.context)
    nagramShowImportPreview(remote.payload, target: .cloud, window: context.window, applied: {
        service.applied(remote)
    })
}

func nagramBackupToCloud(_ context: NagramActionContext) {
    runChecked(context, replacing: true) { checked in
        let unreadable = checked.error?.isUnreadable == true
        if !unreadable, !checked.found || checked.action == .upload {
            runUpload(context)
        } else if !unreadable, checked.action == .upToDate {
            showModalText(for: context.window, text: nagramString("lng_nagram_sync_up_to_date"))
        } else {
            let question = nagramString("lng_nagram_sync_overwrite_confirm")
            let text = unreadable ? (checked.error!.text + "\n\n" + question) : question
            verifyAlert(for: context.window, header: nagramString("lng_nagram_sync_title"), information: text, ok: nagramString("lng_nagram_sync_use_local"), successHandler: { _ in
                runUpload(context)
            })
        }
    }
}

func nagramRestoreFromCloud(_ context: NagramActionContext) {
    runChecked(context, replacing: false) { checked in
        if !checked.found {
            showModalText(for: context.window, text: nagramString("lng_nagram_sync_not_found"))
        } else if checked.action == .upToDate {
            showModalText(for: context.window, text: nagramString("lng_nagram_sync_up_to_date"))
        } else if let remote = checked.remote {
            preview(context, remote)
        }
    }
}

func nagramSyncWithCloud(_ context: NagramActionContext) {
    runChecked(context, replacing: false) { checked in
        if !checked.found || checked.action == .upload {
            runUpload(context)
        } else if checked.action == .upToDate {
            showModalText(for: context.window, text: nagramString("lng_nagram_sync_up_to_date"))
        } else if let remote = checked.remote {
            if checked.action == .download {
                preview(context, remote)
            } else {
                verifyAlert_button(for: context.window, header: nagramString("lng_nagram_sync_now"), information: nagramString("lng_nagram_sync_both_changed"), ok: nagramString("lng_nagram_sync_use_cloud"), option: nagramString("lng_nagram_sync_use_local"), successHandler: { result in
                    switch result {
                    case .basic:
                        preview(context, remote)
                    case .thrid:
                        runUpload(context)
                    }
                })
            }
        }
    }
}

func nagramDeleteCloudBackup(_ context: NagramActionContext) {
    verifyAlert(for: context.window, header: nagramString("lng_nagram_sync_title"), information: nagramString("lng_nagram_sync_delete_remote_confirm"), ok: nagramString("lng_nagram_sync_delete_remote"), successHandler: { _ in
        let service = NagramCloudSyncService.shared(context.context)
        if service.busy {
            showModalText(for: context.window, text: NagramCloudSyncError.busy.text)
            return
        }
        let signal = Signal<NagramCloudSyncError?, NoError> { subscriber in
            service.removeRemote { error in
                subscriber.putNext(error)
                subscriber.putCompletion()
            }
            return EmptyDisposable
        }
        _ = showModalProgress(signal: signal, for: context.window).start(next: { error in
            showModalText(for: context.window, text: error?.text ?? nagramString("lng_nagram_sync_deleted"))
        })
    })
}

func nagramCloudSyncStatus() -> String? {
    guard let service = NagramCloudSyncService.existing(account: NagramSettings.shared.currentAccount) else {
        return nil
    }
    if let issue = service.lastAutoIssue {
        return nagramString(issue == .remoteChanged ? "lng_nagram_sync_auto_paused" : "lng_nagram_sync_auto_failed_short")
    }
    guard let state = service.state, state.updatedAt > 0 else {
        return nagramString("lng_nagram_sync_never")
    }
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return nagramString("lng_nagram_sync_last", ["date": formatter.string(from: Date(timeIntervalSince1970: TimeInterval(state.updatedAt)))])
}

private let autoIssueDisposable = MetaDisposable()

public func nagramAttachCloudSync(_ context: any AccountContextProtocol) {
    let service = NagramCloudSyncService.shared(context)
    service.updateAuto()
    autoIssueDisposable.set((service.autoIssue.get() |> deliverOnMainQueue).start(next: { issue in
        guard let issue = issue else {
            return
        }
        let text = issue == .remoteChanged ? issue.text : nagramString("lng_nagram_sync_auto_failed", ["reason": issue.text])
        showModalText(for: context.window, text: text)
    }))
}

func nagramCloudSyncRows() -> [NagramRow] {
    var rows: [NagramRow] = []
    rows.append(.header(nagramString("lng_nagram_sync_title")))
    rows.append(.action(title: nagramString("lng_nagram_sync_backup"), run: nagramBackupToCloud))
    rows.append(.action(title: nagramString("lng_nagram_sync_restore"), run: nagramRestoreFromCloud))
    rows.append(.action(title: nagramString("lng_nagram_sync_now"), value: nagramCloudSyncStatus, run: nagramSyncWithCloud))
    rows.append(.action(title: nagramString("lng_nagram_sync_delete_remote"), destructive: true, run: nagramDeleteCloudBackup))
    rows.append(.footer(nagramString("lng_nagram_sync_about")))
    rows.append(.boundToggle(id: "cloudSyncAuto", title: nagramString("lng_nagram_sync_auto"), info: nagramString("lng_nagram_sync_auto_about"), get: {
        return NagramCloudSyncService.existing(account: NagramSettings.shared.currentAccount)?.autoEnabled ?? false
    }, set: { enabled in
        NagramCloudSyncService.existing(account: NagramSettings.shared.currentAccount)?.setAutoEnabled(enabled)
    }, visible: {
        return NagramCloudSyncService.existing(account: NagramSettings.shared.currentAccount) != nil
    }))
    return rows
}
