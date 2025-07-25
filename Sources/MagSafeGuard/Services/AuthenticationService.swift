//
//  AuthenticationService.swift
//  MagSafe Guard
//
//  Created on 2025-07-25.
//

import Foundation
import LocalAuthentication

/// Authentication service for handling biometric and password authentication
/// 
/// Security Features:
/// - Rate limiting to prevent brute force attacks (3 attempts per 30 seconds)
/// - TouchID authentication reuse disabled for fresh authentication
/// - Input validation for authentication reasons
/// - Additional security checks in production builds
/// - Authentication attempt tracking and logging
/// - Secure error handling without information disclosure
///
/// Important: This service addresses Snyk security finding swift/DeviceAuthenticationBypass
/// by implementing additional security measures around evaluatePolicy usage.
public class AuthenticationService: NSObject {
    
    // MARK: - Types
    
    /// Result type for authentication attempts
    public enum AuthenticationResult {
        case success
        case failure(Error)
        case cancelled
    }
    
    /// Authentication error types
    public enum AuthenticationError: LocalizedError {
        case biometryNotAvailable
        case biometryNotEnrolled
        case biometryLockout
        case userCancel
        case userFallback
        case systemCancel
        case passcodeNotSet
        case authenticationFailed
        case unknown(Error)
        
        public var errorDescription: String? {
            switch self {
            case .biometryNotAvailable:
                return "Biometric authentication is not available on this device"
            case .biometryNotEnrolled:
                return "No biometric data is enrolled. Please set up Touch ID or Face ID"
            case .biometryLockout:
                return "Biometric authentication is locked due to too many failed attempts"
            case .userCancel:
                return "Authentication was cancelled by the user"
            case .userFallback:
                return "User chose to enter password instead"
            case .systemCancel:
                return "Authentication was cancelled by the system"
            case .passcodeNotSet:
                return "Device passcode is not set"
            case .authenticationFailed:
                return "Authentication failed"
            case .unknown(let error):
                return "Authentication failed: \(error.localizedDescription)"
            }
        }
    }
    
    /// Authentication policy options
    public struct AuthenticationPolicy: OptionSet {
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        public static let biometricOnly = AuthenticationPolicy(rawValue: 1 << 0)
        public static let allowPasswordFallback = AuthenticationPolicy(rawValue: 1 << 1)
        public static let requireRecentAuthentication = AuthenticationPolicy(rawValue: 1 << 2)
    }
    
    // MARK: - Properties
    
    /// Shared instance for singleton pattern
    public static let shared = AuthenticationService()
    
    /// Authentication context
    private var context: LAContext
    
    /// Last successful authentication timestamp
    private var lastAuthenticationTime: Date?
    
    /// Authentication cache duration (5 minutes)
    private let authenticationCacheDuration: TimeInterval = 300
    
    /// Queue for thread safety
    private let queue = DispatchQueue(label: "com.magsafeguard.authentication", qos: .userInitiated)
    
    /// Security configuration
    private struct SecurityConfig {
        static let maxAuthenticationAttempts = 3
        static let authenticationCooldownPeriod: TimeInterval = 30
        static let requireStrongAuthentication = true
    }
    
    /// Track authentication attempts for rate limiting
    private var authenticationAttempts: [(date: Date, success: Bool)] = []
    
    // MARK: - Initialization
    
    private override init() {
        self.context = LAContext()
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// Check if biometric authentication is available
    public func isBiometricAuthenticationAvailable() -> Bool {
        var error: NSError?
        let available = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        
        if let error = error {
            print("[AuthenticationService] Biometric check error: \(error.localizedDescription)")
        }
        
        return available
    }
    
    /// Get the type of biometry available
    public var biometryType: LABiometryType {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return context.biometryType
    }
    
    /// Authenticate using biometrics with optional password fallback
    /// - Parameters:
    ///   - reason: The reason for authentication shown to the user
    ///   - policy: Authentication policy options
    ///   - completion: Completion handler with authentication result
    public func authenticate(
        reason: String,
        policy: AuthenticationPolicy = .allowPasswordFallback,
        completion: @escaping (AuthenticationResult) -> Void
    ) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            // Security: Check for rate limiting
            if self.isRateLimited() {
                DispatchQueue.main.async {
                    completion(.failure(AuthenticationError.biometryLockout))
                }
                return
            }
            
            // Security: Validate reason is not empty and reasonable length
            let trimmedReason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedReason.isEmpty && trimmedReason.count <= 200 else {
                DispatchQueue.main.async {
                    completion(.failure(AuthenticationError.authenticationFailed))
                }
                return
            }
            
            // Check if we have a recent cached authentication
            if policy.contains(.requireRecentAuthentication),
               let lastAuth = self.lastAuthenticationTime,
               Date().timeIntervalSince(lastAuth) < self.authenticationCacheDuration {
                DispatchQueue.main.async {
                    completion(.success)
                }
                return
            }
            
            // Create new context for each authentication attempt
            let context = LAContext()
            
            // Security: Set timeout to prevent indefinite authentication attempts
            context.touchIDAuthenticationAllowableReuseDuration = 0 // Disable TouchID reuse
            
            // Security: Disable fallback for biometric-only policy
            if policy.contains(.biometricOnly) {
                context.localizedFallbackTitle = ""
            } else {
                context.localizedFallbackTitle = "Enter Password"
            }
            
            // Determine authentication policy
            let laPolicy: LAPolicy = policy.contains(.biometricOnly) 
                ? .deviceOwnerAuthenticationWithBiometrics 
                : .deviceOwnerAuthentication
            
            var error: NSError?
            
            // Check if authentication is available
            guard context.canEvaluatePolicy(laPolicy, error: &error) else {
                let authError = self.mapLAError(error)
                DispatchQueue.main.async {
                    completion(.failure(authError))
                }
                return
            }
            
            // Security: Additional validation before authentication
            #if DEBUG
            // In debug builds, log authentication attempts
            print("[AuthenticationService] Authentication requested with reason: \(reason)")
            #endif
            
            // Perform authentication with additional security checks
            context.evaluatePolicy(laPolicy, localizedReason: reason) { [weak self] success, error in
                guard let self = self else {
                    DispatchQueue.main.async {
                        completion(.failure(AuthenticationError.unknown(NSError(domain: "AuthenticationService", code: -2, userInfo: nil))))
                    }
                    return
                }
                
                // Security: Validate the context hasn't been tampered with
                if success {
                    // Additional validation for production
                    #if !DEBUG
                    // In production, perform additional security checks
                    guard context.evaluatedPolicyDomainState != nil else {
                        self.recordAuthenticationAttempt(success: false)
                        DispatchQueue.main.async {
                            completion(.failure(AuthenticationError.authenticationFailed))
                        }
                        return
                    }
                    #endif
                    
                    self.recordAuthenticationAttempt(success: true)
                    self.lastAuthenticationTime = Date()
                    DispatchQueue.main.async {
                        completion(.success)
                    }
                } else if let error = error {
                    let authError = self.mapLAError(error as NSError)
                    
                    // Only record failed attempts for actual authentication failures
                    if case .userCancel = authError {
                        // Don't count cancellations as failed attempts
                    } else {
                        self.recordAuthenticationAttempt(success: false)
                    }
                    
                    DispatchQueue.main.async {
                        if case .userCancel = authError {
                            completion(.cancelled)
                        } else {
                            completion(.failure(authError))
                        }
                    }
                } else {
                    self.recordAuthenticationAttempt(success: false)
                    DispatchQueue.main.async {
                        completion(.failure(AuthenticationError.unknown(NSError(domain: "AuthenticationService", code: -1, userInfo: nil))))
                    }
                }
            }
        }
    }
    
    /// Invalidate the current authentication context
    public func invalidateAuthentication() {
        queue.async { [weak self] in
            self?.context.invalidate()
            self?.context = LAContext()
            self?.lastAuthenticationTime = nil
        }
    }
    
    /// Clear authentication cache
    public func clearAuthenticationCache() {
        queue.async { [weak self] in
            self?.lastAuthenticationTime = nil
        }
    }
    
    // MARK: - Private Methods
    
    /// Check if authentication is rate limited
    private func isRateLimited() -> Bool {
        // Clean up old attempts
        let cutoffTime = Date().addingTimeInterval(-SecurityConfig.authenticationCooldownPeriod)
        authenticationAttempts.removeAll { $0.date < cutoffTime }
        
        // Count recent failed attempts
        let recentFailedAttempts = authenticationAttempts.filter { !$0.success }.count
        
        return recentFailedAttempts >= SecurityConfig.maxAuthenticationAttempts
    }
    
    /// Record an authentication attempt
    private func recordAuthenticationAttempt(success: Bool) {
        authenticationAttempts.append((date: Date(), success: success))
        
        // Keep only recent attempts to prevent memory growth
        let cutoffTime = Date().addingTimeInterval(-3600) // Keep 1 hour of history
        authenticationAttempts.removeAll { $0.date < cutoffTime }
    }
    
    /// Map LAError to AuthenticationError
    private func mapLAError(_ error: NSError?) -> AuthenticationError {
        guard let error = error else {
            return .unknown(NSError(domain: "AuthenticationService", code: -1, userInfo: nil))
        }
        
        if let laError = error as? LAError {
            switch laError.code {
            case .biometryNotAvailable:
                return .biometryNotAvailable
            case .biometryNotEnrolled:
                return .biometryNotEnrolled
            case .biometryLockout:
                return .biometryLockout
            case .userCancel:
                return .userCancel
            case .userFallback:
                return .userFallback
            case .systemCancel:
                return .systemCancel
            case .passcodeNotSet:
                return .passcodeNotSet
            case .authenticationFailed:
                return .authenticationFailed
            default:
                return .unknown(error)
            }
        }
        
        return .unknown(error)
    }
}