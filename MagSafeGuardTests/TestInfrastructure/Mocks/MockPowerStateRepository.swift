//
//  MockPowerStateRepository.swift
//  MagSafe Guard
//
//  Created on 2025-08-03.
//
//  Mock implementation of PowerStateRepository for testing.
//  Provides controllable power state behavior for unit tests.
//

import Foundation
@testable import MagSafeGuard

/// Mock implementation of PowerStateRepository for testing.
/// Allows full control over power state behavior in tests.
public actor MockPowerStateRepository: PowerStateRepository {

    // MARK: - Properties

    /// Current power state to return
    public var currentPowerState: PowerStateInfo = PowerStateBuilder.acConnected().build()

    /// Error to throw on getCurrentPowerState
    public var getPowerStateError: Error?

    /// Whether monitoring should fail
    public var shouldFailObservation = false

    /// Delay for async operations (to test timeouts)
    public var operationDelay: TimeInterval = 0

    /// Track method calls
    public private(set) var getCurrentPowerStateCalls = 0
    public private(set) var observePowerStateChangesCalls = 0

    /// Power state sequence for simulating changes
    private var powerStateSequence: [PowerStateInfo] = []
    private var sequenceIndex = 0

    /// Active continuation for power state changes
    private var continuation: AsyncThrowingStream<PowerStateInfo, Error>.Continuation?

    // MARK: - Initialization

    /// Initialize mock repository
    public init() {}

    // MARK: - Configuration Methods

    /// Set a sequence of power states to emit
    /// - Parameter states: Sequence of states to emit
    public func setPowerStateSequence(_ states: [PowerStateInfo]) {
        powerStateSequence = states
        sequenceIndex = 0
    }

    /// Simulate a power state change
    /// - Parameter state: New power state
    public func simulatePowerStateChange(_ state: PowerStateInfo) {
        continuation?.yield(state)
    }

    /// Simulate an error in the power state stream
    /// - Parameter error: Error to emit
    public func simulateError(_ error: Error) {
        continuation?.finish(throwing: error)
    }

    /// Complete the power state stream
    public func completeStream() {
        continuation?.finish()
    }

    /// Reset all mock state
    public func reset() {
        currentPowerState = PowerStateBuilder.acConnected().build()
        getPowerStateError = nil
        shouldFailObservation = false
        operationDelay = 0
        getCurrentPowerStateCalls = 0
        observePowerStateChangesCalls = 0
        powerStateSequence = []
        sequenceIndex = 0
        continuation = nil
    }

    // MARK: - PowerStateRepository Implementation

    public func getCurrentPowerState() async throws -> PowerStateInfo {
        getCurrentPowerStateCalls += 1

        // Simulate delay if configured
        if operationDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000))
        }

        // Throw error if configured
        if let error = getPowerStateError {
            throw error
        }

        // Return from sequence if available
        if !powerStateSequence.isEmpty && sequenceIndex < powerStateSequence.count {
            let state = powerStateSequence[sequenceIndex]
            sequenceIndex = (sequenceIndex + 1) % powerStateSequence.count
            return state
        }

        return currentPowerState
    }

    public func observePowerStateChanges() -> AsyncThrowingStream<PowerStateInfo, Error> {
        observePowerStateChangesCalls += 1

        if shouldFailObservation {
            return AsyncThrowingStream { continuation in
                continuation.finish(throwing: MockError.observationFailed)
            }
        }

        return AsyncThrowingStream { continuation in
            self.continuation = continuation

            // Emit sequence if configured
            if !powerStateSequence.isEmpty {
                Task {
                    for state in powerStateSequence {
                        if operationDelay > 0 {
                            try? await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000))
                        }
                        continuation.yield(state)
                    }
                }
            }

            continuation.onTermination = { _ in
                Task { await self.handleTermination() }
            }
        }
    }

    private func handleTermination() {
        continuation = nil
    }
}

// MARK: - Mock Errors

/// Errors that can be thrown by mocks
public enum MockError: LocalizedError, Equatable {
    case observationFailed
    case connectionLost
    case unauthorized
    case timeout
    case customError(String)

    public var errorDescription: String? {
        switch self {
        case .observationFailed:
            return "Power state observation failed"
        case .connectionLost:
            return "Connection to power monitor lost"
        case .unauthorized:
            return "Unauthorized to access power state"
        case .timeout:
            return "Operation timed out"
        case .customError(let message):
            return message
        }
    }
}

// MARK: - Test Helpers

extension MockPowerStateRepository {

    /// Simulate AC power disconnection
    public func simulateACDisconnection() {
        let disconnectedState = PowerStateBuilder.onBattery().build()
        simulatePowerStateChange(disconnectedState)
    }

    /// Simulate AC power connection
    public func simulateACConnection() {
        let connectedState = PowerStateBuilder.acConnected().build()
        simulatePowerStateChange(connectedState)
    }

    /// Simulate battery level change
    /// - Parameter level: New battery level
    public func simulateBatteryLevelChange(to level: Int) {
        let state = PowerStateBuilder()
            .connected(currentPowerState.isConnected)
            .batteryLevel(level)
            .build()
        simulatePowerStateChange(state)
    }

    /// Configure for testing timeout scenarios
    /// - Parameter delay: Delay in seconds
    public func configureForTimeout(delay: TimeInterval = 5.0) {
        operationDelay = delay
    }

    /// Configure for testing error scenarios
    /// - Parameter error: Error to throw
    public func configureForError(_ error: Error = MockError.connectionLost) {
        getPowerStateError = error
    }
}
