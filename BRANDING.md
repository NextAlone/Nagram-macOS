# Nagram for macOS branding

Nagram for macOS is an independent Telegram client maintained by NextAlone.
It is based on Telegram for macOS; upstream source, history, license and
copyright notices remain with their respective authors.

The Nagram name and project identity are controlled by NextAlone.
Nagram icon artwork is Copyright © MaitungTM. All rights reserved.
The artwork is a separate brand asset; the source-code license does not
license its use as the branding of third-party distributions. Preserve this
notice with copied or derived icon assets.

The app icon `Telegram-Mac/AppIcon.icon` is the Nagram iOS layered artwork
(`Nagram.icon`, shared with Nagram Desktop). The PNG renditions in
`Telegram-Mac/Assets.xcassets/AppIcon.appiconset` are derived from it for
systems that do not render Icon Composer icons.

Application identity:

- Display name: Nagram.
- Bundle identifier: `xyz.nextalone.nagram.macos`, share extension
  `xyz.nextalone.nagram.macos.TelegramShare`, team `7P8CLHDH5G`, app group
  `7P8CLHDH5G.xyz.nextalone.nagram.macos`. Telegram data of the official app is
  not shared or imported.
- API credentials are not in the repository; they are read from
  `Telegram-Mac/Nagram.local.xcconfig` (`NAGRAM_API_ID`, `NAGRAM_API_HASH`).
- Internal target names (`Telegram`, `TelegramShare`) and the `tg:` protocol
  are kept for compatibility with the upstream build system.
