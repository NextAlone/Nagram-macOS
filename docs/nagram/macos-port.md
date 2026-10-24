# Porting Nagram Desktop features to macOS

Nagram Desktop (Qt) is the reference: its settings design (`docs/nagram/settings-page.md` in that repository)
numbers every entry (`A01`–`K06`, `E01`–`E40`). This port keeps the same option keys (`nagram.*`), the same
three-language strings (`lng_nagram_*`, copied verbatim into `packages/NagramCore/Sources/NagramCore/Resources`)
and the same configuration export format (`{"version":1,"options":{…}}`), so a configuration exported on one
platform imports on the other. Where each entry hooks into this codebase is in [macos-hooks.md](macos-hooks.md).

## Layout

| Module | Contents |
|---|---|
| `packages/NagramCore` | Option registry (`NagramOptions`, generated from the Qt declarations), storage (`NagramSettings`, UserDefaults; account-scoped keys get `@<peer id>`), exchange, strings, message filters, quiet hours, keyword alerts, menu visibility, text transforms. Depends only on SwiftSignalKit, so hub packages can read options. |
| `packages/NagramUI` | Settings screens: one generic `NagramSettingsController` renders declarative `NagramRow`s; one `Nagram<Section>Rows.swift` per section. A row is only added once its feature works. |
| `packages/ChatUI/.../NagramMessageMenu.swift` | Nagram message-menu actions and the show / hide / Option filter. |
| `packages/ChatHistoryModel/.../NagramHistoryFilter.swift` | Display-time filters, hidden messages and reading transforms, applied while history entries are built. |

Every change to an upstream file carries a nearby `// MARK: NAGRAM`. Options flagged `refreshMessageView`,
`refreshDialogList` or `refreshComposeButtons` re-apply the current theme when they change, which relays out
chats and lists. Options flagged `requiresRestart` offer a restart.

## Status

Done (setting row present and wired):

- Interface: A02 A03 A04 A05 A06 A07 A08 A09 A10 A12 A13 A16 A17 A21 A23.
- Chat list: B02 (one line) B03 B04 B05 (last opened) B06 B07 B08 B10 B11 B12 B13 B22 B30 B31.
- Messages: C01–C10 C11–C24 C25 C26 C28 C29 C30 C31 C32 C33.
- Compose: D01 D02 D03 D04 D05 D06 D07 D08 D09 D11 D12 D14 D15 D16 D17 D18 D19 D20 D22 D23 D26 D27 D28 D31 D32.
- Message menu: visibility for the upstream items (E01–E14, E28) and E15 E16 E17 E20 E23 E24 E25 E26 E29 (no JSON)
  E19 E27 E30 E31 E32 E34 E35 E36 E38 E39 E40.
- Media: F01 F02 F03 F04 F05 F06 F07 F08 F09 F14 F15 F17 F18.
- Privacy: G01 G02 (window capture exclusion, notification and chat-list text) G03 G04 G05 (users) G06 (users) G07 G08 G13 G14 G10 G13 G14 G15 G18 (typing, recording, sticker choice); local names for peers (profile action).
- Rules: I01 (account rules, outgoing, Zalgo, hidden authors, hidden messages) I11 I12 I13 I14 I15 I16 I17.
- Translation: H01 (message translation through OpenAI-compatible, Anthropic, DeepL, Google, Microsoft or Yandex
  instances), H03 (instances, presets, Keychain keys, connection test), H10 (summary).
- Configuration: J01 J02 J03 J04 J06 J07; `tg://nasettings/<section>?r=<row>` and `t.me/nasettings/…` links.

Messages hidden by a rule or by "hide message" keep their bubble, with the media removed and the text replaced by
`lng_nagram_filter_hidden`, as in Nagram Desktop; they are not dropped from the history.

`G01` uses the macOS-only key `nagram.hideMyPhone` (Nagram Desktop reuses its upstream setting).

Not applicable on macOS: A15, A18, A19 (the title already shows the account), A22, B14, B15, B19, D10 (the macOS composer
has no Stars reaction button), D13, G16.

Pending, needing upstream core changes (the `submodules/telegram-ios` submodule would have to be forked):
B23 community grouping, F19 voice bitrate, G18 upload status, I09 Android platform, J05 RPC errors, K01–K06.

Pending, app-side work not yet done: A11 A14 A20, B01 B05 (specific folder) B09 B16 B17 B18 B20 B21 B24 B25–B29, C27,
D21 D24 D25 D29 D30, E18 E21 E22 E33 E37, F10 F11 F12 F13 F16 F21–F27,
G09 G12 G17 G19–G21, H02 H04 H06–H09 H11, I02 I04–I08, J08–J11.
