//
//  PowerMonitorServiceTests.swift
//  MagSafeGuardTests
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
    }
    
    override func tearDown() {
        service.stopMonitoring()
        super.tearDown()
    }
    
    func testServiceSingleton() {
        let instance1 = PowerMonitorService.shared
        let instance2 = PowerMonitorService.shared
        XCTAssertTrue(instance1 === instance2, "PowerMonitorService should be a singleton")
    }
    
    func testInitialState() {
        XCTAssertFalse(service.isMonitoring, "Service should not be monitoring initially")
        XCTAssertNil(service.currentPowerInfo, "Current power info should be nil initially")
    }
    
    func testStartMonitoring() {
        let expectation = XCTestExpectation(description: "Callback should be called")
        
        service.startMonitoring { powerInfo in
            XCTAssertNotNil(powerInfo, "Power info should not be nil")
            expectation.fulfill()
        }
        
        XCTAssertTrue(service.isMonitoring, "Service should be monitoring after start")
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testStopMonitoring() {
        service.startMonitoring { _ in }
        XCTAssertTrue(service.isMonitoring, "Service should be monitoring")
        
        service.stopMonitoring()
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
        XCTAssertFalse(isConnected, "Should return false when no current power info")
        
        let batteryLevel = service.batteryLevel
        XCTAssertEqual(batteryLevel, -1, "Should return -1 when no current power info")
    }
    
    func testPowerStateEnum() {
        XCTAssertEqual(PowerMonitorService.PowerState.connected.rawValue, "connected")
        XCTAssertEqual(PowerMonitorService.PowerState.disconnected.rawValue, "disconnected")
        
        XCTAssertEqual(PowerMonitorService.PowerState.connected.description, "Power adapter connected")
        XCTAssertEqual(PowerMonitorService.PowerState.disconnected.description, "Power adapter disconnected")
    }
}