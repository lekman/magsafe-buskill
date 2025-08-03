//
//  PowerMonitorUseCaseImpl.swift
//  MagSafe Guard
//
//  Created on 2025-08-03.
//

import Foundation

/// Concrete implementation of PowerMonitorUseCase
public final class PowerMonitorUseCaseImpl: PowerMonitorUseCase {

    // MARK: - Properties

    private let repository: PowerStateRepository
    private let analyzer: PowerStateAnalyzer
    private let configuration: PowerMonitorConfiguration

    private var monitoringTask: Task<Void, Never>?
    private var previousState: PowerStateInfo?

    // Stream for power state changes
    private let changeStream = AsyncStream<PowerStateChange>.makeStream()
    /// Stream of power state changes
    public var powerStateChanges: AsyncStream<PowerStateChange> {
        changeStream.stream
    }

    // MARK: - Initialization

    /// Initializes the power monitor use case
    /// - Parameters:
    ///   - repository: The power state repository
    ///   - analyzer: The power state analyzer
    ///   - configuration: Power monitor configuration
    public init(
        repository: PowerStateRepository,
        analyzer: PowerStateAnalyzer,
        configuration: PowerMonitorConfiguration = PowerMonitorConfiguration()
    ) {
        self.repository = repository
        self.analyzer = analyzer
        self.configuration = configuration
    }

    // MARK: - PowerMonitorUseCase Implementation

    /// Starts monitoring power state changes
    public func startMonitoring() async throws {
        // Cancel any existing monitoring
        monitoringTask?.cancel()

        // Get initial state
        let initialState = try await repository.getCurrentPowerState()
        previousState = initialState

        // Start monitoring task
        monitoringTask = Task { [weak self] in
            guard let self = self else { return }

            do {
                for try await newState in repository.observePowerStateChanges() {
                    await self.handleStateUpdate(newState)
                }
            } catch {
                // Handle error but don't crash
                // In production, this would be logged properly
            }
        }
    }

    /// Stops monitoring power state changes
    public func stopMonitoring() {
        monitoringTask?.cancel()
        monitoringTask = nil
        previousState = nil
    }

    /// Gets the current power state
    public func getCurrentPowerState() async throws -> PowerStateInfo {
        return try await repository.getCurrentPowerState()
    }

    // MARK: - Private Methods

    private func handleStateUpdate(_ newState: PowerStateInfo) async {
        guard let previousState = previousState else {
            self.previousState = newState
            return
        }

        // Check if state actually changed
        if hasStateChanged(from: previousState, to: newState) {
            let change = PowerStateChange(previousState: previousState, currentState: newState)

            // Update stored state
            self.previousState = newState

            // Emit change event
            changeStream.continuation.yield(change)
        }
    }

    private func hasStateChanged(from oldState: PowerStateInfo, to newState: PowerStateInfo) -> Bool {
        // Consider a state change if:
        // 1. Connection state changed
        // 2. Battery level changed significantly (more than 5%)
        // 3. Charging state changed

        if oldState.isConnected != newState.isConnected {
            return true
        }

        if let oldBattery = oldState.batteryLevel,
           let newBattery = newState.batteryLevel,
           abs(oldBattery - newBattery) > 5 {
            return true
        }

        if oldState.isCharging != newState.isCharging {
            return true
        }

        return false
    }
}

/// Default implementation of PowerStateAnalyzer
public final class DefaultPowerStateAnalyzer: PowerStateAnalyzer {

    private let settings: SecuritySettings

    /// Security settings for power state analysis
    public struct SecuritySettings {
        /// Whether security monitoring is armed
        public let isArmed: Bool
        /// Grace period before triggering security actions
        public let gracePeriodSeconds: TimeInterval
        /// Whether to consider current location as trusted
        public let considerLocationTrusted: Bool

        /// Initializes security settings
        public init(
            isArmed: Bool = true,
            gracePeriodSeconds: TimeInterval = 5.0,
            considerLocationTrusted: Bool = false
        ) {
            self.isArmed = isArmed
            self.gracePeriodSeconds = gracePeriodSeconds
            self.considerLocationTrusted = considerLocationTrusted
        }
    }

    /// Initializes the power state analyzer
    public init(settings: SecuritySettings = SecuritySettings()) {
        self.settings = settings
    }

    /// Analyzes a power state change for security threats
    public func analyzeStateChange(_ change: PowerStateChange) -> SecurityAnalysis {
        // If not armed, no threat
        guard settings.isArmed else {
            return SecurityAnalysis(
                threatLevel: .none,
                reason: "Security monitoring is not armed"
            )
        }

        // Analyze based on change type
        switch change.changeType {
        case .disconnected:
            // Power disconnection is the primary threat
            if settings.considerLocationTrusted {
                return SecurityAnalysis(
                    threatLevel: .low,
                    reason: "Power disconnected at trusted location",
                    recommendedActions: [.notify]
                )
            } else {
                return SecurityAnalysis(
                    threatLevel: .high,
                    reason: "Power disconnected - potential theft attempt",
                    recommendedActions: [.lockScreen, .notify]
                )
            }

        case .connected:
            // Power reconnection is safe
            return SecurityAnalysis(
                threatLevel: .none,
                reason: "Power adapter connected"
            )

        case .batteryLevelChanged(_, let to):
            // Low battery might be a concern
            if to < 10 {
                return SecurityAnalysis(
                    threatLevel: .low,
                    reason: "Battery level critically low",
                    recommendedActions: [.notify]
                )
            }
            return SecurityAnalysis(
                threatLevel: .none,
                reason: "Battery level changed"
            )

        case .chargingStateChanged:
            // Charging state change is informational
            return SecurityAnalysis(
                threatLevel: .none,
                reason: "Charging state changed"
            )
        }
    }
}
