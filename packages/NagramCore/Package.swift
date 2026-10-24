// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "NagramCore",
    platforms: [.macOS(.v10_13)],
    products: [
        .library(name: "NagramCore", targets: ["NagramCore"]),
    ],
    dependencies: [
        .package(name: "SSignalKit", path: "../../submodules/telegram-ios/submodules/SSignalKit"),
    ],
    targets: [
        .target(
            name: "NagramCore",
            dependencies: [
                .product(name: "SwiftSignalKit", package: "SSignalKit", condition: nil),
            ],
            path: "Sources/NagramCore",
            resources: [.copy("Resources")]),
    ]
)
