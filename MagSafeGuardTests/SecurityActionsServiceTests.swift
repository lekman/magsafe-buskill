//
//  SecurityActionsServiceTests.swift
//  MagSafe Guard
//
//  Created on 2025-07-25.
//

import XCTest

@testable import MagSafeGuard

final class SecurityActionsServiceTests: XCTestCase {

  var service: SecurityActionsService!
  var mockSystemActions: MockSystemActions!

  override func setUp() {
    super.setUp()
    mockSystemActions = MockSystemActions()
    service = SecurityActionsService(systemActions: mockSystemActions)
    // Reset to default configuration
    service.resetToDefault()
    // Wait for configuration to be applied
    Thread.sleep(forTimeInterval: 0.1)
  }

  override func tearDown() {
    service.stopOngoingActions()
    super.tearDown()
  }

  // MARK: - Configuration Tests

  func testDefaultConfiguration() {
    let config = service.configuration

    XCTAssertEqual(config.enabledActions, [.screenLock])
    XCTAssertEqual(config.actionDelay, 0)
    XCTAssertEqual(config.alarmVolume, 1.0)
    XCTAssertEqual(config.shutdownDelay, 30)
    XCTAssertNil(config.customScriptPath)
    XCTAssertFalse(config.executeInParallel)
  }

  func testUpdateConfiguration() {
    var newConfig = SecurityActionsService.Configuration.defaultConfiguration
    newConfig.enabledActions = [.screenLock, .soundAlarm]
    newConfig.actionDelay = 5
    newConfig.alarmVolume = 0.5

    service.updateConfiguration(newConfig)

    // Give time for async update
    let expectation = self.expectation(description: "Configuration updated")
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      XCTAssertEqual(self.service.configuration.enabledActions, [.screenLock, .soundAlarm])
      XCTAssertEqual(self.service.configuration.actionDelay, 5)
      XCTAssertEqual(self.service.configuration.alarmVolume, 0.5)
      expectation.fulfill()
    }

    waitForExpectations(timeout: 1)
  }

  // MARK: - Security Action Tests

  func testSecurityActionEnumProperties() {
    // Test display names
    XCTAssertEqual(SecurityActionsService.SecurityAction.screenLock.displayName, "Lock Screen")
    XCTAssertEqual(SecurityActionsService.SecurityAction.soundAlarm.displayName, "Sound Alarm")
    XCTAssertEqual(SecurityActionsService.SecurityAction.forceLogout.displayName, "Force Logout")
    XCTAssertEqual(SecurityActionsService.SecurityAction.shutdown.displayName, "System Shutdown")
    XCTAssertEqual(SecurityActionsService.SecurityAction.customScript.displayName, "Custom Script")

    // Test descriptions
    XCTAssertTrue(SecurityActionsService.SecurityAction.screenLock.description.contains("lock"))
    XCTAssertTrue(SecurityActionsService.SecurityAction.soundAlarm.description.contains("alarm"))
    XCTAssertTrue(SecurityActionsService.SecurityAction.forceLogout.description.contains("logout"))
    XCTAssertTrue(SecurityActionsService.SecurityAction.shutdown.description.contains("Shutdown"))
    XCTAssertTrue(SecurityActionsService.SecurityAction.customScript.description.contains("script"))

    // Test default enabled state
    XCTAssertTrue(SecurityActionsService.SecurityAction.screenLock.defaultEnabled)
    XCTAssertFalse(SecurityActionsService.SecurityAction.soundAlarm.defaultEnabled)
    XCTAssertFalse(SecurityActionsService.SecurityAction.forceLogout.defaultEnabled)
    XCTAssertFalse(SecurityActionsService.SecurityAction.shutdown.defaultEnabled)
    XCTAssertFalse(SecurityActionsService.SecurityAction.customScript.defaultEnabled)
  }

  func testSecurityActionRawValues() {
    XCTAssertEqual(SecurityActionsService.SecurityAction.screenLock.rawValue, "screen_lock")
    XCTAssertEqual(SecurityActionsService.SecurityAction.soundAlarm.rawValue, "sound_alarm")
    XCTAssertEqual(SecurityActionsService.SecurityAction.forceLogout.rawValue, "force_logout")
    XCTAssertEqual(SecurityActionsService.SecurityAction.shutdown.rawValue, "shutdown")
    XCTAssertEqual(SecurityActionsService.SecurityAction.customScript.rawValue, "custom_script")
  }

  // MARK: - Execution Tests

  func testExecuteScreenLock() {
    var config = service.configuration
    config.enabledActions = [.screenLock]
    service.updateConfiguration(config)

    let expectation = self.expectation(description: "Screen lock executed")

    service.executeActions { result in
      XCTAssertTrue(result.allSucceeded)
      XCTAssertEqual(result.executedActions, [.screenLock])
      XCTAssertTrue(result.failedActions.isEmpty)
      XCTAssertTrue(self.mockSystemActions.lockScreenCalled)
      expectation.fulfill()
    }

    waitForExpectations(timeout: 2)
  }

  func testExecuteSoundAlarm() {
    var config = service.configuration
    config.enabledActions = [.soundAlarm]
    config.alarmVolume = 0.75
    service.updateConfiguration(config)

    let expectation = self.expectation(description: "Sound alarm executed")

    service.executeActions { result in
      XCTAssertTrue(result.allSucceeded)
      XCTAssertEqual(result.executedActions, [.soundAlarm])
      XCTAssertTrue(self.mockSystemActions.playAlarmCalled)
      XCTAssertEqual(self.mockSystemActions.playAlarmVolume, 0.75)
      expectation.fulfill()
    }

    waitForExpectations(timeout: 2)
  }

  func testExecuteMultipleActions() {
    var config = service.configuration
    config.enabledActions = [.screenLock, .soundAlarm]
    service.updateConfiguration(config)

    let expectation = self.expectation(description: "Multiple actions executed")

    service.executeActions { result in
      XCTAssertTrue(result.allSucceeded)
      XCTAssertEqual(Set(result.executedActions), Set([.screenLock, .soundAlarm]))
      XCTAssertTrue(self.mockSystemActions.lockScreenCalled)
      XCTAssertTrue(self.mockSystemActions.playAlarmCalled)
      expectation.fulfill()
    }

    waitForExpectations(timeout: 2)
  }

  func testExecuteActionsWithFailures() {
    mockSystemActions.shouldFailScreenLock = true

    var config = service.configuration
    config.enabledActions = [.screenLock, .soundAlarm]
    service.updateConfiguration(config)

    let expectation = self.expectation(description: "Actions with failures")

    service.executeActions { result in
      XCTAssertFalse(result.allSucceeded)
      XCTAssertEqual(result.executedActions, [.soundAlarm])
      XCTAssertEqual(result.failedActions.count, 1)
      XCTAssertEqual(result.failedActions.first?.action, .screenLock)
      XCTAssertTrue(self.mockSystemActions.lockScreenCalled)
      XCTAssertTrue(self.mockSystemActions.playAlarmCalled)
      expectation.fulfill()
    }

    waitForExpectations(timeout: 2)
  }

  func testExecuteActionsWithNoEnabledActions() {
    var config = service.configuration
    config.enabledActions = []
    service.updateConfiguration(config)

    let expectation = self.expectation(description: "Actions executed")

    service.executeActions { result in
      XCTAssertTrue(result.allSucceeded)
      XCTAssertTrue(result.executedActions.isEmpty)
      XCTAssertTrue(result.failedActions.isEmpty)
      XCTAssertNotNil(result.timestamp)
      expectation.fulfill()
    }

    waitForExpectations(timeout: 2)
  }

  func testExecuteActionsWithDelay() {
    var config = service.configuration
    config.enabledActions = []  // No actions to avoid system calls
    config.actionDelay = 0.5  // 0.5 second delay
    service.updateConfiguration(config)

    let expectation = self.expectation(description: "Actions executed with delay")
    let startTime = Date()

    service.executeActions { result in
      let elapsed = Date().timeIntervalSince(startTime)
      XCTAssertGreaterThanOrEqual(elapsed, 0.5)
      XCTAssertTrue(result.allSucceeded)
      expectation.fulfill()
    }

    waitForExpectations(timeout: 3)
  }

  func testExecuteActionsWhileAlreadyExecuting() {
    var config = service.configuration
    config.enabledActions = []
    config.actionDelay = 0.5  // Add delay to ensure overlap
    service.updateConfiguration(config)

    let expectation1 = self.expectation(description: "First execution")
    let expectation2 = self.expectation(description: "Second execution")
    expectation2.isInverted = true  // Should not be called

    // Start first execution
    service.executeActions { _ in
      expectation1.fulfill()
    }

    // Wait a bit to ensure first execution has started
    Thread.sleep(forTimeInterval: 0.1)

    // Try to start second execution while first is still running
    service.executeActions { _ in
      expectation2.fulfill()
    }

    waitForExpectations(timeout: 2)
  }

  func testStopOngoingActions() {
    // This mainly tests that stopOngoingActions doesn't crash
    service.stopOngoingActions()

    // Call it multiple times to ensure idempotency
    service.stopOngoingActions()
    service.stopOngoingActions()

    XCTAssertTrue(true, "stopOngoingActions should not crash")
  }

  // MARK: - Execution Result Tests

  func testExecutionResultAllSucceeded() {
    let result = SecurityActionsService.ExecutionResult(
      executedActions: [.screenLock, .soundAlarm],
      failedActions: [],
      timestamp: Date()
    )

    XCTAssertTrue(result.allSucceeded)
    XCTAssertEqual(result.executedActions.count, 2)
    XCTAssertTrue(result.failedActions.isEmpty)
  }

  func testExecutionResultWithFailures() {
    let error = NSError(domain: "Test", code: 1, userInfo: nil)
    let result = SecurityActionsService.ExecutionResult(
      executedActions: [.screenLock],
      failedActions: [(.soundAlarm, error)],
      timestamp: Date()
    )

    XCTAssertFalse(result.allSucceeded)
    XCTAssertEqual(result.executedActions.count, 1)
    XCTAssertEqual(result.failedActions.count, 1)
    XCTAssertEqual(result.failedActions.first?.action, .soundAlarm)
  }

  // MARK: - Objective-C Compatibility Tests

  func testObjectiveCCompatibility() {
    // Reset mock for clean test
    mockSystemActions.reset()

    // Test screen lock enabled check
    XCTAssertTrue(service.isScreenLockEnabled)

    // Disable screen lock
    service.setScreenLockEnabled(false)

    // Give time for async update
    let expectation = self.expectation(description: "Screen lock disabled")
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      XCTAssertFalse(self.service.isScreenLockEnabled)
      expectation.fulfill()
    }

    waitForExpectations(timeout: 1)
  }

  func testObjectiveCExecuteActions() {
    var config = service.configuration
    config.enabledActions = []  // No actions to avoid system calls
    service.updateConfiguration(config)

    let expectation = self.expectation(description: "ObjC actions executed")

    service.executeActionsObjC { success in
      XCTAssertTrue(success)
      expectation.fulfill()
    }

    waitForExpectations(timeout: 2)
  }

  // MARK: - Configuration Persistence Tests

  func testConfigurationPersistence() {
    // Create a unique configuration
    var config = SecurityActionsService.Configuration.defaultConfiguration
    config.enabledActions = [.soundAlarm, .forceLogout]
    config.actionDelay = 10
    config.alarmVolume = 0.75
    config.shutdownDelay = 60
    config.customScriptPath = "/tmp/test.sh"
    config.executeInParallel = true

    // Update and save
    service.updateConfiguration(config)

    // Wait for save to complete
    let expectation = self.expectation(description: "Configuration saved")
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      // Verify the configuration was saved to UserDefaults
      if let data = UserDefaults.standard.data(forKey: "SecurityActionsConfiguration"),
        let savedConfig = try? JSONDecoder().decode(
          SecurityActionsService.Configuration.self, from: data)
      {
        XCTAssertEqual(savedConfig.enabledActions, [.soundAlarm, .forceLogout])
        XCTAssertEqual(savedConfig.actionDelay, 10)
        XCTAssertEqual(savedConfig.alarmVolume, 0.75)
        XCTAssertEqual(savedConfig.shutdownDelay, 60)
        XCTAssertEqual(savedConfig.customScriptPath, "/tmp/test.sh")
        XCTAssertTrue(savedConfig.executeInParallel)
      } else {
        XCTFail("Configuration was not saved to UserDefaults")
      }
      expectation.fulfill()
    }

    waitForExpectations(timeout: 1)
  }

  // MARK: - Edge Case Tests

  func testCustomScriptWithoutPath() {
    var config = service.configuration
    config.enabledActions = [.customScript]
    config.customScriptPath = nil
    service.updateConfiguration(config)

    let expectation = self.expectation(description: "Custom script fails")

    service.executeActions { result in
      XCTAssertFalse(result.allSucceeded)
      XCTAssertTrue(result.executedActions.isEmpty)
      XCTAssertEqual(result.failedActions.count, 1)
      XCTAssertEqual(result.failedActions.first?.action, .customScript)
      expectation.fulfill()
    }

    waitForExpectations(timeout: 2)
  }

  func testCustomScriptWithInvalidPath() {
    var config = service.configuration
    config.enabledActions = [.customScript]
    config.customScriptPath = "/nonexistent/path/script.sh"
    service.updateConfiguration(config)

    let expectation = self.expectation(description: "Custom script fails")

    service.executeActions { result in
      XCTAssertFalse(result.allSucceeded)
      XCTAssertTrue(result.executedActions.isEmpty)
      XCTAssertEqual(result.failedActions.count, 1)
      XCTAssertEqual(result.failedActions.first?.action, .customScript)
      XCTAssertTrue(self.mockSystemActions.executeScriptCalled)
      XCTAssertEqual(self.mockSystemActions.executedScriptPath, "/nonexistent/path/script.sh")
      expectation.fulfill()
    }

    waitForExpectations(timeout: 2)
  }

  func testCustomScriptSuccess() {
    // Create a temporary script file
    let tempPath = NSTemporaryDirectory() + "test_script.sh"
    try? "#!/bin/bash\necho 'test'".write(toFile: tempPath, atomically: true, encoding: .utf8)
    defer { try? FileManager.default.removeItem(atPath: tempPath) }

    var config = service.configuration
    config.enabledActions = [.customScript]
    config.customScriptPath = tempPath
    service.updateConfiguration(config)

    let expectation = self.expectation(description: "Custom script succeeds")

    service.executeActions { result in
      XCTAssertTrue(result.allSucceeded)
      XCTAssertEqual(result.executedActions, [.customScript])
      XCTAssertTrue(self.mockSystemActions.executeScriptCalled)
      XCTAssertEqual(self.mockSystemActions.executedScriptPath, tempPath)
      expectation.fulfill()
    }

    waitForExpectations(timeout: 2)
  }
}
