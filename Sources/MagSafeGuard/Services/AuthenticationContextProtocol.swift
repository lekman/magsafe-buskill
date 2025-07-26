//
//  AuthenticationContextProtocol.swift
//  MagSafe Guard
//
//  Created on 2025-07-25.
//
//  Protocol defining authentication context operations.
//  This allows for testability by separating business logic from LAContext.
//

import Foundation
import LocalAuthentication

/// Protocol defining authentication context operations
public protocol AuthenticationContextProtocol {
    /// Check if biometric authentication can be evaluated
    func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool

    /// Evaluate authentication policy
    func evaluatePolicy(_ policy: LAPolicy, localizedReason: String) async throws

    /// Get the biometry type available on the device
    var biometryType: LABiometryType { get }

    /// Invalidate the context (for cleanup)
    func invalidate()
}

/// Real implementation using LAContext
public class RealAuthenticationContext: AuthenticationContextProtocol {
    private let context: LAContext

    /// Creates a new authentication context with LAContext
    public init() {
        self.context = LAContext()
    }

    /// Checks if the device can evaluate the specified policy
    public func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool {
        return context.canEvaluatePolicy(policy, error: error)
    }

    /// Evaluates the specified policy with user authentication
    public func evaluatePolicy(_ policy: LAPolicy, localizedReason: String) async throws {
        try await context.evaluatePolicy(policy, localizedReason: localizedReason)
    }

    /// Returns the type of biometry supported by the device
    public var biometryType: LABiometryType {
        return context.biometryType
    }

    /// Invalidates the authentication context
    public func invalidate() {
        context.invalidate()
    }
}

/// Factory for creating authentication contexts
public protocol AuthenticationContextFactoryProtocol {
    /// Creates a new authentication context
    /// - Returns: A new authentication context instance
    func createContext() -> AuthenticationContextProtocol
}

/// Real factory that creates LAContext instances
public class RealAuthenticationContextFactory: AuthenticationContextFactoryProtocol {
    /// Creates a new factory instance
    public init() {
        // No initialization required - factory simply creates LAContext instances on demand
    }

    /// Creates a new real authentication context
    /// - Returns: A new RealAuthenticationContext instance
    public func createContext() -> AuthenticationContextProtocol {
        return RealAuthenticationContext()
    }
}
