//
//  SettingsModelTests.swift
//  MagSafe Guard
//
//  Created on 2025-07-26.
//
//  Tests for Settings model and validation
//

@testable import MagSafeGuard
import XCTest

final class SettingsModelTests: XCTestCase {

    // MARK: - Default Values Tests

    func testDefaultSettings() {
        let settings = Settings()

        XCTAssertEqual(settings.gracePeriodDuration, 10.0)
        XCTAssertTrue(settings.allowGracePeriodCancellation)
        XCTAssertEqual(settings.securityActions, [.lockScreen, .unmountVolumes])
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
        settings.securityActions = [.lockScreen, .unmountVolumes, .lockScreen, .shutdown, .unmountVolumes]
        let validated2 = settings.validated()
        XCTAssertEqual(validated2.securityActions, [.lockScreen, .unmountVolumes, .shutdown])
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
        XCTAssertEqual(SecurityActionType.logOut.displayName, "Log Out")
        XCTAssertEqual(SecurityActionType.shutdown.displayName, "Shut Down")
        XCTAssertEqual(SecurityActionType.unmountVolumes.displayName, "Unmount External Volumes")
        XCTAssertEqual(SecurityActionType.clearClipboard.displayName, "Clear Clipboard")
        XCTAssertEqual(SecurityActionType.customScript.displayName, "Run Custom Script")

        // Test descriptions
        XCTAssertTrue(SecurityActionType.lockScreen.description.contains("password"))
        XCTAssertTrue(SecurityActionType.unmountVolumes.description.contains("external"))

        // Test symbol names
        XCTAssertEqual(SecurityActionType.lockScreen.symbolName, "lock.fill")
        XCTAssertEqual(SecurityActionType.shutdown.symbolName, "power")
        XCTAssertEqual(SecurityActionType.customScript.symbolName, "terminal.fill")
    }

    func testSecurityActionTypeCodable() throws {
        let actions: [SecurityActionType] = [.lockScreen, .unmountVolumes, .customScript]

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

        XCTAssertEqual(settings1, settings2)

        var settings3 = Settings()
        settings3.gracePeriodDuration = 15.0

        XCTAssertNotEqual(settings1, settings3)
    }
}
