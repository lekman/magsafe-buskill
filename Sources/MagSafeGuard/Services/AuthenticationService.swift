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
    public enum AuthenticationError: LocalizedError, Equatable {
        case biometryNotAvailable
        case biometryNotEnrolled
        case biometryLockout
        case userCancel
        case userFallback
        case systemCancel
        case passcodeNotSet
        case authenticationFailed
        case unknown(Error)
        
        public static func == (lhs: AuthenticationError, rhs: AuthenticationError) -> Bool {
            switch (lhs, rhs) {
            case (.biometryNotAvailable, .biometryNotAvailable),
                 (.biometryNotEnrolled, .biometryNotEnrolled),
                 (.biometryLockout, .biometryLockout),
                 (.userCancel, .userCancel),
                 (.userFallback, .userFallback),
                 (.systemCancel, .systemCancel),
                 (.passcodeNotSet, .passcodeNotSet),
                 (.authenticationFailed, .authenticationFailed):
                return true
            case (.unknown(let lhsError), .unknown(let rhsError)):
                return (lhsError as NSError).code == (rhsError as NSError).code &&
                       (lhsError as NSError).domain == (rhsError as NSError).domain
            default:
                return false
            }
        }
        
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
    
    /// Factory for creating authentication contexts
    internal let contextFactory: AuthenticationContextFactoryProtocol
    
    /// Current authentication context
    internal var context: AuthenticationContextProtocol?
    
    /// Last successful authentication timestamp
    internal var lastAuthenticationTime: Date?
    
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
        self.contextFactory = RealAuthenticationContextFactory()
        super.init()
    }
    
    /// Initialize with custom context factory (for testing)
    internal init(contextFactory: AuthenticationContextFactoryProtocol) {
        self.contextFactory = contextFactory
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// Check if biometric authentication is available
    public func isBiometricAuthenticationAvailable() -> Bool {
        let authContext = contextFactory.createContext()
        var error: NSError?
        let available = authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        
        if let error = error {
            print("[AuthenticationService] Biometric check error: \(error.localizedDescription)")
        }
        
        return available
    }
    
    /// Get the type of biometry available
    public var biometryType: LABiometryType {
        let authContext = contextFactory.createContext()
        _ = authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return authContext.biometryType
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
            guard let self = self else { 
                DispatchQueue.main.async {
                    completion(.failure(AuthenticationError.unknown(NSError(domain: "AuthenticationService", code: -3, userInfo: nil))))
                }
                return 
            }
            
            // Perform pre-authentication checks
            if let earlyResult = self.performPreAuthenticationChecks(reason: reason, policy: policy) {
                DispatchQueue.main.async {
                    completion(earlyResult)
                }
                return
            }
            
            // Setup and perform authentication
            self.performAuthentication(reason: reason, policy: policy, completion: completion)
        }
    }
    
    // MARK: - Authentication Helper Methods
    
    /// Perform pre-authentication security checks
    internal func performPreAuthenticationChecks(reason: String, policy: AuthenticationPolicy) -> AuthenticationResult? {
        // Check rate limiting
        if isRateLimited() {
            return .failure(AuthenticationError.biometryLockout)
        }
        
        // Validate input
        let trimmedReason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedReason.isEmpty && trimmedReason.count <= 200 else {
            return .failure(AuthenticationError.authenticationFailed)
        }
        
        // Check cached authentication
        if policy.contains(.requireRecentAuthentication),
           let lastAuth = lastAuthenticationTime,
           Date().timeIntervalSince(lastAuth) < authenticationCacheDuration {
            return .success
        }
        
        return nil
    }
    
    /// Perform the actual authentication
    private func performAuthentication(reason: String, policy: AuthenticationPolicy, completion: @escaping (AuthenticationResult) -> Void) {
        // Delegate to LAContext-specific implementation
        performAuthenticationWithLAContext(reason: reason, policy: policy, completion: completion)
    }
    
    /// Invalidate the current authentication context
    public func invalidateAuthentication() {
        queue.async { [weak self] in
            self?.context?.invalidate()
            self?.context = nil
            self?.lastAuthenticationTime = nil
        }
    }
    
    /// Clear authentication cache
    public func clearAuthenticationCache() {
        queue.async { [weak self] in
            self?.lastAuthenticationTime = nil
        }
    }
    
    /// Reset authentication attempts (for testing only)
    internal func resetAuthenticationAttempts() {
        queue.sync {
            authenticationAttempts.removeAll()
        }
    }
    
    // MARK: - Private Methods
    
    /// Check if authentication is rate limited
    internal func isRateLimited() -> Bool {
        // Clean up old attempts
        let cutoffTime = Date().addingTimeInterval(-SecurityConfig.authenticationCooldownPeriod)
        authenticationAttempts.removeAll { $0.date < cutoffTime }
        
        // Count recent failed attempts
        let recentFailedAttempts = authenticationAttempts.filter { !$0.success }.count
        
        return recentFailedAttempts >= SecurityConfig.maxAuthenticationAttempts
    }
    
    /// Record an authentication attempt
    internal func recordAuthenticationAttempt(success: Bool) {
        queue.sync {
            authenticationAttempts.append((date: Date(), success: success))
            
            // Keep only recent attempts to prevent memory growth
            let cutoffTime = Date().addingTimeInterval(-3600) // Keep 1 hour of history
            authenticationAttempts.removeAll { $0.date < cutoffTime }
        }
    }
    
    /// Map LAError to AuthenticationError
    internal func mapLAError(_ error: NSError?) -> AuthenticationError {
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