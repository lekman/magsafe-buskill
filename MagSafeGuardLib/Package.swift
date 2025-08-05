// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MagSafeGuardLib",
    platforms: [
        .macOS(.v13)
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
        // Add any external dependencies here
    ],
    targets: [
        // Domain Layer
        .target(
            name: "MagSafeGuardDomain",
            dependencies: [],
            path: "Sources/MagSafeGuardDomain"
        ),
        
        // Core Layer
        .target(
            name: "MagSafeGuardCore",
            dependencies: ["MagSafeGuardDomain"],
            path: "Sources/MagSafeGuardCore"
        ),
        
        // Test Infrastructure Target
        .target(
            name: "TestInfrastructure",
            dependencies: ["MagSafeGuardDomain", "MagSafeGuardCore"],
            path: "Tests/TestInfrastructure"
        ),
        
        // Test Targets
        .testTarget(
            name: "MagSafeGuardDomainTests",
            dependencies: ["MagSafeGuardDomain", "MagSafeGuardCore", "TestInfrastructure"],
            path: "Tests/MagSafeGuardDomainTests"
        ),
        .testTarget(
            name: "MagSafeGuardCoreTests",
            dependencies: ["MagSafeGuardCore", "MagSafeGuardDomain", "TestInfrastructure"],
            path: "Tests/MagSafeGuardCoreTests"
        ),
    ]
)