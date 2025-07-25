//
//  AuthenticationServiceLAContext.swift
//  MagSafe Guard
//
//  Created on 2025-07-25.
//
//  This file contains LAContext-dependent code that is difficult to unit test.
//  It is excluded from code coverage as it requires actual device authentication.
//

import Foundation
import LocalAuthentication

extension AuthenticationService {
    
    /// Perform the actual authentication using LAContext
    /// - Note: This method is excluded from coverage as it requires device authentication
    internal func performAuthenticationWithLAContext(reason: String, policy: AuthenticationPolicy, completion: @escaping (AuthenticationResult) -> Void) {
        let authContext = contextFactory.createContext()
        self.context = authContext
        
        let laPolicy: LAPolicy = policy.contains(.biometricOnly)
            ? .deviceOwnerAuthenticationWithBiometrics
            : .deviceOwnerAuthentication
        
        var error: NSError?
        guard authContext.canEvaluatePolicy(laPolicy, error: &error) else {
            let authError = mapLAError(error)
            DispatchQueue.main.async {
                completion(.failure(authError))
            }
            return
        }
        
        #if DEBUG
        print("[AuthenticationService] Authentication requested with reason: \(reason)")
        #endif
        
        // Security Note: We use evaluatePolicy here because it's the official Apple API
        // for biometric authentication. The Snyk warning about DeviceAuthenticationBypass
        // is mitigated through our comprehensive security measures:
        // 1. Rate limiting prevents brute force attempts
        // 2. Input validation prevents injection attacks
        // 3. Fresh contexts prevent replay attacks
        // 4. Production security checks validate authentication state
        // 5. Attempt tracking monitors for suspicious activity
        
        // Use async/await to call the protocol method
        Task {
            do {
                try await authContext.evaluatePolicy(laPolicy, localizedReason: reason)
                self.handleAuthenticationSuccess(context: authContext, completion: completion)
            } catch {
                self.handleAuthenticationError(error as NSError, completion: completion)
            }
        }
    }
    
    
    /// Handle authentication result
    private func handleAuthenticationResult(success: Bool, error: Error?, context: AuthenticationContextProtocol, completion: @escaping (AuthenticationResult) -> Void) {
        if success {
            handleAuthenticationSuccess(context: context, completion: completion)
        } else if let error = error {
            handleAuthenticationError(error as NSError, completion: completion)
        } else {
            recordAuthenticationAttempt(success: false)
            DispatchQueue.main.async {
                completion(.failure(AuthenticationError.unknown(NSError(domain: "AuthenticationService", code: -1, userInfo: nil))))
            }
        }
    }
    
    /// Handle successful authentication
    private func handleAuthenticationSuccess(context: AuthenticationContextProtocol, completion: @escaping (AuthenticationResult) -> Void) {
        recordAuthenticationAttempt(success: true)
        lastAuthenticationTime = Date()
        DispatchQueue.main.async {
            completion(.success)
        }
    }
    
    /// Handle authentication error
    private func handleAuthenticationError(_ error: NSError, completion: @escaping (AuthenticationResult) -> Void) {
        let authError = mapLAError(error)
        
        // Only record failed attempts for actual authentication failures
        if case .userCancel = authError {
            // Don't count cancellations as failed attempts
        } else {
            recordAuthenticationAttempt(success: false)
        }
        
        DispatchQueue.main.async {
            if case .userCancel = authError {
                completion(.cancelled)
            } else {
                completion(.failure(authError))
            }
        }
    }
    
}