//
//  ResourceProtectionProtocols.swift
//  MagSafeGuardDomain
//
//  Created on 2025-08-06.
//
//  Domain layer protocols for resource protection following Clean Architecture.
//  These protocols define the business rules for protecting system resources
//  independent of any infrastructure implementation details.
//

import Foundation

// MARK: - Domain Models

/// Circuit breaker states for fault tolerance
public enum CircuitState: String, Codable, Sendable {
    /// Normal operation - allowing requests
    case closed
    /// Circuit tripped - rejecting requests
    case open
    /// Testing if service has recovered
    case halfOpen
}

/// Protection metrics for monitoring resource usage
public struct ProtectionMetrics: Equatable, Sendable {
    public let totalAttempts: Int
    public let successfulExecutions: Int
    public let rateLimitedAttempts: Int
    public let circuitBreakerRejections: Int
    public let lastAttemptTime: Date?
    public let successRate: Double
    
    public init(
        totalAttempts: Int,
        successfulExecutions: Int,
        rateLimitedAttempts: Int,
        circuitBreakerRejections: Int,
        lastAttemptTime: Date?,
        successRate: Double
    ) {
        self.totalAttempts = totalAttempts
        self.successfulExecutions = successfulExecutions
        self.rateLimitedAttempts = rateLimitedAttempts
        self.circuitBreakerRejections = circuitBreakerRejections
        self.lastAttemptTime = lastAttemptTime
        self.successRate = successRate
    }
    
    /// Empty metrics for initialization
    public static let empty = ProtectionMetrics(
        totalAttempts: 0,
        successfulExecutions: 0,
        rateLimitedAttempts: 0,
        circuitBreakerRejections: 0,
        lastAttemptTime: nil,
        successRate: 0.0
    )
}

// MARK: - Protection Protocols

/// Policy for resource protection - abstracts protection mechanisms
public protocol ResourceProtectionPolicy: Sendable {
    /// Validate if an action can proceed
    func validateAction(_ action: SecurityActionType) async throws
    
    /// Record successful action execution
    func recordSuccess(_ action: SecurityActionType) async
    
    /// Record failed action execution
    func recordFailure(_ action: SecurityActionType) async
    
    /// Get protection metrics for an action
    func getMetrics(for action: SecurityActionType) async -> ProtectionMetrics
    
    /// Reset protection for specific action
    func reset(action: SecurityActionType) async
}

/// Protocol for rate limiting functionality
public protocol RateLimiterProtocol: Sendable {
    /// Check if an action is allowed based on rate limits
    /// - Parameter action: The action identifier
    /// - Returns: True if action is allowed, false if rate limited
    func allowAction(_ action: String) async -> Bool
    
    /// Reset rate limits for a specific action
    /// - Parameter action: The action identifier
    func reset(action: String) async
    
    /// Reset all rate limits
    func resetAll() async
    
    /// Get remaining tokens for an action
    /// - Parameter action: The action identifier
    /// - Returns: Number of remaining tokens
    func getRemainingTokens(_ action: String) async -> Int
}

/// Protocol for circuit breaker functionality
public protocol CircuitBreakerProtocol: Sendable {
    /// Execute an action through the circuit breaker
    /// - Parameter action: The action identifier
    /// - Returns: True if action can proceed, false if circuit is open
    func canExecute(_ action: String) async -> Bool
    
    /// Record successful action execution
    /// - Parameter action: The action identifier
    func recordSuccess(_ action: String) async
    
    /// Record failed action execution
    /// - Parameter action: The action identifier
    func recordFailure(_ action: String) async
    
    /// Get current state of a circuit
    /// - Parameter action: The action identifier
    /// - Returns: Current circuit state
    func getState(_ action: String) async -> CircuitState
    
    /// Reset circuit for an action
    /// - Parameter action: The action identifier
    func reset(action: String) async
}

// MARK: - Configuration Models

/// Rate limiter configuration for system actions
public struct RateLimiterConfig: Sendable {
    public let lockScreen: (capacity: Int, refillRate: TimeInterval)
    public let playAlarm: (capacity: Int, refillRate: TimeInterval)
    public let forceLogout: (capacity: Int, refillRate: TimeInterval)
    public let shutdown: (capacity: Int, refillRate: TimeInterval)
    public let executeScript: (capacity: Int, refillRate: TimeInterval)
    
    public init(
        lockScreen: (capacity: Int, refillRate: TimeInterval),
        playAlarm: (capacity: Int, refillRate: TimeInterval),
        forceLogout: (capacity: Int, refillRate: TimeInterval),
        shutdown: (capacity: Int, refillRate: TimeInterval),
        executeScript: (capacity: Int, refillRate: TimeInterval)
    ) {
        self.lockScreen = lockScreen
        self.playAlarm = playAlarm
        self.forceLogout = forceLogout
        self.shutdown = shutdown
        self.executeScript = executeScript
    }
    
    /// Default configuration with balanced limits
    public static let defaultConfig = RateLimiterConfig(
        lockScreen: (capacity: 5, refillRate: 2.0),      // 5 locks per 10 seconds
        playAlarm: (capacity: 3, refillRate: 5.0),       // 3 alarms per 15 seconds
        forceLogout: (capacity: 2, refillRate: 30.0),    // 2 logouts per minute
        shutdown: (capacity: 1, refillRate: 60.0),       // 1 shutdown per minute
        executeScript: (capacity: 3, refillRate: 10.0)   // 3 scripts per 30 seconds
    )
    
    /// Strict configuration with lower limits
    public static let strict = RateLimiterConfig(
        lockScreen: (capacity: 3, refillRate: 5.0),      // More restrictive
        playAlarm: (capacity: 2, refillRate: 10.0),
        forceLogout: (capacity: 1, refillRate: 60.0),
        shutdown: (capacity: 1, refillRate: 300.0),      // 1 per 5 minutes
        executeScript: (capacity: 1, refillRate: 30.0)
    )
    
    /// Test configuration with fast limits
    public static let test = RateLimiterConfig(
        lockScreen: (capacity: 2, refillRate: 0.1),
        playAlarm: (capacity: 2, refillRate: 0.1),
        forceLogout: (capacity: 1, refillRate: 0.1),
        shutdown: (capacity: 1, refillRate: 0.1),
        executeScript: (capacity: 2, refillRate: 0.1)
    )
}

/// Circuit breaker configuration for system actions
public struct CircuitBreakerConfig: Sendable {
    public let lockScreen: (failures: Int, successes: Int, timeout: TimeInterval)
    public let playAlarm: (failures: Int, successes: Int, timeout: TimeInterval)
    public let forceLogout: (failures: Int, successes: Int, timeout: TimeInterval)
    public let shutdown: (failures: Int, successes: Int, timeout: TimeInterval)
    public let executeScript: (failures: Int, successes: Int, timeout: TimeInterval)
    
    public init(
        lockScreen: (failures: Int, successes: Int, timeout: TimeInterval),
        playAlarm: (failures: Int, successes: Int, timeout: TimeInterval),
        forceLogout: (failures: Int, successes: Int, timeout: TimeInterval),
        shutdown: (failures: Int, successes: Int, timeout: TimeInterval),
        executeScript: (failures: Int, successes: Int, timeout: TimeInterval)
    ) {
        self.lockScreen = lockScreen
        self.playAlarm = playAlarm
        self.forceLogout = forceLogout
        self.shutdown = shutdown
        self.executeScript = executeScript
    }
    
    /// Default configuration with balanced thresholds
    public static let defaultConfig = CircuitBreakerConfig(
        lockScreen: (failures: 3, successes: 2, timeout: 30.0),
        playAlarm: (failures: 3, successes: 2, timeout: 30.0),
        forceLogout: (failures: 2, successes: 1, timeout: 60.0),
        shutdown: (failures: 2, successes: 1, timeout: 120.0),
        executeScript: (failures: 2, successes: 2, timeout: 60.0)
    )
    
    /// Resilient configuration with higher tolerance
    public static let resilient = CircuitBreakerConfig(
        lockScreen: (failures: 5, successes: 3, timeout: 20.0),
        playAlarm: (failures: 5, successes: 3, timeout: 20.0),
        forceLogout: (failures: 3, successes: 2, timeout: 45.0),
        shutdown: (failures: 3, successes: 2, timeout: 90.0),
        executeScript: (failures: 3, successes: 2, timeout: 45.0)
    )
    
    /// Test configuration with fast transitions
    public static let test = CircuitBreakerConfig(
        lockScreen: (failures: 2, successes: 1, timeout: 0.2),
        playAlarm: (failures: 2, successes: 1, timeout: 0.2),
        forceLogout: (failures: 1, successes: 1, timeout: 0.2),
        shutdown: (failures: 1, successes: 1, timeout: 0.2),
        executeScript: (failures: 2, successes: 1, timeout: 0.2)
    )
}

/// Combined resource protector configuration
public struct ResourceProtectorConfig: Sendable {
    public let rateLimiter: RateLimiterConfig
    public let circuitBreaker: CircuitBreakerConfig
    public let enableMetrics: Bool
    public let enableLogging: Bool
    
    public init(
        rateLimiter: RateLimiterConfig,
        circuitBreaker: CircuitBreakerConfig,
        enableMetrics: Bool,
        enableLogging: Bool
    ) {
        self.rateLimiter = rateLimiter
        self.circuitBreaker = circuitBreaker
        self.enableMetrics = enableMetrics
        self.enableLogging = enableLogging
    }
    
    /// Default configuration
    public static let defaultConfig = ResourceProtectorConfig(
        rateLimiter: .defaultConfig,
        circuitBreaker: .defaultConfig,
        enableMetrics: true,
        enableLogging: true
    )
    
    /// Strict configuration for high security
    public static let strict = ResourceProtectorConfig(
        rateLimiter: .strict,
        circuitBreaker: .resilient,
        enableMetrics: true,
        enableLogging: true
    )
    
    /// Test configuration for unit tests
    public static let test = ResourceProtectorConfig(
        rateLimiter: .test,
        circuitBreaker: .test,
        enableMetrics: true,
        enableLogging: false
    )
}