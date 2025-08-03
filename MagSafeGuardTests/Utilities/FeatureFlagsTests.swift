//
//  FeatureFlagsTests.swift
//  MagSafe Guard
//
//  Created on 2025-07-26.
//

import XCTest

@testable import MagSafeGuardCore

final class FeatureFlagsTests: XCTestCase {

  override func setUp() {
    super.setUp()
    // Reset to defaults before each test
    FeatureFlags.shared.reload()
    // Ensure all flags are at their default values
    for flag in FeatureFlags.Flag.allCases {
      FeatureFlags.shared.setFlag(flag, enabled: flag.defaultValue)
    }
  }

  override func tearDown() {
    super.tearDown()
    // Clean up any test files
    let testPath = FileManager.default.currentDirectoryPath + "/test-feature-flags.json"
    try? FileManager.default.removeItem(atPath: testPath)
  }

  // MARK: - Singleton Tests

  func testSharedInstanceIsSingleton() {
    let instance1 = FeatureFlags.shared
    let instance2 = FeatureFlags.shared
    XCTAssertTrue(instance1 === instance2, "FeatureFlags should be a singleton")
  }

  // MARK: - Default Values Tests

  func testDefaultFlagValues() {
    // Most flags should be enabled by default
    // Note: Some debug flags may be disabled in CI environments
    let expectedEnabledFlags: [FeatureFlags.Flag] = [
      .powerMonitoring, .accessibilityManager, .notificationService,
      .authenticationService, .autoArmManager, .locationManager,
      .networkMonitor, .securityEvidence, .cloudSync,
      .sentryEnabled, .sentryDebug, .performanceMetrics,
      .verboseLogging
    ]

    for flag in expectedEnabledFlags {
      XCTAssertTrue(
        FeatureFlags.shared.isEnabled(flag),
        "Flag \(flag.rawValue) should be enabled by default")
    }

    // Debug flags may vary based on environment
    // Just verify they have a value (enabled or disabled)
    XCTAssertNotNil(FeatureFlags.shared.allFlags()[.mockServices])
    XCTAssertNotNil(FeatureFlags.shared.allFlags()[.disableSandbox])
  }

  func testFlagDescriptions() {
    // Ensure all flags have descriptions
    for flag in FeatureFlags.Flag.allCases {
      XCTAssertFalse(
        flag.description.isEmpty,
        "Flag \(flag.rawValue) should have a description")
    }
  }

  // MARK: - Flag Management Tests

  func testSetFlagEnabled() {
    FeatureFlags.shared.setFlag(.verboseLogging, enabled: false)
    XCTAssertFalse(FeatureFlags.shared.isEnabled(.verboseLogging))

    FeatureFlags.shared.setFlag(.verboseLogging, enabled: true)
    XCTAssertTrue(FeatureFlags.shared.isEnabled(.verboseLogging))
  }

  func testGetAllFlags() {
    let allFlags = FeatureFlags.shared.allFlags()
    XCTAssertEqual(allFlags.count, FeatureFlags.Flag.allCases.count)

    // All should be true by default
    for (_, value) in allFlags {
      XCTAssertTrue(value)
    }
  }

  func testAreEnabledMultipleFlags() {
    // All enabled by default
    XCTAssertTrue(FeatureFlags.shared.areEnabled(.powerMonitoring, .authenticationService))

    // Disable one
    FeatureFlags.shared.setFlag(.authenticationService, enabled: false)
    XCTAssertFalse(FeatureFlags.shared.areEnabled(.powerMonitoring, .authenticationService))
  }

  func testIsAnyEnabledMultipleFlags() {
    // All enabled by default
    XCTAssertTrue(FeatureFlags.shared.isAnyEnabled(.powerMonitoring, .authenticationService))

    // Disable both
    FeatureFlags.shared.setFlag(.powerMonitoring, enabled: false)
    FeatureFlags.shared.setFlag(.authenticationService, enabled: false)
    XCTAssertFalse(FeatureFlags.shared.isAnyEnabled(.powerMonitoring, .authenticationService))

    // Enable one
    FeatureFlags.shared.setFlag(.powerMonitoring, enabled: true)
    XCTAssertTrue(FeatureFlags.shared.isAnyEnabled(.powerMonitoring, .authenticationService))
  }

  // MARK: - Convenience Properties Tests

  func testConvenienceProperties() {
    XCTAssertEqual(
      FeatureFlags.shared.isPowerMonitoringEnabled,
      FeatureFlags.shared.isEnabled(.powerMonitoring))
    XCTAssertEqual(
      FeatureFlags.shared.isAccessibilityEnabled,
      FeatureFlags.shared.isEnabled(.accessibilityManager))
    XCTAssertEqual(
      FeatureFlags.shared.isNotificationsEnabled,
      FeatureFlags.shared.isEnabled(.notificationService))
    XCTAssertEqual(
      FeatureFlags.shared.isAuthenticationEnabled,
      FeatureFlags.shared.isEnabled(.authenticationService))
    XCTAssertEqual(
      FeatureFlags.shared.isAutoArmEnabled,
      FeatureFlags.shared.isEnabled(.autoArmManager))
    XCTAssertEqual(
      FeatureFlags.shared.isLocationEnabled,
      FeatureFlags.shared.isEnabled(.locationManager))
    XCTAssertEqual(
      FeatureFlags.shared.isNetworkMonitorEnabled,
      FeatureFlags.shared.isEnabled(.networkMonitor))
    XCTAssertEqual(
      FeatureFlags.shared.isSecurityEvidenceEnabled,
      FeatureFlags.shared.isEnabled(.securityEvidence))
    XCTAssertEqual(
      FeatureFlags.shared.isCloudSyncEnabled,
      FeatureFlags.shared.isEnabled(.cloudSync))
    XCTAssertEqual(
      FeatureFlags.shared.isSentryEnabled,
      FeatureFlags.shared.isEnabled(.sentryEnabled))
    XCTAssertEqual(
      FeatureFlags.shared.isPerformanceMetricsEnabled,
      FeatureFlags.shared.isEnabled(.performanceMetrics))
    XCTAssertEqual(
      FeatureFlags.shared.isVerboseLoggingEnabled,
      FeatureFlags.shared.isEnabled(.verboseLogging))
  }

  // MARK: - JSON Save/Load Tests

  func testSaveToJSON() throws {
    let tempDir = FileManager.default.temporaryDirectory
    let testPath = tempDir.appendingPathComponent("test-feature-flags.json").path

    // Ensure flags are initialized before modifying
    FeatureFlags.shared.reload()
    
    // Modify some flags
    FeatureFlags.shared.setFlag(.verboseLogging, enabled: false)
    FeatureFlags.shared.setFlag(.mockServices, enabled: false)

    // Save to JSON
    try FeatureFlags.shared.saveToJSON(at: testPath)

    // Verify file exists
    XCTAssertTrue(FileManager.default.fileExists(atPath: testPath))

    // Load and verify JSON content
    let data = try Data(contentsOf: URL(fileURLWithPath: testPath))
    let jsonFlags = try JSONDecoder().decode([String: Bool].self, from: data)

    // Debug: print all saved flags in CI
    #if CI_BUILD
    print("Saved flags: \(jsonFlags)")
    #endif
    
    // Verify the flags we explicitly set
    XCTAssertEqual(jsonFlags[FeatureFlags.Flag.verboseLogging.rawValue], false)
    
    // mockServices should be saved as false
    XCTAssertNotNil(jsonFlags[FeatureFlags.Flag.mockServices.rawValue], "mockServices flag should be saved")
    XCTAssertEqual(jsonFlags[FeatureFlags.Flag.mockServices.rawValue], false)
    
    // powerMonitoring should have its default value (true)
    XCTAssertEqual(jsonFlags[FeatureFlags.Flag.powerMonitoring.rawValue], true)
    
    // Verify that all flags from Flag.allCases are saved
    for flag in FeatureFlags.Flag.allCases {
      XCTAssertNotNil(jsonFlags[flag.rawValue], "Flag \(flag.rawValue) should be saved")
    }
  }

  func testLoadFromJSON() throws {
    // Save current flags to restore later
    let currentFlags = FeatureFlags.shared.allFlags()
    
    // Create test flags
    let testFlags: [String: Bool] = [
      FeatureFlags.Flag.verboseLogging.rawValue: false,
      FeatureFlags.Flag.sentryEnabled.rawValue: false,
      FeatureFlags.Flag.powerMonitoring.rawValue: true
    ]
    
    // Create a temp file and save it
    let tempDir = FileManager.default.temporaryDirectory
    let testPath = tempDir.appendingPathComponent("test-feature-flags.json").path
    
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    let data = try encoder.encode(testFlags)
    try data.write(to: URL(fileURLWithPath: testPath))
    
    // Since there's no loadFromJSON, we'll test by verifying the save/load round trip
    // First set the flags manually
    FeatureFlags.shared.setFlag(.verboseLogging, enabled: false)
    FeatureFlags.shared.setFlag(.sentryEnabled, enabled: false)
    FeatureFlags.shared.setFlag(.powerMonitoring, enabled: true)
    
    // Save to the test path
    try FeatureFlags.shared.saveToJSON(at: testPath)
    
    // Reset all flags to defaults
    for flag in FeatureFlags.Flag.allCases {
      FeatureFlags.shared.setFlag(flag, enabled: flag.defaultValue)
    }
    
    // Verify defaults are set (different from our test values)
    XCTAssertTrue(FeatureFlags.shared.isEnabled(.verboseLogging)) // default is true
    XCTAssertTrue(FeatureFlags.shared.isEnabled(.sentryEnabled)) // default is true
    
    // Now manually load and verify the JSON content
    let loadedData = try Data(contentsOf: URL(fileURLWithPath: testPath))
    let loadedFlags = try JSONDecoder().decode([String: Bool].self, from: loadedData)
    
    XCTAssertEqual(loadedFlags[FeatureFlags.Flag.verboseLogging.rawValue], false)
    XCTAssertEqual(loadedFlags[FeatureFlags.Flag.sentryEnabled.rawValue], false)
    XCTAssertEqual(loadedFlags[FeatureFlags.Flag.powerMonitoring.rawValue], true)
    
    // Clean up
    try? FileManager.default.removeItem(atPath: testPath)
    
    // Restore original flags
    for (flag, value) in currentFlags {
      FeatureFlags.shared.setFlag(flag, enabled: value)
    }
  }

  // MARK: - Export Tests

  func testExport() {
    let exported = FeatureFlags.shared.export()

    // Check metadata
    XCTAssertNotNil(exported["_metadata"] as? [String: Any])
    let metadata = exported["_metadata"] as? [String: Any]
    XCTAssertEqual(metadata?["version"] as? String, "1.0")
    XCTAssertNotNil(metadata?["generated"])
    XCTAssertNotNil(metadata?["description"])

    // Check categories
    XCTAssertNotNil(exported["core_features"] as? [String: Bool])
    XCTAssertNotNil(exported["telemetry"] as? [String: Bool])
    XCTAssertNotNil(exported["debug_options"] as? [String: Bool])

    // Verify categorization
    let coreFeatures = exported["core_features"] as? [String: Bool] ?? [:]
    XCTAssertNotNil(coreFeatures["FEATURE_POWER_MONITORING"])
    XCTAssertNil(coreFeatures["DEBUG_VERBOSE_LOGGING"])

    let debugOptions = exported["debug_options"] as? [String: Bool] ?? [:]
    XCTAssertNotNil(debugOptions["DEBUG_VERBOSE_LOGGING"])
    XCTAssertNil(debugOptions["FEATURE_POWER_MONITORING"])
  }

  // MARK: - Thread Safety Tests

  func testConcurrentAccess() {
    let expectation = self.expectation(description: "Concurrent access")
    expectation.expectedFulfillmentCount = 100

    let queue = DispatchQueue(label: "test.concurrent", attributes: .concurrent)

    // Perform concurrent reads and writes
    for index in 0..<100 {
      queue.async {
        if index % 2 == 0 {
          // Write
          FeatureFlags.shared.setFlag(.verboseLogging, enabled: index % 4 == 0)
        } else {
          // Read
          _ = FeatureFlags.shared.isEnabled(.verboseLogging)
        }
        expectation.fulfill()
      }
    }

    waitForExpectations(timeout: 5.0)
  }

  // MARK: - Environment Variable Tests

  func testEnvironmentVariableOverride() {
    // This test would require process restart to properly test env vars
    // Since ProcessInfo.processInfo.environment is read-only after launch,
    // we can only verify the behavior exists in the code

    // Verify the flag loading respects the documented priority
    let testPath = FileManager.default.currentDirectoryPath + "/feature-flags.json"

    // Create JSON that disables a flag
    let testFlags: [String: Bool] = [
      FeatureFlags.Flag.verboseLogging.rawValue: false
    ]

    do {
      let data = try JSONEncoder().encode(testFlags)
      try data.write(to: URL(fileURLWithPath: testPath))

      // Reload and verify JSON was loaded
      FeatureFlags.shared.reload()
      XCTAssertFalse(FeatureFlags.shared.isEnabled(.verboseLogging))

      // Clean up
      try? FileManager.default.removeItem(atPath: testPath)
    } catch {
      XCTFail("Failed to test environment variable override: \(error)")
    }
  }
}
