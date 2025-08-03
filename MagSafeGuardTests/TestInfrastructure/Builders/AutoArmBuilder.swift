//
//  AutoArmBuilder.swift
//  MagSafe Guard
//
//  Created on 2025-08-03.
//
//  Test builders for creating auto-arm test data.
//  Provides fluent APIs for constructing test instances with sensible defaults.
//

import Foundation
@testable import MagSafeGuard

/// Builder for creating AutoArmConfiguration test instances.
public final class AutoArmConfigurationBuilder {
    private var isEnabled: Bool = true
    private var armByLocation: Bool = true
    private var armOnUntrustedNetwork: Bool = true
    private var armCooldownPeriod: TimeInterval = 30
    private var notifyBeforeArming: Bool = true
    private var notificationDelay: TimeInterval = 2.0
    
    /// Initialize a new auto-arm configuration builder.
    public init() {}
    
    /// Enable or disable auto-arm.
    /// - Parameter enabled: Whether auto-arm is enabled
    /// - Returns: Self for chaining
    @discardableResult
    public func enabled(_ enabled: Bool) -> AutoArmConfigurationBuilder {
        self.isEnabled = enabled
        return self
    }
    
    /// Enable location-based arming.
    /// - Parameter enabled: Whether to arm by location
    /// - Returns: Self for chaining
    @discardableResult
    public func armByLocation(_ enabled: Bool) -> AutoArmConfigurationBuilder {
        self.armByLocation = enabled
        return self
    }
    
    /// Enable network-based arming.
    /// - Parameter enabled: Whether to arm on untrusted networks
    /// - Returns: Self for chaining
    @discardableResult
    public func armOnUntrustedNetwork(_ enabled: Bool) -> AutoArmConfigurationBuilder {
        self.armOnUntrustedNetwork = enabled
        return self
    }
    
    /// Set cooldown period.
    /// - Parameter period: Cooldown in seconds
    /// - Returns: Self for chaining
    @discardableResult
    public func cooldownPeriod(_ period: TimeInterval) -> AutoArmConfigurationBuilder {
        self.armCooldownPeriod = period
        return self
    }
    
    /// Enable notification before arming.
    /// - Parameter notify: Whether to notify
    /// - Returns: Self for chaining
    @discardableResult
    public func notifyBeforeArming(_ notify: Bool) -> AutoArmConfigurationBuilder {
        self.notifyBeforeArming = notify
        return self
    }
    
    /// Set notification delay.
    /// - Parameter delay: Delay in seconds
    /// - Returns: Self for chaining
    @discardableResult
    public func notificationDelay(_ delay: TimeInterval) -> AutoArmConfigurationBuilder {
        self.notificationDelay = delay
        return self
    }
    
    /// Build the AutoArmConfiguration instance.
    /// - Returns: Configured AutoArmConfiguration
    public func build() -> AutoArmConfiguration {
        return AutoArmConfiguration(
            isEnabled: isEnabled,
            armByLocation: armByLocation,
            armOnUntrustedNetwork: armOnUntrustedNetwork,
            armCooldownPeriod: armCooldownPeriod,
            notifyBeforeArming: notifyBeforeArming,
            notificationDelay: notificationDelay
        )
    }
    
    // MARK: - Preset Configurations
    
    /// Create location-only preset.
    /// - Returns: Configured builder
    public static func locationOnly() -> AutoArmConfigurationBuilder {
        return AutoArmConfigurationBuilder()
            .enabled(true)
            .armByLocation(true)
            .armOnUntrustedNetwork(false)
    }
    
    /// Create network-only preset.
    /// - Returns: Configured builder
    public static func networkOnly() -> AutoArmConfigurationBuilder {
        return AutoArmConfigurationBuilder()
            .enabled(true)
            .armByLocation(false)
            .armOnUntrustedNetwork(true)
    }
    
    /// Create testing preset (fast timers).
    /// - Returns: Configured builder
    public static func testing() -> AutoArmConfigurationBuilder {
        return AutoArmConfigurationBuilder()
            .enabled(true)
            .cooldownPeriod(1)
            .notificationDelay(0.1)
    }
}

/// Builder for creating TrustedLocationDomain test instances.
public final class TrustedLocationBuilder {
    private var id: UUID = UUID()
    private var name: String = "Test Location"
    private var latitude: Double = 37.7749
    private var longitude: Double = -122.4194
    private var radius: Double = 100.0
    
    /// Initialize a new trusted location builder.
    public init() {}
    
    /// Set the location ID.
    /// - Parameter id: Unique identifier
    /// - Returns: Self for chaining
    @discardableResult
    public func id(_ id: UUID) -> TrustedLocationBuilder {
        self.id = id
        return self
    }
    
    /// Set the location name.
    /// - Parameter name: Location name
    /// - Returns: Self for chaining
    @discardableResult
    public func name(_ name: String) -> TrustedLocationBuilder {
        self.name = name
        return self
    }
    
    /// Set the coordinates.
    /// - Parameters:
    ///   - latitude: Latitude
    ///   - longitude: Longitude
    /// - Returns: Self for chaining
    @discardableResult
    public func coordinates(latitude: Double, longitude: Double) -> TrustedLocationBuilder {
        self.latitude = latitude
        self.longitude = longitude
        return self
    }
    
    /// Set the trust radius.
    /// - Parameter radius: Radius in meters
    /// - Returns: Self for chaining
    @discardableResult
    public func radius(_ radius: Double) -> TrustedLocationBuilder {
        self.radius = radius
        return self
    }
    
    /// Build the TrustedLocationDomain instance.
    /// - Returns: Configured TrustedLocationDomain
    public func build() -> TrustedLocationDomain {
        return TrustedLocationDomain(
            id: id,
            name: name,
            latitude: latitude,
            longitude: longitude,
            radius: radius
        )
    }
    
    // MARK: - Preset Locations
    
    /// Create home location preset.
    /// - Returns: Configured builder
    public static func home() -> TrustedLocationBuilder {
        return TrustedLocationBuilder()
            .name("Home")
            .coordinates(latitude: 37.7749, longitude: -122.4194)
            .radius(50)
    }
    
    /// Create office location preset.
    /// - Returns: Configured builder
    public static func office() -> TrustedLocationBuilder {
        return TrustedLocationBuilder()
            .name("Office")
            .coordinates(latitude: 37.7858, longitude: -122.4065)
            .radius(100)
    }
    
    /// Create cafe location preset.
    /// - Returns: Configured builder
    public static func cafe() -> TrustedLocationBuilder {
        return TrustedLocationBuilder()
            .name("Coffee Shop")
            .coordinates(latitude: 37.7699, longitude: -122.4469)
            .radius(25)
    }
}

/// Builder for creating TrustedNetwork test instances.
public final class TrustedNetworkBuilder {
    private var ssid: String = "TestNetwork"
    private var addedDate: Date = Date()
    
    /// Initialize a new trusted network builder.
    public init() {}
    
    /// Set the network SSID.
    /// - Parameter ssid: Network name
    /// - Returns: Self for chaining
    @discardableResult
    public func ssid(_ ssid: String) -> TrustedNetworkBuilder {
        self.ssid = ssid
        return self
    }
    
    /// Set when the network was added.
    /// - Parameter date: Added date
    /// - Returns: Self for chaining
    @discardableResult
    public func addedDate(_ date: Date) -> TrustedNetworkBuilder {
        self.addedDate = date
        return self
    }
    
    /// Build the TrustedNetwork instance.
    /// - Returns: Configured TrustedNetwork
    public func build() -> TrustedNetwork {
        return TrustedNetwork(
            ssid: ssid,
            addedDate: addedDate
        )
    }
    
    // MARK: - Preset Networks
    
    /// Create home WiFi preset.
    /// - Returns: Configured builder
    public static func homeWiFi() -> TrustedNetworkBuilder {
        return TrustedNetworkBuilder()
            .ssid("HomeNetwork")
    }
    
    /// Create office WiFi preset.
    /// - Returns: Configured builder
    public static func officeWiFi() -> TrustedNetworkBuilder {
        return TrustedNetworkBuilder()
            .ssid("CorporateNetwork")
    }
    
    /// Create public WiFi preset.
    /// - Returns: Configured builder
    public static func publicWiFi() -> TrustedNetworkBuilder {
        return TrustedNetworkBuilder()
            .ssid("StarbucksWiFi")
    }
}

/// Builder for creating AutoArmEvent test instances.
public final class AutoArmEventBuilder {
    private var trigger: AutoArmTrigger = .manual(reason: "Test")
    private var timestamp: Date = Date()
    private var configuration: AutoArmConfiguration = .default
    
    /// Initialize a new auto-arm event builder.
    public init() {}
    
    /// Set the trigger.
    /// - Parameter trigger: What triggered the event
    /// - Returns: Self for chaining
    @discardableResult
    public func trigger(_ trigger: AutoArmTrigger) -> AutoArmEventBuilder {
        self.trigger = trigger
        return self
    }
    
    /// Set left trusted location trigger.
    /// - Parameter name: Location name
    /// - Returns: Self for chaining
    @discardableResult
    public func leftLocation(_ name: String? = nil) -> AutoArmEventBuilder {
        self.trigger = .leftTrustedLocation(name: name)
        return self
    }
    
    /// Set entered untrusted network trigger.
    /// - Parameter ssid: Network SSID
    /// - Returns: Self for chaining
    @discardableResult
    public func enteredUntrustedNetwork(_ ssid: String) -> AutoArmEventBuilder {
        self.trigger = .enteredUntrustedNetwork(ssid: ssid)
        return self
    }
    
    /// Set the timestamp.
    /// - Parameter timestamp: Event timestamp
    /// - Returns: Self for chaining
    @discardableResult
    public func timestamp(_ timestamp: Date) -> AutoArmEventBuilder {
        self.timestamp = timestamp
        return self
    }
    
    /// Set the configuration.
    /// - Parameter configuration: Auto-arm configuration
    /// - Returns: Self for chaining
    @discardableResult
    public func configuration(_ configuration: AutoArmConfiguration) -> AutoArmEventBuilder {
        self.configuration = configuration
        return self
    }
    
    /// Build the AutoArmEvent instance.
    /// - Returns: Configured AutoArmEvent
    public func build() -> AutoArmEvent {
        return AutoArmEvent(
            trigger: trigger,
            timestamp: timestamp,
            configuration: configuration
        )
    }
}

/// Builder for creating NetworkInfo test instances.
public final class NetworkInfoBuilder {
    private var isConnected: Bool = true
    private var currentSSID: String? = "TestNetwork"
    private var isTrusted: Bool = true
    
    /// Initialize a new network info builder.
    public init() {}
    
    /// Set connection status.
    /// - Parameter connected: Whether connected
    /// - Returns: Self for chaining
    @discardableResult
    public func connected(_ connected: Bool) -> NetworkInfoBuilder {
        self.isConnected = connected
        if !connected {
            self.currentSSID = nil
        }
        return self
    }
    
    /// Set current SSID.
    /// - Parameter ssid: Network SSID
    /// - Returns: Self for chaining
    @discardableResult
    public func ssid(_ ssid: String?) -> NetworkInfoBuilder {
        self.currentSSID = ssid
        return self
    }
    
    /// Set trust status.
    /// - Parameter trusted: Whether network is trusted
    /// - Returns: Self for chaining
    @discardableResult
    public func trusted(_ trusted: Bool) -> NetworkInfoBuilder {
        self.isTrusted = trusted
        return self
    }
    
    /// Build the NetworkInfo instance.
    /// - Returns: Configured NetworkInfo
    public func build() -> NetworkInfo {
        return NetworkInfo(
            isConnected: isConnected,
            currentSSID: currentSSID,
            isTrusted: isTrusted
        )
    }
    
    // MARK: - Preset Configurations
    
    /// Create trusted network preset.
    /// - Returns: Configured builder
    public static func trustedNetwork() -> NetworkInfoBuilder {
        return NetworkInfoBuilder()
            .connected(true)
            .ssid("TrustedNetwork")
            .trusted(true)
    }
    
    /// Create untrusted network preset.
    /// - Returns: Configured builder
    public static func untrustedNetwork() -> NetworkInfoBuilder {
        return NetworkInfoBuilder()
            .connected(true)
            .ssid("PublicWiFi")
            .trusted(false)
    }
    
    /// Create disconnected preset.
    /// - Returns: Configured builder
    public static func disconnected() -> NetworkInfoBuilder {
        return NetworkInfoBuilder()
            .connected(false)
            .ssid(nil)
            .trusted(false)
    }
}