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
                "Models/",
                "Controllers/AppController.swift",
                "Utilities/FeatureFlags.swift",
                "Utilities/Logger.swift",
                "Views/Settings/UserDefaultsManager.swift",
                "Services/PowerMonitorService.swift",
                "Services/PowerMonitorCore.swift",
                "Services/AuthenticationService.swift",
                "Services/AuthenticationContextProtocol.swift",
                "Services/SecurityActionsService.swift",
                "Services/SystemActionsProtocol.swift",
                "Services/AutoArmManager.swift",
                "Services/LocationManagerProtocol.swift",
                "NotificationService.swift"
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
                "Controllers/AppControllerTests.swift",
                "Mocks/"
            ]
        ),
    ]
)