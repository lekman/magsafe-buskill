//
//  TestConfiguration.swift
//  MagSafe Guard
//
//  Created on 2025-08-03.
//

import Foundation
import Testing

/// Configuration for test environment detection and CI/CD setup
public struct TestConfiguration {
    
    // MARK: - Environment Detection
    
    /// Whether tests are running in CI environment
    public static var isCI: Bool {
        ProcessInfo.processInfo.environment["CI"] != nil ||
        ProcessInfo.processInfo.environment["GITHUB_ACTIONS"] != nil ||
        ProcessInfo.processInfo.environment["JENKINS_HOME"] != nil ||
        ProcessInfo.processInfo.environment["TEAMCITY_VERSION"] != nil ||
        ProcessInfo.processInfo.environment["BITRISE_IO"] != nil
    }
    
    /// Whether tests are running on GitHub Actions
    public static var isGitHubActions: Bool {
        ProcessInfo.processInfo.environment["GITHUB_ACTIONS"] != nil
    }
    
    /// Whether tests are running in Xcode
    public static var isXcode: Bool {
        ProcessInfo.processInfo.environment["__XCODE_BUILT_PRODUCTS_DIR_PATHS"] != nil
    }
    
    /// Whether UI tests should be skipped
    public static var skipUITests: Bool {
        ProcessInfo.processInfo.environment["SKIP_UI_TESTS"] != nil
    }
    
    /// Whether integration tests should be skipped
    public static var skipIntegrationTests: Bool {
        ProcessInfo.processInfo.environment["SKIP_INTEGRATION_TESTS"] != nil
    }
    
    /// Whether performance tests should be skipped
    public static var skipPerformanceTests: Bool {
        ProcessInfo.processInfo.environment["SKIP_PERFORMANCE_TESTS"] != nil
    }
    
    // MARK: - Test Timeouts
    
    /// Default timeout for async operations
    public static var defaultTimeout: Duration {
        isCI ? .seconds(10) : .seconds(5)
    }
    
    /// Timeout for network operations
    public static var networkTimeout: Duration {
        isCI ? .seconds(30) : .seconds(15)
    }
    
    /// Timeout for authentication operations
    public static var authenticationTimeout: Duration {
        isCI ? .seconds(5) : .seconds(2)
    }
    
    /// Timeout for file operations
    public static var fileOperationTimeout: Duration {
        isCI ? .seconds(10) : .seconds(5)
    }
    
    // MARK: - Coverage Configuration
    
    /// Minimum coverage threshold percentage
    public static var coverageThreshold: Int {
        if let threshold = ProcessInfo.processInfo.environment["COVERAGE_THRESHOLD"],
           let value = Int(threshold) {
            return value
        }
        return 80 // Default 80% coverage
    }
    
    /// Whether to fail tests if coverage is below threshold
    public static var enforceCodeCoverage: Bool {
        ProcessInfo.processInfo.environment["ENFORCE_COVERAGE"] != nil
    }
    
    // MARK: - Logging Configuration
    
    /// Whether to enable verbose logging
    public static var verboseLogging: Bool {
        ProcessInfo.processInfo.environment["VERBOSE_TESTS"] != nil ||
        ProcessInfo.processInfo.environment["DEBUG"] != nil
    }
    
    /// Whether to save test artifacts
    public static var saveArtifacts: Bool {
        isCI || ProcessInfo.processInfo.environment["SAVE_TEST_ARTIFACTS"] != nil
    }
    
    /// Directory for test artifacts
    public static var artifactsDirectory: URL {
        if let path = ProcessInfo.processInfo.environment["TEST_ARTIFACTS_DIR"] {
            return URL(fileURLWithPath: path)
        }
        return FileManager.default.temporaryDirectory
            .appendingPathComponent("MagSafeGuard-TestArtifacts")
    }
    
    // MARK: - Platform Configuration
    
    /// Whether running on physical device
    public static var isPhysicalDevice: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return true
        #endif
    }
    
    /// Whether biometric authentication is available
    public static var isBiometricAvailable: Bool {
        // In CI, biometric is never available
        if isCI { return false }
        
        // Check if we're in simulator/physical device
        #if targetEnvironment(simulator)
        // Simulator may have Face ID/Touch ID enabled
        return ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] != nil
        #else
        return true
        #endif
    }
    
    // MARK: - Test Data Configuration
    
    /// Whether to use mock data
    public static var useMockData: Bool {
        isCI || ProcessInfo.processInfo.environment["USE_MOCK_DATA"] != nil
    }
    
    /// Whether to reset state between tests
    public static var resetStateBetweenTests: Bool {
        ProcessInfo.processInfo.environment["NO_RESET"] == nil
    }
    
    // MARK: - Parallel Testing
    
    /// Maximum parallel test execution
    public static var maxParallelTests: Int {
        if let value = ProcessInfo.processInfo.environment["MAX_PARALLEL_TESTS"],
           let count = Int(value) {
            return count
        }
        return isCI ? 2 : 4
    }
    
    // MARK: - Helpers
    
    /// Prints current test configuration (for debugging)
    public static func printConfiguration() {
        print("""
        Test Configuration:
        - Environment: \(isCI ? "CI" : "Local")
        - Platform: \(isGitHubActions ? "GitHub Actions" : (isXcode ? "Xcode" : "Other"))
        - Skip UI Tests: \(skipUITests)
        - Skip Integration Tests: \(skipIntegrationTests)
        - Skip Performance Tests: \(skipPerformanceTests)
        - Default Timeout: \(defaultTimeout)
        - Coverage Threshold: \(coverageThreshold)%
        - Enforce Coverage: \(enforceCodeCoverage)
        - Verbose Logging: \(verboseLogging)
        - Save Artifacts: \(saveArtifacts)
        - Biometric Available: \(isBiometricAvailable)
        - Use Mock Data: \(useMockData)
        - Max Parallel Tests: \(maxParallelTests)
        """)
    }
}

// MARK: - Test Traits

/// Trait for CI-specific test configuration
public struct CITestTrait: TestTrait {
    public init() {}
}

/// Trait for integration tests
public struct IntegrationTestTrait: TestTrait {
    public init() {}
}

/// Trait for performance tests
public struct PerformanceTestTrait: TestTrait {
    public init() {}
}

/// Trait for UI tests
public struct UITestTrait: TestTrait {
    public init() {}
}

/// Trait for tests requiring biometric authentication
public struct BiometricTestTrait: TestTrait {
    public init() {}
}

/// Trait for tests requiring network access
public struct NetworkTestTrait: TestTrait {
    public init() {}
}

// MARK: - Conditional Test Execution

/// Skip test if running in CI
@available(macOS 13.0, iOS 16.0, *)
public func skipIfCI() -> ((TestFunction) -> TestFunction) {
    return { test in
        if TestConfiguration.isCI {
            return TestFunction.disabled("Skipped in CI environment")
        }
        return test
    }
}

/// Skip test if UI tests are disabled
@available(macOS 13.0, iOS 16.0, *)
public func skipIfUITestsDisabled() -> ((TestFunction) -> TestFunction) {
    return { test in
        if TestConfiguration.skipUITests {
            return TestFunction.disabled("UI tests are disabled")
        }
        return test
    }
}

/// Skip test if integration tests are disabled
@available(macOS 13.0, iOS 16.0, *)
public func skipIfIntegrationTestsDisabled() -> ((TestFunction) -> TestFunction) {
    return { test in
        if TestConfiguration.skipIntegrationTests {
            return TestFunction.disabled("Integration tests are disabled")
        }
        return test
    }
}

/// Skip test if performance tests are disabled
@available(macOS 13.0, iOS 16.0, *)
public func skipIfPerformanceTestsDisabled() -> ((TestFunction) -> TestFunction) {
    return { test in
        if TestConfiguration.skipPerformanceTests {
            return TestFunction.disabled("Performance tests are disabled")
        }
        return test
    }
}

/// Skip test if biometric is not available
@available(macOS 13.0, iOS 16.0, *)
public func requiresBiometric() -> ((TestFunction) -> TestFunction) {
    return { test in
        if !TestConfiguration.isBiometricAvailable {
            return TestFunction.disabled("Biometric authentication not available")
        }
        return test
    }
}

// MARK: - Test Helpers

/// Executes a test with timeout appropriate for environment
public func withTimeout<T>(
    _ timeout: Duration? = nil,
    operation: () async throws -> T
) async throws -> T {
    let effectiveTimeout = timeout ?? TestConfiguration.defaultTimeout
    
    return try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }
        
        group.addTask {
            try await Task.sleep(for: effectiveTimeout)
            throw TestTimeoutError()
        }
        
        guard let result = try await group.next() else {
            throw TestTimeoutError()
        }
        
        group.cancelAll()
        return result
    }
}

/// Error thrown when test times out
struct TestTimeoutError: Error, CustomStringConvertible {
    var description: String {
        "Test operation timed out"
    }
}

// MARK: - Environment Setup

/// Sets up test environment based on configuration
public func setupTestEnvironment() async throws {
    // Create artifacts directory if needed
    if TestConfiguration.saveArtifacts {
        try FileManager.default.createDirectory(
            at: TestConfiguration.artifactsDirectory,
            withIntermediateDirectories: true
        )
    }
    
    // Print configuration in verbose mode
    if TestConfiguration.verboseLogging {
        TestConfiguration.printConfiguration()
    }
}

/// Cleans up test environment
public func tearDownTestEnvironment() async throws {
    // Clean up artifacts if not saving
    if !TestConfiguration.saveArtifacts && 
       FileManager.default.fileExists(atPath: TestConfiguration.artifactsDirectory.path) {
        try FileManager.default.removeItem(at: TestConfiguration.artifactsDirectory)
    }
}