// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VimeoRestrictedPlayer",
    platforms: [
        .iOS(.v13),
        .macOS(.v12)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "VimeoRestrictedPlayer",
            targets: ["VimeoRestrictedPlayer"]),
    ],
    dependencies: [
        // Add dependencies here if needed in the future
        // Example: .package(url: "https://github.com/example/package.git", from: "1.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "VimeoRestrictedPlayer",
            dependencies: [],
            path: "Sources/VimeoRestrictedPlayer",
            sources: [
                // Core Components
                "Core/VimeoRestrictedPlayerViewController.swift",
                "Core/VimeoPlayerWebViewBridge.swift",
                
                // Models
                "Models/VimeoPlayerConfiguration.swift",
                "Models/VimeoPlayerState.swift",
                "Models/VimeoPlayerError.swift",
                
                // Protocols
                "Protocols/VimeoPlayerDelegate.swift",
                
                // Utilities
                "Utilities/VimeoHTMLGenerator.swift",
                "Utilities/VimeoURLParser.swift",
                "Utilities/TimeFormatter.swift",
                
                // UI Components
                "UI/VimeoPlayerTheme.swift",
                "UI/VimeoPlayerControls.swift",
                
                // SwiftUI Integration
                "SwiftUI/VimeoPlayerSwiftUIView.swift"
            ],
            resources: [
                // Add resources here if needed
                // .process("Resources")
            ],
            swiftSettings: [
                .define("VIMEO_RESTRICTED_PLAYER", .when(configuration: .debug)),
            ]
        ),
        .testTarget(
            name: "VimeoRestrictedPlayerTests",
            dependencies: ["VimeoRestrictedPlayer"],
            path: "Tests/VimeoRestrictedPlayerTests"
        ),
    ],
    swiftLanguageVersions: [.v5]
)
