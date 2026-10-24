// swift-tools-version:5.5

import PackageDescription

let deps: [(String, String)] = [
    ("AlertsUI", "../AlertsUI"),
    ("ApiCredentials", "../ApiCredentials"),
    ("GeneralRows", "../GeneralRows"),
    ("InputDataUI", "../InputDataUI"),
    ("Localization", "../Localization"),
    ("NagramCore", "../NagramCore"),
    ("TGUIKit", "../TGUIKit"),
    ("TelegramContext", "../TelegramContext"),
    ("TelegramTheme", "../TelegramTheme"),
    ("TelegramUtils", "../TelegramUtils"),
]

let package = Package(
    name: "NagramUI",
    platforms: [.macOS(.v10_13)],
    products: [
        .library(name: "NagramUI", targets: ["NagramUI"]),
    ],
    dependencies: [
        .package(name: "SSignalKit", path: "../../submodules/telegram-ios/submodules/SSignalKit"),
        .package(name: "TelegramCore", path: "../../submodules/telegram-ios/submodules/TelegramCore"),
        .package(name: "Postbox", path: "../../submodules/telegram-ios/submodules/Postbox"),
        .package(name: "MtProtoKit", path: "../../submodules/telegram-ios/submodules/MtProtoKit"),
    ] + deps.map { .package(name: $0.0, path: $0.1) },
    targets: [
        .target(
            name: "NagramUI",
            dependencies: [
                .product(name: "SwiftSignalKit", package: "SSignalKit", condition: nil),
                .product(name: "TelegramCore", package: "TelegramCore", condition: nil),
                .product(name: "Postbox", package: "Postbox", condition: nil),
                .product(name: "MtProtoKit", package: "MtProtoKit", condition: nil),
            ] + deps.map { .product(name: $0.0, package: $0.0, condition: nil) },
            path: "Sources/NagramUI"),
    ]
)
