//
//  AuthenticationProtocols.swift
//  MagSafe Guard
//
//  Created on 2025-08-03.
//
//  Domain layer protocols for authentication following Clean Architecture.
//  These protocols define the business rules for user authentication
//  independent of any system implementation details.
//

import Foundation

// MARK: - Domain Models

/// Domain model representing an authentication request.
/// Encapsulates all information needed to authenticate a user.
public struct AuthenticationRequest: Equatable {
    /// The reason for authentication shown to the user
    public let reason: String
    /// The authentication policy to apply
    public let policy: AuthenticationPolicy
    /// When the authentication was requested
    public let timestamp: Date

    /// Initialize an authentication request.
    /// - Parameters:
    ///   - reason: The reason shown to the user
    ///   - policy: Authentication policy to use (defaults to standard)
    ///   - timestamp: When the request was created
    public init(
        reason: String,
        policy: AuthenticationPolicy = .standard,
        timestamp: Date = Date()
    ) {
        self.reason = reason
        self.policy = policy
        self.timestamp = timestamp
    }
}

/// Domain model for authentication policy options.
/// Defines the rules and constraints for authentication.
public struct AuthenticationPolicy: Equatable {
    /// Whether biometric authentication is required
    public let requireBiometric: Bool
    /// Whether password can be used if biometric fails
    public let allowPasswordFallback: Bool
    /// Whether cached authentication must be recent
    public let requireRecentAuthentication: Bool
    /// How long authentication remains valid (seconds)
    public let cacheDuration: TimeInterval

    /// Initialize an authentication policy.
    /// - Parameters:
    ///   - requireBiometric: Whether biometric is required
    ///   - allowPasswordFallback: Whether password fallback is allowed
    ///   - requireRecentAuthentication: Whether cached auth must be recent
    ///   - cacheDuration: How long authentication remains valid (seconds)
    public init(
        requireBiometric: Bool = false,
        allowPasswordFallback: Bool = true,
        requireRecentAuthentication: Bool = false,
        cacheDuration: TimeInterval = 300
    ) {
        self.requireBiometric = requireBiometric
        self.allowPasswordFallback = allowPasswordFallback
        self.requireRecentAuthentication = requireRecentAuthentication
        self.cacheDuration = cacheDuration
    }

    /// Standard authentication policy with password fallback.
    /// Suitable for general authentication needs.
    public static let standard = AuthenticationPolicy()

    /// High security policy requiring biometric only.
    /// Use for sensitive operations like disarming.
    public static let highSecurity = AuthenticationPolicy(
        requireBiometric: true,
        allowPasswordFallback: false,
        requireRecentAuthentication: true,
        cacheDuration: 60
    )
}

/// Domain model representing authentication result.
/// Captures all possible outcomes of an authentication attempt.
public enum AuthenticationResult: Equatable {
    /// Authentication succeeded
    case success(AuthenticationSuccess)
    /// Authentication failed with reason
    case failure(AuthenticationFailure)
    /// User cancelled authentication
    case cancelled

    /// Whether the authentication was successful.
    public var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
}

/// Authentication success details.
/// Contains information about a successful authentication.
public struct AuthenticationSuccess: Equatable {
    /// When the authentication occurred
    public let authenticatedAt: Date
    /// The method used to authenticate
    public let method: AuthenticationMethod
    /// Whether this was from cache vs fresh authentication
    public let cached: Bool

    /// Initialize authentication success details.
    /// - Parameters:
    ///   - authenticatedAt: When authentication occurred
    ///   - method: The method used to authenticate
    ///   - cached: Whether this was from cache
    public init(
        authenticatedAt: Date = Date(),
        method: AuthenticationMethod,
        cached: Bool = false
    ) {
        self.authenticatedAt = authenticatedAt
        self.method = method
        self.cached = cached
    }
}

/// Authentication method used.
/// Identifies how the user authenticated.
public enum AuthenticationMethod: String, Equatable {
    /// Touch ID fingerprint authentication
    case touchID = "TouchID"
    /// Face ID facial recognition
    case faceID = "FaceID"
    /// System password authentication
    case password = "Password"
    /// Previously cached authentication
    case cached = "Cached"
}

/// Authentication failure reasons.
/// Comprehensive list of why authentication might fail.
public enum AuthenticationFailure: Equatable {
    /// Biometric hardware not available on device
    case biometryNotAvailable
    /// User has not enrolled any biometric data
    case biometryNotEnrolled
    /// Biometry locked due to too many failed attempts
    case biometryLockout
    /// Device passcode not configured
    case passcodeNotSet
    /// Authentication rate limited until specified date
    case rateLimited(untilDate: Date)
    /// Invalid authentication request
    case invalidRequest(reason: String)
    /// System-level authentication error
    case systemError(description: String)

    /// User-friendly error message.
    public var userMessage: String {
        switch self {
        case .biometryNotAvailable:
            return "Biometric authentication is not available on this device"
        case .biometryNotEnrolled:
            return "No biometric data is enrolled. Please set up Touch ID or Face ID"
        case .biometryLockout:
            return "Biometric authentication is locked due to too many failed attempts"
        case .passcodeNotSet:
            return "Device passcode is not set"
        case .rateLimited(let date):
            let formatter = RelativeDateTimeFormatter()
            let remaining = formatter.localizedString(for: date, relativeTo: Date())
            return "Too many attempts. Try again \(remaining)"
        case .invalidRequest(let reason):
            return "Invalid authentication request: \(reason)"
        case .systemError(let description):
            return "Authentication failed: \(description)"
        }
    }
}

// MARK: - Repository Protocol

/// Repository protocol for device authentication.
/// Abstracts the system-level authentication implementation.
public protocol AuthenticationRepository {
    /// Check if biometric authentication is available.
    /// - Returns: Availability status and biometric type
    func isBiometricAvailable() async -> BiometricAvailability

    /// Perform authentication with the device.
    /// - Parameter request: The authentication request details
    /// - Returns: Result of the authentication attempt
    func authenticate(request: AuthenticationRequest) async -> AuthenticationResult

    /// Invalidate any active authentication sessions.
    /// - Note: This clears any cached authentication
    func invalidateAuthentication() async
}

/// Biometric availability information.
/// Details about biometric authentication capabilities.
public struct BiometricAvailability: Equatable {
    /// Whether biometric authentication is available
    public let isAvailable: Bool
    /// The type of biometric available
    public let biometricType: BiometricType?
    /// Reason if biometric is unavailable
    public let unavailableReason: String?

    /// Initialize biometric availability information.
    /// - Parameters:
    ///   - isAvailable: Whether biometric is available
    ///   - biometricType: Type of biometric if available
    ///   - unavailableReason: Reason if unavailable
    public init(
        isAvailable: Bool,
        biometricType: BiometricType? = nil,
        unavailableReason: String? = nil
    ) {
        self.isAvailable = isAvailable
        self.biometricType = biometricType
        self.unavailableReason = unavailableReason
    }
}

/// Type of biometric authentication.
/// Different biometric methods available on Apple devices.
public enum BiometricType: String, Equatable {
    /// Touch ID fingerprint sensor
    case touchID = "TouchID"
    /// Face ID facial recognition
    case faceID = "FaceID"
    /// Optic ID iris scanning (Vision Pro)
    case opticID = "OpticID"
}

// MARK: - Use Case Protocols

/// Use case for user authentication.
/// Encapsulates business logic for authenticating users.
public protocol AuthenticationUseCase {
    /// Authenticate the user with specified policy.
    /// - Parameters:
    ///   - reason: The reason shown to the user
    ///   - policy: Authentication policy to apply
    /// - Returns: Result of the authentication attempt
    func authenticate(reason: String, policy: AuthenticationPolicy) async -> AuthenticationResult

    /// Check if biometric authentication is available.
    /// - Returns: Biometric availability information
    func checkBiometricAvailability() async -> BiometricAvailability

    /// Clear authentication cache.
    /// - Note: Forces fresh authentication on next attempt
    func clearAuthenticationCache() async

    /// Get last successful authentication info.
    /// - Returns: Details of last authentication, if any
    func getLastAuthentication() async -> AuthenticationSuccess?
}

/// Use case for managing authentication state.
/// Tracks and manages the authentication lifecycle.
public protocol AuthenticationStateUseCase {
    /// Check if user is currently authenticated (within cache period).
    /// - Parameter policy: Policy to check against
    /// - Returns: True if authenticated within policy constraints
    func isAuthenticated(policy: AuthenticationPolicy) async -> Bool

    /// Invalidate current authentication.
    /// - Note: User will need to re-authenticate
    func invalidateAuthentication() async

    /// Get authentication history.
    /// - Returns: List of recent authentication attempts
    func getAuthenticationHistory() async -> [AuthenticationAttempt]
}

/// Authentication attempt record.
/// Historical record of an authentication attempt.
public struct AuthenticationAttempt: Equatable {
    /// When the attempt occurred
    public let timestamp: Date
    /// Whether it succeeded
    public let success: Bool
    /// Method used if successful
    public let method: AuthenticationMethod?
    /// The reason provided for authentication
    public let reason: String

    /// Initialize an authentication attempt record.
    /// - Parameters:
    ///   - timestamp: When the attempt occurred
    ///   - success: Whether it succeeded
    ///   - method: Method used if successful
    ///   - reason: The reason provided
    public init(
        timestamp: Date,
        success: Bool,
        method: AuthenticationMethod? = nil,
        reason: String
    ) {
        self.timestamp = timestamp
        self.success = success
        self.method = method
        self.reason = reason
    }
}

// MARK: - Security Configuration

/// Security configuration for authentication.
/// Defines security policies and constraints.
public struct AuthenticationSecurityConfig {
    /// Maximum failed attempts before rate limiting
    public let maxFailedAttempts: Int

    /// Cooldown period after max attempts reached (seconds)
    public let rateLimitDuration: TimeInterval

    /// Maximum reason string length
    public let maxReasonLength: Int

    /// Whether to log authentication attempts
    public let logAuthenticationAttempts: Bool

    /// Initialize authentication security configuration.
    /// - Parameters:
    ///   - maxFailedAttempts: Max attempts before rate limiting
    ///   - rateLimitDuration: Cooldown period (seconds)
    ///   - maxReasonLength: Maximum reason string length
    ///   - logAuthenticationAttempts: Whether to log attempts
    public init(
        maxFailedAttempts: Int = 3,
        rateLimitDuration: TimeInterval = 30,
        maxReasonLength: Int = 200,
        logAuthenticationAttempts: Bool = true
    ) {
        self.maxFailedAttempts = maxFailedAttempts
        self.rateLimitDuration = rateLimitDuration
        self.maxReasonLength = maxReasonLength
        self.logAuthenticationAttempts = logAuthenticationAttempts
    }

    /// Default security configuration.
    /// Balanced for usability and security.
    public static let `default` = AuthenticationSecurityConfig()

    /// High security configuration with stricter limits.
    /// Use for sensitive environments.
    public static let highSecurity = AuthenticationSecurityConfig(
        maxFailedAttempts: 2,
        rateLimitDuration: 60,
        maxReasonLength: 100,
        logAuthenticationAttempts: true
    )
}
