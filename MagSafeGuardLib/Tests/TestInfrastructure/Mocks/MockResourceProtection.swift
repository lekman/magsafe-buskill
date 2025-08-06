//
//  MockResourceProtection.swift
//  MagSafeGuardTests
//
//  Created on 2025-08-06.
//
//  Mock implementations for resource protection testing.
//

import Foundation
@testable import MagSafeGuardDomain

// MARK: - Mock Resource Protection Policy

/// Mock implementation of ResourceProtectionPolicy for testing
public final class MockResourceProtectionPolicy: ResourceProtectionPolicy, @unchecked Sendable {
    
    // Tracking properties
    public var validateActionCalled = false
    public var validateActionCallCount = 0
    public var lastValidatedAction: SecurityActionType?
    public var shouldFailValidation = false
    public var validationError: SecurityActionError?
    
    public var recordSuccessCalled = false
    public var recordSuccessCallCount = 0
    public var lastSuccessAction: SecurityActionType?
    
    public var recordFailureCalled = false
    public var recordFailureCallCount = 0
    public var lastFailureAction: SecurityActionType?
    
    public var resetCalled = false
    public var resetCallCount = 0
    public var lastResetAction: SecurityActionType?
    
    // Configurable metrics
    public var mockMetrics = ProtectionMetrics.empty
    
    public init() {}
    
    public func validateAction(_ action: SecurityActionType) async throws {
        validateActionCalled = true
        validateActionCallCount += 1
        lastValidatedAction = action
        
        if shouldFailValidation {
            throw validationError ?? SecurityActionError.rateLimitExceeded
        }
    }
    
    public func recordSuccess(_ action: SecurityActionType) async {
        recordSuccessCalled = true
        recordSuccessCallCount += 1
        lastSuccessAction = action
    }
    
    public func recordFailure(_ action: SecurityActionType) async {
        recordFailureCalled = true
        recordFailureCallCount += 1
        lastFailureAction = action
    }
    
    public func getMetrics(for action: SecurityActionType) async -> ProtectionMetrics {
        return mockMetrics
    }
    
    public func reset(action: SecurityActionType) async {
        resetCalled = true
        resetCallCount += 1
        lastResetAction = action
    }
}

// MARK: - Mock Rate Limiter

/// Mock implementation of RateLimiterProtocol for testing
public actor MockRateLimiter: RateLimiterProtocol {
    
    // Configuration
    private var allowedActions: Set<String> = []
    private var tokenCounts: [String: Int] = [:]
    private var defaultTokens: Int = 3
    
    // Tracking
    private var allowActionCallCount: [String: Int] = [:]
    private var resetCallCount: [String: Int] = [:]
    private var resetAllCallCount = 0
    
    public init(defaultTokens: Int = 3) {
        self.defaultTokens = defaultTokens
    }
    
    public func allowAction(_ action: String) -> Bool {
        allowActionCallCount[action, default: 0] += 1
        
        if allowedActions.contains(action) {
            return true
        }
        
        let tokens = tokenCounts[action, default: defaultTokens]
        if tokens > 0 {
            tokenCounts[action] = tokens - 1
            return true
        }
        return false
    }
    
    public func reset(action: String) {
        resetCallCount[action, default: 0] += 1
        tokenCounts[action] = defaultTokens
        allowedActions.remove(action)
    }
    
    public func resetAll() {
        resetAllCallCount += 1
        tokenCounts.removeAll()
        allowedActions.removeAll()
    }
    
    public func getRemainingTokens(_ action: String) -> Int {
        return tokenCounts[action, default: defaultTokens]
    }
    
    // Test helpers
    public func setAllowed(_ action: String, allowed: Bool) {
        if allowed {
            allowedActions.insert(action)
        } else {
            allowedActions.remove(action)
        }
    }
    
    public func setTokens(_ action: String, tokens: Int) {
        tokenCounts[action] = tokens
    }
    
    public func getCallCount(for action: String) -> Int {
        return allowActionCallCount[action, default: 0]
    }
}

// MARK: - Mock Circuit Breaker

/// Mock implementation of CircuitBreakerProtocol for testing
public actor MockCircuitBreaker: CircuitBreakerProtocol {
    
    // State management
    private var states: [String: CircuitState] = [:]
    private var defaultState: CircuitState = .closed
    
    // Tracking
    private var canExecuteCallCount: [String: Int] = [:]
    private var recordSuccessCallCount: [String: Int] = [:]
    private var recordFailureCallCount: [String: Int] = [:]
    private var resetCallCount: [String: Int] = [:]
    
    public init(defaultState: CircuitState = .closed) {
        self.defaultState = defaultState
    }
    
    public func canExecute(_ action: String) -> Bool {
        canExecuteCallCount[action, default: 0] += 1
        let state = states[action, default: defaultState]
        return state != .open
    }
    
    public func recordSuccess(_ action: String) {
        recordSuccessCallCount[action, default: 0] += 1
        // Simulate state transition
        if states[action] == .halfOpen {
            states[action] = .closed
        }
    }
    
    public func recordFailure(_ action: String) {
        recordFailureCallCount[action, default: 0] += 1
        // Simulate state transition
        if states[action] == .halfOpen {
            states[action] = .open
        } else if states[action] == .closed {
            // Could transition to open based on threshold
        }
    }
    
    public func getState(_ action: String) -> CircuitState {
        return states[action, default: defaultState]
    }
    
    public func reset(action: String) {
        resetCallCount[action, default: 0] += 1
        states[action] = .closed
    }
    
    // Test helpers
    public func setState(_ action: String, state: CircuitState) {
        states[action] = state
    }
    
    public func getCallCount(for action: String, operation: String) -> Int {
        switch operation {
        case "canExecute":
            return canExecuteCallCount[action, default: 0]
        case "recordSuccess":
            return recordSuccessCallCount[action, default: 0]
        case "recordFailure":
            return recordFailureCallCount[action, default: 0]
        case "reset":
            return resetCallCount[action, default: 0]
        default:
            return 0
        }
    }
}

// MARK: - Test Helpers

/// Builder for creating test protection metrics
public struct ProtectionMetricsBuilder {
    private var metrics = ProtectionMetrics.empty
    
    public init() {}
    
    public func withTotalAttempts(_ count: Int) -> ProtectionMetricsBuilder {
        var builder = self
        builder.metrics = ProtectionMetrics(
            totalAttempts: count,
            successfulExecutions: metrics.successfulExecutions,
            rateLimitedAttempts: metrics.rateLimitedAttempts,
            circuitBreakerRejections: metrics.circuitBreakerRejections,
            lastAttemptTime: metrics.lastAttemptTime,
            successRate: metrics.successRate
        )
        return builder
    }
    
    public func withSuccessfulExecutions(_ count: Int) -> ProtectionMetricsBuilder {
        var builder = self
        builder.metrics = ProtectionMetrics(
            totalAttempts: metrics.totalAttempts,
            successfulExecutions: count,
            rateLimitedAttempts: metrics.rateLimitedAttempts,
            circuitBreakerRejections: metrics.circuitBreakerRejections,
            lastAttemptTime: metrics.lastAttemptTime,
            successRate: Double(count) / Double(max(metrics.totalAttempts, 1))
        )
        return builder
    }
    
    public func withRateLimitedAttempts(_ count: Int) -> ProtectionMetricsBuilder {
        var builder = self
        builder.metrics = ProtectionMetrics(
            totalAttempts: metrics.totalAttempts,
            successfulExecutions: metrics.successfulExecutions,
            rateLimitedAttempts: count,
            circuitBreakerRejections: metrics.circuitBreakerRejections,
            lastAttemptTime: metrics.lastAttemptTime,
            successRate: metrics.successRate
        )
        return builder
    }
    
    public func build() -> ProtectionMetrics {
        return metrics
    }
}