// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MagSafeGuard",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .executable(
            name: "MagSafeGuard",
            targets: ["MagSafeGuard"]
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // Currently no external dependencies
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "MagSafeGuard",
            dependencies: [],
            path: "Sources/MagSafeGuard",
            resources: [
                .copy("../../Resources/Assets.xcassets"),
                .copy("../../Resources/Info.plist")
            ],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug))
            ],
            linkerSettings: [
                .linkedFramework("IOKit"),
                .linkedFramework("ServiceManagement"),
                .linkedFramework("LocalAuthentication"),
                .linkedFramework("CloudKit"),
                .linkedFramework("CoreLocation")
            ]
        ),
        .testTarget(
            name: "MagSafeGuardTests",
            dependencies: ["MagSafeGuard"],
            path: "Tests/MagSafeGuardTests"
        ),
    ]
)