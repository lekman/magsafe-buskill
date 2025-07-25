//
//  AuthenticationService.swift
//  MagSafe Guard
//
//  Created on 2025-07-25.
//

import Foundation
import LocalAuthentication

/// Authentication service for handling biometric and password authentication
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
            
            // Configure context based on policy
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
            
            // Perform authentication
            context.evaluatePolicy(laPolicy, localizedReason: reason) { success, error in
                if success {
                    self.lastAuthenticationTime = Date()
                    DispatchQueue.main.async {
                        completion(.success)
                    }
                } else if let error = error {
                    let authError = self.mapLAError(error as NSError)
                    DispatchQueue.main.async {
                        if case .userCancel = authError {
                            completion(.cancelled)
                        } else {
                            completion(.failure(authError))
                        }
                    }
                } else {
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