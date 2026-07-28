// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "BridgeLock",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "BridgeLock",
            targets: [
                "BridgeLock"
            ]
        )
    ],
    targets: [
        .executableTarget(
            name: "BridgeLock",
            path: "Sources/BridgeLock",

            swiftSettings: [
                .swiftLanguageMode(.v6)
            ],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("Security"),
                .linkedFramework("CryptoKit"),
                .linkedFramework("ServiceManagement"),
                .linkedFramework("CoreGraphics")
            ]
        )
    ]
)