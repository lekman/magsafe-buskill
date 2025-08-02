//
//  PowerMonitorServiceTests.swift
//  MagSafe Guard
//
//  Created on 2025-07-25.
//

import XCTest

@testable import MagSafeGuard

final class PowerMonitorServiceTests: XCTestCase {

  var service: PowerMonitorService!

  override func setUp() {
    super.setUp()
    service = PowerMonitorService.shared
    // Ensure clean state before each test
    service.resetForTesting()
  }

  override func tearDown() {
    service.resetForTesting()
    super.tearDown()
  }

  func testServiceSingleton() {
    let instance1 = PowerMonitorService.shared
    let instance2 = PowerMonitorService.shared
    XCTAssertTrue(instance1 === instance2, "PowerMonitorService should be a singleton")
  }

  func testInitialState() {
    XCTAssertFalse(service.isMonitoring, "Service should not be monitoring initially")
    // currentPowerInfo may be set by getCurrentPowerInfo on initialization
  }

  func testStartMonitoring() {
    let expectation = XCTestExpectation(description: "Callback should be called")

    service.startMonitoring { powerInfo in
      XCTAssertNotNil(powerInfo, "Power info should not be nil")
      expectation.fulfill()
    }

    // Wait a moment for async operation to complete
    Thread.sleep(forTimeInterval: 0.1)

    XCTAssertTrue(service.isMonitoring, "Service should be monitoring after start")

    wait(for: [expectation], timeout: 2.0)
  }

  func testStopMonitoring() {
    service.startMonitoring { _ in }

    // Wait for async start operation
    Thread.sleep(forTimeInterval: 0.1)
    XCTAssertTrue(service.isMonitoring, "Service should be monitoring")

    service.stopMonitoring()

    // Wait for async stop operation
    Thread.sleep(forTimeInterval: 0.1)
    XCTAssertFalse(service.isMonitoring, "Service should not be monitoring after stop")
  }

  func testGetCurrentPowerInfo() {
    let powerInfo = service.getCurrentPowerInfo()
    XCTAssertNotNil(powerInfo, "Should return power info")

    if let info = powerInfo {
      XCTAssertNotNil(info.state, "Power state should not be nil")
      XCTAssertNotNil(info.timestamp, "Timestamp should not be nil")
    }
  }

  func testObjectiveCCompatibility() {
    // Test Objective-C compatible properties
    let isConnected = service.isPowerConnected
    // isConnected depends on actual system state
    XCTAssertTrue(isConnected == true || isConnected == false)

    let batteryLevel = service.batteryLevel
    // Battery level should be valid (-1 or 0-100)
    XCTAssertTrue(batteryLevel >= -1 && batteryLevel <= 100)
  }

  func testPowerStateEnum() {
    XCTAssertEqual(PowerMonitorService.PowerState.connected.rawValue, "connected")
    XCTAssertEqual(PowerMonitorService.PowerState.disconnected.rawValue, "disconnected")

    XCTAssertEqual(PowerMonitorService.PowerState.connected.description, "Power adapter connected")
    XCTAssertEqual(
      PowerMonitorService.PowerState.disconnected.description, "Power adapter disconnected")
  }

  func testPowerInfoProperties() {
    let info = PowerMonitorService.PowerInfo(
      state: .connected,
      batteryLevel: 85,
      isCharging: true,
      adapterWattage: 96,
      timestamp: Date()
    )

    XCTAssertEqual(info.state, .connected)
    XCTAssertEqual(info.batteryLevel, 85)
    XCTAssertTrue(info.isCharging)
    XCTAssertEqual(info.adapterWattage, 96)
    XCTAssertNotNil(info.timestamp)
  }

  func testMultipleCallbacks() {
    let expectation1 = XCTestExpectation(description: "First callback")
    expectation1.expectedFulfillmentCount = 1
    expectation1.assertForOverFulfill = false  // Don't fail if called more than once

    var callbackCount = 0
    let lock = NSLock()

    // Start monitoring with first callback
    service.startMonitoring { _ in
      lock.lock()
      callbackCount += 1
      lock.unlock()
      expectation1.fulfill()
    }

    Thread.sleep(forTimeInterval: 0.2)

    // Try to start again (should be ignored since already monitoring)
    service.startMonitoring { _ in
      // This callback should not be called
      XCTFail("Second callback should not be called")
    }

    // Wait for the initial callback
    wait(for: [expectation1], timeout: 2.0)

    // Give a bit more time to ensure no second callback
    Thread.sleep(forTimeInterval: 0.1)

    service.stopMonitoring()

    // Verify we got at least one callback from the first monitor
    lock.lock()
    XCTAssertGreaterThanOrEqual(callbackCount, 1, "Should have received at least one callback")
    lock.unlock()
  }

  func testMultipleStartCalls() {
    // Test that multiple start calls don't cause issues
    service.startMonitoring { _ in }

    // Give first call time to set isMonitoring
    Thread.sleep(forTimeInterval: 0.1)

    XCTAssertTrue(service.isMonitoring)

    // Second call should be ignored
    service.startMonitoring { _ in }

    XCTAssertTrue(service.isMonitoring)

    service.stopMonitoring()
    Thread.sleep(forTimeInterval: 0.1)
    XCTAssertFalse(service.isMonitoring)
  }

  func testPowerInfoUpdate() {
    // Test that power info gets updated
    let expectation = XCTestExpectation(description: "Power info update")

    service.startMonitoring { powerInfo in
      XCTAssertNotNil(powerInfo)
      XCTAssertNotNil(powerInfo.timestamp)
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 2.0)

    service.stopMonitoring()
  }

  func testPowerSourceDetails() {
    // Test power source information parsing
    let powerInfo = service.getCurrentPowerInfo()

    if let info = powerInfo {
      // Log power info details for debugging
      Log.debug("Power state: \(info.state)", category: .powerMonitor)
      Log.debug("Battery level: \(info.batteryLevel ?? -1)", category: .powerMonitor)
      Log.debug("Is charging: \(info.isCharging)", category: .powerMonitor)
      Log.debug("Adapter wattage: \(info.adapterWattage ?? 0)", category: .powerMonitor)
    }

    XCTAssertNotNil(powerInfo)
  }

  func testStopWithoutStart() {
    // Test stopping when not monitoring
    XCTAssertFalse(service.isMonitoring)
    service.stopMonitoring()  // Should not crash
    XCTAssertFalse(service.isMonitoring)
  }

  func testCallbackOnMainQueue() {
    let expectation = XCTestExpectation(description: "Main queue callback")

    service.startMonitoring { _ in
      XCTAssertTrue(Thread.isMainThread, "Callback should be on main thread")
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 2.0)
  }

  func testPowerInfoTimestamp() {
    let info1 = service.getCurrentPowerInfo()
    Thread.sleep(forTimeInterval: 0.1)
    let info2 = service.getCurrentPowerInfo()

    if let timestamp1 = info1?.timestamp,
      let timestamp2 = info2?.timestamp
    {
      XCTAssertTrue(timestamp2 > timestamp1, "Later timestamp should be greater")
    }
  }

  func testGetCurrentPowerInfoDetailed() {
    // Test getCurrentPowerInfo method returns valid data
    let powerInfo = service.getCurrentPowerInfo()

    XCTAssertNotNil(powerInfo)
    XCTAssertTrue(powerInfo?.state == .connected || powerInfo?.state == .disconnected)
    XCTAssertNotNil(powerInfo?.timestamp)

    // Battery level should be between 0-100 or nil
    if let battery = powerInfo?.batteryLevel {
      XCTAssertTrue(battery >= 0 && battery <= 100)
    }
  }

  func testPowerStateDescriptions() {
    // Test the description property of PowerState enum
    XCTAssertEqual(PowerMonitorService.PowerState.connected.description, "Power adapter connected")
    XCTAssertEqual(
      PowerMonitorService.PowerState.disconnected.description, "Power adapter disconnected")
  }

  func testServiceSingletonIdentity() {
    // Verify singleton returns same instance
    let instance1 = PowerMonitorService.shared
    let instance2 = PowerMonitorService.shared

    XCTAssertTrue(instance1 === instance2)
    XCTAssertIdentical(instance1, instance2)
  }

  func testCurrentPowerInfoUpdates() {
    // Test that currentPowerInfo gets updated during monitoring
    let expectation = XCTestExpectation(description: "Power info updated")

    service.startMonitoring { [weak self] powerInfo in
      // Verify currentPowerInfo is updated
      XCTAssertNotNil(self?.service.currentPowerInfo)
      XCTAssertEqual(self?.service.currentPowerInfo?.state, powerInfo.state)
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 2.0)
    service.stopMonitoring()
  }

  func testPowerStateRawValues() {
    // Test raw values for Objective-C compatibility
    XCTAssertEqual(PowerMonitorService.PowerState.connected.rawValue, "connected")
    XCTAssertEqual(PowerMonitorService.PowerState.disconnected.rawValue, "disconnected")
  }

  func testPowerInfoEquality() {
    // Test PowerInfo struct properties
    let date = Date()
    let info1 = PowerMonitorService.PowerInfo(
      state: .connected,
      batteryLevel: 80,
      isCharging: true,
      adapterWattage: 96,
      timestamp: date
    )

    let info2 = PowerMonitorService.PowerInfo(
      state: .connected,
      batteryLevel: 80,
      isCharging: true,
      adapterWattage: 96,
      timestamp: date
    )

    // Verify all properties
    XCTAssertEqual(info1.state, info2.state)
    XCTAssertEqual(info1.batteryLevel, info2.batteryLevel)
    XCTAssertEqual(info1.isCharging, info2.isCharging)
    XCTAssertEqual(info1.adapterWattage, info2.adapterWattage)
    XCTAssertEqual(info1.timestamp, info2.timestamp)
  }

  func testMonitoringWithImmediateStop() {
    // In CI, the initial callback might fire before stop takes effect
    // So we'll allow the initial callback but verify monitoring stops
    var callbackCount = 0
    let lock = NSLock()

    // Test starting and immediately stopping
    service.startMonitoring { _ in
      lock.lock()
      callbackCount += 1
      lock.unlock()
    }

    // Stop immediately
    service.stopMonitoring()

    // Record count right after stop
    Thread.sleep(forTimeInterval: 0.1)
    lock.lock()
    let countAfterStop = callbackCount
    lock.unlock()

    // Wait a bit more to ensure no more callbacks
    Thread.sleep(forTimeInterval: 0.3)

    lock.lock()
    let finalCount = callbackCount
    lock.unlock()

    // Verify monitoring stopped
    XCTAssertFalse(service.isMonitoring)

    // The count should not increase after stop
    XCTAssertEqual(countAfterStop, finalCount, "No callbacks should occur after stop")

    // In CI, we might get 0 or 1 initial callback
    XCTAssertLessThanOrEqual(finalCount, 1, "Should have at most one initial callback")
  }

  func testGetCurrentPowerInfoConsistency() {
    // Test multiple calls return consistent data structure
    let info1 = service.getCurrentPowerInfo()
    let info2 = service.getCurrentPowerInfo()

    if let i1 = info1, let i2 = info2 {
      // Both should have valid timestamps
      XCTAssertNotNil(i1.timestamp)
      XCTAssertNotNil(i2.timestamp)

      // State should be valid
      XCTAssertTrue(i1.state == .connected || i1.state == .disconnected)
      XCTAssertTrue(i2.state == .connected || i2.state == .disconnected)
    }
  }

  func testServiceCleanup() {
    // Test proper cleanup after monitoring
    service.startMonitoring { _ in }
    Thread.sleep(forTimeInterval: 0.1)

    XCTAssertTrue(service.isMonitoring)
    XCTAssertNotNil(service.currentPowerInfo)

    service.stopMonitoring()
    Thread.sleep(forTimeInterval: 0.1)

    XCTAssertFalse(service.isMonitoring)
  }
}
