//
//  AutoArmProtocols.swift
//  MagSafe Guard
//
//  Created on 2025-08-03.
//

import Foundation

// MARK: - Domain Models

/// Configuration for auto-arm behavior
public struct AutoArmConfiguration: Equatable, Sendable {
    /// Whether auto-arm is enabled
    public let isEnabled: Bool

    /// Enable arming based on location changes
    public let armByLocation: Bool

    /// Enable arming when connecting to untrusted networks
    public let armOnUntrustedNetwork: Bool

    /// Minimum time between auto-arm activations (seconds)
    public let armCooldownPeriod: TimeInterval

    /// Show notification before arming
    public let notifyBeforeArming: Bool

    /// Delay before arming after notification (seconds)
    public let notificationDelay: TimeInterval

    /// Initializes auto-arm configuration
    /// - Parameters:
    ///   - isEnabled: Whether auto-arm is enabled
    ///   - armByLocation: Enable location-based arming
    ///   - armOnUntrustedNetwork: Enable network-based arming
    ///   - armCooldownPeriod: Minimum time between auto-arms
    ///   - notifyBeforeArming: Show notification before arming
    ///   - notificationDelay: Delay after notification
    public init(
        isEnabled: Bool = false,
        armByLocation: Bool = false,
        armOnUntrustedNetwork: Bool = false,
        armCooldownPeriod: TimeInterval = 30,
        notifyBeforeArming: Bool = true,
        notificationDelay: TimeInterval = 2.0
    ) {
        self.isEnabled = isEnabled
        self.armByLocation = armByLocation
        self.armOnUntrustedNetwork = armOnUntrustedNetwork
        self.armCooldownPeriod = max(armCooldownPeriod, 0)
        self.notifyBeforeArming = notifyBeforeArming
        self.notificationDelay = max(notificationDelay, 0)
    }

    /// Default configuration with auto-arm disabled
    public static let `default` = AutoArmConfiguration()
}

/// Trigger that caused auto-arm activation
public enum AutoArmTrigger: Equatable, Sendable {
    /// Left a trusted location
    case leftTrustedLocation(name: String?)
    /// Connected to an untrusted network
    case enteredUntrustedNetwork(ssid: String)
    /// Disconnected from a trusted network
    case disconnectedFromTrustedNetwork(ssid: String)
    /// Lost all network connectivity
    case lostNetworkConnectivity
    /// Manual trigger with reason
    case manual(reason: String)

    /// Human-readable description of the trigger.
    public var description: String {
        switch self {
        case .leftTrustedLocation(let name):
            return name.map { "Left trusted location: \($0)" } ?? "Left trusted location"
        case .enteredUntrustedNetwork(let ssid):
            return "Connected to untrusted network: \(ssid)"
        case .disconnectedFromTrustedNetwork(let ssid):
            return "Disconnected from trusted network: \(ssid)"
        case .lostNetworkConnectivity:
            return "Lost network connectivity"
        case .manual(let reason):
            return reason
        }
    }
}

/// Auto-arm event for tracking and decision making
public struct AutoArmEvent: Equatable, Sendable {
    /// The trigger that caused this event
    public let trigger: AutoArmTrigger
    /// When the event occurred
    public let timestamp: Date
    /// Configuration at time of event
    public let configuration: AutoArmConfiguration

    /// Initializes an auto-arm event
    /// - Parameters:
    ///   - trigger: The trigger that caused this event
    ///   - timestamp: When the event occurred
    ///   - configuration: Configuration at time of event
    public init(
        trigger: AutoArmTrigger,
        timestamp: Date = Date(),
        configuration: AutoArmConfiguration
    ) {
        self.trigger = trigger
        self.timestamp = timestamp
        self.configuration = configuration
    }
}

/// Result of auto-arm decision
public enum AutoArmDecision: Equatable, Sendable {
    /// Decision to arm with reason
    case arm(reason: String)
    /// Decision to skip arming with reason
    case skip(reason: AutoArmSkipReason)

    /// Whether the decision is to arm
    public var shouldArm: Bool {
        if case .arm = self { return true }
        return false
    }
}

/// Reasons for skipping auto-arm
public enum AutoArmSkipReason: Equatable, Sendable {
    /// Auto-arm feature is disabled
    case disabled
    /// System is already armed
    case alreadyArmed
    /// Auto-arm temporarily disabled until date
    case temporarilyDisabled(until: Date)
    /// In cooldown period until date
    case cooldownPeriod(until: Date)
    /// Required conditions not met
    case conditionNotMet

    /// Human-readable explanation of skip reason.
    public var description: String {
        switch self {
        case .disabled:
            return "Auto-arm is disabled"
        case .alreadyArmed:
            return "System is already armed"
        case .temporarilyDisabled(let date):
            let formatter = RelativeDateTimeFormatter()
            return "Temporarily disabled until \(formatter.localizedString(for: date, relativeTo: Date()))"
        case .cooldownPeriod(let date):
            let formatter = RelativeDateTimeFormatter()
            return "In cooldown period until \(formatter.localizedString(for: date, relativeTo: Date()))"
        case .conditionNotMet:
            return "Auto-arm conditions not met"
        }
    }
}

/// Trusted location for auto-arm
public struct TrustedLocationDomain: Equatable, Sendable {
    /// Unique identifier
    public let id: UUID
    /// User-friendly name
    public let name: String
    /// Location latitude
    public let latitude: Double
    /// Location longitude
    public let longitude: Double
    /// Trust radius in meters
    public let radius: Double

    /// Initializes a trusted location
    /// - Parameters:
    ///   - id: Unique identifier
    ///   - name: User-friendly name
    ///   - latitude: Location latitude
    ///   - longitude: Location longitude
    ///   - radius: Trust radius in meters (minimum 10m)
    public init(
        id: UUID = UUID(),
        name: String,
        latitude: Double,
        longitude: Double,
        radius: Double = 100.0
    ) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.radius = max(radius, 10) // Minimum 10 meter radius
    }
}

/// Trusted network for auto-arm
public struct TrustedNetwork: Equatable, Sendable {
    /// Network SSID
    public let ssid: String
    /// When the network was added as trusted
    public let addedDate: Date

    /// Initializes a trusted network
    /// - Parameters:
    ///   - ssid: Network SSID
    ///   - addedDate: When added as trusted
    public init(
        ssid: String,
        addedDate: Date = Date()
    ) {
        self.ssid = ssid
        self.addedDate = addedDate
    }
}

// MARK: - Repository Protocols

/// Repository for location monitoring
public protocol LocationRepository {
    /// Start monitoring location changes
    func startMonitoring() async throws

    /// Stop monitoring location changes
    func stopMonitoring() async

    /// Get current location trust status
    func isInTrustedLocation() async -> Bool

    /// Add a trusted location
    func addTrustedLocation(_ location: TrustedLocationDomain) async throws

    /// Remove a trusted location
    func removeTrustedLocation(id: UUID) async throws

    /// Get all trusted locations
    func getTrustedLocations() async -> [TrustedLocationDomain]

    /// Subscribe to location trust changes
    func observeLocationTrustChanges() -> AsyncStream<Bool>
}

/// Repository for network monitoring
public protocol NetworkRepository {
    /// Start monitoring network changes
    func startMonitoring() async throws

    /// Stop monitoring network changes
    func stopMonitoring() async

    /// Get current network trust status
    func getCurrentNetworkInfo() async -> NetworkInfo

    /// Add a trusted network
    func addTrustedNetwork(_ network: TrustedNetwork) async throws

    /// Remove a trusted network
    func removeTrustedNetwork(ssid: String) async throws

    /// Get all trusted networks
    func getTrustedNetworks() async -> [TrustedNetwork]

    /// Subscribe to network changes
    func observeNetworkChanges() -> AsyncStream<NetworkChangeEvent>
}

/// Network information
public struct NetworkInfo: Equatable, Sendable {
    /// Whether network is connected
    public let isConnected: Bool
    /// Current network SSID if connected
    public let currentSSID: String?
    /// Whether current network is trusted
    public let isTrusted: Bool

    /// Initializes network information
    /// - Parameters:
    ///   - isConnected: Whether network is connected
    ///   - currentSSID: Current network SSID
    ///   - isTrusted: Whether network is trusted
    public init(
        isConnected: Bool,
        currentSSID: String? = nil,
        isTrusted: Bool = false
    ) {
        self.isConnected = isConnected
        self.currentSSID = currentSSID
        self.isTrusted = isTrusted
    }
}

/// Network change event
public enum NetworkChangeEvent: Equatable, Sendable {
    /// Connected to a network
    case connectedToNetwork(ssid: String, trusted: Bool)
    /// Disconnected from a network
    case disconnectedFromNetwork(ssid: String?, trusted: Bool)
    /// General connectivity changed
    case connectivityChanged(isConnected: Bool)
}

// MARK: - Use Case Protocols

/// Use case for auto-arm decision making
public protocol AutoArmDecisionUseCase {
    /// Evaluate whether to auto-arm based on event
    func evaluateAutoArmEvent(_ event: AutoArmEvent) async -> AutoArmDecision

    /// Check if auto-arm is currently possible
    func canAutoArm() async -> Bool

    /// Get current auto-arm status
    func getAutoArmStatus() async -> AutoArmStatus
}

/// Use case for managing auto-arm configuration
public protocol AutoArmConfigurationUseCase {
    /// Get current configuration
    func getConfiguration() async -> AutoArmConfiguration

    /// Update configuration
    func updateConfiguration(_ configuration: AutoArmConfiguration) async throws

    /// Temporarily disable auto-arm
    func temporarilyDisable(for duration: TimeInterval) async

    /// Cancel temporary disable
    func cancelTemporaryDisable() async

    /// Check if temporarily disabled
    func isTemporarilyDisabled() async -> (disabled: Bool, until: Date?)
}

/// Use case for auto-arm monitoring
public protocol AutoArmMonitoringUseCase {
    /// Start monitoring for auto-arm conditions
    func startMonitoring() async throws

    /// Stop monitoring
    func stopMonitoring() async

    /// Subscribe to auto-arm events
    func observeAutoArmEvents() -> AsyncStream<AutoArmEvent>
}

/// Auto-arm status information
public struct AutoArmStatus: Equatable, Sendable {
    /// Whether auto-arm is enabled
    public let isEnabled: Bool
    /// Whether actively monitoring
    public let isMonitoring: Bool
    /// Whether temporarily disabled
    public let isTemporarilyDisabled: Bool
    /// Temporary disable end time
    public let temporaryDisableUntil: Date?
    /// Last auto-arm event
    public let lastEvent: AutoArmEvent?
    /// Current conditions state
    public let currentConditions: AutoArmConditions

    /// Initializes auto-arm status
    /// - Parameters:
    ///   - isEnabled: Whether auto-arm is enabled
    ///   - isMonitoring: Whether actively monitoring
    ///   - isTemporarilyDisabled: Whether temporarily disabled
    ///   - temporaryDisableUntil: Temporary disable end time
    ///   - lastEvent: Last auto-arm event
    ///   - currentConditions: Current conditions state
    public init(
        isEnabled: Bool,
        isMonitoring: Bool,
        isTemporarilyDisabled: Bool,
        temporaryDisableUntil: Date? = nil,
        lastEvent: AutoArmEvent? = nil,
        currentConditions: AutoArmConditions
    ) {
        self.isEnabled = isEnabled
        self.isMonitoring = isMonitoring
        self.isTemporarilyDisabled = isTemporarilyDisabled
        self.temporaryDisableUntil = temporaryDisableUntil
        self.lastEvent = lastEvent
        self.currentConditions = currentConditions
    }
}

/// Current auto-arm conditions
public struct AutoArmConditions: Equatable, Sendable {
    /// Whether in a trusted location
    public let isInTrustedLocation: Bool
    /// Current network information
    public let currentNetwork: NetworkInfo
    /// Whether conditions suggest auto-arm
    public let shouldAutoArm: Bool

    /// Initializes auto-arm conditions
    /// - Parameters:
    ///   - isInTrustedLocation: Whether in trusted location
    ///   - currentNetwork: Current network info
    ///   - shouldAutoArm: Whether to auto-arm
    public init(
        isInTrustedLocation: Bool,
        currentNetwork: NetworkInfo,
        shouldAutoArm: Bool
    ) {
        self.isInTrustedLocation = isInTrustedLocation
        self.currentNetwork = currentNetwork
        self.shouldAutoArm = shouldAutoArm
    }
}

// MARK: - Service Protocol

/// Protocol for system arming operations
public protocol SystemArmingService {
    /// Check if system is currently armed
    func isArmed() async -> Bool

    /// Arm the system
    func arm() async throws
}

// MARK: - Notification Protocol

/// Protocol for user notifications
public protocol AutoArmNotificationService {
    /// Show notification about auto-arm event
    func showAutoArmNotification(trigger: AutoArmTrigger) async

    /// Show notification about auto-arm being disabled
    func showAutoArmDisabledNotification(until: Date) async

    /// Show notification about auto-arm failure
    func showAutoArmFailedNotification(error: Error) async
}
