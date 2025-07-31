//
//  MockLAContext.swift
//  MagSafe Guard
//
//  Created on 2025-07-25.
//

import Foundation
import LocalAuthentication

/// Mock LAContext for testing authentication flows
class MockLAContext: LAContext {

    // MARK: - Configuration

    var mockCanEvaluatePolicy = true
    var mockCanEvaluatePolicyError: Error?
    var mockEvaluatePolicyResult = true
    var mockEvaluatePolicyError: Error?
    var mockEvaluatePolicyDelay: TimeInterval = 0
    var mockBiometryType: LABiometryType = .none
    var mockEvaluatedPolicyDomainState: Data? = Data([1, 2, 3, 4])

    // MARK: - Tracking

    var evaluatePolicyCalled = false
    var evaluatePolicyCount = 0
    var lastEvaluatePolicyReason: String?
    var lastEvaluatePolicyPolicy: LAPolicy?

    // MARK: - Overrides

    override var biometryType: LABiometryType {
        return mockBiometryType
    }

    override var evaluatedPolicyDomainState: Data? {
        return mockEvaluatedPolicyDomainState
    }

    override func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool {
        if let mockError = mockCanEvaluatePolicyError {
            error?.pointee = mockError as NSError
            return false
        }
        return mockCanEvaluatePolicy
    }

    override func evaluatePolicy(_ policy: LAPolicy, localizedReason: String, reply: @escaping (Bool, Error?) -> Void) {
        evaluatePolicyCalled = true
        evaluatePolicyCount += 1
        lastEvaluatePolicyReason = localizedReason
        lastEvaluatePolicyPolicy = policy

        // Simulate async behavior
        DispatchQueue.main.asyncAfter(deadline: .now() + mockEvaluatePolicyDelay) {
            reply(self.mockEvaluatePolicyResult, self.mockEvaluatePolicyError)
        }
    }
}

/// Factory for creating LAError instances for testing
class LAErrorFactory {

    static func createError(code: LAError.Code) -> NSError {
        return NSError(domain: LAErrorDomain, code: code.rawValue, userInfo: nil)
    }

    static func biometryNotAvailable() -> NSError {
        return createError(code: .biometryNotAvailable)
    }

    static func biometryNotEnrolled() -> NSError {
        return createError(code: .biometryNotEnrolled)
    }

    static func biometryLockout() -> NSError {
        return createError(code: .biometryLockout)
    }

    static func userCancel() -> NSError {
        return createError(code: .userCancel)
    }

    static func userFallback() -> NSError {
        return createError(code: .userFallback)
    }

    static func systemCancel() -> NSError {
        return createError(code: .systemCancel)
    }

    static func passcodeNotSet() -> NSError {
        return createError(code: .passcodeNotSet)
    }

    static func authenticationFailed() -> NSError {
        return createError(code: .authenticationFailed)
    }

    static func appCancel() -> NSError {
        return createError(code: .appCancel)
    }

    static func invalidContext() -> NSError {
        return createError(code: .invalidContext)
    }

    static func notInteractive() -> NSError {
        return createError(code: .notInteractive)
    }
}
