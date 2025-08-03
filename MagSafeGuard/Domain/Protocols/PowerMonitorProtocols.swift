//
//  PowerMonitorProtocols.swift
//  MagSafe Guard
//
//  Created on 2025-08-03.
//

import Foundation

// MARK: - Domain Models

/// Domain model representing power state information
public struct PowerStateInfo: Equatable {
    /// Indicates whether AC power is connected
    public let isConnected: Bool

    /// Current battery level percentage (0-100), nil if unavailable
    public let batteryLevel: Int?

    /// Indicates whether the battery is currently charging
    public let isCharging: Bool

    /// Wattage of the connected power adapter, nil if not connected or unavailable
    public let adapterWattage: Int?

    /// Timestamp when this power state was captured
    public let timestamp: Date

    /// Initializes a new power state info
    /// - Parameters:
    ///   - isConnected: Whether AC power is connected
    ///   - batteryLevel: Battery level percentage (0-100)
    ///   - isCharging: Whether battery is charging
    ///   - adapterWattage: Power adapter wattage
    ///   - timestamp: When this state was captured
    public init(
        isConnected: Bool,
        batteryLevel: Int? = nil,
        isCharging: Bool = false,
        adapterWattage: Int? = nil,
        timestamp: Date = Date()
    ) {
        self.isConnected = isConnected
        self.batteryLevel = batteryLevel
        self.isCharging = isCharging
        self.adapterWattage = adapterWattage
        self.timestamp = timestamp
    }
}

/// Domain model representing a power state change event
public struct PowerStateChange: Equatable {
    /// The power state before the change
    public let previousState: PowerStateInfo

    /// The power state after the change
    public let currentState: PowerStateInfo

    /// The type of change that occurred
    public let changeType: ChangeType

    /// Types of power state changes
    public enum ChangeType: Equatable {
        /// AC power was connected
        case connected
        /// AC power was disconnected
        case disconnected
        /// Battery level changed significantly
        case batteryLevelChanged(from: Int, to: Int)
        /// Charging status changed
        case chargingStateChanged(isCharging: Bool)
    }

    /// Initializes a power state change event
    /// - Parameters:
    ///   - previousState: The state before the change
    ///   - currentState: The state after the change
    public init(previousState: PowerStateInfo, currentState: PowerStateInfo) {
        self.previousState = previousState
        self.currentState = currentState

        // Determine change type
        if previousState.isConnected != currentState.isConnected {
            self.changeType = currentState.isConnected ? .connected : .disconnected
        } else if let prevLevel = previousState.batteryLevel,
                  let currLevel = currentState.batteryLevel,
                  prevLevel != currLevel {
            self.changeType = .batteryLevelChanged(from: prevLevel, to: currLevel)
        } else if previousState.isCharging != currentState.isCharging {
            self.changeType = .chargingStateChanged(isCharging: currentState.isCharging)
        } else {
            // Default to current connection state if no change detected
            self.changeType = currentState.isConnected ? .connected : .disconnected
        }
    }
}

// MARK: - Repository Protocol

/// Repository protocol for accessing power state data
public protocol PowerStateRepository {
    /// Get the current power state
    func getCurrentPowerState() async throws -> PowerStateInfo

    /// Observe power state changes
    func observePowerStateChanges() -> AsyncThrowingStream<PowerStateInfo, Error>
}

// MARK: - Use Case Protocols

/// Use case for monitoring power state changes
public protocol PowerMonitorUseCase {
    /// Start monitoring power state changes
    func startMonitoring() async throws

    /// Stop monitoring power state changes
    func stopMonitoring()

    /// Get the current power state
    func getCurrentPowerState() async throws -> PowerStateInfo

    /// Subscribe to power state changes
    var powerStateChanges: AsyncStream<PowerStateChange> { get }
}

/// Use case for analyzing power state changes for security threats
public protocol PowerStateAnalyzer {
    /// Analyze a power state change for potential security implications
    func analyzeStateChange(_ change: PowerStateChange) -> SecurityAnalysis
}

/// Security analysis result
public struct SecurityAnalysis: Equatable {
    /// The assessed threat level
    public let threatLevel: ThreatLevel

    /// Human-readable reason for the threat assessment
    public let reason: String

    /// Recommended security actions to take
    public let recommendedActions: [SecurityAction]

    /// Threat severity levels
    public enum ThreatLevel: Int, Comparable {
        /// No threat detected
        case none = 0
        /// Low threat - monitoring recommended
        case low = 1
        /// Medium threat - user notification recommended
        case medium = 2
        /// High threat - immediate action recommended
        case high = 3

        /// Compares threat levels by their severity
        public static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    /// Available security actions
    public enum SecurityAction: Equatable {
        /// No action required
        case none
        /// Notify the user
        case notify
        /// Lock the screen
        case lockScreen
        /// Shutdown the system
        case shutdown
        /// Custom action with description
        case custom(String)
    }

    /// Initializes a security analysis result
    /// - Parameters:
    ///   - threatLevel: The assessed threat level
    ///   - reason: Human-readable reason for the assessment
    ///   - recommendedActions: Recommended security actions
    public init(
        threatLevel: ThreatLevel,
        reason: String,
        recommendedActions: [SecurityAction] = []
    ) {
        self.threatLevel = threatLevel
        self.reason = reason
        self.recommendedActions = recommendedActions
    }
}

// MARK: - Service Configuration

/// Configuration for power monitoring behavior
public struct PowerMonitorConfiguration {
    /// Interval between power state checks (for polling implementations)
    public let pollingInterval: TimeInterval

    /// Whether to use system notifications (vs polling)
    public let useSystemNotifications: Bool

    /// Minimum time between reported state changes to prevent flooding
    public let debounceInterval: TimeInterval

    /// Initializes power monitor configuration
    /// - Parameters:
    ///   - pollingInterval: How often to check power state
    ///   - useSystemNotifications: Whether to use system notifications
    ///   - debounceInterval: Minimum time between state changes
    public init(
        pollingInterval: TimeInterval = 0.1,
        useSystemNotifications: Bool = true,
        debounceInterval: TimeInterval = 0.5
    ) {
        self.pollingInterval = pollingInterval
        self.useSystemNotifications = useSystemNotifications
        self.debounceInterval = debounceInterval
    }
}
