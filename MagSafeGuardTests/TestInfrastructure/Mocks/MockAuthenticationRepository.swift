//
//  MockAuthenticationRepository.swift
//  MagSafe Guard
//
//  Created on 2025-08-03.
//
//  Mock implementation of AuthenticationRepository for testing.
//  Provides controllable authentication behavior for unit tests.
//

import Foundation
@testable import MagSafeGuardCore
@testable import MagSafeGuardDomain

/// Mock implementation of AuthenticationRepository for testing.
/// Allows full control over authentication behavior in tests.
public actor MockAuthenticationRepository: AuthenticationRepository {

    // MARK: - Properties

    /// Biometric availability to return
    public var biometricAvailability = BiometricAvailabilityBuilder.touchIDAvailable().build()

    /// Authentication result to return
    public var authenticationResult: AuthenticationResult = .success(AuthenticationSuccess(
        method: .touchID,
        cached: false
    ))

    /// Delay for async operations
    public var operationDelay: TimeInterval = 0

    /// Track method calls
    public private(set) var isBiometricAvailableCalls = 0
    public private(set) var authenticateCalls = 0
    public private(set) var invalidateAuthenticationCalls = 0

    /// Track authentication requests
    public private(set) var lastAuthenticationRequest: AuthenticationRequest?
    public private(set) var authenticationHistory: [AuthenticationRequest] = []

    /// Simulate authentication dialog behavior
    public var shouldAutoAuthenticate = true
    public var authenticationDelay: TimeInterval = 0.1

    /// Rate limiting simulation
    public var failedAttempts = 0
    public var maxFailedAttempts = 3
    public var rateLimitDuration: TimeInterval = 30
    public var lastFailedAttempt: Date?

    // MARK: - Initialization

    /// Initialize mock repository
    public init() {}

    // MARK: - Configuration Methods

    /// Configure for successful authentication
    /// - Parameter method: Authentication method to simulate
    public func configureSuccess(method: AuthenticationMethod = .touchID) {
        authenticationResult = AuthenticationResultBuilder.success(method: method)
    }

    /// Configure for authentication failure
    /// - Parameter failure: Failure reason
    public func configureFailure(_ failure: AuthenticationFailure) {
        authenticationResult = AuthenticationResultBuilder.failure(failure)
    }

    /// Configure for user cancellation
    public func configureCancellation() {
        authenticationResult = .cancelled
    }

    /// Configure biometric availability
    /// - Parameter availability: Availability to return
    public func configureBiometricAvailability(_ availability: BiometricAvailability) {
        biometricAvailability = availability
    }

    /// Simulate rate limiting
    public func simulateRateLimiting() {
        failedAttempts = maxFailedAttempts + 1
        lastFailedAttempt = Date()
        let unlockDate = Date().addingTimeInterval(rateLimitDuration)
        authenticationResult = .failure(.rateLimited(untilDate: unlockDate))
    }

    /// Reset all mock state
    public func reset() {
        biometricAvailability = BiometricAvailabilityBuilder.touchIDAvailable().build()
        authenticationResult = .success(AuthenticationSuccess(method: .touchID, cached: false))
        operationDelay = 0
        isBiometricAvailableCalls = 0
        authenticateCalls = 0
        invalidateAuthenticationCalls = 0
        lastAuthenticationRequest = nil
        authenticationHistory = []
        shouldAutoAuthenticate = true
        authenticationDelay = 0.1
        failedAttempts = 0
        lastFailedAttempt = nil
    }

    // MARK: - AuthenticationRepository Implementation

    public func isBiometricAvailable() async -> BiometricAvailability {
        isBiometricAvailableCalls += 1

        // Simulate delay if configured
        if operationDelay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000))
        }

        return biometricAvailability
    }

    public func authenticate(request: AuthenticationRequest) async -> AuthenticationResult {
        authenticateCalls += 1
        lastAuthenticationRequest = request
        authenticationHistory.append(request)

        // Simulate authentication dialog delay
        if authenticationDelay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(authenticationDelay * 1_000_000_000))
        }

        // Check rate limiting
        if let lastFailed = lastFailedAttempt {
            let timeSinceLastFailed = Date().timeIntervalSince(lastFailed)
            if failedAttempts >= maxFailedAttempts && timeSinceLastFailed < rateLimitDuration {
                let remainingTime = rateLimitDuration - timeSinceLastFailed
                let unlockDate = Date().addingTimeInterval(remainingTime)
                return .failure(.rateLimited(untilDate: unlockDate))
            } else if timeSinceLastFailed >= rateLimitDuration {
                // Reset rate limiting
                failedAttempts = 0
                lastFailedAttempt = nil
            }
        }

        // Update failed attempts based on result
        switch authenticationResult {
        case .failure:
            failedAttempts += 1
            lastFailedAttempt = Date()
        case .success:
            failedAttempts = 0
            lastFailedAttempt = nil
        case .cancelled:
            break // Don't count cancellation as failed attempt
        }

        return authenticationResult
    }

    public func invalidateAuthentication() async {
        invalidateAuthenticationCalls += 1

        // Clear any cached authentication
        if case .success(let success) = authenticationResult, success.cached {
            authenticationResult = .failure(.invalidRequest(reason: "Authentication invalidated"))
        }
    }
}

// MARK: - Test Helpers

extension MockAuthenticationRepository {

    /// Simulate a series of authentication attempts
    /// - Parameter results: Results to return in sequence
    public func configureSequence(_ results: [AuthenticationResult]) async {
        var index = 0
        for _ in results {
            if index < results.count {
                authenticationResult = results[index]
                index += 1
            }
        }
    }

    /// Configure for biometric not available scenario
    /// - Parameter reason: Why biometric is unavailable
    public func configureBiometricUnavailable(reason: String = "Biometric not available") {
        biometricAvailability = BiometricAvailability(
            isAvailable: false,
            biometricType: nil,
            unavailableReason: reason
        )
        authenticationResult = .failure(.biometryNotAvailable)
    }

    /// Configure for biometric lockout scenario
    public func configureBiometricLockout() {
        biometricAvailability = BiometricAvailabilityBuilder
            .lockedOut()
            .build()
        authenticationResult = .failure(.biometryLockout)
    }

    /// Verify authentication was requested with correct parameters
    /// - Parameters:
    ///   - reason: Expected reason
    ///   - policy: Expected policy
    /// - Returns: True if request matches
    public func verifyAuthenticationRequest(
        reason: String? = nil,
        policy: AuthenticationPolicy? = nil
    ) -> Bool {
        guard let request = lastAuthenticationRequest else { return false }

        if let expectedReason = reason, request.reason != expectedReason {
            return false
        }

        if let expectedPolicy = policy, request.policy != expectedPolicy {
            return false
        }

        return true
    }

    /// Get authentication attempt count for a specific reason
    /// - Parameter reason: Reason to filter by
    /// - Returns: Number of attempts
    public func getAuthenticationAttempts(for reason: String) -> Int {
        authenticationHistory.filter { $0.reason == reason }.count
    }
}
