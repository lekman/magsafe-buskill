//
//  AuthenticationBuilder.swift
//  MagSafe Guard
//
//  Created on 2025-08-03.
//
//  Test builders for creating authentication-related test data.
//  Provides fluent APIs for constructing test instances with sensible defaults.
//

import Foundation
@testable import MagSafeGuardCore
@testable import MagSafeGuardDomain

/// Builder for creating AuthenticationRequest test instances.
public final class AuthenticationRequestBuilder {
    private var reason: String = "Test authentication"
    private var policy: AuthenticationPolicy = .standard
    private var timestamp = Date()

    /// Initialize a new authentication request builder.
    public init() {}

    /// Set the authentication reason.
    /// - Parameter reason: Reason for authentication
    /// - Returns: Self for chaining
    @discardableResult
    public func reason(_ reason: String) -> AuthenticationRequestBuilder {
        self.reason = reason
        return self
    }

    /// Set the authentication policy.
    /// - Parameter policy: Policy to use
    /// - Returns: Self for chaining
    @discardableResult
    public func policy(_ policy: AuthenticationPolicy) -> AuthenticationRequestBuilder {
        self.policy = policy
        return self
    }

    /// Use high security policy.
    /// - Returns: Self for chaining
    @discardableResult
    public func highSecurity() -> AuthenticationRequestBuilder {
        self.policy = .highSecurity
        return self
    }

    /// Set the timestamp.
    /// - Parameter timestamp: Request timestamp
    /// - Returns: Self for chaining
    @discardableResult
    public func timestamp(_ timestamp: Date) -> AuthenticationRequestBuilder {
        self.timestamp = timestamp
        return self
    }

    /// Build the AuthenticationRequest instance.
    /// - Returns: Configured AuthenticationRequest
    public func build() -> AuthenticationRequest {
        return AuthenticationRequest(
            reason: reason,
            policy: policy,
            timestamp: timestamp
        )
    }
}

/// Builder for creating AuthenticationPolicy test instances.
public final class AuthenticationPolicyBuilder {
    private var requireBiometric: Bool = false
    private var allowPasswordFallback: Bool = true
    private var requireRecentAuthentication: Bool = false
    private var cacheDuration: TimeInterval = 300

    /// Initialize a new authentication policy builder.
    public init() {}

    /// Require biometric authentication.
    /// - Parameter required: Whether biometric is required
    /// - Returns: Self for chaining
    @discardableResult
    public func requireBiometric(_ required: Bool = true) -> AuthenticationPolicyBuilder {
        self.requireBiometric = required
        return self
    }

    /// Allow password fallback.
    /// - Parameter allowed: Whether password fallback is allowed
    /// - Returns: Self for chaining
    @discardableResult
    public func allowPasswordFallback(_ allowed: Bool) -> AuthenticationPolicyBuilder {
        self.allowPasswordFallback = allowed
        return self
    }

    /// Require recent authentication.
    /// - Parameter required: Whether recent auth is required
    /// - Returns: Self for chaining
    @discardableResult
    public func requireRecentAuthentication(_ required: Bool = true) -> AuthenticationPolicyBuilder {
        self.requireRecentAuthentication = required
        return self
    }

    /// Set cache duration.
    /// - Parameter duration: Cache duration in seconds
    /// - Returns: Self for chaining
    @discardableResult
    public func cacheDuration(_ duration: TimeInterval) -> AuthenticationPolicyBuilder {
        self.cacheDuration = duration
        return self
    }

    /// Build the AuthenticationPolicy instance.
    /// - Returns: Configured AuthenticationPolicy
    public func build() -> AuthenticationPolicy {
        return AuthenticationPolicy(
            requireBiometric: requireBiometric,
            allowPasswordFallback: allowPasswordFallback,
            requireRecentAuthentication: requireRecentAuthentication,
            cacheDuration: cacheDuration
        )
    }
}

/// Builder for creating authentication result test data.
public final class AuthenticationResultBuilder {

    /// Create a successful authentication result.
    /// - Parameters:
    ///   - method: Authentication method used
    ///   - cached: Whether from cache
    /// - Returns: Success result
    public static func success(
        method: AuthenticationMethod = .touchID,
        cached: Bool = false
    ) -> AuthenticationResult {
        return .success(AuthenticationSuccess(
            authenticatedAt: Date(),
            method: method,
            cached: cached
        ))
    }

    /// Create a failed authentication result.
    /// - Parameter failure: Failure reason
    /// - Returns: Failure result
    public static func failure(_ failure: AuthenticationFailure) -> AuthenticationResult {
        return .failure(failure)
    }

    /// Create a cancelled authentication result.
    /// - Returns: Cancelled result
    public static func cancelled() -> AuthenticationResult {
        return .cancelled
    }
}

/// Builder for creating BiometricAvailability test instances.
public final class BiometricAvailabilityBuilder {
    private var isAvailable: Bool = true
    private var biometricType: BiometricType? = .touchID
    private var unavailableReason: String?

    /// Initialize a new biometric availability builder.
    public init() {}

    /// Set availability status.
    /// - Parameter available: Whether biometric is available
    /// - Returns: Self for chaining
    @discardableResult
    public func available(_ available: Bool) -> BiometricAvailabilityBuilder {
        self.isAvailable = available
        if !available && biometricType != nil {
            self.biometricType = nil
        }
        return self
    }

    /// Set biometric type.
    /// - Parameter type: Type of biometric
    /// - Returns: Self for chaining
    @discardableResult
    public func type(_ type: BiometricType?) -> BiometricAvailabilityBuilder {
        self.biometricType = type
        return self
    }

    /// Set unavailable reason.
    /// - Parameter reason: Why biometric is unavailable
    /// - Returns: Self for chaining
    @discardableResult
    public func unavailableReason(_ reason: String?) -> BiometricAvailabilityBuilder {
        self.unavailableReason = reason
        return self
    }

    /// Build the BiometricAvailability instance.
    /// - Returns: Configured BiometricAvailability
    public func build() -> BiometricAvailability {
        return BiometricAvailability(
            isAvailable: isAvailable,
            biometricType: biometricType,
            unavailableReason: unavailableReason
        )
    }

    // MARK: - Preset Configurations

    /// Create Touch ID available preset.
    /// - Returns: Configured builder
    public static func touchIDAvailable() -> BiometricAvailabilityBuilder {
        return BiometricAvailabilityBuilder()
            .available(true)
            .type(.touchID)
    }

    /// Create Face ID available preset.
    /// - Returns: Configured builder
    public static func faceIDAvailable() -> BiometricAvailabilityBuilder {
        return BiometricAvailabilityBuilder()
            .available(true)
            .type(.faceID)
    }

    /// Create biometric not enrolled preset.
    /// - Returns: Configured builder
    public static func notEnrolled() -> BiometricAvailabilityBuilder {
        return BiometricAvailabilityBuilder()
            .available(false)
            .unavailableReason("No biometric data enrolled")
    }

    /// Create biometric locked out preset.
    /// - Returns: Configured builder
    public static func lockedOut() -> BiometricAvailabilityBuilder {
        return BiometricAvailabilityBuilder()
            .available(false)
            .unavailableReason("Biometric authentication locked due to too many failed attempts")
    }
}
