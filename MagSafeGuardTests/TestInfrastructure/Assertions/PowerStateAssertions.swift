//
//  PowerStateAssertions.swift
//  MagSafe Guard
//
//  Created on 2025-08-03.
//
//  Custom assertions for power state testing with Swift Testing.
//  Provides domain-specific assertions for clearer test intent.
//

import Foundation
@testable import MagSafeGuardDomain
@testable import MagSafeGuardCore
import Testing

/// Custom assertions for power state testing
public struct PowerStateAssertions {

    /// Assert that power is connected
    /// - Parameters:
    ///   - state: Power state to check
    ///   - sourceLocation: Source location for test failure
    public static func assertConnected(
        _ state: PowerStateInfo,
        sourceLocation: SourceLocation = SourceLocation()
    ) {
        #expect(
            state.isConnected,
            "Expected power to be connected but was disconnected",
            sourceLocation: sourceLocation
        )
    }

    /// Assert that power is disconnected
    /// - Parameters:
    ///   - state: Power state to check
    ///   - sourceLocation: Source location for test failure
    public static func assertDisconnected(
        _ state: PowerStateInfo,
        sourceLocation: SourceLocation = SourceLocation()
    ) {
        #expect(
            !state.isConnected,
            "Expected power to be disconnected but was connected",
            sourceLocation: sourceLocation
        )
    }

    /// Assert battery level is within range
    /// - Parameters:
    ///   - state: Power state to check
    ///   - range: Expected battery level range
    ///   - sourceLocation: Source location for test failure
    public static func assertBatteryLevel(
        _ state: PowerStateInfo,
        in range: ClosedRange<Int>,
        sourceLocation: SourceLocation = SourceLocation()
    ) {
        guard let batteryLevel = state.batteryLevel else {
            Issue.record(
                "Battery level is nil",
                sourceLocation: sourceLocation
            )
            return
        }

        #expect(
            range.contains(batteryLevel),
            "Expected battery level to be in range \(range) but was \(batteryLevel)",
            sourceLocation: sourceLocation
        )
    }

    /// Assert charging state
    /// - Parameters:
    ///   - state: Power state to check
    ///   - isCharging: Expected charging state
    ///   - sourceLocation: Source location for test failure
    public static func assertCharging(
        _ state: PowerStateInfo,
        is isCharging: Bool,
        sourceLocation: SourceLocation = SourceLocation()
    ) {
        #expect(
            state.isCharging == isCharging,
            "Expected charging to be \(isCharging) but was \(state.isCharging)",
            sourceLocation: sourceLocation
        )
    }

    /// Assert power state change type
    /// - Parameters:
    ///   - change: Power state change to check
    ///   - expectedType: Expected change type
    ///   - sourceLocation: Source location for test failure
    public static func assertChangeType(
        _ change: PowerStateChange,
        is expectedType: PowerStateChange.ChangeType,
        sourceLocation: SourceLocation = SourceLocation()
    ) {
        #expect(
            change.changeType == expectedType,
            "Expected change type \(expectedType) but was \(change.changeType)",
            sourceLocation: sourceLocation
        )
    }

    /// Assert AC disconnection occurred
    /// - Parameters:
    ///   - change: Power state change to check
    ///   - sourceLocation: Source location for test failure
    public static func assertACDisconnection(
        _ change: PowerStateChange,
        sourceLocation: SourceLocation = SourceLocation()
    ) {
        assertChangeType(change, is: .disconnected, sourceLocation: sourceLocation)
        assertConnected(change.previousState, sourceLocation: sourceLocation)
        assertDisconnected(change.currentState, sourceLocation: sourceLocation)
    }

    /// Assert AC connection occurred
    /// - Parameters:
    ///   - change: Power state change to check
    ///   - sourceLocation: Source location for test failure
    public static func assertACConnection(
        _ change: PowerStateChange,
        sourceLocation: SourceLocation = SourceLocation()
    ) {
        assertChangeType(change, is: .connected, sourceLocation: sourceLocation)
        assertDisconnected(change.previousState, sourceLocation: sourceLocation)
        assertConnected(change.currentState, sourceLocation: sourceLocation)
    }
}

// MARK: - Async Stream Assertions

extension PowerStateAssertions {

    /// Assert that a power state change occurs within timeout
    /// - Parameters:
    ///   - stream: Stream to observe
    ///   - timeout: Timeout duration
    ///   - condition: Condition to check
    ///   - sourceLocation: Source location for test failure
    /// - Returns: The matching state change if found
    @discardableResult
    public static func assertChangeOccurs(
        in stream: AsyncStream<PowerStateChange>,
        timeout: TimeInterval = 1.0,
        matching condition: @escaping (PowerStateChange) -> Bool,
        sourceLocation: SourceLocation = SourceLocation()
    ) async -> PowerStateChange? {
        let deadline = Date().addingTimeInterval(timeout)

        for await change in stream {
            if condition(change) {
                return change
            }

            if Date() > deadline {
                Issue.record(
                    "Timeout waiting for power state change matching condition",
                    sourceLocation: sourceLocation
                )
                return nil
            }
        }

        Issue.record(
            "Stream ended without matching power state change",
            sourceLocation: sourceLocation
        )
        return nil
    }

    /// Assert that AC disconnection occurs in stream
    /// - Parameters:
    ///   - stream: Stream to observe
    ///   - timeout: Timeout duration
    ///   - sourceLocation: Source location for test failure
    /// - Returns: The disconnection event if found
    @discardableResult
    public static func assertDisconnectionOccurs(
        in stream: AsyncStream<PowerStateChange>,
        timeout: TimeInterval = 1.0,
        sourceLocation: SourceLocation = SourceLocation()
    ) async -> PowerStateChange? {
        return await assertChangeOccurs(
            in: stream,
            timeout: timeout,
            matching: { $0.changeType == .disconnected },
            sourceLocation: sourceLocation
        )
    }
}

// MARK: - Convenience Extensions

/// Extension for more natural assertion syntax
extension PowerStateInfo {

    /// Assert this state is connected
    /// - Parameter sourceLocation: Source location for test failure
    public func assertConnected(
        sourceLocation: SourceLocation = SourceLocation()
    ) {
        PowerStateAssertions.assertConnected(self, sourceLocation: sourceLocation)
    }

    /// Assert this state is disconnected
    /// - Parameter sourceLocation: Source location for test failure
    public func assertDisconnected(
        sourceLocation: SourceLocation = SourceLocation()
    ) {
        PowerStateAssertions.assertDisconnected(self, sourceLocation: sourceLocation)
    }

    /// Assert battery level is in range
    /// - Parameters:
    ///   - range: Expected range
    ///   - sourceLocation: Source location for test failure
    public func assertBatteryLevel(
        in range: ClosedRange<Int>,
        sourceLocation: SourceLocation = SourceLocation()
    ) {
        PowerStateAssertions.assertBatteryLevel(self, in: range, sourceLocation: sourceLocation)
    }
}

/// Extension for power state change assertions
extension PowerStateChange {

    /// Assert this is an AC disconnection
    /// - Parameter sourceLocation: Source location for test failure
    public func assertIsDisconnection(
        sourceLocation: SourceLocation = SourceLocation()
    ) {
        PowerStateAssertions.assertACDisconnection(self, sourceLocation: sourceLocation)
    }

    /// Assert this is an AC connection
    /// - Parameter sourceLocation: Source location for test failure
    public func assertIsConnection(
        sourceLocation: SourceLocation = SourceLocation()
    ) {
        PowerStateAssertions.assertACConnection(self, sourceLocation: sourceLocation)
    }
}
