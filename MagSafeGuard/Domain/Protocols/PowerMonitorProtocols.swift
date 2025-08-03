//
//  PowerMonitorProtocols.swift
//  MagSafe Guard
//
//  Domain layer protocols for power monitoring following Clean Architecture.
//  These protocols define the business rules and use cases independent of
//  any system implementation details.
//

import Foundation

// MARK: - Domain Models

/// Domain model representing power state information
public struct PowerStateInfo: Equatable {
    public let isConnected: Bool
    public let batteryLevel: Int?
    public let isCharging: Bool
    public let adapterWattage: Int?
    public let timestamp: Date

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
    public let previousState: PowerStateInfo
    public let currentState: PowerStateInfo
    public let changeType: ChangeType

    public enum ChangeType: Equatable {
        case connected
        case disconnected
        case batteryLevelChanged(from: Int, to: Int)
        case chargingStateChanged(isCharging: Bool)
    }

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
    public let threatLevel: ThreatLevel
    public let reason: String
    public let recommendedActions: [SecurityAction]

    public enum ThreatLevel: Int, Comparable {
        case none = 0
        case low = 1
        case medium = 2
        case high = 3

        public static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    public enum SecurityAction: Equatable {
        case none
        case notify
        case lockScreen
        case shutdown
        case custom(String)
    }

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
