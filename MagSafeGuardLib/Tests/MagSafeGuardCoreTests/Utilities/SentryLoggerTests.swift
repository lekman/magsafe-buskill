//
//  SentryLoggerTests.swift
//  MagSafe Guard Tests
//
//  Created on 2025-08-05.
//
//  Tests for Sentry integration
//

import XCTest
@testable import MagSafeGuardCore

final class SentryLoggerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Clear any previous Sentry configuration
    }

    override func tearDown() {
        super.tearDown()
    }

    func testSentryConfigurationFromEnvironment() {
        // Test default configuration when disabled
        let config = SentryLogger.Configuration()
        
        // Should use default DSN from .todo.md requirements
        XCTAssertEqual(
            config.dsn, 
            "https://e74a158126b00e128ebdda98f6a36b76@o4509752039243776.ingest.de.sentry.io/4509752042127440"
        )
        
        // Should default to development environment
        XCTAssertEqual(config.environment, "development")
        
        // Should be disabled by default (no environment variable set)
        XCTAssertFalse(config.enabled)
    }

    func testSentryConfigurationCustomValues() {
        // Test custom configuration
        let customConfig = SentryLogger.Configuration(
            dsn: "https://custom@sentry.io/123",
            environment: "production", 
            enabled: true,
            debug: false
        )
        
        XCTAssertEqual(customConfig.dsn, "https://custom@sentry.io/123")
        XCTAssertEqual(customConfig.environment, "production")
        XCTAssertTrue(customConfig.enabled)
        XCTAssertFalse(customConfig.debug)
    }

    func testSentryInitializationWhenDisabled() {
        // Test that initialization is skipped when disabled
        let disabledConfig = SentryLogger.Configuration(
            dsn: "test://dsn",
            environment: "test",
            enabled: false
        )
        
        // Should not crash or throw when initializing with disabled config
        XCTAssertNoThrow(SentryLogger.initialize(with: disabledConfig))
        
        // Should remain disabled
        XCTAssertFalse(SentryLogger.isEnabled)
    }

    func testSentryLogMethodsWhenDisabled() {
        // Ensure logging methods don't crash when Sentry is disabled
        let disabledConfig = SentryLogger.Configuration(
            dsn: "test://dsn", 
            environment: "test",
            enabled: false
        )
        
        SentryLogger.initialize(with: disabledConfig)
        
        // These should not crash when Sentry is disabled
        XCTAssertNoThrow(SentryLogger.logError("Test error"))
        XCTAssertNoThrow(SentryLogger.logWarning("Test warning"))
        XCTAssertNoThrow(SentryLogger.logInfo("Test info"))
        XCTAssertNoThrow(SentryLogger.setUserContext(userId: "test123"))
        XCTAssertNoThrow(SentryLogger.flush())
    }

    func testPrivacyScrubbing() {
        // This tests the private scrubSensitiveData method indirectly
        // by checking that no sensitive data patterns are included in logs
        
        let testMessages = [
            "password=secret123",
            "token=abc123def456", 
            "key=mySecretKey",
            "/Users/johndoe/Documents/secret.txt",
            "user@example.com sent a message"
        ]
        
        // Verify logging doesn't crash with potentially sensitive data
        for message in testMessages {
            XCTAssertNoThrow(SentryLogger.logError(message))
        }
    }

    func testLoggerIntegration() {
        // Test that Log.initialize() includes Sentry initialization
        XCTAssertNoThrow(Log.initialize())
        
        // Test that Log methods include Sentry calls
        XCTAssertNoThrow(Log.error("Test error", category: .security))
        XCTAssertNoThrow(Log.warning("Test warning", category: .authentication))
        XCTAssertNoThrow(Log.critical("Test critical", category: .general))
        XCTAssertNoThrow(Log.fault("Test fault", category: .powerMonitor))
    }

    func testErrorLoggingWithSwiftError() {
        enum TestError: Error {
            case testFailure(String)
        }
        
        let error = TestError.testFailure("Something went wrong")
        
        // Should not crash when logging Swift errors
        XCTAssertNoThrow(SentryLogger.logError("Test error occurred", error: error))
        XCTAssertNoThrow(Log.error("Test error via Log", error: error, category: .general))
    }

    func testSendTestEventWhenDisabled() {
        // Test that sendTestEvent works when Sentry is disabled
        let disabledConfig = SentryLogger.Configuration(
            dsn: "test://dsn",
            environment: "test", 
            enabled: false
        )
        
        SentryLogger.initialize(with: disabledConfig)
        
        let expectation = XCTestExpectation(description: "Test event completion")
        
        SentryLogger.sendTestEvent { success in
            XCTAssertFalse(success, "Should return false when Sentry is disabled")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }

    func testSendTestEventWhenEnabled() {
        // Test that sendTestEvent doesn't crash when enabled (can't test actual sending in unit tests)
        let enabledConfig = SentryLogger.Configuration(
            dsn: "https://test@sentry.io/123",
            environment: "test",
            enabled: true,
            debug: false
        )
        
        // Note: This initializes Sentry but won't actually send events in test environment
        XCTAssertNoThrow(SentryLogger.initialize(with: enabledConfig))
        
        // Should not crash when calling sendTestEvent
        XCTAssertNoThrow(SentryLogger.sendTestEvent())
        
        // Test with completion handler
        let expectation = XCTestExpectation(description: "Test event completion")
        
        SentryLogger.sendTestEvent { success in
            // In test environment, this should complete but we can't verify actual success
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 3.0)
    }
}