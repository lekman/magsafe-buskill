//
//  PowerMonitorCoreTests.swift
//  MagSafe Guard
//
//  Created on 2025-07-26.
//

@testable import MagSafeGuard
import XCTest

final class PowerMonitorCoreTests: XCTestCase {

    var core: PowerMonitorCore!

    override func setUp() {
        super.setUp()
        core = PowerMonitorCore()
    }

    override func tearDown() {
        core = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization() {
        XCTAssertNil(core.currentPowerInfo)
        XCTAssertEqual(core.pollingInterval, 1.0)
    }

    func testCustomPollingInterval() {
        let customCore = PowerMonitorCore(pollingInterval: 0.5)
        XCTAssertEqual(customCore.pollingInterval, 0.5)
    }

    // MARK: - Power Source Processing Tests

    func testProcessPowerSourceInfoConnected() {
        let sources = [[
            "Power Source State": "AC Power",
            "Current Capacity": 85,
            "Max Capacity": 100,
            "Is Charging": true,
            "AdapterInfo": 96
        ]]

        let info = core.processPowerSourceInfo(sources)

        XCTAssertNotNil(info)
        XCTAssertEqual(info?.state, .connected)
        XCTAssertEqual(info?.batteryLevel, 85)
        XCTAssertTrue(info?.isCharging ?? false)
        XCTAssertEqual(info?.adapterWattage, 96)
        XCTAssertNotNil(info?.timestamp)
    }

    func testProcessPowerSourceInfoDisconnected() {
        let sources = [[
            "Power Source State": "Battery Power",
            "Current Capacity": 50,
            "Max Capacity": 100,
            "Is Charging": false
        ]]

        let info = core.processPowerSourceInfo(sources)

        XCTAssertNotNil(info)
        XCTAssertEqual(info?.state, .disconnected)
        XCTAssertEqual(info?.batteryLevel, 50)
        XCTAssertFalse(info?.isCharging ?? true)
        XCTAssertNil(info?.adapterWattage)
    }

    func testProcessPowerSourceInfoWithAdapterDetails() {
        let sources = [[
            "Power Source State": "AC Power",
            "Current Capacity": 100,
            "Max Capacity": 100,
            "Is Charging": false,
            "AdapterDetails": ["Watts": 140]
        ]]

        let info = core.processPowerSourceInfo(sources)

        XCTAssertNotNil(info)
        XCTAssertEqual(info?.state, .connected)
        XCTAssertEqual(info?.adapterWattage, 140)
    }

    func testProcessPowerSourceInfoEmpty() {
        let sources: [[String: Any]] = []

        let info = core.processPowerSourceInfo(sources)

        XCTAssertNotNil(info)
        XCTAssertEqual(info?.state, .disconnected)
        XCTAssertNil(info?.batteryLevel)
        XCTAssertFalse(info?.isCharging ?? true)
    }

    func testProcessPowerSourceInfoInvalidBattery() {
        let sources = [[
            "Power Source State": "AC Power",
            "Current Capacity": 50,
            "Max Capacity": 0, // Invalid max capacity
            "Is Charging": true
        ]]

        let info = core.processPowerSourceInfo(sources)

        XCTAssertNotNil(info)
        XCTAssertEqual(info?.state, .connected)
        XCTAssertNil(info?.batteryLevel) // Should be nil due to invalid max capacity
    }

    // MARK: - State Change Detection Tests

    func testHasPowerStateChangedFirstReading() {
        let info = PowerMonitorCore.PowerInfo(
            state: .connected,
            batteryLevel: 80,
            isCharging: true,
            adapterWattage: 96,
            timestamp: Date()
        )

        XCTAssertTrue(core.hasPowerStateChanged(newInfo: info))
        XCTAssertNotNil(core.currentPowerInfo)
        XCTAssertEqual(core.currentPowerInfo?.state, .connected)
    }

    func testHasPowerStateChangedSameState() {
        // First reading
        let info1 = PowerMonitorCore.PowerInfo(
            state: .connected,
            batteryLevel: 80,
            isCharging: true,
            adapterWattage: 96,
            timestamp: Date()
        )
        XCTAssertTrue(core.hasPowerStateChanged(newInfo: info1))

        // Same state, different battery level
        let info2 = PowerMonitorCore.PowerInfo(
            state: .connected,
            batteryLevel: 79,
            isCharging: true,
            adapterWattage: 96,
            timestamp: Date()
        )
        XCTAssertFalse(core.hasPowerStateChanged(newInfo: info2))

        // Current info should be updated
        XCTAssertEqual(core.currentPowerInfo?.batteryLevel, 79)
    }

    func testHasPowerStateChangedDifferentState() {
        // First reading - connected
        let info1 = PowerMonitorCore.PowerInfo(
            state: .connected,
            batteryLevel: 80,
            isCharging: true,
            adapterWattage: 96,
            timestamp: Date()
        )
        XCTAssertTrue(core.hasPowerStateChanged(newInfo: info1))

        // State change to disconnected
        let info2 = PowerMonitorCore.PowerInfo(
            state: .disconnected,
            batteryLevel: 79,
            isCharging: false,
            adapterWattage: nil,
            timestamp: Date()
        )
        XCTAssertTrue(core.hasPowerStateChanged(newInfo: info2))
        XCTAssertEqual(core.currentPowerInfo?.state, .disconnected)
    }

    // MARK: - Objective-C Compatibility Tests

    func testGetBatteryLevelWithInfo() {
        let info = PowerMonitorCore.PowerInfo(
            state: .connected,
            batteryLevel: 75,
            isCharging: true,
            adapterWattage: 96,
            timestamp: Date()
        )
        _ = core.hasPowerStateChanged(newInfo: info)

        XCTAssertEqual(core.getBatteryLevel(), 75)
    }

    func testGetBatteryLevelWithoutInfo() {
        XCTAssertEqual(core.getBatteryLevel(), -1)
    }

    func testIsPowerConnectedWithInfo() {
        let info = PowerMonitorCore.PowerInfo(
            state: .connected,
            batteryLevel: 75,
            isCharging: true,
            adapterWattage: 96,
            timestamp: Date()
        )
        _ = core.hasPowerStateChanged(newInfo: info)

        XCTAssertTrue(core.isPowerConnected())
    }

    func testIsPowerDisconnectedWithInfo() {
        let info = PowerMonitorCore.PowerInfo(
            state: .disconnected,
            batteryLevel: 75,
            isCharging: false,
            adapterWattage: nil,
            timestamp: Date()
        )
        _ = core.hasPowerStateChanged(newInfo: info)

        XCTAssertFalse(core.isPowerConnected())
    }

    func testIsPowerConnectedWithoutInfo() {
        XCTAssertFalse(core.isPowerConnected())
    }

    // MARK: - Reset Tests

    func testReset() {
        // Set some state
        let info = PowerMonitorCore.PowerInfo(
            state: .connected,
            batteryLevel: 75,
            isCharging: true,
            adapterWattage: 96,
            timestamp: Date()
        )
        _ = core.hasPowerStateChanged(newInfo: info)
        XCTAssertNotNil(core.currentPowerInfo)

        // Reset
        core.reset()
        XCTAssertNil(core.currentPowerInfo)
        XCTAssertEqual(core.getBatteryLevel(), -1)
        XCTAssertFalse(core.isPowerConnected())
    }

    // MARK: - PowerState Tests

    func testPowerStateRawValues() {
        XCTAssertEqual(PowerMonitorCore.PowerState.connected.rawValue, "connected")
        XCTAssertEqual(PowerMonitorCore.PowerState.disconnected.rawValue, "disconnected")
    }

    func testPowerStateDescriptions() {
        XCTAssertEqual(PowerMonitorCore.PowerState.connected.description, "Power adapter connected")
        XCTAssertEqual(PowerMonitorCore.PowerState.disconnected.description, "Power adapter disconnected")
    }

    // MARK: - PowerInfo Tests

    func testPowerInfoEquality() {
        let date = Date()
        let info1 = PowerMonitorCore.PowerInfo(
            state: .connected,
            batteryLevel: 80,
            isCharging: true,
            adapterWattage: 96,
            timestamp: date
        )

        let info2 = PowerMonitorCore.PowerInfo(
            state: .connected,
            batteryLevel: 80,
            isCharging: true,
            adapterWattage: 96,
            timestamp: date
        )

        XCTAssertEqual(info1, info2)
    }

    func testPowerInfoInequality() {
        let date = Date()
        let info1 = PowerMonitorCore.PowerInfo(
            state: .connected,
            batteryLevel: 80,
            isCharging: true,
            adapterWattage: 96,
            timestamp: date
        )

        let info2 = PowerMonitorCore.PowerInfo(
            state: .disconnected, // Different state
            batteryLevel: 80,
            isCharging: true,
            adapterWattage: 96,
            timestamp: date
        )

        XCTAssertNotEqual(info1, info2)
    }

    // MARK: - Edge Cases

    func testMultiplePowerSources() {
        let sources = [
            [
                "Power Source State": "Battery Power",
                "Current Capacity": 50,
                "Max Capacity": 100,
                "Is Charging": false
            ],
            [
                "Power Source State": "AC Power",
                "Current Capacity": 85,
                "Max Capacity": 100,
                "Is Charging": true,
                "AdapterInfo": 96
            ]
        ]

        let info = core.processPowerSourceInfo(sources)

        // Should use the last source (AC power)
        XCTAssertNotNil(info)
        XCTAssertEqual(info?.state, .connected)
        XCTAssertEqual(info?.batteryLevel, 85)
    }
}
