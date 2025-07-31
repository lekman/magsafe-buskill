//
//  MockAuthenticationContext.swift
//  MagSafe Guard
//
//  Created on 2025-07-25.
//
//  Mock implementation of authentication context for testing.
//

import Foundation
import LocalAuthentication
@testable import MagSafeGuard

/// Mock implementation of authentication context for testing
class MockAuthenticationContext: AuthenticationContextProtocol {

    // Control test behavior
    var canEvaluatePolicyResult = true
    var canEvaluatePolicyError: Error?
    var evaluatePolicyShouldSucceed = true
    var evaluatePolicyError: Error?
    var mockBiometryType: LABiometryType = .touchID

    // Track what was called
    var canEvaluatePolicyCalled = false
    var evaluatePolicyCalled = false
    var evaluatePolicyReason: String?
    var invalidateCalled = false

    func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool {
        canEvaluatePolicyCalled = true
        if let canEvaluatePolicyError = canEvaluatePolicyError {
            error?.pointee = canEvaluatePolicyError as NSError
        }
        return canEvaluatePolicyResult
    }

    func evaluatePolicy(_ policy: LAPolicy, localizedReason: String) async throws {
        evaluatePolicyCalled = true
        evaluatePolicyReason = localizedReason

        if !evaluatePolicyShouldSucceed {
            throw evaluatePolicyError ?? LAError(.authenticationFailed)
        }
    }

    var biometryType: LABiometryType {
        return mockBiometryType
    }

    func invalidate() {
        invalidateCalled = true
    }

    // Reset method for test setup
    func reset() {
        canEvaluatePolicyResult = true
        canEvaluatePolicyError = nil
        evaluatePolicyShouldSucceed = true
        evaluatePolicyError = nil
        mockBiometryType = .touchID

        canEvaluatePolicyCalled = false
        evaluatePolicyCalled = false
        evaluatePolicyReason = nil
        invalidateCalled = false
    }
}
