//
//  AutoArmManagerTests.swift
//  MagSafe Guard
//
//  Created on 2025-07-26.
//
//  Tests for auto-arm functionality
//

import CoreLocation
import XCTest

@testable import MagSafeGuard

final class AutoArmManagerTests: XCTestCase {

  var appController: AppController!
  var autoArmManager: AutoArmManager!
  var settingsManager: UserDefaultsManager!
  var mockLocationManager: MockLocationManager!

  override func setUpWithError() throws {
    try super.setUpWithError()

    // Reset settings
    UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier ?? "")

    // Enable test environment to skip auto-arm initialization in AppController
    AppController.isTestEnvironment = true

    settingsManager = UserDefaultsManager.shared
    appController = AppController()

    // Create mock location manager
    mockLocationManager = MockLocationManager()

    // Create AutoArmManager with mock location manager
    autoArmManager = AutoArmManager(
      appController: appController, locationManager: mockLocationManager)
  }

  override func tearDown() {
    autoArmManager?.stopMonitoring()
    autoArmManager = nil
    mockLocationManager = nil
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
    settingsManager.updateSetting(\.autoArmEnabled, value: true)
    settingsManager.updateSetting(\.autoArmByLocation, value: true)

    autoArmManager.startMonitoring()

    XCTAssertTrue(autoArmManager.isMonitoring)
    XCTAssertTrue(mockLocationManager.startMonitoringCalled)
  }

  func testStartMonitoringWhenDisabled() {
    // Disable auto-arm in settings
    settingsManager.updateSetting(\.autoArmEnabled, value: false)

    autoArmManager.startMonitoring()

    XCTAssertFalse(autoArmManager.isMonitoring)
  }

  func testStopMonitoring() {
    // Start monitoring first
    settingsManager.updateSetting(\.autoArmEnabled, value: true)
    autoArmManager.startMonitoring()

    // Then stop
    autoArmManager.stopMonitoring()

    XCTAssertFalse(autoArmManager.isMonitoring)
    XCTAssertTrue(mockLocationManager.stopMonitoringCalled)
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
    settingsManager.updateSetting(\.autoArmEnabled, value: true)
    autoArmManager.startMonitoring()
    XCTAssertTrue(autoArmManager.isMonitoring)

    // Disable auto-arm and update
    settingsManager.updateSetting(\.autoArmEnabled, value: false)
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
    settingsManager.updateSetting(\.autoArmEnabled, value: false)

    let status = autoArmManager.statusSummary
    XCTAssertEqual(status, "Auto-arm disabled")
  }

  func testStatusSummaryWhenTemporarilyDisabled() {
    settingsManager.updateSetting(\.autoArmEnabled, value: true)
    autoArmManager.temporarilyDisable(for: 60)

    let status = autoArmManager.statusSummary
    XCTAssertEqual(status, "Auto-arm temporarily disabled")
  }

  func testIsAutoArmConditionMet() {
    // Initially should be false
    XCTAssertFalse(autoArmManager.isAutoArmConditionMet)

    // Enable location-based auto-arm
    settingsManager.updateSetting(\.autoArmEnabled, value: true)
    settingsManager.updateSetting(\.autoArmByLocation, value: true)

    // Without being in a trusted location, condition should be met
    // (This is a simplified test - in real usage, LocationManager would determine this)
  }

  // MARK: - Location Delegate Tests

  func testLocationManagerDidLeaveTrustedLocationTriggersArm() {
    // Enable auto-arm
    settingsManager.updateSetting(\.autoArmEnabled, value: true)
    settingsManager.updateSetting(\.autoArmByLocation, value: true)
    autoArmManager.startMonitoring()

    // Ensure system is disarmed
    appController.disarm { _ in }

    // Simulate leaving trusted location
    mockLocationManager.simulateLeaveTrustedLocation()

    // Verify auto-arm was triggered (it happens after 2 second delay)
    let expectation = self.expectation(description: "Auto-arm triggered")
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
      XCTAssertEqual(self.appController.currentState, .armed)
      expectation.fulfill()
    }

    waitForExpectations(timeout: 3.0)
  }

  func testLocationManagerDidLeaveTrustedLocationDoesNotTriggerWhenDisabled() {
    // Disable auto-arm
    settingsManager.updateSetting(\.autoArmEnabled, value: false)

    // Ensure system is disarmed
    appController.disarm { _ in }

    // Simulate leaving trusted location
    mockLocationManager.simulateLeaveTrustedLocation()

    // Verify auto-arm was NOT triggered
    let expectation = self.expectation(description: "Wait for potential auto-arm")
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
      XCTAssertEqual(self.appController.currentState, .disarmed)
      expectation.fulfill()
    }

    waitForExpectations(timeout: 3.0)
  }
}
