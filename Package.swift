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
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "VimeoRestrictedPlayer",
            targets: ["VimeoRestrictedPlayer"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // No external dependencies required - using native iOS frameworks only
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "VimeoRestrictedPlayer",
            dependencies: [],
            path: "Sources/VimeoRestrictedPlayer"
        ),
        .testTarget(
            name: "VimeoRestrictedPlayerTests",
            dependencies: ["VimeoRestrictedPlayer"],
            path: "Tests/VimeoRestrictedPlayerTests"
        ),
    ]
)
