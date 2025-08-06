//
//  ResourceProtector.swift
//  MagSafe Guard
//
//  Created on 2025-08-05.
//

import Foundation
import MagSafeGuardDomain
import os.log

/// Errors specific to resource protection
public enum ResourceProtectionError: LocalizedError {
    /// Action is rate limited and should retry after specified interval
    case rateLimited(action: String, retryAfter: TimeInterval)
    /// Circuit breaker is open, service temporarily unavailable
    case circuitOpen(action: String, state: CircuitState)
    /// Resources for the action are exhausted
    case resourceExhausted(action: String)
    /// Resource protection is disabled
    case protectionDisabled

    /// Localized error description
    public var errorDescription: String? {
        switch self {
        case .rateLimited(let action, let retryAfter):
            return "Action '\(action)' is rate limited. Retry after \(Int(retryAfter)) seconds."
        case .circuitOpen(let action, let state):
            return "Circuit breaker for '\(action)' is \(state). Service temporarily unavailable."
        case .resourceExhausted(let action):
            return "Resources for '\(action)' are exhausted. Please wait before retrying."
        case .protectionDisabled:
            return "Resource protection is disabled."
        }
    }
}

/// Comprehensive resource protection coordinator
public actor ResourceProtector {

    // MARK: - Properties

    private let rateLimiter: RateLimiter
    private let circuitBreaker: CircuitBreaker
    private let logger = Logger(subsystem: "com.magsafeguard", category: "ResourceProtector")
    private var metrics: [String: ActionMetrics] = [:]
    private var isEnabled: Bool = true

    // MARK: - Types

    private struct ActionMetrics {
        var totalAttempts: Int = 0
        var successfulExecutions: Int = 0
        var rateLimitedAttempts: Int = 0
        var circuitBreakerRejections: Int = 0
        var lastAttemptTime: Date?
        var lastSuccessTime: Date?
        var lastFailureTime: Date?
    }

    // MARK: - Initialization

    /// Initialize resource protector with configurations
    /// - Parameters:
    ///   - rateLimiterConfig: Rate limiting configuration
    ///   - circuitBreakerConfig: Circuit breaker configuration
    public init(
        rateLimiterConfig: RateLimiterConfig = .default,
        circuitBreakerConfig: CircuitBreakerConfig = .default
    ) {
        self.rateLimiter = RateLimiter()
        self.circuitBreaker = CircuitBreaker()

        // Configure rate limiters
        Task {
            await configureRateLimiters(with: rateLimiterConfig)
            await configureCircuitBreakers(with: circuitBreakerConfig)
        }
    }

    // MARK: - Public Methods

    /// Check if an action is allowed to proceed
    /// - Parameter action: The action identifier
    /// - Returns: True if action can proceed
    /// - Throws: ResourceProtectionError if action is blocked
    public func checkAction(_ action: String) async throws -> Bool {
        guard isEnabled else {
            throw ResourceProtectionError.protectionDisabled
        }

        // Update metrics
        metrics[action, default: ActionMetrics()].totalAttempts += 1
        metrics[action]?.lastAttemptTime = Date()

        // Check circuit breaker first (fail fast)
        let circuitState = await circuitBreaker.getState(action)
        if circuitState == .open {
            metrics[action]?.circuitBreakerRejections += 1
            logger.warning("Circuit breaker open for action: \(action)")
            throw ResourceProtectionError.circuitOpen(action: action, state: circuitState)
        }

        // Check rate limiter
        let isAllowed = await rateLimiter.allowAction(action)
        if !isAllowed {
            metrics[action]?.rateLimitedAttempts += 1
            logger.warning("Rate limit exceeded for action: \(action)")
            throw ResourceProtectionError.rateLimited(action: action, retryAfter: estimateRetryTime(for: action))
        }

        logger.debug("Action '\(action)' allowed to proceed")
        return true
    }

    /// Record successful action execution
    /// - Parameter action: The action identifier
    public func recordSuccess(_ action: String) async {
        await circuitBreaker.recordSuccess(action)
        metrics[action]?.successfulExecutions += 1
        metrics[action]?.lastSuccessTime = Date()
        logger.debug("Recorded success for action: \(action)")
    }

    /// Record failed action execution
    /// - Parameter action: The action identifier
    public func recordFailure(_ action: String) async {
        await circuitBreaker.recordFailure(action)
        metrics[action]?.lastFailureTime = Date()
        logger.warning("Recorded failure for action: \(action)")
    }

    /// Get current metrics for an action
    /// - Parameter action: The action identifier
    /// - Returns: Dictionary of metric values
    public func getMetrics(for action: String) -> [String: Any] {
        guard let actionMetrics = metrics[action] else {
            return [:]
        }

        return [
            "totalAttempts": actionMetrics.totalAttempts,
            "successfulExecutions": actionMetrics.successfulExecutions,
            "rateLimitedAttempts": actionMetrics.rateLimitedAttempts,
            "circuitBreakerRejections": actionMetrics.circuitBreakerRejections,
            "lastAttemptTime": actionMetrics.lastAttemptTime?.timeIntervalSince1970 ?? 0,
            "lastSuccessTime": actionMetrics.lastSuccessTime?.timeIntervalSince1970 ?? 0,
            "lastFailureTime": actionMetrics.lastFailureTime?.timeIntervalSince1970 ?? 0,
            "successRate": calculateSuccessRate(for: actionMetrics)
        ]
    }

    /// Reset protection for specific action
    /// - Parameter action: The action identifier
    public func reset(action: String) async {
        await rateLimiter.reset(action: action)
        await circuitBreaker.reset(action: action)
        metrics[action] = ActionMetrics()
        logger.info("Reset protection for action: \(action)")
    }

    /// Enable or disable resource protection
    /// - Parameter enabled: Whether protection should be enabled
    public func setEnabled(_ enabled: Bool) {
        self.isEnabled = enabled
        logger.info("Resource protection \(enabled ? "enabled" : "disabled")")
    }

    /// Execute an action with protection
    /// - Parameters:
    ///   - action: The action identifier
    ///   - operation: The operation to execute
    /// - Returns: The result of the operation
    /// - Throws: ResourceProtectionError or operation errors
    public func executeProtected<T>(
        _ action: String,
        operation: () async throws -> T
    ) async throws -> T {
        // Check if action is allowed
        _ = try await checkAction(action)

        do {
            // Execute the operation
            let result = try await operation()

            // Record success
            await recordSuccess(action)

            return result
        } catch {
            // Record failure
            await recordFailure(action)
            throw error
        }
    }

    // MARK: - Private Methods

    private func configureRateLimiters(with config: RateLimiterConfig) async {
        await rateLimiter.configure(
            action: "lockScreen",
            capacity: config.lockScreen.capacity,
            refillRate: config.lockScreen.refillRate
        )
        await rateLimiter.configure(
            action: "playAlarm",
            capacity: config.playAlarm.capacity,
            refillRate: config.playAlarm.refillRate
        )
        await rateLimiter.configure(
            action: "forceLogout",
            capacity: config.forceLogout.capacity,
            refillRate: config.forceLogout.refillRate
        )
        await rateLimiter.configure(
            action: "shutdown",
            capacity: config.shutdown.capacity,
            refillRate: config.shutdown.refillRate
        )
        await rateLimiter.configure(
            action: "executeScript",
            capacity: config.executeScript.capacity,
            refillRate: config.executeScript.refillRate
        )
    }

    private func configureCircuitBreakers(with config: CircuitBreakerConfig) async {
        await circuitBreaker.configure(
            action: "lockScreen",
            failureThreshold: config.lockScreen.failures,
            successThreshold: config.lockScreen.successes,
            timeout: config.lockScreen.timeout
        )
        await circuitBreaker.configure(
            action: "playAlarm",
            failureThreshold: config.playAlarm.failures,
            successThreshold: config.playAlarm.successes,
            timeout: config.playAlarm.timeout
        )
        await circuitBreaker.configure(
            action: "forceLogout",
            failureThreshold: config.forceLogout.failures,
            successThreshold: config.forceLogout.successes,
            timeout: config.forceLogout.timeout
        )
        await circuitBreaker.configure(
            action: "shutdown",
            failureThreshold: config.shutdown.failures,
            successThreshold: config.shutdown.successes,
            timeout: config.shutdown.timeout
        )
        await circuitBreaker.configure(
            action: "executeScript",
            failureThreshold: config.executeScript.failures,
            successThreshold: config.executeScript.successes,
            timeout: config.executeScript.timeout
        )
    }

    private func estimateRetryTime(for action: String) -> TimeInterval {
        // Simple estimation based on action type
        switch action {
        case "lockScreen":
            return 2.0
        case "playAlarm":
            return 5.0
        case "forceLogout":
            return 30.0
        case "shutdown":
            return 60.0
        case "executeScript":
            return 10.0
        default:
            return 5.0
        }
    }

    private func calculateSuccessRate(for metrics: ActionMetrics) -> Double {
        guard metrics.totalAttempts > 0 else { return 0.0 }
        return Double(metrics.successfulExecutions) / Double(metrics.totalAttempts)
    }
}
