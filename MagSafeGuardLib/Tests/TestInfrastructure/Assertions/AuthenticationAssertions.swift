//
//  AuthenticationAssertions.swift
//  MagSafe Guard
//
//  Created on 2025-08-03.
//
//  Custom assertions for authentication testing with Swift Testing.
//  Provides domain-specific assertions for clearer test intent.
//

import Foundation
@testable import MagSafeGuardCore
@testable import MagSafeGuardDomain
import Testing

/// Custom assertions for authentication testing
public struct AuthenticationAssertions {

    /// Assert authentication succeeded
    /// - Parameters:
    ///   - result: Authentication result to check
    ///   - expectedMethod: Expected authentication method (optional)
    ///   - sourceLocation: Source location for test failure
    public static func assertSuccess(
        _ result: AuthenticationResult,
        method expectedMethod: AuthenticationMethod? = nil,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        guard case .success(let success) = result else {
            Issue.record(
                "Expected authentication success but got \(result)",
                sourceLocation: sourceLocation
            )
            return
        }

        if let expectedMethod = expectedMethod {
            #expect(
                success.method == expectedMethod,
                "Expected authentication method \(expectedMethod) but got \(success.method)",
                sourceLocation: sourceLocation
            )
        }
    }

    /// Assert authentication failed
    /// - Parameters:
    ///   - result: Authentication result to check
    ///   - expectedFailure: Expected failure reason (optional)
    ///   - sourceLocation: Source location for test failure
    public static func assertFailure(
        _ result: AuthenticationResult,
        reason expectedFailure: AuthenticationFailure? = nil,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        guard case .failure(let failure) = result else {
            Issue.record(
                "Expected authentication failure but got \(result)",
                sourceLocation: sourceLocation
            )
            return
        }

        if let expectedFailure = expectedFailure {
            #expect(
                failure == expectedFailure,
                "Expected failure \(expectedFailure) but got \(failure)",
                sourceLocation: sourceLocation
            )
        }
    }

    /// Assert authentication was cancelled
    /// - Parameters:
    ///   - result: Authentication result to check
    ///   - sourceLocation: Source location for test failure
    public static func assertCancelled(
        _ result: AuthenticationResult,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        guard case .cancelled = result else {
            Issue.record(
                "Expected authentication cancelled but got \(result)",
                sourceLocation: sourceLocation
            )
            return
        }
    }

    /// Assert biometric is available
    /// - Parameters:
    ///   - availability: Biometric availability to check
    ///   - expectedType: Expected biometric type (optional)
    ///   - sourceLocation: Source location for test failure
    public static func assertBiometricAvailable(
        _ availability: BiometricAvailability,
        type expectedType: BiometricType? = nil,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        #expect(
            availability.isAvailable,
            "Expected biometric to be available but was unavailable: \(availability.unavailableReason ?? "unknown")",
            sourceLocation: sourceLocation
        )

        if let expectedType = expectedType {
            #expect(
                availability.biometricType == expectedType,
                "Expected biometric type \(expectedType) but got \(String(describing: availability.biometricType))",
                sourceLocation: sourceLocation
            )
        }
    }

    /// Assert biometric is not available
    /// - Parameters:
    ///   - availability: Biometric availability to check
    ///   - sourceLocation: Source location for test failure
    public static func assertBiometricUnavailable(
        _ availability: BiometricAvailability,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        #expect(
            !availability.isAvailable,
            "Expected biometric to be unavailable but was available",
            sourceLocation: sourceLocation
        )
    }

    /// Assert authentication policy matches expected values
    /// - Parameters:
    ///   - policy: Policy to check
    ///   - requireBiometric: Expected biometric requirement
    ///   - allowPasswordFallback: Expected password fallback
    ///   - sourceLocation: Source location for test failure
    public static func assertPolicy(
        _ policy: AuthenticationPolicy,
        requireBiometric: Bool? = nil,
        allowPasswordFallback: Bool? = nil,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        if let expectedBiometric = requireBiometric {
            #expect(
                policy.requireBiometric == expectedBiometric,
                "Expected requireBiometric to be \(expectedBiometric) but was \(policy.requireBiometric)",
                sourceLocation: sourceLocation
            )
        }

        if let expectedFallback = allowPasswordFallback {
            #expect(
                policy.allowPasswordFallback == expectedFallback,
                "Expected allowPasswordFallback to be \(expectedFallback) but was \(policy.allowPasswordFallback)",
                sourceLocation: sourceLocation
            )
        }
    }
}

// MARK: - Rate Limiting Assertions

extension AuthenticationAssertions {

    /// Assert authentication is rate limited
    /// - Parameters:
    ///   - result: Authentication result to check
    ///   - minimumWait: Minimum expected wait time
    ///   - sourceLocation: Source location for test failure
    public static func assertRateLimited(
        _ result: AuthenticationResult,
        minimumWait: TimeInterval? = nil,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        guard case .failure(let failure) = result,
              case .rateLimited(let untilDate) = failure else {
            Issue.record(
                "Expected rate limited failure but got \(result)",
                sourceLocation: sourceLocation
            )
            return
        }

        if let minimumWait = minimumWait {
            let actualWait = untilDate.timeIntervalSinceNow
            #expect(
                actualWait >= minimumWait - 1, // Allow 1 second tolerance
                "Expected minimum wait of \(minimumWait)s but got \(actualWait)s",
                sourceLocation: sourceLocation
            )
        }
    }

    /// Assert biometric is locked out
    /// - Parameters:
    ///   - result: Authentication result to check
    ///   - sourceLocation: Source location for test failure
    public static func assertBiometryLockout(
        _ result: AuthenticationResult,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        assertFailure(result, reason: .biometryLockout, sourceLocation: sourceLocation)
    }
}

// MARK: - Convenience Extensions

/// Extension for more natural assertion syntax
extension AuthenticationResult {

    /// Assert this result is success
    /// - Parameters:
    ///   - method: Expected method (optional)
    ///   - sourceLocation: Source location for test failure
    public func assertSuccess(
        method: AuthenticationMethod? = nil,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        AuthenticationAssertions.assertSuccess(self, method: method, sourceLocation: sourceLocation)
    }

    /// Assert this result is failure
    /// - Parameters:
    ///   - reason: Expected failure reason (optional)
    ///   - sourceLocation: Source location for test failure
    public func assertFailure(
        reason: AuthenticationFailure? = nil,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        AuthenticationAssertions.assertFailure(self, reason: reason, sourceLocation: sourceLocation)
    }

    /// Assert this result is cancelled
    /// - Parameter sourceLocation: Source location for test failure
    public func assertCancelled(
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        AuthenticationAssertions.assertCancelled(self, sourceLocation: sourceLocation)
    }

    /// Assert this result is rate limited
    /// - Parameters:
    ///   - minimumWait: Minimum expected wait time
    ///   - sourceLocation: Source location for test failure
    public func assertRateLimited(
        minimumWait: TimeInterval? = nil,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        AuthenticationAssertions.assertRateLimited(
            self,
            minimumWait: minimumWait,
            sourceLocation: sourceLocation
        )
    }
}

/// Extension for biometric availability assertions
extension BiometricAvailability {

    /// Assert biometric is available
    /// - Parameters:
    ///   - type: Expected type (optional)
    ///   - sourceLocation: Source location for test failure
    public func assertAvailable(
        type: BiometricType? = nil,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        AuthenticationAssertions.assertBiometricAvailable(
            self,
            type: type,
            sourceLocation: sourceLocation
        )
    }

    /// Assert biometric is unavailable
    /// - Parameter sourceLocation: Source location for test failure
    public func assertUnavailable(
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        AuthenticationAssertions.assertBiometricUnavailable(self, sourceLocation: sourceLocation)
    }
}
