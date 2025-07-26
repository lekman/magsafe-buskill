//
//  UserDefaultsManagerTests.swift
//  MagSafeGuardTests
//
//  Created on 2025-07-26.
//
//  Tests for UserDefaultsManager and settings persistence
//

import XCTest
@testable import MagSafeGuard

final class UserDefaultsManagerTests: XCTestCase {
    
    var sut: UserDefaultsManager!
    var testDefaults: UserDefaults!
    
    override func setUp() {
        super.setUp()
        // Create a test suite to avoid polluting real UserDefaults
        testDefaults = UserDefaults(suiteName: "com.magsafeguard.tests")!
        testDefaults.removePersistentDomain(forName: "com.magsafeguard.tests")
        sut = UserDefaultsManager(userDefaults: testDefaults)
    }
    
    override func tearDown() {
        testDefaults.removePersistentDomain(forName: "com.magsafeguard.tests")
        sut = nil
        testDefaults = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitWithDefaultSettings() {
        XCTAssertEqual(sut.settings.gracePeriodDuration, 10.0)
        XCTAssertTrue(sut.settings.allowGracePeriodCancellation)
        XCTAssertEqual(sut.settings.securityActions, [.lockScreen, .unmountVolumes])
        XCTAssertTrue(sut.settings.showStatusNotifications)
    }
    
    func testFirstLaunchSetsDefaults() {
        // First launch should have sensible defaults
        XCTAssertTrue(sut.settings.showStatusNotifications)
        XCTAssertTrue(sut.settings.playCriticalAlertSound)
        XCTAssertEqual(sut.settings.gracePeriodDuration, 10.0)
    }
    
    // MARK: - Persistence Tests
    
    func testSettingsPersistence() {
        // Update settings
        sut.updateSetting(\.gracePeriodDuration, value: 15.0)
        sut.updateSetting(\.launchAtLogin, value: true)
        
        // Create new manager with same UserDefaults
        let newManager = UserDefaultsManager(userDefaults: testDefaults)
        
        XCTAssertEqual(newManager.settings.gracePeriodDuration, 15.0)
        XCTAssertTrue(newManager.settings.launchAtLogin)
    }
    
    func testBatchUpdateSettings() {
        sut.updateSettings { settings in
            settings.gracePeriodDuration = 20.0
            settings.autoArmEnabled = true
            settings.trustedNetworks = ["HomeWiFi", "OfficeWiFi"]
        }
        
        XCTAssertEqual(sut.settings.gracePeriodDuration, 20.0)
        XCTAssertTrue(sut.settings.autoArmEnabled)
        XCTAssertEqual(sut.settings.trustedNetworks, ["HomeWiFi", "OfficeWiFi"])
    }
    
    // MARK: - Validation Tests
    
    func testGracePeriodValidation() {
        // Test lower bound
        sut.updateSetting(\.gracePeriodDuration, value: 2.0)
        XCTAssertEqual(sut.settings.gracePeriodDuration, 5.0) // Should be clamped to minimum
        
        // Test upper bound
        sut.updateSetting(\.gracePeriodDuration, value: 45.0)
        XCTAssertEqual(sut.settings.gracePeriodDuration, 30.0) // Should be clamped to maximum
        
        // Test valid range
        sut.updateSetting(\.gracePeriodDuration, value: 15.0)
        XCTAssertEqual(sut.settings.gracePeriodDuration, 15.0)
    }
    
    func testSecurityActionsValidation() {
        // Test empty security actions
        sut.updateSetting(\.securityActions, value: [])
        XCTAssertEqual(sut.settings.securityActions, [.lockScreen]) // Should have at least one
        
        // Test duplicate removal
        sut.updateSetting(\.securityActions, value: [.lockScreen, .unmountVolumes, .lockScreen])
        XCTAssertEqual(sut.settings.securityActions, [.lockScreen, .unmountVolumes])
    }
    
    // MARK: - Import/Export Tests
    
    func testExportSettings() throws {
        // Configure settings
        sut.updateSettings { settings in
            settings.gracePeriodDuration = 25.0
            settings.autoArmEnabled = true
            settings.debugLoggingEnabled = true
        }
        
        // Export
        let data = try sut.exportSettings()
        
        // Verify we can decode the data
        let decoder = JSONDecoder()
        let exportedSettings = try decoder.decode(Settings.self, from: data)
        
        XCTAssertEqual(exportedSettings.gracePeriodDuration, 25.0)
        XCTAssertTrue(exportedSettings.autoArmEnabled)
        XCTAssertTrue(exportedSettings.debugLoggingEnabled)
    }
    
    func testImportSettings() throws {
        // Create settings to import
        var settingsToImport = Settings()
        settingsToImport.gracePeriodDuration = 18.0
        settingsToImport.launchAtLogin = true
        settingsToImport.customScripts = ["/usr/local/bin/custom.sh"]
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(settingsToImport)
        
        // Import
        try sut.importSettings(from: data)
        
        XCTAssertEqual(sut.settings.gracePeriodDuration, 18.0)
        XCTAssertTrue(sut.settings.launchAtLogin)
        XCTAssertEqual(sut.settings.customScripts, ["/usr/local/bin/custom.sh"])
    }
    
    // MARK: - Reset Tests
    
    func testResetToDefaults() {
        // Change settings
        sut.updateSettings { settings in
            settings.gracePeriodDuration = 25.0
            settings.autoArmEnabled = true
            settings.customScripts = ["test.sh"]
        }
        
        // Reset
        sut.resetToDefaults()
        
        // Verify defaults
        XCTAssertEqual(sut.settings.gracePeriodDuration, 10.0)
        XCTAssertFalse(sut.settings.autoArmEnabled)
        XCTAssertTrue(sut.settings.customScripts.isEmpty)
    }
    
    // MARK: - Convenience Accessors Tests
    
    func testConvenienceAccessors() {
        // Test grace period
        sut.gracePeriodDuration = 22.0
        XCTAssertEqual(sut.settings.gracePeriodDuration, 22.0)
        
        // Test security actions
        sut.securityActions = [.shutdown, .clearClipboard]
        XCTAssertEqual(sut.settings.securityActions, [.shutdown, .clearClipboard])
        
        // Test launch at login
        sut.launchAtLogin = true
        XCTAssertTrue(sut.settings.launchAtLogin)
        
        // Test auto-arm
        sut.autoArmEnabled = true
        XCTAssertTrue(sut.settings.autoArmEnabled)
    }
}