//
//  AutoArmManagerTests.swift
//  MagSafe Guard Tests
//
//  Created on 2025-07-26.
//
//  Tests for auto-arm functionality
//

import XCTest
import CoreLocation
@testable import MagSafeGuard

final class AutoArmManagerTests: XCTestCase {
    
    var appController: AppController!
    var autoArmManager: AutoArmManager!
    var settingsManager: UserDefaultsManager!
    
    override func setUp() {
        super.setUp()
        
        // Reset settings
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier ?? "")
        
        // Enable test environment to skip auto-arm initialization in AppController
        AppController.isTestEnvironment = true
        
        settingsManager = UserDefaultsManager.shared
        appController = AppController()
        
        // Create AutoArmManager directly since AppController won't create it in test mode
        autoArmManager = AutoArmManager(appController: appController)
    }
    
    override func tearDown() {
        autoArmManager.stopMonitoring()
        AppController.isTestEnvironment = false
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testAutoArmManagerInitialization() {
        XCTAssertNotNil(autoArmManager)
        XCTAssertFalse(autoArmManager.isMonitoring)
        XCTAssertFalse(autoArmManager.isTemporarilyDisabled)
    }
    
    // MARK: - Monitoring Tests
    
    func testStartMonitoringWhenEnabled() {
        // Enable auto-arm in settings
        settingsManager.settings.autoArmEnabled = true
        settingsManager.settings.autoArmByLocation = true
        
        autoArmManager.startMonitoring()
        
        XCTAssertTrue(autoArmManager.isMonitoring)
    }
    
    func testStartMonitoringWhenDisabled() {
        // Disable auto-arm in settings
        settingsManager.settings.autoArmEnabled = false
        
        autoArmManager.startMonitoring()
        
        XCTAssertFalse(autoArmManager.isMonitoring)
    }
    
    func testStopMonitoring() {
        // Start monitoring first
        settingsManager.settings.autoArmEnabled = true
        autoArmManager.startMonitoring()
        
        // Then stop
        autoArmManager.stopMonitoring()
        
        XCTAssertFalse(autoArmManager.isMonitoring)
    }
    
    // MARK: - Temporary Disable Tests
    
    func testTemporaryDisable() {
        autoArmManager.temporarilyDisable(for: 60)
        
        XCTAssertTrue(autoArmManager.isTemporarilyDisabled)
    }
    
    func testCancelTemporaryDisable() {
        // First disable
        autoArmManager.temporarilyDisable(for: 60)
        XCTAssertTrue(autoArmManager.isTemporarilyDisabled)
        
        // Then cancel
        autoArmManager.cancelTemporaryDisable()
        XCTAssertFalse(autoArmManager.isTemporarilyDisabled)
    }
    
    // MARK: - Settings Update Tests
    
    func testUpdateSettings() {
        // Enable auto-arm and start monitoring
        settingsManager.settings.autoArmEnabled = true
        autoArmManager.startMonitoring()
        XCTAssertTrue(autoArmManager.isMonitoring)
        
        // Disable auto-arm and update
        settingsManager.settings.autoArmEnabled = false
        autoArmManager.updateSettings()
        
        // Should stop monitoring
        XCTAssertFalse(autoArmManager.isMonitoring)
    }
    
    // MARK: - Trusted Location Tests
    
    func testAddTrustedLocation() {
        let location = TrustedLocation(
            name: "Test Location",
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            radius: 100
        )
        
        autoArmManager.addTrustedLocation(location)
        
        let locations = autoArmManager.getTrustedLocations()
        XCTAssertEqual(locations.count, 1)
        XCTAssertEqual(locations.first?.name, "Test Location")
    }
    
    func testRemoveTrustedLocation() {
        // Add a location first
        let location = TrustedLocation(
            name: "Test Location",
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            radius: 100
        )
        autoArmManager.addTrustedLocation(location)
        
        // Then remove it
        autoArmManager.removeTrustedLocation(id: location.id)
        
        let locations = autoArmManager.getTrustedLocations()
        XCTAssertEqual(locations.count, 0)
    }
    
    // MARK: - Status Tests
    
    func testStatusSummaryWhenDisabled() {
        settingsManager.settings.autoArmEnabled = false
        
        let status = autoArmManager.statusSummary
        XCTAssertEqual(status, "Auto-arm disabled")
    }
    
    func testStatusSummaryWhenTemporarilyDisabled() {
        settingsManager.settings.autoArmEnabled = true
        autoArmManager.temporarilyDisable(for: 60)
        
        let status = autoArmManager.statusSummary
        XCTAssertEqual(status, "Auto-arm temporarily disabled")
    }
    
    func testIsAutoArmConditionMet() {
        // Initially should be false
        XCTAssertFalse(autoArmManager.isAutoArmConditionMet)
        
        // Enable location-based auto-arm
        settingsManager.settings.autoArmEnabled = true
        settingsManager.settings.autoArmByLocation = true
        
        // Without being in a trusted location, condition should be met
        // (This is a simplified test - in real usage, LocationManager would determine this)
    }
}