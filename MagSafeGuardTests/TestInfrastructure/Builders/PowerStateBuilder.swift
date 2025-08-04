//
//  PowerStateBuilder.swift
//  MagSafe Guard
//
//  Created on 2025-08-03.
//
//  Test builder for creating PowerStateInfo instances in tests.
//  Provides a fluent API for constructing test data with sensible defaults.
//

import Foundation
@testable import MagSafeGuardDomain
@testable import MagSafeGuardCore

/// Builder for creating PowerStateInfo test instances.
/// Provides fluent API for setting up test data with sensible defaults.
public final class PowerStateBuilder {

    // MARK: - Properties

    private var isConnected: Bool = true
    private var batteryLevel: Int? = 80
    private var isCharging: Bool = true
    private var adapterWattage: Int? = 96
    private var timestamp = Date()

    // MARK: - Initialization

    /// Initialize a new power state builder with defaults.
    public init() {}

    // MARK: - Builder Methods

    /// Set the connected state.
    /// - Parameter connected: Whether power is connected
    /// - Returns: Self for chaining
    @discardableResult
    public func connected(_ connected: Bool) -> PowerStateBuilder {
        self.isConnected = connected
        return self
    }

    /// Set as disconnected (convenience method).
    /// - Returns: Self for chaining
    @discardableResult
    public func disconnected() -> PowerStateBuilder {
        self.isConnected = false
        self.isCharging = false
        return self
    }

    /// Set the battery level.
    /// - Parameter level: Battery percentage (0-100)
    /// - Returns: Self for chaining
    @discardableResult
    public func batteryLevel(_ level: Int?) -> PowerStateBuilder {
        self.batteryLevel = level
        return self
    }

    /// Set the charging state.
    /// - Parameter charging: Whether battery is charging
    /// - Returns: Self for chaining
    @discardableResult
    public func charging(_ charging: Bool) -> PowerStateBuilder {
        self.isCharging = charging
        return self
    }

    /// Set the adapter wattage.
    /// - Parameter wattage: Adapter power in watts
    /// - Returns: Self for chaining
    @discardableResult
    public func adapterWattage(_ wattage: Int?) -> PowerStateBuilder {
        self.adapterWattage = wattage
        return self
    }

    /// Set the timestamp.
    /// - Parameter timestamp: When the state was captured
    /// - Returns: Self for chaining
    @discardableResult
    public func timestamp(_ timestamp: Date) -> PowerStateBuilder {
        self.timestamp = timestamp
        return self
    }

    /// Build the PowerStateInfo instance.
    /// - Returns: Configured PowerStateInfo
    public func build() -> PowerStateInfo {
        return PowerStateInfo(
            isConnected: isConnected,
            batteryLevel: batteryLevel,
            isCharging: isCharging,
            adapterWattage: adapterWattage,
            timestamp: timestamp
        )
    }

    // MARK: - Preset Configurations

    /// Create a builder preset for AC connected state.
    /// - Returns: Configured builder
    public static func acConnected() -> PowerStateBuilder {
        return PowerStateBuilder()
            .connected(true)
            .charging(true)
            .batteryLevel(80)
            .adapterWattage(96)
    }

    /// Create a builder preset for battery power state.
    /// - Returns: Configured builder
    public static func onBattery() -> PowerStateBuilder {
        return PowerStateBuilder()
            .connected(false)
            .charging(false)
            .batteryLevel(75)
            .adapterWattage(nil)
    }

    /// Create a builder preset for low battery state.
    /// - Returns: Configured builder
    public static func lowBattery() -> PowerStateBuilder {
        return PowerStateBuilder()
            .connected(false)
            .charging(false)
            .batteryLevel(15)
            .adapterWattage(nil)
    }

    /// Create a builder preset for critical battery state.
    /// - Returns: Configured builder
    public static func criticalBattery() -> PowerStateBuilder {
        return PowerStateBuilder()
            .connected(false)
            .charging(false)
            .batteryLevel(5)
            .adapterWattage(nil)
    }
}

// MARK: - Convenience Extensions

extension PowerStateInfo {
    /// Create a test instance using a builder.
    /// - Parameter configure: Configuration closure
    /// - Returns: Configured PowerStateInfo
    public static func testInstance(
        configure: (PowerStateBuilder) -> PowerStateBuilder = { $0 }
    ) -> PowerStateInfo {
        let builder = PowerStateBuilder()
        return configure(builder).build()
    }
}
