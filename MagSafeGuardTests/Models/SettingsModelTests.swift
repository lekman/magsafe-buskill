//
//  SettingsModelTests.swift
//  MagSafe Guard
//
//  Created on 2025-07-26.
//
//  Tests for Settings model and validation
//

import XCTest

@testable import MagSafeGuardCore
@testable import MagSafeGuardDomain

final class SettingsModelTests: XCTestCase {

  // MARK: - Default Values Tests

  func testDefaultSettings() {
    let settings = Settings()

    XCTAssertEqual(settings.gracePeriodDuration, 10.0)
    XCTAssertTrue(settings.allowGracePeriodCancellation)
    XCTAssertEqual(settings.securityActions, [.lockScreen, .soundAlarm])
    XCTAssertFalse(settings.autoArmEnabled)
    XCTAssertTrue(settings.showStatusNotifications)
    XCTAssertTrue(settings.playCriticalAlertSound)
    XCTAssertFalse(settings.launchAtLogin)
    XCTAssertFalse(settings.showInDock)
    XCTAssertFalse(settings.debugLoggingEnabled)
  }

  // MARK: - Validation Tests

  func testGracePeriodValidation() {
    var settings = Settings()

    // Test below minimum
    settings.gracePeriodDuration = 3.0
    let validated1 = settings.validated()
    XCTAssertEqual(validated1.gracePeriodDuration, 5.0)

    // Test above maximum
    settings.gracePeriodDuration = 50.0
    let validated2 = settings.validated()
    XCTAssertEqual(validated2.gracePeriodDuration, 30.0)

    // Test valid value
    settings.gracePeriodDuration = 15.0
    let validated3 = settings.validated()
    XCTAssertEqual(validated3.gracePeriodDuration, 15.0)
  }

  func testSecurityActionsValidation() {
    var settings = Settings()

    // Test empty actions
    settings.securityActions = []
    let validated1 = settings.validated()
    XCTAssertEqual(validated1.securityActions, [.lockScreen])

    // Test duplicate removal
    settings.securityActions = [
      .lockScreen, .soundAlarm, .lockScreen, .shutdown, .soundAlarm
    ]
    let validated2 = settings.validated()
    XCTAssertEqual(validated2.securityActions, [.lockScreen, .soundAlarm, .shutdown])
  }

  // MARK: - Codable Tests

  func testSettingsEncodingDecoding() throws {
    var original = Settings()
    original.gracePeriodDuration = 20.0
    original.autoArmEnabled = true
    original.trustedNetworks = ["Network1", "Network2"]
    original.customScripts = ["/path/to/script.sh"]
    original.debugLoggingEnabled = true

    // Encode
    let encoder = JSONEncoder()
    let data = try encoder.encode(original)

    // Decode
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(Settings.self, from: data)

    XCTAssertEqual(decoded.gracePeriodDuration, original.gracePeriodDuration)
    XCTAssertEqual(decoded.autoArmEnabled, original.autoArmEnabled)
    XCTAssertEqual(decoded.trustedNetworks, original.trustedNetworks)
    XCTAssertEqual(decoded.customScripts, original.customScripts)
    XCTAssertEqual(decoded.debugLoggingEnabled, original.debugLoggingEnabled)
  }

  // MARK: - SecurityActionType Tests

  func testSecurityActionTypeProperties() {
    // Test display names
    XCTAssertEqual(SecurityActionType.lockScreen.displayName, "Lock Screen")
    XCTAssertEqual(SecurityActionType.forceLogout.displayName, "Force Logout")
    XCTAssertEqual(SecurityActionType.shutdown.displayName, "System Shutdown")
    XCTAssertEqual(SecurityActionType.forceLogout.displayName, "Force Logout")
    XCTAssertEqual(SecurityActionType.soundAlarm.displayName, "Sound Alarm")
    XCTAssertEqual(SecurityActionType.customScript.displayName, "Custom Script")

    // Test descriptions
    XCTAssertTrue(SecurityActionType.lockScreen.description.contains("lock"))
    XCTAssertTrue(SecurityActionType.forceLogout.displayName.contains("Logout"))

    // Test symbol names
    XCTAssertEqual(SecurityActionType.lockScreen.symbolName, "lock.fill")
    XCTAssertEqual(SecurityActionType.shutdown.symbolName, "power")
    XCTAssertEqual(SecurityActionType.customScript.symbolName, "terminal.fill")
  }

  func testSecurityActionTypeCodable() throws {
    let actions: [SecurityActionType] = [.lockScreen, .soundAlarm, .customScript]

    let encoder = JSONEncoder()
    let data = try encoder.encode(actions)

    let decoder = JSONDecoder()
    let decoded = try decoder.decode([SecurityActionType].self, from: data)

    XCTAssertEqual(decoded, actions)
  }

  // MARK: - Equatable Tests

  func testSettingsEquatable() {
    let settings1 = Settings()
    let settings2 = Settings()

    // Test basic equality of key properties
    XCTAssertEqual(settings1.gracePeriodDuration, settings2.gracePeriodDuration)
    XCTAssertEqual(settings1.securityActions, settings2.securityActions)

    var settings3 = Settings()
    settings3.gracePeriodDuration = 15.0

    // Test that modified settings differ
    XCTAssertNotEqual(settings1.gracePeriodDuration, settings3.gracePeriodDuration)
  }
}
