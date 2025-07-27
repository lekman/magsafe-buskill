//
//  AuthenticationService.swift
//  MagSafe Guard
//
//  Created on 2025-07-25.
//

import Foundation
import LocalAuthentication

/// Authentication service for handling biometric and password authentication.
///
/// AuthenticationService provides secure user authentication using Touch ID, Face ID,
/// or device passcode with comprehensive security measures to prevent bypass attacks
/// and brute force attempts.
///
/// ## Security Features
///
/// - **Rate Limiting**: Prevents brute force attacks (3 attempts per 30 seconds)
/// - **Fresh Authentication**: TouchID reuse disabled for security-critical operations
/// - **Input Validation**: Validates authentication reasons and parameters
/// - **Attempt Tracking**: Logs authentication attempts for security monitoring
/// - **Secure Error Handling**: Prevents information disclosure through error messages
/// - **Context Invalidation**: Ensures authentication contexts are properly cleaned up
///
/// ## Compliance
///
/// This service addresses Snyk security finding `swift/DeviceAuthenticationBypass`
/// by implementing additional security measures around `evaluatePolicy` usage,
/// including proper context management and validation.
///
/// ## Usage
///
/// ```swift
/// AuthenticationService.shared.authenticate(reason: "Unlock security settings") { result in
///     switch result {
///     case .success:
///         // Proceed with authenticated action
///     case .failure(let error):
///         // Handle authentication failure
///     case .cancelled:
///         // User cancelled authentication
///     }
/// }
/// ```
///
/// ## Thread Safety
///
/// All methods are thread-safe and use a dedicated serial queue for authentication
/// operations. Completion handlers are always called on the main queue.
public class AuthenticationService: NSObject {

    // MARK: - Types

    /// Result type for authentication attempts.
    ///
    /// Represents the outcome of an authentication request with specific
    /// cases for successful authentication, failures, and user cancellation.
    public enum AuthenticationResult {
        /// Authentication completed successfully
        case success
        /// Authentication failed with specific error
        case failure(Error)
        /// User cancelled the authentication dialog
        case cancelled
    }

    /// Authentication error types with detailed failure reasons.
    ///
    /// Provides specific error cases for different authentication failures,
    /// enabling appropriate user messaging and error handling strategies.
    public enum AuthenticationError: LocalizedError, Equatable {
        /// Device does not support biometric authentication
        case biometryNotAvailable
        /// User has not enrolled any biometric credentials
        case biometryNotEnrolled
        /// Biometry is locked out due to too many failed attempts
        case biometryLockout
        /// User explicitly cancelled the authentication dialog
        case userCancel
        /// User chose to use password/passcode instead of biometry
        case userFallback
        /// System cancelled authentication (e.g., app moved to background)
        case systemCancel
        /// Device does not have a passcode set
        case passcodeNotSet
        /// Authentication attempt failed (wrong credentials)
        case authenticationFailed
        /// An unknown error occurred during authentication
        case unknown(Error)

        /// Compares two authentication errors for equality
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

        /// Provides a localized description of the authentication error
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

    /// Authentication policy options for controlling authentication behavior.
    ///
    /// Allows customization of authentication requirements and fallback options
    /// based on security needs and user experience requirements.
    public struct AuthenticationPolicy: OptionSet {
        /// The raw value of the authentication policy option
        public let rawValue: Int

        /// Creates a new authentication policy with the specified raw value
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        /// Require biometric authentication only (no password fallback)
        public static let biometricOnly = AuthenticationPolicy(rawValue: 1 << 0)
        /// Allow fallback to device passcode if biometrics fail
        public static let allowPasswordFallback = AuthenticationPolicy(rawValue: 1 << 1)
        /// Use cached authentication if recent (within 5 minutes)
        public static let requireRecentAuthentication = AuthenticationPolicy(rawValue: 1 << 2)
    }

    // MARK: - Properties

    /// Shared instance for singleton pattern.
    ///
    /// The shared instance provides global access to authentication functionality.
    /// All components should use this instance for consistent authentication state.
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

    /// Check if biometric authentication is available on this device.
    ///
    /// Determines whether Touch ID or Face ID is available and properly
    /// configured for use. This check is performed immediately without
    /// prompting the user.
    ///
    /// - Returns: True if biometric authentication is available and enrolled
    public func isBiometricAuthenticationAvailable() -> Bool {
        let authContext = contextFactory.createContext()
        var error: NSError?
        let available = authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        if let error = error {
            Log.error("Biometric check error", error: error, category: .authentication)
        }

        return available
    }

    /// The type of biometric authentication available on this device.
    ///
    /// Returns the specific biometry type (Touch ID, Face ID, or none)
    /// supported by the current device. This property performs a capability
    /// check and returns the result from LocalAuthentication framework.
    public var biometryType: LABiometryType {
        let authContext = contextFactory.createContext()
        _ = authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return authContext.biometryType
    }

    /// Authenticate the user using biometrics with optional password fallback.
    ///
    /// Initiates user authentication using the device's biometric sensors
    /// (Touch ID/Face ID) or device passcode based on the specified policy.
    /// The authentication includes security checks, rate limiting, and proper
    /// error handling.
    ///
    /// ## Security Features
    ///
    /// - Rate limiting prevents brute force attacks
    /// - Input validation ensures safe authentication reasons
    /// - Fresh authentication context for each request
    /// - Secure error mapping prevents information disclosure
    ///
    /// - Parameters:
    ///   - reason: User-facing explanation for why authentication is needed
    ///   - policy: Authentication policy controlling behavior and fallbacks
    ///   - completion: Result handler called on main queue
    ///
    /// - Note: The completion handler is always called on the main queue
    ///   for UI safety, regardless of which thread initiated the call
    public func authenticate(
        reason: String,
        policy: AuthenticationPolicy = .allowPasswordFallback,
        completion: @escaping (AuthenticationResult) -> Void
    ) {
        queue.async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async {
                    let error = NSError(
                        domain: "AuthenticationService",
                        code: -3,
                        userInfo: nil
                    )
                    completion(.failure(AuthenticationError.unknown(error)))
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
    internal func performPreAuthenticationChecks(
        reason: String,
        policy: AuthenticationPolicy
    ) -> AuthenticationResult? {
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
    private func performAuthentication(
        reason: String,
        policy: AuthenticationPolicy,
        completion: @escaping (AuthenticationResult) -> Void
    ) {
        // Delegate to LAContext-specific implementation
        performAuthenticationWithLAContext(reason: reason, policy: policy, completion: completion)
    }

    /// Invalidate the current authentication context and clear cached state.
    ///
    /// Forces termination of any active authentication context and clears
    /// the authentication cache. This should be called when security context
    /// changes or when maximum security is required.
    ///
    /// - Note: After invalidation, fresh authentication will be required
    ///   even if recent authentication cache would normally apply
    public func invalidateAuthentication() {
        queue.async { [weak self] in
            self?.context?.invalidate()
            self?.context = nil
            self?.lastAuthenticationTime = nil
        }
    }

    /// Clear the authentication cache without invalidating active contexts.
    ///
    /// Removes cached authentication timestamps, forcing fresh authentication
    /// on the next request. Does not affect active authentication contexts.
    ///
    /// Use this when authentication requirements change but you don't want
    /// to interrupt ongoing authentication flows.
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
