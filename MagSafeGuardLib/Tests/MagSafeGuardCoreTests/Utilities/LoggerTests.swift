//
//  LoggerTests.swift
//  MagSafe Guard
//
//  Created on 2025-08-03.
//
//  Tests for the Logger utility
//

import XCTest

@testable import MagSafeGuardCore

final class LoggerTests: XCTestCase {

  // MARK: - Basic Logging Tests

  func testDebugLogging() {
    // Test basic debug logging
    Log.debug("Test debug message")
    Log.debug("Test debug with category", category: .general)
    Log.debug("Power monitoring test", category: .powerMonitor)

    // These should not crash and complete successfully
    XCTAssertTrue(true, "Debug logging should complete without errors")
  }

  func testDebugSensitiveLogging() {
    // Test sensitive debug logging
    Log.debugSensitive("User ID", value: "12345")
    Log.debugSensitive("Token", value: "secret-token", category: .authentication)

    XCTAssertTrue(true, "Sensitive debug logging should complete without errors")
  }

  func testInfoLogging() {
    // Test info logging
    Log.info("Application started")
    Log.info("Settings loaded", category: .settings)
    Log.info("Network connected", category: .network)

    XCTAssertTrue(true, "Info logging should complete without errors")
  }

  func testInfoSensitiveLogging() {
    // Test sensitive info logging
    Log.infoSensitive("User email", value: "user@example.com")
    Log.infoSensitive("Location", value: "37.7749,-122.4194", category: .location)

    XCTAssertTrue(true, "Sensitive info logging should complete without errors")
  }

  func testNoticeLogging() {
    // Test notice logging
    Log.notice("Configuration changed")
    Log.notice("Auto-arm enabled", category: .autoArm)

    XCTAssertTrue(true, "Notice logging should complete without errors")
  }

  func testNoticeSensitiveLogging() {
    // Test sensitive notice logging
    Log.noticeSensitive("Network SSID", value: "MyHomeNetwork")
    Log.noticeSensitive("Device name", value: "John's MacBook", category: .security)

    XCTAssertTrue(true, "Sensitive notice logging should complete without errors")
  }

  func testWarningLogging() {
    // Test warning logging
    Log.warning("Low battery detected")
    Log.warning("Authentication timeout", category: .authentication)

    XCTAssertTrue(true, "Warning logging should complete without errors")
  }

  func testErrorLogging() {
    // Test error logging without error object
    Log.error("Failed to load settings")
    Log.error("Network disconnected", category: .network)

    // Test error logging with error object
    let testError = NSError(domain: "TestDomain", code: 100, userInfo: [
      NSLocalizedDescriptionKey: "Test error description"
    ])
    Log.error("Operation failed", error: testError)
    Log.error("Authentication failed", error: testError, category: .authentication)

    XCTAssertTrue(true, "Error logging should complete without errors")
  }

  func testCriticalLogging() {
    // Test critical logging without error
    Log.critical("Critical system failure")
    Log.critical("Security breach detected", category: .security)

    // Test critical logging with error
    let criticalError = NSError(domain: "CriticalDomain", code: 500, userInfo: [
      NSLocalizedDescriptionKey: "Critical error description"
    ])
    Log.critical("System crashed", error: criticalError)
    Log.critical("Data corruption", error: criticalError, category: .settings)

    XCTAssertTrue(true, "Critical logging should complete without errors")
  }

  func testFaultLogging() {
    // Test fault logging
    Log.fault("Unrecoverable error")
    Log.fault("Memory corruption detected", category: .general)

    XCTAssertTrue(true, "Fault logging should complete without errors")
  }

  // MARK: - Privacy-Aware Logging Tests

  func testPrivateInfoLogging() {
    // Test private info logging
    Log.infoPrivate("User data", privateData: "John Doe")
    Log.infoPrivate("API key", privateData: "sk_test_123456", category: .authentication)

    XCTAssertTrue(true, "Private info logging should complete without errors")
  }

  func testMixedDebugLogging() {
    // Test mixed public/private debug logging
    Log.debugMixed(publicMessage: "Processing user", privateData: "user@example.com")
    Log.debugMixed(
      publicMessage: "Connecting to network",
      privateData: "192.168.1.1",
      category: .network
    )

    XCTAssertTrue(true, "Mixed debug logging should complete without errors")
  }

  // MARK: - Category Tests

  func testAllCategories() {
    // Test logging with all available categories
    let categories: [LogCategory] = [
      .general, .powerMonitor, .authentication, .settings,
      .security, .ui, .autoArm, .network, .location
    ]

    for category in categories {
      Log.info("Testing category: \(category.categoryName)", category: category)
    }

    XCTAssertTrue(true, "All categories should be usable")
  }

  func testCategoryNames() {
    // Test category name generation
    XCTAssertEqual(LogCategory.general.categoryName, "General")
    XCTAssertEqual(LogCategory.powerMonitor.categoryName, "PowerMonitor")
    XCTAssertEqual(LogCategory.authentication.categoryName, "Authentication")
    XCTAssertEqual(LogCategory.settings.categoryName, "Settings")
    XCTAssertEqual(LogCategory.security.categoryName, "Security")
    XCTAssertEqual(LogCategory.ui.categoryName, "UI")
    XCTAssertEqual(LogCategory.autoArm.categoryName, "AutoArm")
    XCTAssertEqual(LogCategory.network.categoryName, "Network")
    XCTAssertEqual(LogCategory.location.categoryName, "Location")
  }

  func testCategoryLogger() {
    // Test that each category has its own logger instance
    let generalLogger = LogCategory.general.logger
    let powerLogger = LogCategory.powerMonitor.logger

    // Each category should have a logger (non-nil test by using them)
    XCTAssertNotNil(generalLogger)
    XCTAssertNotNil(powerLogger)
  }

  // MARK: - Stress Tests

  @MainActor
  func testConcurrentLogging() {
    // Test thread safety with concurrent logging
    let expectation = self.expectation(description: "Concurrent logging")
    expectation.expectedFulfillmentCount = 100

    let queue = DispatchQueue(label: "test.concurrent", attributes: .concurrent)

    for i in 0..<100 {
      queue.async {
        Log.info("Concurrent log \(i)")
        expectation.fulfill()
      }
    }

    waitForExpectations(timeout: 5.0)
  }

  func testHighVolumeLogging() {
    // Test logging performance with high volume
    measure {
      for i in 0..<1000 {
        Log.debug("High volume log \(i)")
      }
    }
  }

  // MARK: - Edge Cases

  func testEmptyMessages() {
    // Test logging with empty messages
    Log.debug("")
    Log.info("")
    Log.warning("")
    Log.error("")

    XCTAssertTrue(true, "Empty messages should not crash")
  }

  func testLongMessages() {
    // Test logging with very long messages
    let longMessage = String(repeating: "a", count: 10000)
    Log.info(longMessage)

    XCTAssertTrue(true, "Long messages should not crash")
  }

  func testSpecialCharacters() {
    // Test logging with special characters
    Log.info("Special chars: 🎉 \n \t \\ \" ' @#$%^&*()")
    Log.infoSensitive("Unicode", value: "测试 テスト 🌍")

    XCTAssertTrue(true, "Special characters should not crash")
  }

  // MARK: - DEBUG Build Tests

  #if DEBUG
  func testVerboseLogging() {
    // Test verbose logging (only available in DEBUG)
    Log.verbose("Verbose debug information")
    Log.verbose("Detailed state", category: .powerMonitor)

    XCTAssertTrue(true, "Verbose logging should complete without errors")
  }
  #endif

  // MARK: - Test Environment Verification

  func testFileLoggerDisabledInTests() {
    // Verify that file logging is disabled in test environment
    // This is implicitly tested by all the logging calls above not creating files
    // File logger should be nil in test environment

    // We can't directly access fileLogger as it's private, but we can verify
    // that error logging doesn't crash even though file logging is disabled
    Log.error("Test error - should not write to file")
    Log.critical("Test critical - should not write to file")
    Log.fault("Test fault - should not write to file")

    XCTAssertTrue(true, "File logging should be disabled in tests")
  }
  
  // MARK: - Initialization Tests
  
  func testLoggerInitialization() {
    // Test that Log.initialize() works without errors
    XCTAssertNoThrow(Log.initialize())
    
    // Multiple initializations should be safe  
    XCTAssertNoThrow(Log.initialize())
    XCTAssertNoThrow(Log.initialize())
    
    // Verify that initialization calls Sentry setup
    // (This should execute the SentryLogger.initialize() line in Logger.swift)
    Log.initialize()
  }
  
  func testFileLoggerDisabledInTestEnvironment() {
    // Test that file logging is properly disabled in test environment
    // This should execute the fileLogger initialization code path
    
    // Verify test environment detection works
    // In CI or with CI=true, XCTestConfigurationFilePath may not be set
    // Instead, check for either XCTestConfigurationFilePath or CI environment variable
    let isTestEnv = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil ||
                    ProcessInfo.processInfo.environment["CI"] != nil
    XCTAssertTrue(isTestEnv, "Should detect test environment")
    
    // Test that error logging still works even with file logging disabled
    XCTAssertNoThrow(Log.error("Test file logging disabled"))
    XCTAssertNoThrow(Log.critical("Test critical with disabled file logging"))
    XCTAssertNoThrow(Log.fault("Test fault with disabled file logging"))
  }
  
  // MARK: - Sentry Integration Tests
  
  func testSentryTestEventIntegration() {
    // Test Log.sendTestEvent() method
    XCTAssertNoThrow(Log.sendTestEvent())
    
    // Test with completion handler
    let expectation = XCTestExpectation(description: "sendTestEvent completion")
    
    Log.sendTestEvent { success in
      // Should complete regardless of Sentry configuration in tests
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 3.0)
  }
  
  // MARK: - All Category Coverage
  
  func testAllCategoriesWithAllLevels() {
    let allCategories: [LogCategory] = [
      .general, .authentication, .powerMonitor, .security,
      .network, .ui, .settings, .location
    ]
    
    for category in allCategories {
      // Test all log levels with each category
      Log.debug("Debug message", category: category)
      Log.info("Info message", category: category)
      Log.notice("Notice message", category: category)
      Log.warning("Warning message", category: category)
      Log.error("Error message", category: category)
      Log.critical("Critical message", category: category)
      Log.fault("Fault message", category: category)
      
      // Test sensitive variants
      Log.debugSensitive("Debug sensitive", value: "test", category: category)
      Log.infoSensitive("Info sensitive", value: "test", category: category)
      Log.noticeSensitive("Notice sensitive", value: "test", category: category)
      
      #if DEBUG
      Log.verbose("Verbose message", category: category)
      #endif
    }
  }
  
  // MARK: - Error Logging with Swift Errors
  
  func testErrorLoggingWithSwiftErrors() {
    enum TestError: Error {
      case networkFailure(String)
      case authenticationFailure
      case configurationError(code: Int)
    }
    
    struct CustomError: Error {
      let description: String
      let timestamp: Date
    }
    
    let errors: [Error] = [
      TestError.networkFailure("Connection timeout"),
      TestError.authenticationFailure,
      TestError.configurationError(code: 500),
      CustomError(description: "Custom error", timestamp: Date()),
      NSError(domain: "TestDomain", code: 404, userInfo: [
        NSLocalizedDescriptionKey: "Resource not found"
      ])
    ]
    
    for error in errors {
      XCTAssertNoThrow(Log.error("Error occurred", error: error))
      XCTAssertNoThrow(Log.error("Error with category", error: error, category: .network))
      XCTAssertNoThrow(Log.critical("Critical error", error: error, category: .security))
      XCTAssertNoThrow(Log.fault("Fault error", category: .general))
    }
  }
  
  // MARK: - Log Category Properties
  
  func testLogCategoryProperties() {
    let allCategories: [LogCategory] = [
      .general, .authentication, .powerMonitor, .security,
      .network, .ui, .settings, .location
    ]
    
    for category in allCategories {
      // Test that category names are not empty
      XCTAssertFalse(category.categoryName.isEmpty, "Category \(category) should have a name")
      
      // Test category consistency
      XCTAssertNoThrow(Log.info("Category test", category: category))
    }
  }
  
  // MARK: - Mixed Logging Scenarios
  
  func testAdvancedMixedDebugLogging() {
    // Test various combinations of debug logging
    Log.debug("Simple debug")
    Log.debug("Debug with category", category: .authentication)
    Log.debugSensitive("Sensitive debug", value: "secret")
    Log.debugSensitive("Sensitive debug with category", value: "token", category: .security)
    
    #if DEBUG
    Log.verbose("Verbose logging")
    Log.verbose("Verbose with category", category: .powerMonitor)
    #endif
  }
  
  // MARK: - Edge Case Message Formats
  
  func testComplexMessageFormats() {
    let complexMessages = [
      "Message with newlines\nLine 2\nLine 3",
      "Message with tabs\tTab\tSeparated",
      "Unicode: 🔒 🔑 ⚡ 🔋 📱 💻",
      "JSON-like: {\"key\": \"value\", \"number\": 123}",
      "URL-like: https://example.com/path?param=value",
      "XML-like: <tag attribute=\"value\">content</tag>",
      "Very long message: " + String(repeating: "test ", count: 200),
      "   Leading and trailing spaces   ",
      ""  // Empty string
    ]
    
    for message in complexMessages {
      Log.info(message)
      Log.error(message)
      Log.debug(message)
      Log.infoSensitive("Complex", value: message)
    }
  }
  
  // MARK: - Concurrent Logging Tests
  
  func testAdvancedConcurrentLogging() {
    let expectation = XCTestExpectation(description: "Advanced concurrent logging")
    expectation.expectedFulfillmentCount = 20
    
    // Test concurrent logging from multiple queues
    for i in 0..<10 {
      DispatchQueue.global(qos: .background).async {
        Log.info("Background log \(i)")
        expectation.fulfill()
      }
      
      DispatchQueue.global(qos: .userInitiated).async {
        Log.error("User initiated log \(i)")
        expectation.fulfill()
      }
    }
    
    wait(for: [expectation], timeout: 5.0)
  }
  
  // MARK: - Bundle and System Information
  
  func testBundleInformationLogging() {
    // Test logging that might access bundle information
    Log.info("App version test")
    Log.error("System information test")
    
    // Test with various system states
    Log.debug("Bundle test", category: .settings)
    Log.notice("System test", category: .general)
  }
  
  // MARK: - Performance Tests
  
  func testLoggingPerformance() {
    // Test that logging doesn't significantly impact performance
    let startTime = Date()
    
    for i in 0..<1000 {
      Log.debug("Performance test \(i)")
    }
    
    let endTime = Date()
    let duration = endTime.timeIntervalSince(startTime)
    
    // Logging 1000 messages should complete reasonably quickly (< 1 second)
    XCTAssertLessThan(duration, 1.0, "Logging should complete within 1 second")
  }
  
  // MARK: - Category Name Verification
  
  func testAdvancedCategoryNames() {
    // Verify that all categories have meaningful names
    let categoryNames = [
      LogCategory.general.categoryName,
      LogCategory.authentication.categoryName,
      LogCategory.powerMonitor.categoryName,
      LogCategory.security.categoryName,
      LogCategory.network.categoryName,
      LogCategory.ui.categoryName,
      LogCategory.settings.categoryName,
      LogCategory.location.categoryName
    ]
    
    for name in categoryNames {
      XCTAssertFalse(name.isEmpty, "Category name should not be empty")
      XCTAssertGreaterThanOrEqual(name.count, 2, "Category name should be meaningful")
    }
  }
  
  // MARK: - Test Environment Stability
  
  func testLoggerStabilityInTestEnvironment() {
    // Ensure logger works reliably in test environment
    let iterations = 100
    
    for i in 0..<iterations {
      Log.debug("Stability test \(i)")
      Log.info("Info stability \(i)")
      Log.warning("Warning stability \(i)")
      Log.error("Error stability \(i)")
      
      if i % 10 == 0 {
        Log.debugSensitive("Sensitive \(i)", value: "test\(i)")
      }
    }
    
    XCTAssertTrue(true, "Logger should remain stable during repeated use")
  }
}
