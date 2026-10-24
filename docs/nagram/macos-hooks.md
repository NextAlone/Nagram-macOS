# Nagram macOS hook map

Where each Nagram feature (IDs from the Nagram Desktop settings design, `A01`–`K06`) attaches to this
codebase. Paths are relative to the repository root; `TC` = `submodules/telegram-ios/submodules/TelegramCore/Sources`,
`MTK` = `submodules/telegram-ios/submodules/MtProtoKit/Sources`. Line numbers are from the 2026-10-25 survey and drift.

General facts:

- The network runs on the Rust engine (`RustNetworkEngineFactory()` in `Telegram-Mac/app/AppDelegate.swift`);
  `MTContext` still picks transport schemes and looks up backup addresses.
- App-only behaviour is reached through `*Hooks` structs installed from `Telegram-Mac/packages-integration/hooks/`.
- Nothing uses the macOS Translation framework; `AppConfigTranslateState.system` is skipped by `translateBlocks`.

## Translation / AI (H)

| ID | Hook | Change |
|---|---|---|
| H01 single message | `packages/TranslateUI/Sources/TranslateUI/TranslateModalController.swift` `translateBlocks()` | Provider switch before the `configState` switch; message-id branch too |
| H01/H09 whole chat | `packages/ChatHistoryModel/Sources/ChatHistoryModel/ChatLiveTranslateContext.swift` `activateTranslation` | Replace `engine.messages.translateMessages` with the provider signal |
| H06–H08 auto-translate | `ChatLiveTranslateContext.swift` auto-translate gate (`autoTranslate`/`isPremium`) | OR the Nagram override in |
| H02 transcription | `packages/ChatUI/Sources/ChatUI/ChatController.swift` `chatInteraction.transcribeAudio` | Branch before `engine.messages.transcribeAudio` |
| H03 keychain | none; model on `packages/WebAppUI/Sources/WebAppUI/WebAppSecureStorage.swift` | Small `SecItem` wrapper |
| H04 draft AI | `TranslateModalController.swift` `composeMessageWithAI` | Branch to LLM provider |
| H10 summarize | `ChatLiveTranslateContext.swift` `activateSummarization` | Replace `summarizeMessage` signal |
| H11 translate before send | `ChatController.swift` `chatInteraction.sendMessage` → `Sender.enqueue(input:)` | Transform input before enqueue |

## Rules (I)

| ID | Hook | Change |
|---|---|---|
| I01 filters | `packages/ChatHistoryModel/Sources/ChatHistoryModel/ChatHistoryEntry.swift` `messageEntries(...)` loop (`withAppliedEphemeralReplacementMessage`) | `continue` to hide, `withUpdatedText` to mask/replace |
| I02 link rules | `Telegram-Mac/utils/InAppLinks.swift` `execute(inapp:)` `.external` | Rewrite `url` first |
| I11 no auto-login | `InAppLinks.swift` `tryApplyAutologinToken` → `AppDelegate` | Return nil |
| I17 skip link confirm | `packages/ChatUI/Sources/ChatUI/ChatMessageItem.swift` (`confirm: confirm ? text != url : false`) | Force false |
| I16 keyword alerts | `Telegram-Mac/account/SharedNotificationManager.swift` notify filter and muted `continue` | `|| matchesKeyword` |
| I06/I07 inline bot | `ChatInputView.swift` `processPaste`; `ChatInterfaceInputContext.swift` | Rewrite to `@bot <link>` |
| I12/I13 hashtag | `ChatController.swift` `chatInteraction.hashtag` | In-chat vs global search |
| I14/I15 web app size | `packages/WebAppUI/Sources/WebAppUI/WebappBrowser.swift` initial size; `WebpageModalController.swift` `measure(size:)` | Scale |
| I08 external webview links | `WebpageModalController.swift` `decidePolicyFor` | Open in browser on regex match |
| I09 android platform | `TC/TelegramEngine/Messages/BotWebView.swift` `botWebViewPlatform` | Runtime-settable |

## Network (K)

| ID | Hook | Change |
|---|---|---|
| K01 IP version | `submodules/telegram-ios/submodules/MTProtoRustEngine/Sources/MTProtoRustEngine/RustNetworkSession.swift` `loadSchemes`; `MTK/MTContext.m` `chooseTransportScheme…` | Filter/prefer |
| K02 no backup lookup | `TC/Network/Network.swift` `setDiscoverBackupAddressListSignal` | Skip |
| K03 system DNS | already system DNS (`MTK/MTDNS.m`, Rust `resolver.rs`) | No-op on macOS |
| K04 custom DoH | `MTK/MTBackupAddressSignals.m` `fetchBackupIpsResolveGoogle` | Inject URL |
| K05 download boost | `TC/Network/FetchV2.swift` pending-parts constants; `MultipartFetch.swift` | Raise |
| K06 upload boost | `TC/Network/MultipartUpload.swift` `parallelParts`/`defaultPartSize` | Larger parts |

## Config (J), settings entry, branding

| Item | Hook |
|---|---|
| J06/J07 logs | `packages/SettingsUI/Sources/SettingsUI/DeveloperViewController.swift` `toggleLogs`, logs folder |
| J05 RPC errors | `TC/Network/Network.swift` `request<T>` (no central UI) |
| J08–J11 cloud backup | `enqueueMessages` to `context.peerId` |
| `nasettings` links | `packages/TelegramLinks/Sources/TelegramLinks/LinkParsing.swift` `known_scheme`/`parseInAppLink`; `InAppLinks.swift` `execute` |
| Settings row | `packages/SettingsUI/Sources/SettingsUI/AccountViewController.swift` `accountInfoEntries` |
| Settings search | `packages/SettingsUI/Sources/SettingsUI/SettingsSearchableItems.swift` |
| Bundle id, team, groups | `Telegram.xcodeproj/project.pbxproj`, `Telegram-Mac/*.entitlements`, `packages/ApiCredentials/Sources/ApiCredentials/Config.swift` |
| Update feed | `Telegram-Mac/{common,Debug,Beta,Release}.xcconfig` (`SFEED_URL`) |

## Interface (A)

Not applicable on macOS: A18 (no seasonal decorations), A15 (string post-processing only; impractical).

| ID | Hook | Change |
|---|---|---|
| A02 bubble radius | `packages/TelegramTheme/Sources/TelegramTheme/ChatMessageBubbleImages.swift` `messageBubbleMainRadius`/`AuxiliaryRadius`/`Diameter` | Scale; diameter ≥ 2× radius; cached, restart |
| A03/A04 avatar radius | `packages/TelegramUtils/Sources/TelegramUtils/PeerAvatarImage.swift` (`roundImage` −1 = circle, forum/monoforum radius) | Size-based radius; avatar cache key has no radius → restart |
| A23 search radius | `packages/TGUIKit/Sources/SearchView.swift` `layer?.cornerRadius = 15` | Read option |
| A05 text width | `packages/ChatUI/Sources/ChatUI/ChatRowItem.swift` `min_block_width` (450) | Scale |
| A06 wide channel posts | `packages/ChatUI/Sources/ChatUI/ChatMessageItem.swift` `min_block_width` override | Larger cap for broadcast |
| A07 bubble tail | `ChatMessageBubbleImages.swift` `messageBubbleArguments` `drawTail` | Force false |
| A08 theme reply colors | `packages/ChatUI/Sources/ChatUI/TelegramChatColorsItems.swift` `replyTitle`/`blockColor`/`replyPattern`/`replyQuote` | Skip `nameColor` branch |
| A09 reply thumbnail | `packages/ChatHistoryModel/Sources/ChatHistoryModel/ReplyModel.swift` `updatedMedia` | nil |
| A10/A16/A17 chat theme | `ChatController.swift` `themeEmoticon` and per-peer `wallpaper` | nil by peer kind |
| A12 dock badge | `packages/GeneralRows/Sources/GeneralRows/GlobalBadgeNode.swift` dock `badgeLabel` | nil |
| A13/A14/A21 notifications | `Telegram-Mac/account/SharedNotificationManager.swift` pipeline | Delay / quiet hours |
| A19 account in title | `Telegram-Mac/utils/NetworkStatusManager.swift` (`appName @ name`) | Gate suffix |

## Chat list (B)

Not applicable on macOS: B14/B15 (no overscroll to next channel), B19 (no phone suggestion UI).

| ID | Hook | Change |
|---|---|---|
| B01 compact | `packages/ChatListUI/Sources/ChatListUI/ChatListRowItem.swift` `height` (70), avatar 50 in `ChatListRowView.swift` | Smaller |
| B02 preview lines | `ChatListRowItem.swift` `maximumNumberOfLines: 2` | N |
| B30 seconds | `packages/DateUtils/Sources/DateUtils/DateUtils.mm` `stringForMessageListDate` (callers in `ChatListRowItem.swift`) | Variant with seconds |
| B03 hide previews | `ChatListRowItem.swift` messageLayout for saved / archive | Skip |
| B04 stories | `PeersListController.swift` `hasStories`/`storyList`; `ChatListController.swift` `storyState` | Off |
| B05 startup folder | `ChatListController.swift` first `withUpdatedFilter` | Pick configured |
| B06 hide All chats | `packages/InAppSettings/Sources/InAppSettings/ChatListFilterPreferences.swift` | Drop `.allChats` |
| B07/B27/B28 archive/saved | `ChatListController.swift` group entries; `ChatListRevealItem.swift` tabs; `SidebarUI/.../LeftSidebarController.swift` | Pseudo items |
| B08 folder unread | `ChatListRevealItem.swift` `generateIcon`; `LeftSidebarController.swift` | 0 |
| B09 sort | `ChatListController.swift` `prepare` of `update.list.items` | Stable sort loaded page |
| B10 sponsored | `ChatController.swift` `adMessages`; `ChatListUI/.../SearchController.swift` ad peers | Empty |
| B11/B12/B13 promos | `ChatListController.swift` `additionalItems`, premium/stars suggestion items, birthdays | Skip |
| B16/B24 recent chats | `ChatController.swift` `viewDidAppear`; `ShareUI/.../ShareModalController.swift` | MRU list |
| B31 mutual contacts | `ChatListUI/.../ContactsController.swift` row status (`.mutualContact`) | Marker |
| B17 reading position | `ChatController.swift` initial location / `viewWillDisappear` | Save/restore |
| B18 top bar tools | `ChatUI/.../ChatTitleBarView.swift` | Extra buttons |
| B20 compact tabs | `ChatListRevealItem.swift` font/insets/height | Smaller |
| B21 folder after join | `ChatUI/.../JoinChannelAction.swift`; `InviteLinksUI/.../InviteJoinAction.swift` | Folder picker |
| B22 no global search | `SearchController.swift` `searchRemotePeers` | Empty |
| B23 community grouping | `TC/UpdatePeers.swift` `isPeerHiddenByCollapsedCommunity` | false (core change) |
| B25/B26 local pins | `ChatListRowItem.swift` `togglePinned` `.limitExceeded`; `ChatListController.swift` ordering | Local pins |
| B29 cleanup | model on `InactiveChannelsUI/.../InactiveChannelsController.swift` | New screen |

## Messages (C) and compose (D)

Paths under `packages/ChatUI/Sources/ChatUI/` unless stated.

| ID | Hook | Change |
|---|---|---|
| C01 seconds | `packages/TelegramUtils/Sources/TelegramUtils/DateSelectorUtil.swift` `chatDateFormatter` | HH:mm:ss |
| C02 forward date | `ChatRowItem.swift` date label from `message.timestamp` | `forwardInfo?.date` |
| C03 service time | `ChatServiceItem.swift` `text` layout | Append time |
| C04 message id | `ChatRowItem.swift` `fullDate` tooltip; date attr | Append ID |
| C27 online dot | `ChatAvatarView.swift` `setPeer` | Presence subscription |
| C05 exact counts | `ChatRowItem.swift` replies/views `.prettyNumber` | `.separatedNumber` |
| C32 forward count | `ChatRowItem.swift` attributes loop (`ForwardCountMessageAttribute`); `ChatRightView.swift` | New layout |
| C06 hide views | `ChatRowItem.swift` `channelViews` | nil |
| C07 signature | `ChatRowItem.swift` `postAuthor` | nil |
| C08/C09/C28 edited | `ChatRowItem.swift` `isEditMarkVisible`, `chatMessageEdited`, `editedLabel` | Hide / text / icon |
| C10–C13 reactions | `ChatRowItem.swift` `reactionsLayout` | nil by peer kind |
| C14/C15 reaction panel | `ChatRowItem.swift` `menuAdditionView`; `ChatMessageItem.swift`/`ChatGroupedItem.swift` `topWindow` | nil |
| C33 who reacted on top | `ChatMessageMenuItems.swift` `MessageReadMenuItem` block | Move first |
| C16–C18 effects | `ChatController.swift` premium/effect targets; `EmojiScreenEffect.swift` `addAnimation`/`addPremiumEffect` | Skip |
| C19 spoilers | `ChatMessageItem.swift` `isSpoilerRevealed`; `ChatHistoryEntry.swift` `isRevealed` | true |
| C20 share button | `ChatRowItem.swift` `shareVisible` | false |
| C21/C29 recommended channels | `ChatController.swift` `recommendedChannels`; `JoinChannelAction.swift` | nil / collapse |
| C22 premium badges | `packages/PremiumStatusUI/Sources/PremiumStatusUI/PremiumStatusControl.swift` `control(...)` | Drop premium/emoji status |
| C23 saved tags | `ChatController.swift` `savedMessageTags` | nil |
| C24 typing in private | `ChatController.swift` `inputActivities`; `ChatListUI/.../PeersListController.swift` | Filter |
| C25/C26 pangu / zh conversion | `ChatMessageItem.swift` text/attributes; captions in `ChatMediaItem.swift`, `ChatGroupedItem.swift` | Transform + remap entities |
| C30 simple replies | `ChatHistoryModel/.../ChatAccessoryModel.swift`; `ChatRowItem.swift` `replyPresentation` | No pattern/background |
| C31 video avatars | `ChatAvatarView.swift` `peer.hasVideo` | Gate |
| D01–D09 input buttons | `ChatInputView.swift` attach/voice/bot menu/AI/send-as; `ChatInputActionsView.swift` emoji/timer/gift | Hide |
| D11/D28 channel bottom | `ChatPresentationInterfaceState.swift` mute `.action` | `.none` / `.channelWithDiscussion` |
| D12 emoji hover | `ChatInputActionsView.swift` `addHoverObserver` | Skip |
| D13 attach hover | n/a (click only) | — |
| D14 bot command to draft | `ChatController.swift` `sendPlainText`; `InputContextHelper.swift` `sendCommand` | Fill input |
| D15 placeholder | `ChatInputView.swift` `textPlaceholder` | Chat title / send-as |
| D32 tall list | `InputContextHelper.swift` height cap | Raise |
| D16 auto markdown | `packages/InputView/Sources/InputView/ChatTextInputState.swift` `markdownRegex` | Skip |
| D17 link preview | `ChatController.swift` `composeDisableUrlPreview` | Default off |
| D18/D19/D31 send/edit transform | `ChatHistoryModel/.../SenderController.swift` `subState`; `ChatController.swift` edit `inputState` | Transform |
| D20 code language | `ChatTextInputState.swift` `.pre(range, language)` | Default |
| D21 quick replies | `ChatInterfaceStateContextQueries.swift` shortcut lookup | Merge local |
| D22/D23 confirm sticker/GIF | `ChatController.swift` `sendAppFile`, `sendInlineResult` | `verifyAlert` |
| D24/D25 preview recording | `ChatInputRecordingView.swift` `stopAndSend` | Pause → preview |
| D26 confirm call | `packages/CallsUI/Sources/CallsUI/PCallLaunch.swift` `phoneCall` | `verifyAlert` |
| D27 forward before comment | `ChatController.swift` `makeTextSignal() |> then(forward)` | Swap |
| D29/D30 format toolbar/menu | `InputView/.../ChatInputTextView.swift` selection, `transformItems` | Toolbar / filter |

## Message menu (E)

`packages/ChatUI/Sources/ChatUI/ChatMessageMenuItems.swift` `chatMenuItems` builds blocks joined near the end
(`zeroBlock, firstBlock, add_secondBlock, thirdBlock, secondBlock, fourthBlock, fifthBlock, sixBlock, sevenBlock`);
filtering for show/hide/Option and the compact menu goes there. Ephemeral replacement messages take an early-return path.

| Action | API |
|---|---|
| Repeat / without quote / forward without author / save to Saved | `Sender.forwardMessages(messageIds:context:peerId:…hideNames:)` (`ChatHistoryModel/.../SenderController.swift`); text via `Sender.enqueue(input:)` |
| Select range / by sender / all loaded | selection state in `ChatPresentationInterfaceState.swift` (cap 100); loaded history via a new `ChatInteraction` closure implemented in `ChatController` |
| Other messages from user | `chatInteraction.searchPeerMessages(peer)` exists, unused |
| Hide sender / message locally | filter before `messageEntries` in `ChatController` |
| Delete downloaded file | empty `if data.fileFinderPath != nil {}` slot; `mediaBox.removeCachedResources` |
| Details + raw JSON | `engine.messages.getMessagesLoadIfNecessary` or raw `Api.functions.*.getMessages` |
| Original/translated | `chatInteraction.toggleTranslate` |
| Transcribe | `chatInteraction.transcribeAudio` |
| Copy as markdown | new exporter (only markdown → attributes exists) |
| Screenshot | row view snapshot via table |

## Media (F)

| ID | Hook | Change |
|---|---|---|
| F01 sticker size | `packages/ChatUI/Sources/ChatUI/ChatLayoutUtils.swift` 208×208 | Scale |
| F02 sticker time | `ChatRowItem.swift` `rightFrames` for stickers | nil |
| F03 recent count | `packages/EntertainmentUI/Sources/EntertainmentUI/StickersViewController.swift` `files.count == 20` | Option |
| F04/F05 group/trending stickers | same file `specificPack`, `.featured` | Skip |
| F06 trending emoji | `EmojiesController.swift` `featuredEmojiPacks` | Empty |
| F07 GIF categories | `GifKeyboardController.swift` `.trending`/`.recommended` | Skip |
| F08 greeting sticker | `ChatEmptyPeerItem.swift` `randomGreetingSticker` | nil |
| F09 video autoplay | `ChatMediaLayoutParameters.swift` `autoplayMedia.videos` | false (also exists in Data & Storage) |
| F11 mp4 preview | `SenderController.swift` `makeFileMedia`/`previewForFile` | Keep thumbnail |
| F12/F13 sticker list | `StickerSettingsUI/.../InstalledStickerPacksController.swift` | Rows |
| F14 small GIFs | `ChatLayoutUtils.swift` animated branch | Smaller |
| F15 panel size | `Telegram-Mac/app/ApplicationContext.swift` `EntertainmentViewController(size:)` | Scale |
| F16 downloads | `Telegram-Mac/app/MainViewController.swift` menu | Item |
| F17/F18 block exe/archives | `TelegramMediaUtils/.../AutomaticMediaDownloadAbility.swift` `dangerExts` | Extend |
| F19 voice bitrate | `OpusBinding/.../opusenc.m` bitrate; writer in `TelegramMedia/Sources/AudioRecorder.swift` | Property |
| F21 cover URL | `TelegramMediaUtils/.../ExternalMusicAlbumArtResources.swift` | Custom fetch |
| F26/F27 local faves | menu limit check; `SavedStickers.swift`; `StickersViewController.swift` saved list | Local store |

## Privacy (G)

| ID | Hook | Change |
|---|---|---|
| G01 phone | `SettingsUI/.../AccountInfoItem.swift`; `PeerInfoUI/.../UserInfoEntries.swift` own profile | Mask |
| G02 demo mode | `Telegram-Mac/app/AppDelegate.swift` window; `CaptureExclusion` package; chat list text | `sharingType = .none`, mask |
| G03 read time | `ChatUI/.../MessageReadMenuItem.swift` | Hide |
| G04 share phone | `ChatController.swift` `.canShareContact` → `.shareInfo` | Skip |
| G18 typing status | `TC/State/ManagedLocalInputActivities.swift` `requestActivity` / `TC/Account/Account.swift` `updateLocalInputActivity` | Early return |
| G13 protected content | `MessageUtils/.../MessageExtras.swift`, `TelegramUtils/.../PeerExtras.swift`, `TC/Utils/MessageUtils.swift` `isCopyProtected` | false |
| G14 restrictions | `MessageUtils/.../MessageExtensions.swift` `restrictedText`; `TelegramTheme/.../SyncCoreExtension.swift` | nil |
| G15 sensitive media | `ChatInteractiveContentView.swift` `isSensitive`; `InlineMediaGrid/.../MediaCell.swift` | false |
| G05/G06/G17 profile rows | `UserInfoEntries.swift`, `ChannelInfoEntries.swift`, `GroupInfoEntries.swift` | ID / DC / registration rows |
| G07 gifts | `PeerInfoUI/.../PeerMediaController.swift` gifts tab | nil |
| G08 todo | `ChatInputAttachView.swift` `canAttachTodo` | Gate |
| G09 admin shortcuts | `ChatController.swift` `buildChatActionsMenu()` | Items |
| G10 name order, aliases | `TelegramUtils/.../PeerDisplay.swift` `displayTitle` (hub; recompiles ~90 packages) | Swap / alias |
| G12 delete defaults | `ChatController.swift` delete `verifyAlert`; `DeleteGroupMessagesController.swift` initial state | Defaults |
| G19–G21 admin actions | `ChatRowView.swift` `photoContextMenu`; menu link type; `PeerMediaGroupMembersController.swift` | Items |
