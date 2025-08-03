//
//  NetworkMonitorTests.swift
//  MagSafe Guard
//
//  Created on 2025-07-26.
//
//  Tests for network monitoring functionality
//

import XCTest

@testable import MagSafeGuard

final class NetworkMonitorTests: XCTestCase {

  var networkMonitor: NetworkMonitor!

  override func setUp() {
    super.setUp()
    networkMonitor = NetworkMonitor()
  }

  override func tearDown() {
    networkMonitor.stopMonitoring()
    super.tearDown()
  }

  // MARK: - Initialization Tests

  func testNetworkMonitorInitialization() {
    XCTAssertNotNil(networkMonitor)
    XCTAssertFalse(networkMonitor.isMonitoring)
    XCTAssertNil(networkMonitor.currentSSID)
    XCTAssertFalse(networkMonitor.isConnected)
    XCTAssertFalse(networkMonitor.isOnTrustedNetwork)
  }

  // MARK: - Monitoring Tests

  func testStartMonitoring() {
    networkMonitor.startMonitoring()
    XCTAssertTrue(networkMonitor.isMonitoring)
  }

  func testStopMonitoring() {
    networkMonitor.startMonitoring()
    networkMonitor.stopMonitoring()
    XCTAssertFalse(networkMonitor.isMonitoring)
  }

  // MARK: - Trusted Network Management Tests

  func testAddTrustedNetwork() {
    let networkSSID = "TestNetwork"
    networkMonitor.addTrustedNetwork(networkSSID)

    XCTAssertTrue(networkMonitor.trustedNetworks.contains(networkSSID))
  }

  func testRemoveTrustedNetwork() {
    let networkSSID = "TestNetwork"
    networkMonitor.addTrustedNetwork(networkSSID)
    networkMonitor.removeTrustedNetwork(networkSSID)

    XCTAssertFalse(networkMonitor.trustedNetworks.contains(networkSSID))
  }

  func testUpdateTrustedNetworks() {
    let networks: Set<String> = ["Network1", "Network2", "Network3"]
    networkMonitor.updateTrustedNetworks(networks)

    XCTAssertEqual(networkMonitor.trustedNetworks, networks)
  }

  func testAddEmptyNetworkName() {
    // Start with a known state
    networkMonitor.updateTrustedNetworks([])

    // Try to add empty network name - should be ignored
    networkMonitor.addTrustedNetwork("")

    // Should still be empty since empty strings are not allowed
    XCTAssertTrue(networkMonitor.trustedNetworks.isEmpty)
  }

  // MARK: - Network Status Tests

  func testIsCurrentNetworkTrustedWithNoSSID() {
    networkMonitor.addTrustedNetwork("TrustedNetwork")
    XCTAssertFalse(networkMonitor.isCurrentNetworkTrusted())
  }

  func testStatusDescriptionWhenDisconnected() {
    // Force disconnected state
    let status = networkMonitor.statusDescription
    XCTAssertEqual(status, "Disconnected")
  }

  func testShouldAutoArmWhenDisconnected() {
    // When disconnected, should auto-arm
    XCTAssertTrue(networkMonitor.shouldAutoArm)
  }

  // MARK: - Settings Integration Tests

  func testLoadTrustedNetworksFromSettings() {
    // Set up trusted networks in settings
    let settingsManager = UserDefaultsManager.shared
    settingsManager.updateSetting(\.trustedNetworks, value: ["Network1", "Network2"])

    // Create new monitor to test loading
    let newMonitor = NetworkMonitor()

    // Should load from settings
    XCTAssertEqual(newMonitor.trustedNetworks.count, 2)
    XCTAssertTrue(newMonitor.trustedNetworks.contains("Network1"))
    XCTAssertTrue(newMonitor.trustedNetworks.contains("Network2"))
  }

  func testSaveTrustedNetworksToSettings() {
    let settingsManager = UserDefaultsManager.shared

    // Add network through monitor
    networkMonitor.addTrustedNetwork("SavedNetwork")

    // Check if saved to settings
    XCTAssertTrue(settingsManager.settings.trustedNetworks.contains("SavedNetwork"))
  }
}

// MARK: - Mock Network Monitor Delegate

class MockNetworkMonitorDelegate: NetworkMonitorDelegate {
  var didConnectToUntrustedNetwork: String?
  var didDisconnectFromTrustedNetwork = false
  var didConnectToTrustedNetwork: String?
  var connectivityChanged: Bool?

  func networkMonitorDidConnectToUntrustedNetwork(_ ssid: String) {
    didConnectToUntrustedNetwork = ssid
  }

  func networkMonitorDidDisconnectFromTrustedNetwork() {
    didDisconnectFromTrustedNetwork = true
  }

  func networkMonitorDidConnectToTrustedNetwork(_ ssid: String) {
    didConnectToTrustedNetwork = ssid
  }

  func networkMonitor(didChangeConnectivity isConnected: Bool) {
    connectivityChanged = isConnected
  }
}
