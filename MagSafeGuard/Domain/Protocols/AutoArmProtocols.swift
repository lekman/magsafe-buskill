//
//  AutoArmProtocols.swift
//  MagSafe Guard
//
//  Domain layer protocols for auto-arm functionality following Clean Architecture.
//  These protocols define the business rules for automatic security arming
//  independent of any system implementation details.
//

import Foundation

// MARK: - Domain Models

/// Configuration for auto-arm behavior
public struct AutoArmConfiguration: Equatable {
    public let isEnabled: Bool
    public let armByLocation: Bool
    public let armOnUntrustedNetwork: Bool
    public let armCooldownPeriod: TimeInterval
    public let notifyBeforeArming: Bool
    public let notificationDelay: TimeInterval

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

    public static let `default` = AutoArmConfiguration()
}

/// Trigger that caused auto-arm activation
public enum AutoArmTrigger: Equatable {
    case leftTrustedLocation(name: String?)
    case enteredUntrustedNetwork(ssid: String)
    case disconnectedFromTrustedNetwork(ssid: String)
    case lostNetworkConnectivity
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
public struct AutoArmEvent: Equatable {
    public let trigger: AutoArmTrigger
    public let timestamp: Date
    public let configuration: AutoArmConfiguration

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
public enum AutoArmDecision: Equatable {
    case arm(reason: String)
    case skip(reason: AutoArmSkipReason)

    public var shouldArm: Bool {
        if case .arm = self { return true }
        return false
    }
}

/// Reasons for skipping auto-arm
public enum AutoArmSkipReason: Equatable {
    case disabled
    case alreadyArmed
    case temporarilyDisabled(until: Date)
    case cooldownPeriod(until: Date)
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
public struct TrustedLocationDomain: Equatable {
    public let id: UUID
    public let name: String
    public let latitude: Double
    public let longitude: Double
    public let radius: Double // in meters

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
public struct TrustedNetwork: Equatable {
    public let ssid: String
    public let addedDate: Date

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
public struct NetworkInfo: Equatable {
    public let isConnected: Bool
    public let currentSSID: String?
    public let isTrusted: Bool

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
public enum NetworkChangeEvent: Equatable {
    case connectedToNetwork(ssid: String, trusted: Bool)
    case disconnectedFromNetwork(ssid: String?, trusted: Bool)
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
public struct AutoArmStatus: Equatable {
    public let isEnabled: Bool
    public let isMonitoring: Bool
    public let isTemporarilyDisabled: Bool
    public let temporaryDisableUntil: Date?
    public let lastEvent: AutoArmEvent?
    public let currentConditions: AutoArmConditions

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
public struct AutoArmConditions: Equatable {
    public let isInTrustedLocation: Bool
    public let currentNetwork: NetworkInfo
    public let shouldAutoArm: Bool

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
