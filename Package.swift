// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MagSafeGuard",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "MagSafeGuardCore",
            targets: ["MagSafeGuardCore"]
        ),
    ],
    dependencies: [
        // Add package dependencies here if needed
    ],
    targets: [
        // Core business logic target (testable)
        .target(
            name: "MagSafeGuardCore",
            dependencies: [],
            path: "MagSafeGuard",
            sources: [
                "Models/SettingsModel.swift",
                "Utilities/FeatureFlags.swift",
                "Utilities/Logger.swift"
            ],
            exclude: [
                "Controllers/AppController.swift"
            ],
            swiftSettings: [
                .define("CI_BUILD", .when(platforms: [.macOS], configuration: .debug))
            ]
        ),
        // Test target
        .testTarget(
            name: "MagSafeGuardCoreTests",
            dependencies: ["MagSafeGuardCore"],
            path: "MagSafeGuardTests",
            sources: [
                "Models/SettingsModelTests.swift",
                "Utilities/FeatureFlagsTests.swift",
                "Utilities/LoggerTests.swift"
            ]
        ),
    ]
)