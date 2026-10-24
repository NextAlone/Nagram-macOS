
public enum NagramOptions {
    public static let unlimitedPinnedChats = NagramOption<Bool>("nagram.unlimitedPinnedChats", .device, false, .chats, "lng_nagram_unlimited_pinned_chats", [.refreshDialogList])
    public static let localPinnedChats = NagramOption<String>("nagram.localPinnedChats", .account, "", .chats, "lng_nagram_local_pinned_chats", [.hidden], object: true)
    public static let chatListCompact = NagramOption<Bool>("nagram.chatListCompact", .device, false, .chats, "lng_nagram_compact_chat_list", [.refreshDialogList])
    public static let chatPreviewLines = NagramOption<Int>("nagram.chatPreviewLines", .device, 0, .chats, "lng_nagram_chat_preview_lines", [.refreshDialogList])
    public static let hideSavedAndArchivedPreviews = NagramOption<Bool>("nagram.hideSavedAndArchivedPreviews", .device, false, .chats, "lng_nagram_hide_saved_and_archived_previews", [.refreshDialogList])
    public static let secondsInChatList = NagramOption<Bool>("nagram.secondsInChatList", .device, false, .chats, "lng_nagram_seconds_in_chat_list", [.refreshDialogList])
    public static let hideStories = NagramOption<Bool>("nagram.hideStories", .device, false, .chats, "lng_nagram_hide_stories", [])
    public static let hideAllChatsFolder = NagramOption<Bool>("nagram.hideAllChatsFolder", .device, false, .chats, "lng_nagram_hide_all_chats_folder", [])
    public static let showArchiveInFolders = NagramOption<Bool>("nagram.showArchiveInFolders", .device, false, .chats, "lng_nagram_show_archive_in_folders", [.refreshDialogList])
    public static let archiveInFolderList = NagramOption<Bool>("nagram.archiveInFolderList", .device, false, .chats, "lng_nagram_archive_in_folder_list", [.refreshDialogList])
    public static let savedInFolderList = NagramOption<Bool>("nagram.savedInFolderList", .device, false, .chats, "lng_nagram_saved_in_folder_list", [.refreshDialogList])
    public static let hideFolderUnreadCounters = NagramOption<Bool>("nagram.hideFolderUnreadCounters", .device, false, .chats, "lng_nagram_hide_folder_unread_counters", [])
    public static let startupFolderMode = NagramOption<Int>("nagram.startupFolderMode", .account, 0, .chats, "lng_nagram_startup_folder", [])
    public static let startupFolderId = NagramOption<Int>("nagram.startupFolderId", .account, 0, .chats, "lng_nagram_startup_folder", [])
    public static let lastOpenedFolderId = NagramOption<Int>("nagram.lastOpenedFolderId", .account, 0, .chats, "lng_nagram_startup_folder", [])
    public static let chatSort = NagramOption<Int>("nagram.chatSort", .device, 0, .chats, "lng_nagram_chat_sort", [])
    public static let managedFolderIds = NagramOption<String>("nagram.managedFolderIds", .account, "", .chats, "lng_nagram_managed_only", [])
    public static let recentFolderIds = NagramOption<String>("nagram.recentFolderIds", .account, "", .chats, "lng_nagram_recent_chats", [.hidden])
    public static let hideSponsoredMessages = NagramOption<Bool>("nagram.hideSponsoredMessages", .device, false, .chats, "lng_nagram_hide_sponsored_messages", [])
    public static let hideProxySponsor = NagramOption<Bool>("nagram.hideProxySponsor", .device, false, .chats, "lng_nagram_hide_proxy_sponsor", [])
    public static let hidePremiumPromotions = NagramOption<Bool>("nagram.hidePremiumPromotions", .device, false, .chats, "lng_nagram_hide_premium_promotions", [])
    public static let hideBirthdaySuggestions = NagramOption<Bool>("nagram.hideBirthdaySuggestions", .device, false, .chats, "lng_nagram_hide_birthday_suggestions", [])
    public static let disableCommunityGrouping = NagramOption<Bool>("nagram.disableCommunityGrouping", .device, false, .chats, "lng_nagram_disable_community_grouping", [.requiresRestart])
    public static let compactFolderTabs = NagramOption<Bool>("nagram.compactFolderTabs", .device, false, .chats, "lng_nagram_compact_folder_tabs", [.requiresRestart])
    public static let disableGlobalSearch = NagramOption<Bool>("nagram.disableGlobalSearch", .device, false, .chats, "lng_nagram_disable_global_search", [])
    public static let chooseFolderAfterJoin = NagramOption<Bool>("nagram.chooseFolderAfterJoin", .device, false, .chats, "lng_nagram_choose_folder_after_join", [])
    public static let hidePhoneSuggestion = NagramOption<Bool>("nagram.hidePhoneSuggestion", .device, false, .chats, "lng_nagram_hide_phone_suggestion", [])
    public static let markMutualContacts = NagramOption<Bool>("nagram.markMutualContacts", .device, false, .chats, "lng_nagram_mark_mutual_contacts", [])
    public static let disableScrollToNextChannel = NagramOption<Bool>("nagram.disableScrollToNextChannel", .device, false, .chats, "lng_nagram_disable_scroll_to_next_channel", [])
    public static let disableScrollToNextTopic = NagramOption<Bool>("nagram.disableScrollToNextTopic", .device, false, .chats, "lng_nagram_disable_scroll_to_next_topic", [])
    public static let recentChats = NagramOption<Bool>("nagram.recentChats", .device, false, .chats, "lng_nagram_recent_chats_option", [])
    public static let recentChatsLimit = NagramOption<Int>("nagram.recentChatsLimit", .device, 30, .chats, "lng_nagram_recent_chats_limit", [])
    public static let recentChatsList = NagramOption<String>("nagram.recentChatsList", .account, "", .chats, "lng_nagram_recent_chats", [.hidden])
    public static let chatTools = NagramOption<Bool>("nagram.chatTools", .device, false, .chats, "lng_nagram_chat_tools", [])
    public static let topBarActions = NagramOption<String>("nagram.topBarActions", .device, "", .chats, "lng_nagram_top_bar_actions", [.exportable], object: true)
    public static let recentChatsInShare = NagramOption<Bool>("nagram.recentChatsInShare", .device, false, .chats, "lng_nagram_recent_in_share", [])
    public static let saveReadingPosition = NagramOption<Bool>("nagram.saveReadingPosition", .device, false, .chats, "lng_nagram_save_reading_position", [])
    public static let readingPositions = NagramOption<String>("nagram.readingPositions", .account, "", .chats, "lng_nagram_save_reading_position", [.hidden])
    public static let hideAttachButton = NagramOption<Bool>("nagram.hideAttachButton", .device, false, .compose, "lng_nagram_hide_attach_button", [.refreshComposeButtons])
    public static let hideEmojiButton = NagramOption<Bool>("nagram.hideEmojiButton", .device, false, .compose, "lng_nagram_hide_emoji_button", [.refreshComposeButtons])
    public static let hideRecordingButton = NagramOption<Bool>("nagram.hideRecordingButton", .device, false, .compose, "lng_nagram_hide_recording_button", [.refreshComposeButtons])
    public static let hideBotCommandButton = NagramOption<Bool>("nagram.hideBotCommandButton", .device, false, .compose, "lng_nagram_hide_bot_command_button", [.refreshComposeButtons])
    public static let hideBotMenu = NagramOption<Bool>("nagram.hideBotMenu", .device, false, .compose, "lng_nagram_hide_bot_menu", [.refreshComposeButtons])
    public static let hideAutoDeleteButton = NagramOption<Bool>("nagram.hideAutoDeleteButton", .device, false, .compose, "lng_nagram_hide_auto_delete_button", [.refreshComposeButtons])
    public static let hideGiftButton = NagramOption<Bool>("nagram.hideGiftButton", .device, false, .compose, "lng_nagram_hide_gift_button", [.refreshComposeButtons])
    public static let hideAiButton = NagramOption<Bool>("nagram.hideAiButton", .device, false, .compose, "lng_nagram_hide_ai_button", [.refreshComposeButtons])
    public static let hideSendAsButton = NagramOption<Bool>("nagram.hideSendAsButton", .device, false, .compose, "lng_nagram_hide_send_as_button", [.refreshComposeButtons])
    public static let hideStarsReactionButton = NagramOption<Bool>("nagram.hideStarsReactionButton", .device, false, .compose, "lng_nagram_hide_stars_reaction_button", [.refreshComposeButtons])
    public static let hideChannelMuteButton = NagramOption<Bool>("nagram.hideChannelMuteButton", .device, false, .compose, "lng_nagram_hide_channel_mute_button", [.refreshComposeButtons])
    public static let channelDiscussButton = NagramOption<Bool>("nagram.channelDiscussButton", .device, false, .compose, "lng_nagram_channel_discuss_button", [.refreshComposeButtons])
    public static let disableEmojiHover = NagramOption<Bool>("nagram.disableEmojiHover", .device, false, .compose, "lng_nagram_disable_emoji_hover", [])
    public static let disableAttachHover = NagramOption<Bool>("nagram.disableAttachHover", .device, false, .compose, "lng_nagram_disable_attach_hover", [])
    public static let botCommandsToDraft = NagramOption<Bool>("nagram.botCommandsToDraft", .device, false, .compose, "lng_nagram_bot_commands_to_draft", [])
    public static let tallMentionList = NagramOption<Bool>("nagram.tallMentionList", .device, false, .compose, "lng_nagram_tall_mention_list", [])
    public static let inputPlaceholderMode = NagramOption<Int>("nagram.inputPlaceholderMode", .device, 0, .compose, "lng_nagram_input_placeholder", [])
    public static let formatToolbar = NagramOption<Bool>("nagram.formatToolbar", .device, false, .compose, "lng_nagram_format_toolbar", [])
    public static let hiddenFormatItems = NagramOption<Int>("nagram.hiddenFormatItems", .device, 0, .compose, "lng_nagram_format_menu_items", [])
    public static let inputChinese = NagramOption<Int>("nagram.inputChinese", .device, 0, .compose, "lng_nagram_input_chinese", [])
    public static let disableAutoMarkdown = NagramOption<Bool>("nagram.disableAutoMarkdown", .device, false, .compose, "lng_nagram_disable_auto_markdown", [])
    public static let disableLinkPreview = NagramOption<Bool>("nagram.disableLinkPreview", .device, false, .compose, "lng_nagram_disable_link_preview", [])
    public static let spaceOnSend = NagramOption<Bool>("nagram.spaceOnSend", .device, false, .compose, "lng_nagram_space_on_send", [])
    public static let spaceOnEdit = NagramOption<Bool>("nagram.spaceOnEdit", .device, false, .compose, "lng_nagram_space_on_edit", [])
    public static let defaultCodeLanguage = NagramOption<String>("nagram.defaultCodeLanguage", .device, "", .compose, "lng_nagram_default_code_language", [])
    public static let quickReplies = NagramOption<String>("nagram.quickReplies", .device, "{\"version\":1,\"replies\":[\"\",\"\"]}", .compose, "lng_nagram_quick_replies", [], object: true)
    public static let confirmSticker = NagramOption<Bool>("nagram.confirmSticker", .device, false, .compose, "lng_nagram_confirm_sticker", [])
    public static let confirmGif = NagramOption<Bool>("nagram.confirmGif", .device, false, .compose, "lng_nagram_confirm_gif", [])
    public static let previewVoice = NagramOption<Bool>("nagram.previewVoice", .device, false, .compose, "lng_nagram_preview_voice", [])
    public static let previewRoundVideo = NagramOption<Bool>("nagram.previewRoundVideo", .device, false, .compose, "lng_nagram_preview_round_video", [])
    public static let confirmPrivateCall = NagramOption<Bool>("nagram.confirmPrivateCall", .device, false, .compose, "lng_nagram_confirm_private_call", [])
    public static let forwardBeforeComment = NagramOption<Bool>("nagram.forwardBeforeComment", .device, false, .compose, "lng_nagram_forward_before_comment", [])
    public static let showRpcErrors = NagramOption<Bool>("nagram.showRpcErrors", .device, false, .services, "lng_nagram_show_rpc_errors", [.localOnly])
    public static let filters = NagramOption<String>("nagram.filters", .account, "", .rules, "lng_nagram_filter_rules", [.refreshMessageView], object: true)
    public static let filtersGlobal = NagramOption<String>("nagram.filtersGlobal", .device, "", .rules, "lng_nagram_filter_global", [.refreshMessageView], object: true)
    public static let filterScopes = NagramOption<String>("nagram.filterScopes", .account, "", .rules, "lng_nagram_filter_scopes", [.refreshMessageView], object: true)
    public static let hiddenMessages = NagramOption<String>("nagram.hiddenMessages", .account, "", .rules, "lng_nagram_hidden_messages", [.refreshMessageView])
    public static let bubbleRoundness = NagramOption<Int>("nagram.bubbleRoundness", .device, 0, .interface, "lng_nagram_bubble_roundness", [.requiresRestart])
    public static let avatarRoundness = NagramOption<Int>("nagram.avatarRoundness", .device, 0, .interface, "lng_nagram_avatar_roundness", [.requiresRestart])
    public static let searchRoundness = NagramOption<Int>("nagram.searchRoundness", .device, 0, .interface, "lng_nagram_search_roundness", [.requiresRestart])
    public static let uniformAvatarShapes = NagramOption<Bool>("nagram.uniformAvatarShapes", .device, false, .interface, "lng_nagram_uniform_avatar_shapes", [.requiresRestart])
    public static let textMessageWidth = NagramOption<Int>("nagram.textMessageWidth", .device, 0, .interface, "lng_nagram_text_message_width", [.refreshMessageView])
    public static let wideChannelPosts = NagramOption<Bool>("nagram.wideChannelPosts", .device, false, .interface, "lng_nagram_wide_channel_posts", [.refreshMessageView])
    public static let hideBubbleTail = NagramOption<Bool>("nagram.hideBubbleTail", .device, false, .interface, "lng_nagram_hide_bubble_tail", [.refreshMessageView])
    public static let themeReplyColors = NagramOption<Bool>("nagram.themeReplyColors", .device, false, .interface, "lng_nagram_theme_reply_colors", [.refreshMessageView])
    public static let hideReplyThumbnail = NagramOption<Bool>("nagram.hideReplyThumbnail", .device, false, .interface, "lng_nagram_hide_reply_thumbnail", [.refreshMessageView])
    public static let ignoreChatTheme = NagramOption<Bool>("nagram.ignoreChatTheme", .device, false, .interface, "lng_nagram_ignore_chat_theme", [])
    public static let ignorePrivateChatTheme = NagramOption<Bool>("nagram.ignorePrivateChatTheme", .device, false, .interface, "lng_nagram_ignore_private_chat_theme", [])
    public static let ignoreChannelChatTheme = NagramOption<Bool>("nagram.ignoreChannelChatTheme", .device, false, .interface, "lng_nagram_ignore_channel_chat_theme", [])
    public static let accountNameInTitle = NagramOption<Bool>("nagram.accountNameInTitle", .device, false, .interface, "lng_nagram_account_name_in_title", [])
    public static let splitSettings = NagramOption<Bool>("nagram.splitSettings", .device, false, .interface, "lng_nagram_split_settings", [])
    public static let alwaysSeasonalDecorations = NagramOption<Bool>("nagram.alwaysSeasonalDecorations", .device, false, .interface, "lng_nagram_always_seasonal", [.requiresRestart])
    public static let mainMenu = NagramOption<String>("nagram.mainMenu", .device, "", .interface, "lng_nagram_main_menu", [], object: true)
    public static let appIcon = NagramOption<String>("nagram.appIcon", .device, "", .interface, "lng_nagram_app_icon", [.localOnly])
    public static let hideAppIconBadge = NagramOption<Bool>("nagram.hideAppIconBadge", .device, false, .interface, "lng_nagram_hide_app_icon_badge", [])
    public static let notificationDelay = NagramOption<Int>("nagram.notificationDelay", .device, 0, .interface, "lng_nagram_notification_delay", [])
    public static let otherDeviceNotificationDelay = NagramOption<Int>("nagram.otherDeviceNotificationDelay", .device, 0, .interface, "lng_nagram_other_device_notification_delay", [])
    public static let halfwidthUiPunctuation = NagramOption<Bool>("nagram.halfwidthUiPunctuation", .device, false, .interface, "lng_nagram_halfwidth_ui_punctuation", [.requiresRestart])
    public static let autoInlineBotEnabled = NagramOption<Bool>("nagram.autoInlineBotEnabled", .device, false, .rules, "lng_nagram_inline_auto", [])
    public static let inlineBotRules = NagramOption<String>("nagram.inlineBotRules", .device, "", .rules, "lng_nagram_inline_rules", [], object: true)
    public static let linkRules = NagramOption<String>("nagram.linkRules", .device, "", .rules, "lng_nagram_link_rules", [], object: true)
    public static let disableOfficialAutoLogin = NagramOption<Bool>("nagram.disableOfficialAutoLogin", .device, false, .rules, "lng_nagram_disable_official_auto_login", [])
    public static let skipOpenLinkConfirm = NagramOption<Bool>("nagram.skipOpenLinkConfirm", .device, false, .rules, "lng_nagram_skip_open_link_confirm", [])
    public static let hashtagSearchPageChannel = NagramOption<Int>("nagram.hashtagSearchPageChannel", .device, 0, .rules, "lng_nagram_hashtag_page_channel", [])
    public static let hashtagSearchPageChat = NagramOption<Int>("nagram.hashtagSearchPageChat", .device, 0, .rules, "lng_nagram_hashtag_page_chat", [])
    public static let webAppWidthScale = NagramOption<Int>("nagram.webAppWidthScale", .device, 100, .rules, "lng_nagram_web_app_width", [.localOnly])
    public static let webAppHeightScale = NagramOption<Int>("nagram.webAppHeightScale", .device, 100, .rules, "lng_nagram_web_app_height", [.localOnly])
    public static let webAppAndroidPlatform = NagramOption<Bool>("nagram.webAppAndroidPlatform", .device, false, .rules, "lng_nagram_web_app_android_platform", [])
    public static let webviewExternalPattern = NagramOption<String>("nagram.webviewExternalPattern", .device, "", .rules, "lng_nagram_webview_external", [])
    public static let voiceRecordBitrate = NagramOption<Int>("nagram.voiceRecordBitrate", .device, 0, .media, "lng_nagram_voice_record_bitrate", [])
    public static let groupCallRawAudio = NagramOption<Bool>("nagram.groupCallRawAudio", .device, false, .media, "lng_nagram_group_call_raw_audio", [])
    public static let musicCoverUrl = NagramOption<String>("nagram.musicCoverUrl", .device, "", .media, "lng_nagram_music_cover_url", [.hidden])
    public static let stickerExportPath = NagramOption<String>("nagram.stickerExportPath", .device, "", .media, "lng_nagram_sticker_export_path", [.hidden])
    public static let stickerExportAutoSync = NagramOption<Bool>("nagram.stickerExportAutoSync", .device, false, .media, "lng_nagram_sticker_export_auto_sync", [])
    public static let stickerExportDirNaming = NagramOption<Int>("nagram.stickerExportDirNaming", .device, 0, .media, "lng_nagram_sticker_export_dir_naming", [])
    public static let unlimitedFavedStickers = NagramOption<Bool>("nagram.unlimitedFavedStickers", .device, false, .media, "lng_nagram_unlimited_faved_stickers", [])
    public static let localFavedStickers = NagramOption<String>("nagram.localFavedStickers", .account, "", .media, "lng_nagram_local_faved_stickers", [.hidden], object: true)
    public static let stickerScale = NagramOption<Int>("nagram.stickerScale", .device, 100, .media, "lng_nagram_sticker_scale", [.refreshMessageView])
    public static let hideStickerTime = NagramOption<Bool>("nagram.hideStickerTime", .device, false, .media, "lng_nagram_hide_sticker_time", [.refreshMessageView])
    public static let recentStickerLimit = NagramOption<Int>("nagram.recentStickerLimit", .device, 0, .media, "lng_nagram_recent_sticker_limit", [])
    public static let hideGroupStickers = NagramOption<Bool>("nagram.hideGroupStickers", .device, false, .media, "lng_nagram_hide_group_stickers", [])
    public static let hideRecommendedStickers = NagramOption<Bool>("nagram.hideRecommendedStickers", .device, false, .media, "lng_nagram_hide_recommended_stickers", [])
    public static let hideRecommendedEmoji = NagramOption<Bool>("nagram.hideRecommendedEmoji", .device, false, .media, "lng_nagram_hide_recommended_emoji", [])
    public static let hideGifCategories = NagramOption<Bool>("nagram.hideGifCategories", .device, false, .media, "lng_nagram_hide_gif_categories", [])
    public static let hideGreetingSticker = NagramOption<Bool>("nagram.hideGreetingSticker", .device, false, .media, "lng_nagram_hide_greeting_sticker", [])
    public static let disableVideoAutoplay = NagramOption<Bool>("nagram.disableVideoAutoplay", .device, false, .media, "lng_nagram_disable_video_autoplay", [.refreshMessageView])
    public static let gifPlaybackControls = NagramOption<Bool>("nagram.gifPlaybackControls", .device, false, .media, "lng_nagram_gif_playback_controls", [])
    public static let mp4FilePreview = NagramOption<Bool>("nagram.mp4FilePreview", .device, false, .media, "lng_nagram_mp4_file_preview", [])
    public static let smallGifs = NagramOption<Bool>("nagram.smallGifs", .device, false, .media, "lng_nagram_small_gifs", [.refreshMessageView])
    public static let stickerPanelScale = NagramOption<Int>("nagram.stickerPanelScale", .device, 100, .media, "lng_nagram_sticker_panel_scale", [.requiresRestart])
    public static let downloadsInMainMenu = NagramOption<Bool>("nagram.downloadsInMainMenu", .device, false, .media, "lng_nagram_downloads_in_main_menu", [])
    public static let blockExecutableAutoDownload = NagramOption<Bool>("nagram.blockExecutableAutoDownload", .device, false, .media, "lng_nagram_block_executable_auto_download", [])
    public static let blockArchiveAutoDownload = NagramOption<Bool>("nagram.blockArchiveAutoDownload", .device, false, .media, "lng_nagram_block_archive_auto_download", [])
    public static let messageMenu = NagramOption<String>("nagram.messageMenu", .device, "", .menu, "lng_nagram_menu", [.exportable], object: true)
    public static let quickRatingFirst = NagramOption<String>("nagram.quickRatingFirst", .device, "", .menu, "lng_nagram_menu_quick_rating_first", [.exportable])
    public static let quickRatingSecond = NagramOption<String>("nagram.quickRatingSecond", .device, "", .menu, "lng_nagram_menu_quick_rating_second", [.exportable])
    public static let confirmRepeat = NagramOption<Bool>("nagram.confirmRepeat", .device, false, .menu, "lng_nagram_menu_confirm_repeat", [.exportable])
    public static let compactMessageMenu = NagramOption<Bool>("nagram.compactMessageMenu", .device, false, .menu, "lng_nagram_menu_compact", [.exportable])
    public static let repeatWithoutQuote = NagramOption<Bool>("nagram.repeatWithoutQuote", .device, false, .menu, "lng_nagram_menu_repeat_without_quote", [.exportable])
    public static let noRepeatInChannels = NagramOption<Bool>("nagram.noRepeatInChannels", .device, false, .menu, "lng_nagram_menu_no_repeat_channels", [.exportable])
    public static let scrollAfterRepeat = NagramOption<Bool>("nagram.scrollAfterRepeat", .device, false, .menu, "lng_nagram_menu_scroll_after_repeat", [.exportable])
    public static let secondsInMessages = NagramOption<Bool>("nagram.secondsInMessages", .device, false, .messages, "lng_nagram_seconds_in_messages", [.refreshMessageView])
    public static let showForwardedMessageDate = NagramOption<Bool>("nagram.showForwardedMessageDate", .device, false, .messages, "lng_nagram_show_forwarded_message_date", [.refreshMessageView])
    public static let showServiceTime = NagramOption<Bool>("nagram.showServiceTime", .device, false, .messages, "lng_nagram_show_service_time", [.refreshMessageView])
    public static let showMessageId = NagramOption<Bool>("nagram.showMessageId", .device, false, .messages, "lng_nagram_show_message_id", [.hidden])
    public static let messageIdPlace = NagramOption<Int>("nagram.messageIdPlace", .device, 0, .messages, "lng_nagram_show_message_id", [.refreshMessageView])
    public static let senderOnlineStatus = NagramOption<Int>("nagram.senderOnlineStatus", .device, 0, .messages, "lng_nagram_sender_online", [.refreshMessageView])
    public static let exactMessageCounters = NagramOption<Bool>("nagram.exactMessageCounters", .device, false, .messages, "lng_nagram_exact_message_counters", [.refreshMessageView])
    public static let hideMessageViews = NagramOption<Bool>("nagram.hideMessageViews", .device, false, .messages, "lng_nagram_hide_message_views", [.refreshMessageView])
    public static let showForwardCount = NagramOption<Bool>("nagram.showForwardCount", .device, false, .messages, "lng_nagram_show_forward_count", [.refreshMessageView])
    public static let hideChannelSignature = NagramOption<Bool>("nagram.hideChannelSignature", .device, false, .messages, "lng_nagram_hide_channel_signature", [.refreshMessageView])
    public static let hideEditedBadge = NagramOption<Bool>("nagram.hideEditedBadge", .device, false, .messages, "lng_nagram_hide_edited_badge", [.refreshMessageView])
    public static let editedMark = NagramOption<String>("nagram.editedMark", .device, "", .messages, "lng_nagram_edited_mark", [.refreshMessageView])
    public static let hideReactions = NagramOption<Bool>("nagram.hideReactions", .device, false, .messages, "lng_nagram_hide_reactions", [.refreshMessageView])
    public static let hidePrivateReactions = NagramOption<Bool>("nagram.hidePrivateReactions", .device, false, .messages, "lng_nagram_hide_private_reactions", [.refreshMessageView])
    public static let hideGroupReactions = NagramOption<Bool>("nagram.hideGroupReactions", .device, false, .messages, "lng_nagram_hide_group_reactions", [.refreshMessageView])
    public static let hideChannelReactions = NagramOption<Bool>("nagram.hideChannelReactions", .device, false, .messages, "lng_nagram_hide_channel_reactions", [.refreshMessageView])
    public static let hideReactionMenu = NagramOption<Bool>("nagram.hideReactionMenu", .device, false, .messages, "lng_nagram_hide_reaction_menu", [])
    public static let hideReactionMenuWhenSelecting = NagramOption<Bool>("nagram.hideReactionMenuWhenSelecting", .device, false, .messages, "lng_nagram_hide_reaction_menu_when_selecting", [])
    public static let moveWhoReactedToTop = NagramOption<Bool>("nagram.moveWhoReactedToTop", .device, false, .messages, "lng_nagram_move_who_reacted_to_top", [])
    public static let disablePremiumStickerEffects = NagramOption<Bool>("nagram.disablePremiumStickerEffects", .device, false, .messages, "lng_nagram_disable_premium_sticker_effects", [])
    public static let disableEmojiInteractions = NagramOption<Bool>("nagram.disableEmojiInteractions", .device, false, .messages, "lng_nagram_disable_emoji_interactions", [])
    public static let disableMessageEffects = NagramOption<Bool>("nagram.disableMessageEffects", .device, false, .messages, "lng_nagram_disable_message_effects", [])
    public static let revealSpoilers = NagramOption<Bool>("nagram.revealSpoilers", .device, false, .messages, "lng_nagram_reveal_spoilers", [.refreshMessageView])
    public static let hideQuickShare = NagramOption<Bool>("nagram.hideQuickShare", .device, false, .messages, "lng_nagram_hide_quick_share", [.refreshMessageView])
    public static let hideRecommendedChannels = NagramOption<Bool>("nagram.hideRecommendedChannels", .device, false, .messages, "lng_nagram_hide_recommended_channels", [.refreshMessageView])
    public static let hidePremiumBadges = NagramOption<Bool>("nagram.hidePremiumBadges", .device, false, .messages, "lng_nagram_hide_premium_badges", [.refreshMessageView])
    public static let editedIcon = NagramOption<Bool>("nagram.editedIcon", .device, false, .messages, "lng_nagram_edited_icon", [.refreshMessageView])
    public static let simplifiedReplies = NagramOption<Bool>("nagram.simplifiedReplies", .device, false, .messages, "lng_nagram_simplified_replies", [.refreshMessageView])
    public static let disableVideoUserpics = NagramOption<Bool>("nagram.disableVideoUserpics", .device, false, .messages, "lng_nagram_disable_video_userpics", [.refreshMessageView, .refreshDialogList])
    public static let collapseRecommendedChannels = NagramOption<Bool>("nagram.collapseRecommendedChannels", .device, false, .messages, "lng_nagram_collapse_recommended_channels", [])
    public static let hideSavedTags = NagramOption<Bool>("nagram.hideSavedTags", .device, false, .messages, "lng_nagram_hide_saved_tags", [])
    public static let hidePrivateChatActivities = NagramOption<Bool>("nagram.hidePrivateChatActivities", .device, false, .messages, "lng_nagram_hide_private_chat_activities", [])
    public static let readingSpacing = NagramOption<Bool>("nagram.readingSpacing", .device, false, .messages, "lng_nagram_reading_spacing", [.refreshMessageView])
    public static let readingChinese = NagramOption<Int>("nagram.readingChinese", .device, 0, .messages, "lng_nagram_reading_chinese", [.refreshMessageView])
    public static let ipStrategy = NagramOption<Int>("nagram.ipStrategy", .device, 0, .network, "lng_nagram_ip_strategy", [.localOnly])
    public static let disableBackupAddresses = NagramOption<Bool>("nagram.disableBackupAddresses", .device, false, .network, "lng_nagram_disable_backup_addresses", [.localOnly])
    public static let useSystemDns = NagramOption<Bool>("nagram.useSystemDns", .device, false, .network, "lng_nagram_use_system_dns", [.localOnly])
    public static let customDoh = NagramOption<String>("nagram.customDoh", .device, "", .network, "lng_nagram_custom_doh", [.localOnly])
    public static let downloadSpeedBoost = NagramOption<String>("nagram.downloadSpeedBoost", .device, "none", .network, "lng_nagram_download_speed_boost", [.requiresRestart, .localOnly])
    public static let uploadSpeedBoost = NagramOption<Bool>("nagram.uploadSpeedBoost", .device, false, .network, "lng_nagram_upload_speed_boost", [.requiresRestart, .localOnly])
    public static let quietHours = NagramOption<String>("nagram.quietHours", .device, "", .interface, "lng_nagram_quiet_hours", [], object: true)
    public static let keywordAlerts = NagramOption<String>("nagram.keywordAlerts", .account, "", .rules, "lng_nagram_keyword_alerts", [], object: true)
    public static let peerAliases = NagramOption<String>("nagram.peerAliases", .account, "", .privacy, "lng_nagram_peer_alias", [.refreshMessageView, .refreshDialogList], object: true)
    public static let hideMyPhone = NagramOption<Bool>("nagram.hideMyPhone", .device, false, .privacy, "lng_nagram_hide_my_phone", [.refreshDialogList])
    public static let demoMode = NagramOption<Bool>("nagram.demoMode", .device, false, .privacy, "lng_nagram_demo_mode", [.localOnly, .refreshDialogList])
    public static let hideReadTime = NagramOption<Bool>("nagram.hideReadTime", .device, false, .privacy, "lng_nagram_hide_read_time", [])
    public static let hideSharePhonePrompt = NagramOption<Bool>("nagram.hideSharePhonePrompt", .device, false, .privacy, "lng_nagram_hide_share_phone_prompt", [])
    public static let doNotSharePhone = NagramOption<Bool>("nagram.doNotSharePhone", .device, false, .privacy, "lng_nagram_do_not_share_phone", [])
    public static let hideSendStatus = NagramOption<Bool>("nagram.hideSendStatus", .device, false, .privacy, "lng_nagram_hide_send_status", [])
    public static let forceCopy = NagramOption<Bool>("nagram.forceCopy", .device, false, .privacy, "lng_nagram_force_copy", [.refreshMessageView])
    public static let ignoreContentRestrictions = NagramOption<Bool>("nagram.ignoreContentRestrictions", .device, false, .privacy, "lng_nagram_ignore_restrictions", [.refreshMessageView])
    public static let skipSensitiveWarning = NagramOption<Bool>("nagram.skipSensitiveWarning", .device, false, .privacy, "lng_nagram_skip_sensitive_warning", [.refreshMessageView])
    public static let profileIdFormat = NagramOption<Int>("nagram.profileIdFormat", .device, 0, .privacy, "lng_nagram_profile_id_format", [])
    public static let showProfileDc = NagramOption<Bool>("nagram.showProfileDc", .device, false, .privacy, "lng_nagram_show_profile_dc", [])
    public static let showRegistrationDate = NagramOption<Bool>("nagram.showRegistrationDate", .device, false, .privacy, "lng_nagram_show_registration_date", [])
    public static let hideProfileGifts = NagramOption<Bool>("nagram.hideProfileGifts", .device, false, .privacy, "lng_nagram_hide_profile_gifts", [])
    public static let hideCreateTodo = NagramOption<Bool>("nagram.hideCreateTodo", .device, false, .privacy, "lng_nagram_hide_create_todo", [])
    public static let nameOrder = NagramOption<Int>("nagram.nameOrder", .device, 0, .privacy, "lng_nagram_name_order", [.requiresRestart])
    public static let persianCalendar = NagramOption<Int>("nagram.persianCalendar", .device, 0, .privacy, "lng_nagram_persian_calendar", [.refreshMessageView])
    public static let moderateDefaults = NagramOption<Int>("nagram.moderateDefaults", .device, 0, .privacy, "lng_nagram_moderate_defaults", [])
    public static let adminShortcuts = NagramOption<Bool>("nagram.adminShortcuts", .device, false, .privacy, "lng_nagram_admin_shortcuts_option", [])
    public static let userpicAdminActions = NagramOption<Bool>("nagram.userpicAdminActions", .device, false, .privacy, "lng_nagram_userpic_admin_actions", [])
    public static let mentionAdminActions = NagramOption<Bool>("nagram.mentionAdminActions", .device, false, .privacy, "lng_nagram_mention_admin_actions", [])
    public static let kickDeleteMessages = NagramOption<Bool>("nagram.kickDeleteMessages", .device, false, .privacy, "lng_nagram_kick_delete_messages", [])
    public static let autoTranslate = NagramOption<Int>("nagram.autoTranslate", .device, 0, .services, "lng_nagram_auto_translate", [])
    public static let autoTranslateAccount = NagramOption<Int>("nagram.autoTranslateAccount", .account, 0, .services, "lng_nagram_auto_translate_account", [])
    public static let autoTranslateChats = NagramOption<String>("nagram.autoTranslateChats", .account, "", .services, "lng_nagram_auto_translate_chats", [], object: true)
    public static let services = NagramOption<String>("nagram.services", .device, "", .services, "lng_nagram_services", [.localOnly], object: true)
    public static let preferSystemAi = NagramOption<Bool>("nagram.preferSystemAi", .device, false, .services, "lng_nagram_system_ai", [.refreshComposeButtons])
    public static let translationContext = NagramOption<Bool>("nagram.translationContext", .device, false, .services, "lng_nagram_service_use_context", [])
    public static let chatTranslationUseService = NagramOption<Bool>("nagram.chatTranslationUseService", .device, false, .services, "lng_nagram_chat_translation_service", [])
    public static let sendTranslation = NagramOption<Bool>("nagram.sendTranslation", .device, false, .services, "lng_nagram_send_translation", [])
    public static let sendTranslationChats = NagramOption<String>("nagram.sendTranslationChats", .account, "", .services, "lng_nagram_send_translation_chats", [], object: true)
    public static let snapshotCloudTheme = NagramOption<String>("nagram.snapshotCloudTheme", .account, "", .menu, "lng_nagram_snapshot_cloud_theme", [.hidden], object: true)
    public static let snapshotCloudAccount = NagramOption<String>("nagram.snapshotCloudAccount", .device, "", .menu, "lng_nagram_snapshot_cloud_theme", [.hidden])
    public static let snapshot = NagramOption<String>("nagram.snapshot", .device, "", .menu, "lng_nagram_snapshot", [], object: true)
    public static let cloudSyncState = NagramOption<String>("nagram.cloudSyncState", .account, "", .services, "lng_nagram_sync_title", [.hidden], object: true)
    public static let cloudSyncAuto = NagramOption<String>("nagram.cloudSyncAuto", .account, "", .services, "lng_nagram_sync_auto", [])

    public static let all: [NagramOptionInfo] = [
        unlimitedPinnedChats.info,
        localPinnedChats.info,
        chatListCompact.info,
        chatPreviewLines.info,
        hideSavedAndArchivedPreviews.info,
        secondsInChatList.info,
        hideStories.info,
        hideAllChatsFolder.info,
        showArchiveInFolders.info,
        archiveInFolderList.info,
        savedInFolderList.info,
        hideFolderUnreadCounters.info,
        startupFolderMode.info,
        startupFolderId.info,
        lastOpenedFolderId.info,
        chatSort.info,
        managedFolderIds.info,
        recentFolderIds.info,
        hideSponsoredMessages.info,
        hideProxySponsor.info,
        hidePremiumPromotions.info,
        hideBirthdaySuggestions.info,
        disableCommunityGrouping.info,
        compactFolderTabs.info,
        disableGlobalSearch.info,
        chooseFolderAfterJoin.info,
        hidePhoneSuggestion.info,
        markMutualContacts.info,
        disableScrollToNextChannel.info,
        disableScrollToNextTopic.info,
        recentChats.info,
        recentChatsLimit.info,
        recentChatsList.info,
        chatTools.info,
        topBarActions.info,
        recentChatsInShare.info,
        saveReadingPosition.info,
        readingPositions.info,
        hideAttachButton.info,
        hideEmojiButton.info,
        hideRecordingButton.info,
        hideBotCommandButton.info,
        hideBotMenu.info,
        hideAutoDeleteButton.info,
        hideGiftButton.info,
        hideAiButton.info,
        hideSendAsButton.info,
        hideStarsReactionButton.info,
        hideChannelMuteButton.info,
        channelDiscussButton.info,
        disableEmojiHover.info,
        disableAttachHover.info,
        botCommandsToDraft.info,
        tallMentionList.info,
        inputPlaceholderMode.info,
        formatToolbar.info,
        hiddenFormatItems.info,
        inputChinese.info,
        disableAutoMarkdown.info,
        disableLinkPreview.info,
        spaceOnSend.info,
        spaceOnEdit.info,
        defaultCodeLanguage.info,
        quickReplies.info,
        confirmSticker.info,
        confirmGif.info,
        previewVoice.info,
        previewRoundVideo.info,
        confirmPrivateCall.info,
        forwardBeforeComment.info,
        showRpcErrors.info,
        filters.info,
        filtersGlobal.info,
        filterScopes.info,
        hiddenMessages.info,
        bubbleRoundness.info,
        avatarRoundness.info,
        searchRoundness.info,
        uniformAvatarShapes.info,
        textMessageWidth.info,
        wideChannelPosts.info,
        hideBubbleTail.info,
        themeReplyColors.info,
        hideReplyThumbnail.info,
        ignoreChatTheme.info,
        ignorePrivateChatTheme.info,
        ignoreChannelChatTheme.info,
        accountNameInTitle.info,
        splitSettings.info,
        alwaysSeasonalDecorations.info,
        mainMenu.info,
        appIcon.info,
        hideAppIconBadge.info,
        notificationDelay.info,
        otherDeviceNotificationDelay.info,
        halfwidthUiPunctuation.info,
        autoInlineBotEnabled.info,
        inlineBotRules.info,
        linkRules.info,
        disableOfficialAutoLogin.info,
        skipOpenLinkConfirm.info,
        hashtagSearchPageChannel.info,
        hashtagSearchPageChat.info,
        webAppWidthScale.info,
        webAppHeightScale.info,
        webAppAndroidPlatform.info,
        webviewExternalPattern.info,
        voiceRecordBitrate.info,
        groupCallRawAudio.info,
        musicCoverUrl.info,
        stickerExportPath.info,
        stickerExportAutoSync.info,
        stickerExportDirNaming.info,
        unlimitedFavedStickers.info,
        localFavedStickers.info,
        stickerScale.info,
        hideStickerTime.info,
        recentStickerLimit.info,
        hideGroupStickers.info,
        hideRecommendedStickers.info,
        hideRecommendedEmoji.info,
        hideGifCategories.info,
        hideGreetingSticker.info,
        disableVideoAutoplay.info,
        gifPlaybackControls.info,
        mp4FilePreview.info,
        smallGifs.info,
        stickerPanelScale.info,
        downloadsInMainMenu.info,
        blockExecutableAutoDownload.info,
        blockArchiveAutoDownload.info,
        messageMenu.info,
        quickRatingFirst.info,
        quickRatingSecond.info,
        confirmRepeat.info,
        compactMessageMenu.info,
        repeatWithoutQuote.info,
        noRepeatInChannels.info,
        scrollAfterRepeat.info,
        secondsInMessages.info,
        showForwardedMessageDate.info,
        showServiceTime.info,
        showMessageId.info,
        messageIdPlace.info,
        senderOnlineStatus.info,
        exactMessageCounters.info,
        hideMessageViews.info,
        showForwardCount.info,
        hideChannelSignature.info,
        hideEditedBadge.info,
        editedMark.info,
        hideReactions.info,
        hidePrivateReactions.info,
        hideGroupReactions.info,
        hideChannelReactions.info,
        hideReactionMenu.info,
        hideReactionMenuWhenSelecting.info,
        moveWhoReactedToTop.info,
        disablePremiumStickerEffects.info,
        disableEmojiInteractions.info,
        disableMessageEffects.info,
        revealSpoilers.info,
        hideQuickShare.info,
        hideRecommendedChannels.info,
        hidePremiumBadges.info,
        editedIcon.info,
        simplifiedReplies.info,
        disableVideoUserpics.info,
        collapseRecommendedChannels.info,
        hideSavedTags.info,
        hidePrivateChatActivities.info,
        readingSpacing.info,
        readingChinese.info,
        ipStrategy.info,
        disableBackupAddresses.info,
        useSystemDns.info,
        customDoh.info,
        downloadSpeedBoost.info,
        uploadSpeedBoost.info,
        quietHours.info,
        keywordAlerts.info,
        peerAliases.info,
        hideMyPhone.info,
        demoMode.info,
        hideReadTime.info,
        hideSharePhonePrompt.info,
        doNotSharePhone.info,
        hideSendStatus.info,
        forceCopy.info,
        ignoreContentRestrictions.info,
        skipSensitiveWarning.info,
        profileIdFormat.info,
        showProfileDc.info,
        showRegistrationDate.info,
        hideProfileGifts.info,
        hideCreateTodo.info,
        nameOrder.info,
        persianCalendar.info,
        moderateDefaults.info,
        adminShortcuts.info,
        userpicAdminActions.info,
        mentionAdminActions.info,
        kickDeleteMessages.info,
        autoTranslate.info,
        autoTranslateAccount.info,
        autoTranslateChats.info,
        services.info,
        preferSystemAi.info,
        translationContext.info,
        chatTranslationUseService.info,
        sendTranslation.info,
        sendTranslationChats.info,
        snapshotCloudTheme.info,
        snapshotCloudAccount.info,
        snapshot.info,
        cloudSyncState.info,
        cloudSyncAuto.info,
    ]
}
