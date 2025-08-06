//
//  CircuitBreaker.swift
//  MagSafe Guard
//
//  Created on 2025-08-05.
//

import Foundation
import MagSafeGuardDomain

/// Circuit breaker implementation for fault tolerance
public actor CircuitBreaker: CircuitBreakerProtocol {

    // MARK: - Types

    private struct Circuit {
        var state: CircuitState = .closed
        var failureCount: Int = 0
        var successCount: Int = 0
        var lastFailureTime: Date?
        var lastStateChange = Date()
        let failureThreshold: Int
        let successThreshold: Int
        let timeout: TimeInterval

        mutating func recordSuccess() {
            switch state {
            case .closed:
                failureCount = 0
            case .halfOpen:
                successCount += 1
                if successCount >= successThreshold {
                    state = .closed
                    failureCount = 0
                    successCount = 0
                    lastStateChange = Date()
                }
            case .open:
                break
            }
        }

        mutating func recordFailure() {
            lastFailureTime = Date()

            switch state {
            case .closed:
                failureCount += 1
                if failureCount >= failureThreshold {
                    state = .open
                    lastStateChange = Date()
                }
            case .halfOpen:
                state = .open
                successCount = 0
                lastStateChange = Date()
            case .open:
                break
            }
        }

        mutating func checkTimeout() {
            if state == .open {
                let elapsed = Date().timeIntervalSince(lastStateChange)
                if elapsed >= timeout {
                    state = .halfOpen
                    successCount = 0
                    lastStateChange = Date()
                }
            }
        }

        var canExecute: Bool {
            switch state {
            case .closed, .halfOpen:
                return true
            case .open:
                return false
            }
        }
    }

    // MARK: - Properties

    private var circuits: [String: Circuit] = [:]
    private let defaultFailureThreshold: Int
    private let defaultSuccessThreshold: Int
    private let defaultTimeout: TimeInterval

    // MARK: - Initialization

    /// Initialize circuit breaker with default settings
    /// - Parameters:
    ///   - failureThreshold: Number of failures before opening circuit
    ///   - successThreshold: Number of successes in half-open before closing
    ///   - timeout: Time before attempting recovery from open state
    public init(
        failureThreshold: Int = 3,
        successThreshold: Int = 2,
        timeout: TimeInterval = 60.0
    ) {
        self.defaultFailureThreshold = failureThreshold
        self.defaultSuccessThreshold = successThreshold
        self.defaultTimeout = timeout
    }

    // MARK: - Public Methods

    /// Check if action can execute through circuit breaker
    public func canExecute(_ action: String) -> Bool {
        // Ensure circuit exists
        let circuit = circuits[action] ?? Circuit(
            failureThreshold: defaultFailureThreshold,
            successThreshold: defaultSuccessThreshold,
            timeout: defaultTimeout
        )

        if circuits[action] == nil {
            circuits[action] = circuit
        }

        // Check timeout and update state if needed
        circuits[action]?.checkTimeout()
        return circuits[action]?.canExecute ?? true
    }

    /// Record successful action execution
    public func recordSuccess(_ action: String) {
        if circuits[action] == nil {
            circuits[action] = Circuit(
                failureThreshold: defaultFailureThreshold,
                successThreshold: defaultSuccessThreshold,
                timeout: defaultTimeout
            )
        }
        circuits[action]?.recordSuccess()
    }

    /// Record failed action execution
    public func recordFailure(_ action: String) {
        if circuits[action] == nil {
            circuits[action] = Circuit(
                failureThreshold: defaultFailureThreshold,
                successThreshold: defaultSuccessThreshold,
                timeout: defaultTimeout
            )
        }
        circuits[action]?.recordFailure()
    }

    /// Get current state of a circuit
    public func getState(_ action: String) -> CircuitState {
        circuits[action]?.checkTimeout()
        return circuits[action]?.state ?? .closed
    }

    /// Reset circuit for an action
    public func reset(action: String) {
        circuits[action] = Circuit(
            failureThreshold: defaultFailureThreshold,
            successThreshold: defaultSuccessThreshold,
            timeout: defaultTimeout
        )
    }

    /// Configure circuit breaker for a specific action
    /// - Parameters:
    ///   - action: The action identifier
    ///   - failureThreshold: Failures before opening
    ///   - successThreshold: Successes before closing
    ///   - timeout: Recovery timeout
    public func configure(
        action: String,
        failureThreshold: Int,
        successThreshold: Int,
        timeout: TimeInterval
    ) {
        circuits[action] = Circuit(
            failureThreshold: failureThreshold,
            successThreshold: successThreshold,
            timeout: timeout
        )
    }
}
