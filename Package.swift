// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MagSafeGuard",
    platforms: [
        .macOS(.v14)  // Updated for Swift Testing support
    ],
    products: [
        .library(
            name: "MagSafeGuardDomain", 
            targets: ["MagSafeGuardDomain"]
        ),
        .library(
            name: "MagSafeGuardCore",
            targets: ["MagSafeGuardCore"]
        ),
    ],
    dependencies: [
        // Swift Testing is included in Swift 5.10+, no external dependency needed
    ],
    targets: [
        // Domain Layer (95-100% test coverage target)
        .target(
            name: "MagSafeGuardDomain",
            dependencies: [],
            path: "MagSafeGuard",
            sources: [
                "Domain/Protocols/PowerMonitorProtocols.swift",
                "Domain/Protocols/SecurityActionProtocols.swift", 
                "Domain/Protocols/AuthenticationProtocols.swift",
                "Domain/Protocols/AutoArmProtocols.swift",
                "Domain/UseCases/SecurityActionUseCaseImpl.swift",
                "Domain/UseCases/PowerMonitorUseCaseImpl.swift",
                "Domain/UseCases/AuthenticationUseCaseImpl.swift",
                "Domain/UseCases/AutoArmUseCaseImpl.swift"
            ],
            swiftSettings: [
                .define("CI_BUILD", .when(platforms: [.macOS], configuration: .debug))
            ]
        ),
        
        // Data & Models Layer (100% test coverage target for data models)
        .target(
            name: "MagSafeGuardCore",
            dependencies: ["MagSafeGuardDomain"],
            path: "MagSafeGuard",
            sources: [
                "Models/SettingsModel.swift",
                "Utilities/FeatureFlags.swift",
                "Utilities/Logger.swift",
                // Data repositories are excluded from SPM testing per TEST_REFACTORING_PLAN_V2.md
                // as they are system integration layer
            ],
            swiftSettings: [
                .define("CI_BUILD", .when(platforms: [.macOS], configuration: .debug))
            ]
        ),
        
        // Domain Layer Tests (Swift Testing) - protocol and domain model tests
        .testTarget(
            name: "MagSafeGuardDomainTests",
            dependencies: ["MagSafeGuardDomain", "MagSafeGuardCore"],
            path: "MagSafeGuardTests",
            sources: [
                "SimpleTest.swift",
                "Domain/DomainProtocolTests.swift",
                "Domain/UseCases/SecurityActionUseCaseImplTests.swift",
                "Domain/UseCases/PowerMonitorUseCaseImplTests.swift",
                "Domain/UseCases/AuthenticationUseCaseImplTests.swift",
                "Domain/UseCases/AutoArmUseCaseImplTests.swift"
            ]
        ),
        
        // Core/Models Tests  
        .testTarget(
            name: "MagSafeGuardCoreTests",
            dependencies: ["MagSafeGuardCore", "MagSafeGuardDomain"],
            path: "MagSafeGuardTests",
            sources: [
                "Models/SettingsModelTests.swift",
                "Utilities/FeatureFlagsTests.swift",
                "Utilities/LoggerTests.swift"
            ]
        ),
        
        // Legacy Tests (XCTest) - temporarily disabled due to refactoring
        // .testTarget(
        //     name: "MagSafeGuardLegacyTests",
        //     dependencies: ["MagSafeGuardCore"],
        //     path: "MagSafeGuardTests",
        //     sources: [
        //         "Controllers/AppControllerTests.swift",
        //         "Mocks/"
        //     ],
        //     resources: []
        // ),
    ]
)